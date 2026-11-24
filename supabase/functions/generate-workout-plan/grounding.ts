import { z } from "npm:zod@3.23.8";

export const GenerateWorkoutRequestSchema = z.object({
  goal: z.enum([
    "hypertrophy",
    "fat_loss",
    "strength",
    "conditioning",
    "recomposition",
  ]),
  experience: z.enum(["beginner", "intermediate", "advanced"]),
  days_per_week: z.number().int().min(2).max(6),
  session_minutes: z.number().int().min(25).max(120).default(60),
  preferred_split: z.string().trim().max(80).optional(),
  focus_muscles: z.array(z.string().trim().min(1).max(40)).max(6).default([]),
  equipment_access: z.enum([
    "full_gym",
    "home_dumbbells",
    "minimal",
  ]).default("full_gym"),
  include_cardio: z.boolean().default(true),
  cardio_minutes_per_session: z.number().int().min(0).max(90).default(15),
  restrictions_notes: z.string().trim().max(400).optional(),
  biological_sex: z.enum(["M", "F"]).optional(),
});

export type GenerateWorkoutRequest = z.infer<typeof GenerateWorkoutRequestSchema>;

export const CatalogExerciseSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  primary_muscle_group: z.string().min(1),
  equipment: z.string().nullable().optional(),
  movement_pattern: z.string().nullable().optional(),
});

export type CatalogExercise = z.infer<typeof CatalogExerciseSchema>;

export type GeminiModelDescriptor = {
  name: string;
  supportedGenerationMethods?: readonly string[];
};

export const FALLBACK_GEMINI_MODELS: readonly string[] = [
  "gemini-4-hydrogen",
  "gemini-4-argon",
  "gemini-4-carbon",
  "gemini-3.8-flash",
  "gemini-3-flash-preview",
  "gemini-2.5-flash",
  "gemini-2.0-flash",
  "gemini-1.5-flash",
];

const EXCLUDED_MODEL_SUBSTRINGS = [
  "embedding",
  "imagen",
  "veo",
  "tts",
  "audio",
  "aqa",
  "robotics",
  "computer-use",
  "learnlm",
  "image-generation",
  "live",
  "bisect",
];

function scoreGeminiModelId(id: string): number {
  const lower = id.toLowerCase();
  let score = 0;

  if (lower.startsWith("gemini-4")) score += 5000;
  else if (lower.startsWith("gemini-3.8")) score += 4300;
  else if (lower.startsWith("gemini-3.7")) score += 4200;
  else if (lower.startsWith("gemini-3.5")) score += 4000;
  else if (lower.startsWith("gemini-3")) score += 3800;
  else if (lower.startsWith("gemini-2.5")) score += 3000;
  else if (lower.startsWith("gemini-2.0")) score += 2500;
  else if (lower.startsWith("gemini-1.5")) score += 2000;
  else if (lower.startsWith("gemini-")) score += 1000;

  if (lower.includes("hydrogen")) score += 180;
  else if (lower.includes("argon")) score += 140;
  else if (lower.includes("flash") && !lower.includes("lite")) score += 120;
  else if (lower.includes("carbon") || lower.includes("pro")) score += 100;
  else if (lower.includes("neon")) score += 90;
  else if (lower.includes("lite")) score += 70;

  if (lower.includes("latest")) score += 15;
  if (lower.includes("exp")) score -= 40;

  return score;
}

/**
 * Ranks available Gemini models returned by `GET /v1beta/models`, prioritizing
 * Gemini 4 Hydrogen (`gemini-4-hydrogen`) as #1 followed by `gemini-4-argon`,
 * `gemini-4-carbon` and the newest available Flash/Pro models supporting `generateContent`.
 */
