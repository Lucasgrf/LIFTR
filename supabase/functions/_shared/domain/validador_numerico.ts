/**
 * Validador numérico (PRD §8.4): todo número no texto redigido pelo LLM precisa existir nos fatos.
 * Função pura, sem I/O.
 *
 * Fatos aceitos como "números existentes":
 * - qualquer número (valor numérico ou dentro de strings, ex.: "27/10 a 02/11", "33/36");
 * - o tamanho de arrays de números (ex.: reps [10,10,10] → 3, para "3x10").
 */

export type NumeroEncontrado = { texto: string; valores: number[] };

export type ResultadoValidacaoNumerica = { valido: boolean; invalidos: string[] };

const REGEX_NUMERO = /\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:[.,]\d+)?/g;

/**
 * Extrai números de um texto pt-BR. "2.650" é ambíguo (2650 ou 2,65), então devolve as duas leituras.
 */
export function extrairNumeros(texto: string): NumeroEncontrado[] {
  const encontrados: NumeroEncontrado[] = [];
  for (const m of texto.matchAll(REGEX_NUMERO)) {
    const bruto = m[0];
    const valores = new Set<number>();
    if (/^\d{1,3}(?:\.\d{3})+(?:,\d+)?$/.test(bruto)) {
      // Leitura milhar: 2.650 -> 2650 ; 1.420,5 -> 1420.5
      valores.add(Number(bruto.replace(/\./g, "").replace(",", ".")));
      // Leitura decimal (só quando há um único ponto e nenhuma vírgula): 2.650 -> 2.65
      if (/^\d{1,3}\.\d{3}$/.test(bruto)) valores.add(Number(bruto));
    } else {
      valores.add(Number(bruto.replace(",", ".")));
    }
    encontrados.push({ texto: bruto, valores: [...valores] });
  }
  return encontrados;
}

/** Coleta recursivamente todos os números existentes num objeto de fatos. */
export function coletarNumerosDosFatos(fatos: unknown): number[] {
  const coletados: number[] = [];
  const visitar = (valor: unknown): void => {
    if (typeof valor === "number") {
      if (Number.isFinite(valor)) coletados.push(valor);
    } else if (typeof valor === "string") {
      for (const n of extrairNumeros(valor)) coletados.push(...n.valores);
    } else if (Array.isArray(valor)) {
      if (valor.length > 0 && valor.every((v) => typeof v === "number")) {
        coletados.push(valor.length);
      }
      valor.forEach(visitar);
    } else if (valor !== null && typeof valor === "object") {
      Object.values(valor as Record<string, unknown>).forEach(visitar);
    }
  };
  visitar(fatos);
  return coletados;
}

export type OpcoesValidacao = {
  /** Tolerância absoluta de arredondamento (padrão 0,05). */
  tolerancia?: number;
};

export function validarNumeros(
  texto: string,
  fatos: unknown,
  opcoes: OpcoesValidacao = {},
): ResultadoValidacaoNumerica {
  const tolerancia = opcoes.tolerancia ?? 0.05;
  const permitidos = coletarNumerosDosFatos(fatos);
  const invalidos: string[] = [];
  for (const n of extrairNumeros(texto)) {
    const existe = n.valores.some((v) => permitidos.some((p) => Math.abs(p - v) <= tolerancia));
    if (!existe) invalidos.push(n.texto);
  }
  return { valido: invalidos.length === 0, invalidos };
}

