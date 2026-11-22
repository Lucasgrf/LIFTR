import { z } from "npm:zod@3.23.8";
import {
  buildGeminiPrompts,
  type CatalogExercise,
  CatalogExerciseSchema,
  extractJsonObject,
  GenerateWorkoutRequestSchema,
  type GroundedPlan,
  validateAndGroundPlan,
} from "./grounding.ts";

const GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta";
const GEMINI_MODEL = "gemini-2.5-flash";

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
        parts: z.array(z.object({ text: z.string().optional() })),
      }),
    }),
  ).min(1),
});

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: CORS_HEADERS,
  });
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

async function callGeminiOnce(params: {
  apiKey: string;
  system: string;
  user: string;
  temperature: number;
  catalog: readonly CatalogExercise[];
}): Promise<GroundedPlan> {
  const resp = await fetch(
    `${GEMINI_BASE_URL}/models/${GEMINI_MODEL}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": params.apiKey,
      },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: params.system }] },
        contents: [{ role: "user", parts: [{ text: params.user }] }],
        generationConfig: {
          temperature: params.temperature,
          responseMimeType: "application/json",
        },
      }),
    },
  );

  if (!resp.ok) {
    throw new Error(`Gemini retornou HTTP ${resp.status}.`);
  }

  const rawBody = await resp.json() as unknown;
  const parsedEnvelope = GeminiApiResponseSchema.safeParse(rawBody);
  if (!parsedEnvelope.success) {
    throw new Error("Resposta do Gemini sem conteúdo utilizável.");
  }

  const rawText = parsedEnvelope.data.candidates[0].content.parts
    .map((p) => p.text ?? "")
    .join("");
  const decoded = extractJsonObject(rawText);
  return validateAndGroundPlan(decoded, params.catalog);
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

  const geminiKey = Deno.env.get("GEMINI_API_KEY")?.trim() ?? "";
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
    let plan: GroundedPlan;
    try {
      plan = await callGeminiOnce({
        apiKey: geminiKey,
        system: prompts.system,
        user: prompts.user,
        temperature: 0.25,
        catalog,
      });
    } catch {
      plan = await callGeminiOnce({
        apiKey: geminiKey,
        system: prompts.system,
        user: prompts.user,
        temperature: 0.1,
        catalog,
      });
    }

    return jsonResponse({ plan, model: GEMINI_MODEL }, 200);
  } catch (err) {
    const message = err instanceof Error
      ? err.message
      : "Não foi possível gerar o treino com a IA agora.";
    return jsonResponse({ error: "AI_GENERATION_FAILED", message }, 502);
  }
});
