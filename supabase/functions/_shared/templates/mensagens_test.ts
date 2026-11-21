import { assertEquals, assertStringIncludes } from "jsr:@std/assert@1";
import { confirmacaoPeso, confirmacaoRefeicao } from "./mensagens.ts";

Deno.test("confirmacaoRefeicao segue o exemplo do PRD §6.2", () => {
  const texto = confirmacaoRefeicao({
    itens: [
      { nome: "frango grelhado", gramas: 150, assumida: false },
      { nome: "arroz branco", gramas: 100, medida: "1 concha", assumida: true },
    ],
    proteinaRefeicaoG: 52,
    kcalRefeicao: 610,
    dia: { proteinaG: 98, kcal: 1420, metaProteinaG: 160, metaKcal: 2600 },
  });
  assertEquals(
    texto,
    [
      "Registrei: frango grelhado (150g), arroz branco (~1 concha, 100g).",
      "~52g de proteína · ~610 kcal",
      "Hoje: 98/160g de proteína · 1.420/2.600 kcal",
      "(responda corrigindo se algo estiver errado)",
    ].join("\n"),
  );
});

Deno.test("confirmacaoPeso: variações", () => {
  const base = { pesoKg: 80, periodo: "este mês", faixa: "0,8 a 1,2kg" };
  assertStringIncludes(
    confirmacaoPeso({
      ...base,
      situacao: { tipo: "acima_bulking", delta: 3, ajusteMeta: "Vou reduzir sua meta em 200 kcal." },
    }),
    "acima do ritmo ideal (0,8 a 1,2kg). Vou reduzir sua meta em 200 kcal.",
  );
  assertStringIncludes(
    confirmacaoPeso({ ...base, situacao: { tipo: "poucos_dados" } }),
    "poucas pesagens",
  );
});

