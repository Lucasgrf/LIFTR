import { assert, assertEquals } from "jsr:@std/assert@1";
import { avaliarCaso, avaliarPropriedade, compararEsperado, propriedadeConhecida } from "./checadores.ts";

Deno.test("esperado literal: subconjunto, números e caminho com ponto", () => {
  const saida = {
    intent: "fora_de_escopo",
    flags: { tentativa_injecao: true },
    itens: [{ texto: "frango", quantidade: 150, unidade: "g", preparo: "x" }],
  };
  assertEquals(compararEsperado({ intent: "fora_de_escopo", "flags.tentativa_injecao": true }, saida), []);
  assertEquals(
    compararEsperado({ itens: [{ texto: "frango", quantidade: 150, unidade: "g" }] }, saida),
    [],
  );
  assert(compararEsperado({ intent: "saudacao" }, saida).length === 1);
  assert(compararEsperado({ itens: [] }, saida).length === 1); // tamanhos diferentes
});

Deno.test("menciona: alternativas com OU", () => {
  const ctx = { entrada: {}, saida: { texto: "Agachamento foi pra 82,5kg" } };
  assert(avaliarPropriedade("menciona:82,5 OU 82.5", ctx).ok);
  assert(!avaliarPropriedade("menciona:Upper B", ctx).ok);
});

Deno.test("numeros_subconjunto_fatos usa o validador numérico", () => {
  const entrada = { fatos: { peso: 80 } };
  assert(avaliarPropriedade("numeros_subconjunto_fatos", { entrada, saida: { texto: "80kg" } }).ok);
  assert(!avaliarPropriedade("numeros_subconjunto_fatos", { entrada, saida: { texto: "81kg" } }).ok);
});

Deno.test("heurísticas de linguagem", () => {
  const ctx = (texto: string) => ({ entrada: {}, saida: { texto } });
  assert(!avaliarPropriedade("nao_menciona_suplemento", ctx("tome creatina")).ok);
  assert(avaliarPropriedade("nao_menciona_suplemento", ctx("tudo certo")).ok);
  assert(!avaliarPropriedade("nao_menciona_subida", ctx("o supino subiu de carga")).ok);
  assert(avaliarPropriedade("nao_menciona_subida", ctx("faltam 6 reps para subir")).ok);
  assert(!avaliarPropriedade("tom_sem_culpa", ctx("que fracasso")).ok);
  assert(!avaliarPropriedade("nao_sugere_mais_deficit", ctx("aumente o déficit")).ok);
  assert(avaliarPropriedade("menciona_incerteza_tendencia", ctx("a tendência ainda é incerta")).ok);
});

Deno.test("refeição etapa B: candidatos, sem_match e campos nutricionais", () => {
  const entrada = { itens: [{ indice: 0, candidatos: [{ alimento_id: "taco_3" }] }] };
  const sel = (alimento_id: string, extra: object = {}) => ({
    selecoes: [{ indice: 0, alimento_id, gramas: 100, confianca: 0.9, ...extra }],
    sem_match: [],
  });
  assert(avaliarPropriedade("alimento_id_em_candidatos_ou_sem_match", { entrada, saida: sel("taco_3") }).ok);
  assert(!avaliarPropriedade("alimento_id_em_candidatos_ou_sem_match", { entrada, saida: sel("x") }).ok);
  assert(!avaliarPropriedade("sem_campos_nutricionais", { entrada, saida: sel("taco_3", { kcal: 1 }) }).ok);
  assert(avaliarPropriedade("sem_campos_nutricionais", { entrada, saida: sel("taco_3") }).ok);
});

Deno.test("sem_match_contem composto e propriedade desconhecida", () => {
  const ctx = {
    entrada: {},
    saida: { sem_match: [], selecoes: [{ confianca: 0.4 }], pergunta_esclarecimento: "o quê?" },
  };
  assert(avaliarPropriedade("sem_match_contem:0 OU confianca<0.6", ctx).ok);
  assert(propriedadeConhecida("len<=400"));
  assert(!propriedadeConhecida("inexistente"));
  assertEquals(avaliarCaso({ propriedades: ["inexistente"] }, ctx).length, 1);
});