export function rankGeminiCandidateModels(
  discovered: readonly GeminiModelDescriptor[],
): string[] {
  const validDiscovered: string[] = [];

  for (const item of discovered) {
    const cleanId = item.name.trim().replace(/^models\//i, "");
    const lower = cleanId.toLowerCase();
    if (!lower.startsWith("gemini-")) continue;

    if (
      item.supportedGenerationMethods &&
      !item.supportedGenerationMethods.includes("generateContent")
    ) {
      continue;
    }

    if (EXCLUDED_MODEL_SUBSTRINGS.some((sub) => lower.includes(sub))) {
      continue;
    }

    validDiscovered.push(cleanId);
  }

  validDiscovered.sort((a, b) => scoreGeminiModelId(b) - scoreGeminiModelId(a));

  const seen = new Set<string>();
  const result: string[] = [];

  // If discovery succeeded, prioritize the models confirmed to exist on this key,
  // while still keeping static Gemini 4 / fallback IDs at the tail.
  for (const id of [...validDiscovered, ...FALLBACK_GEMINI_MODELS]) {
    if (!seen.has(id)) {
      seen.add(id);
      result.push(id);
    }
  }

  return result;
}

const AiRawExerciseSchema = z.object({
  exercise_id: z.string().min(1),
  exercise_name: z.string().min(1),
  is_cardio: z.boolean().optional(),
  sets_count: z.number().int().min(1).max(12).default(3),
  target_reps_min: z.number().int().min(1).max(50).nullable().optional(),
  target_reps_max: z.number().int().min(1).max(50).nullable().optional(),
  target_duration_minutes: z.number().int().min(1).max(180).nullable().optional(),
  target_rir_min: z.number().int().min(0).max(5).nullable().optional(),
  target_rir_max: z.number().int().min(0).max(5).nullable().optional(),
  rest_seconds: z.number().int().min(0).max(600).default(120),
  notes: z.string().max(300).nullable().optional(),
});

const AiRawWorkoutSchema = z.object({
  name: z.string().trim().min(1).max(80),
  day_of_week: z.number().int().min(0).max(6).nullable().optional(),
  estimated_duration_minutes: z.number().int().min(15).max(180).default(55),
  notes: z.string().max(300).nullable().optional(),
  exercises: z.array(AiRawExerciseSchema).min(1).max(14),
});

export const AiRawPlanSchema = z.object({
  plan_name: z.string().trim().min(2).max(100),
  split_type: z.string().trim().min(2).max(80),
  description: z.string().trim().min(2).max(300),
  rationale: z.string().trim().min(2).max(600),
  workouts: z.array(AiRawWorkoutSchema).min(1).max(7),
});

export type GroundedExercise = {
  exercise_id: string;
  exercise_name: string;
  primary_muscle_group: string;
  equipment: string | null;
  movement_pattern: string | null;
  is_cardio: boolean;
  sets_count: number;
  target_reps_min: number | null;
  target_reps_max: number | null;
  target_duration_minutes: number | null;
  target_rir_min: number | null;
  target_rir_max: number | null;
  rest_seconds: number;
  notes: string | null;
};

export type GroundedWorkout = {
  name: string;
  day_of_week: number | null;
  estimated_duration_minutes: number;
  notes: string | null;
  exercises: GroundedExercise[];
};

export type GroundedPlan = {
  plan_name: string;
  split_type: string;
  description: string;
  rationale: string;
  workouts: GroundedWorkout[];
};

const CARDIO_KEYWORDS = [
  "esteira",
  "bicicleta",
  "ergometrica",
  "ergométrica",
  "eliptico",
  "elíptico",
  "escada",
  "corrida",
  "caminhada",
];

function clamp(val: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, Math.round(val)));
}

const HEAVY_COMPOUND_PATTERNS = new Set([
  "squat",
  "hinge",
  "horizontal_push",
  "vertical_push",
  "horizontal_pull",
  "vertical_pull",
]);

