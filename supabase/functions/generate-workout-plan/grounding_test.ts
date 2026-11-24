import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import {
  buildGeminiPrompts,
  type CatalogExercise,
  extractJsonObject,
  GenerateWorkoutRequestSchema,
  rankGeminiCandidateModels,
  validateAndGroundPlan,
} from "./grounding.ts";

const SAMPLE_CATALOG: CatalogExercise[] = [
  {
    id: "00000000-0000-4000-8000-000000000001",
    name: "Supino reto com barra",
    primary_muscle_group: "chest",
    equipment: "barbell",
    movement_pattern: "horizontal_push",
  },
  {
    id: "00000000-0000-4000-8000-000000000014",
    name: "Agachamento livre com barra",
    primary_muscle_group: "legs",
    equipment: "barbell",
    movement_pattern: "squat",
  },
  {
    id: "00000000-0000-4000-8000-000000000035",
    name: "Esteira / Cardio",
    primary_muscle_group: "cardio",
    equipment: "machine",
    movement_pattern: "cardio",
  },
];

Deno.test("grounding: grounds valid strength + cardio plan and clamps sets", () => {
  const raw = {
    plan_name: "Upper / Lower Personalizado",
    split_type: "Upper / Lower",
    description: "4 sessões equilibradas com cardio pós-treino.",
    rationale: "Distribuição ideal para 4 dias semanais.",
    workouts: [
      {
        name: "Upper A",
        day_of_week: 1,
        estimated_duration_minutes: 60,
        notes: null,
        exercises: [
          {
            exercise_id: "00000000-0000-4000-8000-000000000001",
            exercise_name: "Supino reto com barra",
            is_cardio: false,
            sets_count: 4,
            target_reps_min: 10,
            target_reps_max: 8,
            target_duration_minutes: null,
            target_rir_min: 1,
            target_rir_max: 2,
            rest_seconds: 180,
            notes: "Controlar excêntrica",
          },
          {
            exercise_id: "00000000-0000-4000-8000-000000000035",
            exercise_name: "Esteira / Cardio",
            is_cardio: true,
            sets_count: 3,
            target_reps_min: 12,
            target_reps_max: 15,
            target_duration_minutes: 20,
            target_rir_min: 2,
            target_rir_max: 2,
            rest_seconds: 120,
            notes: "Zona 2",
          },
        ],
      },
    ],
  };

  const grounded = validateAndGroundPlan(raw, SAMPLE_CATALOG);
  assertEquals(grounded.workouts.length, 1);
  assertEquals(grounded.workouts[0].exercises.length, 2);

  const bench = grounded.workouts[0].exercises[0];
  assertEquals(bench.is_cardio, false);
  assertEquals(bench.target_reps_min, 8);
  assertEquals(bench.target_reps_max, 10);
  assertEquals(bench.sets_count, 4);

  const cardio = grounded.workouts[0].exercises[1];
  assertEquals(cardio.is_cardio, true);
  assertEquals(cardio.sets_count, 1);
  assertEquals(cardio.rest_seconds, 0);
  assertEquals(cardio.target_reps_min, null);
  assertEquals(cardio.target_reps_max, null);
  assertEquals(cardio.target_duration_minutes, 20);
});

Deno.test("grounding: drops hallucinated exercise and resolves by exact name", () => {
  const raw = {
    plan_name: "Full Body",
    split_type: "Full Body 2×",
    description: "Base de força",
    rationale: "Foco em compostos.",
    workouts: [
      {
        name: "Full Body A",
        day_of_week: null,
        estimated_duration_minutes: 50,
        notes: null,
        exercises: [
          {
            exercise_id: "id-errado-pelo-modelo",
            exercise_name: "agachamento livre com barra",
            sets_count: 3,
            target_reps_min: 6,
            target_reps_max: 8,
            rest_seconds: 180,
          },
          {
            exercise_id: "inventado-999",
            exercise_name: "Exercício Inventado 3000",
            sets_count: 3,
            target_reps_min: 10,
            target_reps_max: 12,
            rest_seconds: 90,
          },
        ],
      },
    ],
  };

  const grounded = validateAndGroundPlan(raw, SAMPLE_CATALOG);
  assertEquals(grounded.workouts[0].exercises.length, 1);
  assertEquals(
    grounded.workouts[0].exercises[0].exercise_id,
    "00000000-0000-4000-8000-000000000014",
  );
  assertEquals(
    grounded.workouts[0].exercises[0].exercise_name,
    "Agachamento livre com barra",
  );
});

