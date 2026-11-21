import { assert, assertEquals } from "jsr:@std/assert@1";
import { extrairNumeros, validarNumeros } from "./validador_numerico.ts";

Deno.test("extrairNumeros: formatos pt-BR", () => {
  assertEquals(extrairNumeros("82,5kg").map((n) => n.valores), [[82.5]]);
  assertEquals(extrairNumeros("meta 2.650 kcal").map((n) => n.valores), [[2650, 2.65]]);
  assertEquals(extrairNumeros("1.420,5").map((n) => n.valores), [[1420.5]]);
  assertEquals(extrairNumeros("80.6").map((n) => n.valores), [[80.6]]);
});

Deno.test("validarNumeros: aceita números presentes nos fatos", () => {
  const fatos = {
    periodo: "27/10 a 02/11",
    treino: { sessoes_feitas: 4 },
    peso: { tendencia_atual: 80.6, variacao_semana: 0.4 },
    ajuste_meta: { kcal_depois: 2650 },
  };
  const texto = "Semana 27/10 a 02/11. 4 sessões. Tendência 80,6kg, +0,4kg. Meta 2.650 kcal.";
  const r = validarNumeros(texto, fatos);
  assert(r.valido, `inválidos: ${r.invalidos.join(", ")}`);
});

Deno.test("validarNumeros: rejeita número alucinado", () => {
  const r = validarNumeros("Você ganhou 3kg", { peso: { variacao_semana: 0.4 } });
  assertEquals(r.valido, false);
  assertEquals(r.invalidos, ["3"]);
});

Deno.test("validarNumeros: tamanho de array de reps vale como número de séries", () => {
  const fatos = { exercicios: [{ peso: 80, reps: [10, 10, 10] }] };
  assert(validarNumeros("fechou 3x10 com 80kg", fatos).valido);
});

Deno.test("validarNumeros: tolerância de arredondamento", () => {
  assert(validarNumeros("tendência em 80,6kg", { t: 80.64 }).valido);
  assertEquals(validarNumeros("tendência em 80,6kg", { t: 80.9 }).valido, false);
});