export function resolveRecommendedRestSeconds(
  repsMin: number,
  repsMax: number,
  movementPattern?: string | null,
): number {
  if (repsMax <= 10) {
    return 180;
  }
  const normalizedPattern = (movementPattern ?? "").trim().toLowerCase();
  if (
    repsMin >= 12 ||
    (repsMax >= 13 &&
      (normalizedPattern === "isolation" || normalizedPattern === "carry"))
  ) {
    return 120;
  }
  return HEAVY_COMPOUND_PATTERNS.has(normalizedPattern) ? 180 : 120;
}

function normalizeText(value: string): string {
  return value.trim().toLowerCase();
}

export function isCatalogExerciseCardio(ex: CatalogExercise): boolean {
  const pattern = normalizeText(ex.movement_pattern ?? "");
  const muscle = normalizeText(ex.primary_muscle_group);
  const name = normalizeText(ex.name);
  if (pattern === "cardio" || muscle === "cardio" || name === "cardio") {
    return true;
  }
  return CARDIO_KEYWORDS.some((kw) => name.includes(kw));
}

export function extractJsonObject(rawText: string): unknown {
  const trimmed = rawText.trim();
  if (!trimmed) {
    throw new Error("Resposta vazia recebida do modelo.");
  }
  const fenceMatch = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const candidate = fenceMatch ? fenceMatch[1].trim() : trimmed;
  try {
    return JSON.parse(candidate) as unknown;
  } catch {
    const firstBrace = candidate.indexOf("{");
    const lastBrace = candidate.lastIndexOf("}");
    if (firstBrace >= 0 && lastBrace > firstBrace) {
      return JSON.parse(candidate.slice(firstBrace, lastBrace + 1)) as unknown;
    }
    throw new Error("Resposta do modelo não contém JSON válido.");
  }
}