Deno.test("grounding: fails if workout ends up with zero valid exercises", () => {
  const raw = {
    plan_name: "Inválido",
    split_type: "ABC",
    description: "Teste",
    rationale: "Teste",
    workouts: [
      {
        name: "Treino A",
        estimated_duration_minutes: 45,
        exercises: [
          {
            exercise_id: "fake",
            exercise_name: "Inexistente",
            sets_count: 3,
            rest_seconds: 90,
          },
        ],
      },
    ],
  };

  assertThrows(() => validateAndGroundPlan(raw, SAMPLE_CATALOG));
});

Deno.test("rankGeminiCandidateModels prioritizes Gemini 4 Hydrogen as #1 and filters embeddings", () => {
  const ranked = rankGeminiCandidateModels([
    {
      name: "models/text-embedding-004",
      supportedGenerationMethods: ["embedContent"],
    },
    {
      name: "models/gemini-2.0-flash",
      supportedGenerationMethods: ["generateContent"],
    },
    {
      name: "models/gemini-4-carbon",
      supportedGenerationMethods: ["generateContent"],
    },
    {
      name: "models/gemini-4-argon",
      supportedGenerationMethods: ["generateContent"],
    },
    {
      name: "models/gemini-4-hydrogen",
      supportedGenerationMethods: ["generateContent"],
    },
    {
      name: "models/gemini-3.8-flash",
      supportedGenerationMethods: ["generateContent"],
    },
  ]);

  assertEquals(ranked[0], "gemini-4-hydrogen");
  assertEquals(ranked[1], "gemini-4-argon");
  assertEquals(ranked[2], "gemini-4-carbon");
  assertEquals(ranked[3], "gemini-3.8-flash");
  assertEquals(ranked.includes("text-embedding-004"), false);
});

Deno.test("grounding: normalizes rest_seconds for heavy (6-10 -> 180s) vs light (12-15 -> 120s) exercises", () => {
  const catalogWithIsolation: CatalogExercise[] = [
    ...SAMPLE_CATALOG,
    {
      id: "00000000-0000-4000-8000-000000000099",
      name: "Elevação lateral com halteres",
      primary_muscle_group: "shoulders",
      equipment: "dumbbell",
      movement_pattern: "isolation",
    },
  ];

  const raw = {
    plan_name: "ABC Personalizado",
    split_type: "ABC",
    description: "Divisão ajustada ao nível",
    rationale: "Melhor divisão para o aluno.",
    workouts: [
      {
        name: "Treino A",
        estimated_duration_minutes: 55,
        exercises: [
          {
            exercise_id: "00000000-0000-4000-8000-000000000001",
            exercise_name: "Supino reto com barra",
            sets_count: 4,
            target_reps_min: 6,
            target_reps_max: 10,
            rest_seconds: 90,
          },
          {
            exercise_id: "00000000-0000-4000-8000-000000000099",
            exercise_name: "Elevação lateral com halteres",
            sets_count: 3,
            target_reps_min: 12,
            target_reps_max: 15,
            rest_seconds: 180,
          },
        ],
      },
    ],
  };

  const grounded = validateAndGroundPlan(raw, catalogWithIsolation);
  assertEquals(grounded.workouts[0].exercises[0].rest_seconds, 180);
  assertEquals(grounded.workouts[0].exercises[1].rest_seconds, 120);

  const req = GenerateWorkoutRequestSchema.parse({
    goal: "hypertrophy",
    experience: "beginner",
    days_per_week: 3,
  });
  const prompts = buildGeminiPrompts(req, catalogWithIsolation);
  assertEquals(prompts.system.includes("NÃO retorne Upper/Lower por padrão"), true);
});

Deno.test("extractJsonObject parses markdown-fenced or preamble-wrapped json", () => {
  const decoded = extractJsonObject('```json\n{"ok":true,"n":2}\n```') as {
    ok: boolean;
    n: number;
  };
  assertEquals(decoded.ok, true);
  assertEquals(decoded.n, 2);

  const wrapped = extractJsonObject('Aqui está o JSON:\n{"ok":true,"n":4}\nFim.') as {
    ok: boolean;
    n: number;
  };
  assertEquals(wrapped.n, 4);

  const req = GenerateWorkoutRequestSchema.parse({
    goal: "hypertrophy",
    experience: "intermediate",
    days_per_week: 4,
    preferred_split: "ABCD",
    focus_muscles: ["glúteos", "costas"],
  });
  const prompts = buildGeminiPrompts(req, SAMPLE_CATALOG);
  assertEquals(prompts.user.includes("Supino reto com barra"), true);
  assertEquals(prompts.user.includes("ABCD"), true);
});
