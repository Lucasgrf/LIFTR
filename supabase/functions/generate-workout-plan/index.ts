import { z } from "npm:zod@3.23.8";
import {
  buildGeminiPrompts,
  type CatalogExercise,
  CatalogExerciseSchema,
  extractJsonObject,
  type GeminiModelDescriptor,
  GenerateWorkoutRequestSchema,
  type GroundedPlan,
  rankGeminiCandidateModels,
  validateAndGroundPlan,
} from "./grounding.ts";

const GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta";

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

const GeminiApiResponseSchema = z.object({
  candidates: z.array(
    z.object({
      content: z.object({
        parts: z.array(
          z.object({
            text: z.string().optional(),
            thought: z.boolean().optional(),
          }),
        ),
      }),
    }),
  ).min(1),
});

const GeminiModelsListSchema = z.object({
  models: z.array(
    z.object({
      name: z.string(),
      supportedGenerationMethods: z.array(z.string()).optional(),
    }),
  ).optional(),
});

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: CORS_HEADERS,
  });
}

function sanitizeApiKey(raw: string): string {
  return raw
    .trim()
    .replace(/^Bearer\s+/i, "")
    .replace(/^["']+|["']+$/g, "")
    .trim();
}

async function verifyAuthenticatedUser(
  supabaseUrl: string,
  anonKey: string,
  authHeader: string,
): Promise<boolean> {
  try {
    const resp = await fetch(`${supabaseUrl}/auth/v1/user`, {
      method: "GET",
      headers: {
        Authorization: authHeader,
        apikey: anonKey,
      },
    });
    return resp.ok;
  } catch {
    return false;
  }
}

async function fetchUserVisibleCatalog(
  supabaseUrl: string,
  anonKey: string,
  authHeader: string,
): Promise<CatalogExercise[]> {
  const endpoint =
    `${supabaseUrl}/rest/v1/exercises` +
    "?select=id,name,primary_muscle_group,equipment,movement_pattern" +
    "&deleted_at=is.null&order=name.asc&limit=300";

  const resp = await fetch(endpoint, {
    method: "GET",
    headers: {
      Authorization: authHeader,
      apikey: anonKey,
      Accept: "application/json",
    },
  });

  if (!resp.ok) {
    throw new Error(`Falha ao consultar catálogo (${resp.status}).`);
  }

  const rawList = await resp.json() as unknown;
  const parsed = z.array(CatalogExerciseSchema).safeParse(rawList);
  if (!parsed.success) {
    throw new Error("Catálogo de exercícios em formato inesperado.");
  }
  return parsed.data;
}

async function discoverModelsForKey(
  apiKey: string,
): Promise<GeminiModelDescriptor[]> {
  try {
    const url =
      `${GEMINI_BASE_URL}/models?pageSize=100&key=${encodeURIComponent(apiKey)}`;
    const resp = await fetch(url, {
      method: "GET",
      headers: { "x-goog-api-key": apiKey },
    });
    if (!resp.ok) return [];
    const raw = await resp.json() as unknown;
    const parsed = GeminiModelsListSchema.safeParse(raw);
    return parsed.success ? (parsed.data.models ?? []) : [];
  } catch {
    return [];
  }
}

async function callGeminiModelOnce(params: {
  apiKey: string;
  modelId: string;
  system: string;
  user: string;
  temperature: number;
  useJsonMimeType: boolean;
  catalog: readonly CatalogExercise[];
}): Promise<GroundedPlan> {
  const cleanModel = params.modelId.replace(/^models\//i, "");
  const url =
    `${GEMINI_BASE_URL}/models/${cleanModel}:generateContent` +
    `?key=${encodeURIComponent(params.apiKey)}`;

  const generationConfig: Record<string, unknown> = {
    temperature: params.temperature,
  };
  if (params.useJsonMimeType) {
    generationConfig.responseMimeType = "application/json";
  }

  const resp = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": params.apiKey,
    },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: params.system }] },
      contents: [{ role: "user", parts: [{ text: params.user }] }],
      generationConfig,
    }),
  });

  if (!resp.ok) {
    let detail = "";
    try {
      const errBody = await resp.json() as {
        error?: { message?: string; status?: string };
      };
      if (errBody?.error?.message) {
        detail = `: ${errBody.error.message}`;
      }
    } catch {
      // Ignore non-JSON error body
    }
    throw new Error(
      `Gemini (${cleanModel}) retornou HTTP ${resp.status}${detail}`,
    );
  }

  const rawBody = await resp.json() as unknown;
  const parsedEnvelope = GeminiApiResponseSchema.safeParse(rawBody);
  if (!parsedEnvelope.success) {
    throw new Error(`Resposta do modelo ${cleanModel} sem conteúdo utilizável.`);
  }

  const parts = parsedEnvelope.data.candidates[0].content.parts;
  const nonThoughtParts = parts.filter((p) => p.thought !== true);
  const effectiveParts = nonThoughtParts.length > 0 ? nonThoughtParts : parts;

  const rawText = effectiveParts.map((p) => p.text ?? "").join("\n");
  const decoded = extractJsonObject(rawText);
  return validateAndGroundPlan(decoded, params.catalog);
}

