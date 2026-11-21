/**
 * Schemas Zod das skills (AGENTS.md regra 3). Toda saída de LLM passa por aqui antes de qualquer uso.
 * Fonte da verdade do formato: skills/<nome>/SKILL.md.
 */
import { z } from "../deps.ts";

export const NOMES_SKILL = [
  "roteador-intencao",
  "registrar-refeicao",
  "registrar-peso",
  "resumo-pos-treino",
  "relatorio-semanal",
  "responder-duvida",
] as const;
export type NomeSkill = (typeof NOMES_SKILL)[number];

// ---------------------------------------------------------------------------
// roteador-intencao
// ---------------------------------------------------------------------------

export const INTENTS = [
  "registrar_refeicao",
  "registrar_peso",
  "corrigir_ultimo",
  "mudar_objetivo",
  "consultar_dia",
  "confirmar",
  "cancelar",
  "saudacao",
  "duvida_treino_dieta",
  "saude_sensivel",
  "fora_de_escopo",
] as const;
export type Intent = (typeof INTENTS)[number];

export const RoteadorIntencaoSchema = z.object({
  intent: z.enum(INTENTS),
  confianca: z.number().min(0).max(1),
  flags: z.object({
    tentativa_injecao: z.boolean(),
    flag_transtorno_alimentar: z.boolean(),
    multiplas_intencoes: z.boolean(),
  }),
  precisa_esclarecer: z.boolean(),
  pergunta_esclarecimento: z.string().max(300).nullable(),
}).strict();
export type RoteadorIntencao = z.infer<typeof RoteadorIntencaoSchema>;

// ---------------------------------------------------------------------------
// registrar-refeicao
// ---------------------------------------------------------------------------

export const UNIDADES_REFEICAO = [
  "g",
  "ml",
  "unidade",
  "fatia",
  "concha",
  "colher_sopa",
  "colher_cha",
  "escumadeira",
  "copo",
  "xicara",
  "porcao",
  "nao_informada",
] as const;

export const RegistrarRefeicaoEtapaASchema = z.object({
  refeicao: z.enum(["almoco", "cafe_da_manha", "lanche", "jantar", "ceia", "nao_informado"]),
  itens: z.array(
    z.object({
      texto: z.string().min(1).max(120),
      preparo: z.string().min(1).max(40),
      quantidade: z.number().positive().nullable(),
      unidade: z.enum(UNIDADES_REFEICAO),
    }).strict(),
  ).max(30),
  origem: z.enum(["texto", "foto"]),
  precisa_esclarecer: z.boolean(),
  pergunta_esclarecimento: z.string().max(300).nullable(),
}).strict();
export type RegistrarRefeicaoEtapaA = z.infer<typeof RegistrarRefeicaoEtapaASchema>;

/** Candidatos recuperados (RAG) por índice de item: apenas esses `alimento_id` são válidos. */
export type CandidatosPorItem = Record<number, readonly string[]>;

/**
 * Etapa B: `alimento_id` precisa estar nos candidatos do item (AGENTS.md regra 4) e nenhum campo
 * nutricional é aceito (`.strict()` rejeita chaves desconhecidas como `kcal`/`proteina`).
 */
export function criarRegistrarRefeicaoEtapaBSchema(candidatos: CandidatosPorItem) {
  return z.object({
    selecoes: z.array(
      z.object({
        indice: z.number().int().min(0),
        alimento_id: z.string().min(1),
        gramas: z.number().positive().max(5000),
        porcao_assumida: z.boolean(),
        confianca: z.number().min(0).max(1),
      }).strict(),
    ),
    sem_match: z.array(z.number().int().min(0)),
    pergunta_esclarecimento: z.string().max(300).nullable(),
  }).strict().superRefine((valor, ctx) => {
    valor.selecoes.forEach((s, i) => {
      const permitidos = candidatos[s.indice];
      if (permitidos === undefined) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ["selecoes", i, "indice"],
          message: `índice ${s.indice} não existe na entrada`,
        });
      } else if (!permitidos.includes(s.alimento_id)) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ["selecoes", i, "alimento_id"],
          message: `alimento_id '${s.alimento_id}' não está nos candidatos do item ${s.indice}`,
        });
      }
    });
    valor.sem_match.forEach((indice, i) => {
      if (candidatos[indice] === undefined) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ["sem_match", i],
          message: `índice ${indice} não existe na entrada`,
        });
      }
    });
  });
}
export type RegistrarRefeicaoEtapaB = z.infer<ReturnType<typeof criarRegistrarRefeicaoEtapaBSchema>>;

// ---------------------------------------------------------------------------
// registrar-peso
// ---------------------------------------------------------------------------

export const RegistrarPesoSchema = z.object({
  peso: z.number().positive().nullable(),
  unidade: z.enum(["kg", "lb"]),
  data: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).nullable(),
  condicao: z.enum(["jejum", "apos_comer", "nao_informada"]),
  precisa_esclarecer: z.boolean(),
  pergunta_esclarecimento: z.string().max(300).nullable(),
}).strict().superRefine((v, ctx) => {
  if (!v.precisa_esclarecer && (v.peso === null || v.data === null)) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "peso e data são obrigatórios quando não precisa esclarecer",
    });
  }
});
export type RegistrarPeso = z.infer<typeof RegistrarPesoSchema>;

// ---------------------------------------------------------------------------
// resumo-pos-treino
// ---------------------------------------------------------------------------

export const ResumoPosTreinoSchema = z.object({
  texto: z.string().min(1).max(400),
  numeros_citados: z.array(z.number()),
}).strict();
export type ResumoPosTreino = z.infer<typeof ResumoPosTreinoSchema>;

// ---------------------------------------------------------------------------
// relatorio-semanal
// ---------------------------------------------------------------------------

/** `acoes_escolhidas` precisa ser 1–2 IDs distintos da lista de candidatas do motor de regras. */
export function criarRelatorioSemanalSchema(idsAcoesCandidatas: readonly string[]) {
  return z.object({
    texto: z.string().min(1).max(900),
    acoes_escolhidas: z.array(z.string()).min(1).max(2),
    numeros_citados: z.array(z.number()),
  }).strict().superRefine((v, ctx) => {
    if (new Set(v.acoes_escolhidas).size !== v.acoes_escolhidas.length) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["acoes_escolhidas"],
        message: "ações repetidas",
      });
    }
    v.acoes_escolhidas.forEach((id, i) => {
      if (!idsAcoesCandidatas.includes(id)) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ["acoes_escolhidas", i],
          message: `ação '${id}' não está entre as candidatas`,
        });
      }
    });
  });
}
export type RelatorioSemanal = z.infer<ReturnType<typeof criarRelatorioSemanalSchema>>;

// ---------------------------------------------------------------------------
// responder-duvida (v2)
// ---------------------------------------------------------------------------

export const ResponderDuvidaSchema = z.object({
  pode_responder: z.boolean(),
  texto: z.string().max(600).optional(),
  trechos_usados: z.array(z.string()).default([]),
}).strict();
export type ResponderDuvida = z.infer<typeof ResponderDuvidaSchema>;

