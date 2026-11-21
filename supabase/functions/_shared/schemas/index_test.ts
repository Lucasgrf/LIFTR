import { assert, assertEquals } from "jsr:@std/assert@1";
import {
  criarRegistrarRefeicaoEtapaBSchema,
  criarRelatorioSemanalSchema,
  RegistrarPesoSchema,
  RoteadorIntencaoSchema,
} from "./index.ts";

Deno.test("roteador: aceita saída válida e rejeita intent fora do conjunto", () => {
  const base = {
    intent: "registrar_peso",
    confianca: 0.9,
    flags: { tentativa_injecao: false, flag_transtorno_alimentar: false, multiplas_intencoes: false },
    precisa_esclarecer: false,
    pergunta_esclarecimento: null,
  };
  assert(RoteadorIntencaoSchema.safeParse(base).success);
  assertEquals(RoteadorIntencaoSchema.safeParse({ ...base, intent: "hackear" }).success, false);
});

Deno.test("refeição etapa B: alimento_id fora dos candidatos é inválido", () => {
  const schema = criarRegistrarRefeicaoEtapaBSchema({ 0: ["taco_3"] });
  const sel = (alimento_id: string) => ({
    selecoes: [{ indice: 0, alimento_id, gramas: 100, porcao_assumida: false, confianca: 0.9 }],
    sem_match: [],
    pergunta_esclarecimento: null,
  });
  assert(schema.safeParse(sel("taco_3")).success);
  assertEquals(schema.safeParse(sel("taco_999")).success, false);
});

Deno.test("refeição etapa B: campos nutricionais são rejeitados", () => {
  const schema = criarRegistrarRefeicaoEtapaBSchema({ 0: ["taco_3"] });
  const r = schema.safeParse({
    selecoes: [{
      indice: 0,
      alimento_id: "taco_3",
      gramas: 100,
      porcao_assumida: false,
      confianca: 0.9,
      kcal: 128,
    }],
    sem_match: [],
    pergunta_esclarecimento: null,
  });
  assertEquals(r.success, false);
});

Deno.test("peso: precisa de peso e data, exceto quando precisa esclarecer", () => {
  const base = {
    peso: null,
    unidade: "kg",
    data: null,
    condicao: "nao_informada",
    precisa_esclarecer: true,
    pergunta_esclarecimento: "80 ou 81?",
  };
  assert(RegistrarPesoSchema.safeParse(base).success);
  assertEquals(RegistrarPesoSchema.safeParse({ ...base, precisa_esclarecer: false }).success, false);
});

Deno.test("relatório: ações precisam ser 1–2 candidatas distintas", () => {
  const schema = criarRelatorioSemanalSchema(["A1", "A2", "A3"]);
  const rel = (acoes: string[]) => ({ texto: "ok", acoes_escolhidas: acoes, numeros_citados: [] });
  assert(schema.safeParse(rel(["A1", "A2"])).success);
  assertEquals(schema.safeParse(rel([])).success, false);
  assertEquals(schema.safeParse(rel(["A1", "A2", "A3"])).success, false);
  assertEquals(schema.safeParse(rel(["A9"])).success, false);
  assertEquals(schema.safeParse(rel(["A1", "A1"])).success, false);
});