async function generateWithFallbackModels(params: {
  apiKey: string;
  system: string;
  user: string;
  catalog: readonly CatalogExercise[];
}): Promise<{ plan: GroundedPlan; model: string }> {
  const discovered = await discoverModelsForKey(params.apiKey);
  const candidates = rankGeminiCandidateModels(discovered).slice(0, 5);
  const errors: string[] = [];

  for (const modelId of candidates) {
    try {
      const plan = await callGeminiModelOnce({
        apiKey: params.apiKey,
        modelId,
        system: params.system,
        user: params.user,
        temperature: 0.2,
        useJsonMimeType: true,
        catalog: params.catalog,
      });
      return { plan, model: modelId };
    } catch (firstErr) {
      const firstMsg = firstErr instanceof Error
        ? firstErr.message
        : String(firstErr);

      // If the model exists (not 404/401/403) but rejected responseMimeType
      // or produced a transient schema mismatch, retry once on the same model.
      const isNotFoundOrAuth =
        firstMsg.includes("HTTP 404") ||
        firstMsg.includes("HTTP 401") ||
        firstMsg.includes("HTTP 403");

      if (!isNotFoundOrAuth) {
        try {
          const plan = await callGeminiModelOnce({
            apiKey: params.apiKey,
            modelId,
            system: params.system,
            user: params.user,
            temperature: 0.1,
            useJsonMimeType: !firstMsg.includes("HTTP 400"),
            catalog: params.catalog,
          });
          return { plan, model: modelId };
        } catch (retryErr) {
          errors.push(
            retryErr instanceof Error ? retryErr.message : String(retryErr),
          );
          continue;
        }
      }

      errors.push(firstMsg);
    }
  }

  throw new Error(
    errors[0] ?? "Não foi possível gerar o treino com os modelos Gemini.",
  );
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      { error: "METHOD_NOT_ALLOWED", message: "Use POST." },
      405,
    );
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim() ?? "";
  const anonKey =
    Deno.env.get("SUPABASE_ANON_KEY")?.trim() ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY")?.trim() ??
    "";

  if (!supabaseUrl || !anonKey) {
    return jsonResponse(
      {
        error: "SERVER_MISCONFIGURED",
        message: "Variáveis do Supabase ausentes no servidor.",
      },
      500,
    );
  }

  const authHeader = req.headers.get("Authorization")?.trim() ?? "";
  if (!authHeader.toLowerCase().startsWith("bearer ")) {
    return jsonResponse(
      {
        error: "UNAUTHORIZED",
        message: "Faça login antes de gerar um treino com IA.",
      },
      401,
    );
  }

  const isValidUser = await verifyAuthenticatedUser(
    supabaseUrl,
    anonKey,
    authHeader,
  );
  if (!isValidUser) {
    return jsonResponse(
      {
        error: "UNAUTHORIZED",
        message: "Sessão expirada. Entre novamente para usar a IA.",
      },
      401,
    );
  }

  const geminiKey = sanitizeApiKey(Deno.env.get("GEMINI_API_KEY") ?? "");
  if (!geminiKey) {
    return jsonResponse(
      {
        error: "GEMINI_KEY_NOT_CONFIGURED",
        message:
          "A chave GEMINI_API_KEY ainda não está configurada no Supabase.",
      },
      503,
    );
  }

  let bodyJson: unknown;
  try {
    bodyJson = await req.json();
  } catch {
    return jsonResponse(
      {
        error: "BAD_REQUEST",
        message: "Corpo da requisição precisa ser JSON válido.",
      },
      400,
    );
  }

  const reqParsed = GenerateWorkoutRequestSchema.safeParse(bodyJson);
  if (!reqParsed.success) {
    return jsonResponse(
      {
        error: "BAD_REQUEST",
        message: reqParsed.error.issues[0]?.message ?? "Parâmetros inválidos.",
      },
      400,
    );
  }

  let catalog: CatalogExercise[];
  try {
    catalog = await fetchUserVisibleCatalog(supabaseUrl, anonKey, authHeader);
  } catch (err) {
    const message = err instanceof Error
      ? err.message
      : "Erro ao consultar exercícios.";
    return jsonResponse({ error: "CATALOG_ERROR", message }, 502);
  }

  if (catalog.length === 0) {
    return jsonResponse(
      {
        error: "EMPTY_CATALOG",
        message: "Nenhum exercício disponível no catálogo para montar o treino.",
      },
      422,
    );
  }

  const prompts = buildGeminiPrompts(reqParsed.data, catalog);

  try {
    const result = await generateWithFallbackModels({
      apiKey: geminiKey,
      system: prompts.system,
      user: prompts.user,
      catalog,
    });
    return jsonResponse({ plan: result.plan, model: result.model }, 200);
  } catch (err) {
    const message = err instanceof Error
      ? err.message
      : "Não foi possível gerar o treino com a IA agora.";
    return jsonResponse({ error: "AI_GENERATION_FAILED", message }, 502);
  }
});