export function validateAndGroundPlan(
  raw: unknown,
  catalog: readonly CatalogExercise[],
): GroundedPlan {
  if (catalog.length === 0) {
    throw new Error("Catálogo de exercícios indisponível para validação.");
  }

  const parsed = AiRawPlanSchema.safeParse(raw);
  if (!parsed.success) {
    throw new Error(
      `JSON do plano inválido: ${parsed.error.issues[0]?.message ?? "formato incorreto"}`,
    );
  }

  const byId = new Map<string, CatalogExercise>();
  const byName = new Map<string, CatalogExercise>();
  for (const item of catalog) {
    byId.set(item.id.trim(), item);
    byName.set(normalizeText(item.name), item);
  }

  const groundedWorkouts: GroundedWorkout[] = [];

  for (const workout of parsed.data.workouts) {
    const groundedExercises: GroundedExercise[] = [];

    for (const ex of workout.exercises) {
      const matched =
        byId.get(ex.exercise_id.trim()) ??
        byName.get(normalizeText(ex.exercise_name));

      if (!matched) {
        continue;
      }

      const cardio = isCatalogExerciseCardio(matched) || ex.is_cardio === true;
      if (cardio) {
        const durationMinutes = clamp(ex.target_duration_minutes ?? 15, 5, 120);
        groundedExercises.push({
          exercise_id: matched.id,
          exercise_name: matched.name,
          primary_muscle_group: matched.primary_muscle_group,
          equipment: matched.equipment ?? null,
          movement_pattern: matched.movement_pattern ?? null,
          is_cardio: true,
          sets_count: 1,
          target_reps_min: null,
          target_reps_max: null,
          target_duration_minutes: durationMinutes,
          target_rir_min: null,
          target_rir_max: null,
          rest_seconds: 0,
          notes: ex.notes?.trim() || null,
        });
        continue;
      }

      const rawMin = clamp(ex.target_reps_min ?? 8, 3, 30);
      const rawMax = clamp(ex.target_reps_max ?? Math.max(rawMin + 2, 12), 3, 35);
      const repsMin = Math.min(rawMin, rawMax);
      const repsMax = Math.max(rawMin, rawMax);

      const rawRirMin = clamp(ex.target_rir_min ?? 1, 0, 4);
      const rawRirMax = clamp(ex.target_rir_max ?? Math.max(rawRirMin, 2), 0, 5);
      const rirMin = Math.min(rawRirMin, rawRirMax);
      const rirMax = Math.max(rawRirMin, rawRirMax);

      const recommendedRest = resolveRecommendedRestSeconds(
        repsMin,
        repsMax,
        matched.movement_pattern,
      );
      const rawRest = clamp(ex.rest_seconds, 60, 300);
      const needsRestNormalization =
        (repsMin >= 12 && rawRest >= 180) ||
        (repsMax <= 10 && rawRest < 150);
      const restSeconds = needsRestNormalization ? recommendedRest : rawRest;

      groundedExercises.push({
        exercise_id: matched.id,
        exercise_name: matched.name,
        primary_muscle_group: matched.primary_muscle_group,
        equipment: matched.equipment ?? null,
        movement_pattern: matched.movement_pattern ?? null,
        is_cardio: false,
        sets_count: clamp(ex.sets_count, 1, 8),
        target_reps_min: repsMin,
        target_reps_max: repsMax,
        target_duration_minutes: null,
        target_rir_min: rirMin,
        target_rir_max: rirMax,
        rest_seconds: restSeconds,
        notes: ex.notes?.trim() || null,
      });
    }

    if (groundedExercises.length === 0) {
      throw new Error(
        `O treino "${workout.name}" não retornou exercícios válidos do catálogo.`,
      );
    }

    groundedWorkouts.push({
      name: workout.name.trim(),
      day_of_week: workout.day_of_week ?? null,
      estimated_duration_minutes: clamp(workout.estimated_duration_minutes, 20, 150),
      notes: workout.notes?.trim() || null,
      exercises: groundedExercises,
    });
  }

  if (groundedWorkouts.length === 0) {
    throw new Error("Nenhuma sessão de treino válida foi gerada.");
  }

  return {
    plan_name: parsed.data.plan_name.trim(),
    split_type: parsed.data.split_type.trim(),
    description: parsed.data.description.trim(),
    rationale: parsed.data.rationale.trim(),
    workouts: groundedWorkouts,
  };
}

export function buildGeminiPrompts(
  req: GenerateWorkoutRequest,
  catalog: readonly CatalogExercise[],
): { system: string; user: string } {
  const system = [
    "Você é o treinador especialista em prescrição baseada em evidências do app LIFTR.",
    "Sua tarefa é montar uma periodização semanal prática em JSON estrito.",
    "Regras obrigatórias:",
    "1. Use EXCLUSIVAMENTE exercícios presentes no CATÁLOGO JSON fornecido abaixo,",
    "   copiando exatamente o campo 'exercise_id' e 'exercise_name'.",
    "2. Nunca invente IDs ou exercícios fora do catálogo.",
    "3. Respeite exatamente 'days_per_week' no número de sessões do array 'workouts'.",
    "4. Ajuste o volume semanal total à experiência (iniciante: 10-14 séries/grupo;",
    "   intermediário: 12-18; avançado: 14-22) e ao tempo disponível por sessão.",
    "5. Se 'include_cardio' for true, inclua 1 exercício de cardio ao final de",
    "   2 a 4 sessões (usando exercise_id de cardio do catálogo), com sets_count=1,",
    "   rest_seconds=0, target_reps_min=null, target_reps_max=null e",
    "   target_duration_minutes preenchido.",
    "6. Para exercícios de força: sets_count entre 2 e 5, target_rir_min/max (ex: 1-2) e target_duration_minutes=null.",
    "   Calibre repetições e descanso pelo tipo do exercício:",
    "   - Multiarticulares/compostos pesados (supino, agachamento, terra, remada livre/barra, desenvolvimento, leg press, barra fixa): target_reps_min=6, target_reps_max=10 (ou 6-8 em força) e rest_seconds=180 (3 min).",
    "   - Auxiliares, isoladores ou mais leves (elevação lateral, rosca, tríceps, extensora/flexora, crucifixo, panturrilha, abdominal): target_reps_min=12, target_reps_max=15 e rest_seconds=120 (2 min).",
    "   - Exercícios intermediários 8-12: compostos pesados usam rest_seconds=180; isoladores/máquinas/cabos leves usam rest_seconds=120.",
    "7. Escolha da divisão ('split_type'):",
    "   - Se 'preferred_split' for informado, siga exatamente essa divisão.",
    "   - Se 'preferred_split' for null, NÃO retorne Upper/Lower por padrão para todos os alunos! Escolha a melhor divisão baseada em experiência, dias_por_semana, objetivo e enfase_muscular:",
    "     * Iniciante: 2-3 dias -> Full Body; 4 dias -> AB (Superior/Inferior) ou ABCD equilibrado conforme foco; 5-6 dias -> ABC ou Push / Pull / Legs moderado.",
    "     * Intermediário: 2 dias -> Full Body 2x; 3 dias -> Full Body 3x, ABC ou Push / Pull / Legs; 4 dias -> varie conforme objetivo e foco (ABCD · Inferiores & Glúteos quando houver foco em pernas/glúteos, ABCD clássico para hipertrofia segmentada, Torso / Membros ou Upper / Lower apenas quando ideal para força/equilíbrio); 5 dias -> PPL + Upper / Lower ou ABCDE; 6 dias -> Push / Pull / Legs 2x ou ABC 2x.",
    "     * Avançado: 3-4 dias -> ABCD, Torso / Membros ou Upper / Lower especializado; 5 dias -> PPL + Upper / Lower ou ABCDE; 6 dias -> Push / Pull / Legs 2x ou Arnold Split.",
    "   - Explique no campo 'rationale' por que essa divisão foi escolhida para o nível e objetivo do aluno.",
    "8. Retorne SOMENTE um objeto JSON válido com o formato exato:",
    "{",
    '  "plan_name": string,',
    '  "split_type": string,',
    '  "description": string,',
    '  "rationale": string,',
    '  "workouts": [{',
    '    "name": string,',
    '    "day_of_week": number | null,',
    '    "estimated_duration_minutes": number,',
    '    "notes": string | null,',
    '    "exercises": [{',
    '      "exercise_id": string,',
    '      "exercise_name": string,',
    '      "is_cardio": boolean,',
    '      "sets_count": number,',
    '      "target_reps_min": number | null,',
    '      "target_reps_max": number | null,',
    '      "target_duration_minutes": number | null,',
    '      "target_rir_min": number | null,',
    '      "target_rir_max": number | null,',
    '      "rest_seconds": number,',
    '      "notes": string | null',
    "    }]",
    "  }]",
    "}",
  ].join("\n");

  const compactCatalog = catalog.map((ex) => ({
    id: ex.id,
    name: ex.name,
    muscle: ex.primary_muscle_group,
    equipment: ex.equipment ?? "machine",
    pattern: ex.movement_pattern ?? "isolation",
  }));

  const user = JSON.stringify({
    aluno: {
      objetivo: req.goal,
      experiencia: req.experience,
      dias_por_semana: req.days_per_week,
      minutos_por_sessao: req.session_minutes,
      divisao_preferida: req.preferred_split ?? null,
      enfase_muscular: req.focus_muscles,
      equipamentos_disponiveis: req.equipment_access,
      incluir_cardio: req.include_cardio,
      cardio_minutos_por_sessao: req.include_cardio ? req.cardio_minutes_per_session : 0,
      restricoes_observacoes: req.restrictions_notes ?? null,
      sexo_biologico: req.biological_sex ?? null,
    },
    catalogo_exercicios: compactCatalog,
  });

  return { system, user };
}
