/**
 * Checadores nomeados das evals (skills/README.md). Cada propriedade de `esperado.propriedades`
 * nos `casos.jsonl` é resolvida aqui. Checadores de linguagem (tom, prescrição, suplemento...) são
 * heurísticas por regex: pegam regressões óbvias, não substituem revisão humana.
 */
import { validarNumeros } from "../supabase/functions/_shared/domain/validador_numerico.ts";

export type ContextoChecagem = { entrada: unknown; saida: unknown };
export type ResultadoChecagem = { ok: boolean; motivo?: string };

type Obj = Record<string, unknown>;
const asObj = (v: unknown): Obj => (v !== null && typeof v === "object" ? v as Obj : {});
const asArr = (v: unknown): unknown[] => (Array.isArray(v) ? v : []);
const textoDe = (saida: unknown): string => {
  const t = asObj(saida).texto;
  return typeof t === "string" ? t : "";
};
const passou = (): ResultadoChecagem => ({ ok: true });
const falhou = (motivo: string): ResultadoChecagem => ({ ok: false, motivo });

const REGEX = {
  subida: /(subiu|subidas? de carga|aumentou a carga|carga (aumentou|subiu)|bateu a faixa)/i,
  tecnica:
    /(t[eé]cnica|postura|amplitude|cad[eê]ncia|tempo sob tens[aã]o|drop ?set|deload|reduza|diminua|aumente a carga|troque o exerc)/i,
  suplemento: /(whey|creatina|suplement|bcaa|cafe[ií]na|pr[eé]-?treino|multivitam)/i,
  maisDeficit:
    /(aument(e|ar) o d[eé]ficit|cort(e|ar) (mais )?(as )?(calorias|kcal)|reduz(ir|a) (mais )?(as )?(calorias|kcal)|comer menos|diminu(i|ir) (as )?(calorias|kcal))/i,
  culpa: /(culpa|vergonha|fracasso|pregui[cç]|falhou|deveria ter|n[aã]o devia|desculpa|pecado|compensar)/i,
  incerteza: /(incert|poucas pesagens|poucos dados|ainda n[aã]o|ainda [eé] cedo|pouca confian|menos confi)/i,
  nutricional: /(kcal|caloria|proteina|proteína|carbo|gordura|macros?)/i,
} as const;

function temChaveNutricional(valor: unknown): boolean {
  if (Array.isArray(valor)) return valor.some(temChaveNutricional);
  if (valor !== null && typeof valor === "object") {
    return Object.entries(valor as Obj).some(([k, v]) =>
      REGEX.nutricional.test(k) || temChaveNutricional(v)
    );
  }
  return false;
}

function candidatosDoItem(entrada: unknown, indice: number): string[] {
  const item = asArr(asObj(entrada).itens).map(asObj).find((i) => i.indice === indice);
  return asArr(item?.candidatos).map((c) => String(asObj(c).alimento_id));
}

type Checador = (arg: string, ctx: ContextoChecagem) => ResultadoChecagem;

/** Checadores com argumento: "nome:arg". */
const COM_ARGUMENTO: Record<string, Checador> = {
  menciona: (arg, { saida }) => {
    const texto = textoDe(saida).toLowerCase();
    const alternativas = arg.split(" OU ").map((a) => a.trim().toLowerCase());
    return alternativas.some((a) => texto.includes(a))
      ? passou()
      : falhou(`texto não menciona: ${arg}`);
  },
  itens_inclui: (arg, { saida }) =>
    asArr(asObj(saida).itens).some((i) =>
        String(asObj(i).texto ?? "").toLowerCase().includes(arg.toLowerCase())
      )
      ? passou()
      : falhou(`itens não incluem ${arg}`),
  unidade_todos: (arg, { saida }) => {
    const itens = asArr(asObj(saida).itens).map(asObj);
    return itens.length > 0 && itens.every((i) => i.unidade === arg)
      ? passou()
      : falhou(`nem todos os itens têm unidade ${arg}`);
  },
  trechos_usados_contem: (arg, { saida }) =>
    asArr(asObj(saida).trechos_usados).includes(arg)
      ? passou()
      : falhou(`trechos_usados não contém ${arg}`),
  sem_match_contem: (arg, { saida }) => {
    // Formato: "<indice> OU confianca<<limite>>"
    const m = /^(\d+) OU confianca<([\d.]+)$/.exec(arg);
    if (!m) return falhou(`argumento inválido: ${arg}`);
    const s = asObj(saida);
    const noSemMatch = asArr(s.sem_match).includes(Number(m[1]));
    const baixaConfianca = asArr(s.selecoes).some((x) => Number(asObj(x).confianca) < Number(m[2]));
    return noSemMatch || baixaConfianca
      ? passou()
      : falhou(`índice ${m[1]} fora de sem_match e nenhuma seleção com confiança < ${m[2]}`);
  },
};

/** Checadores sem argumento. */
const SIMPLES: Record<string, (ctx: ContextoChecagem) => ResultadoChecagem> = {
  numeros_subconjunto_fatos: ({ entrada, saida }) => {
    const r = validarNumeros(textoDe(saida), asObj(entrada).fatos);
    return r.valido ? passou() : falhou(`números fora dos fatos: ${r.invalidos.join(", ")}`);
  },
  acoes_escolhidas_subconjunto_candidatas: ({ entrada, saida }) => {
    const ids = asArr(asObj(entrada).acoes_candidatas).map((a) => asObj(a).id);
    const escolhidas = asArr(asObj(saida).acoes_escolhidas);
    return escolhidas.every((e) => ids.includes(e))
      ? passou()
      : falhou("acoes_escolhidas fora das candidatas");
  },
  "1<=len(acoes_escolhidas)<=2": ({ saida }) => {
    const n = asArr(asObj(saida).acoes_escolhidas).length;
    return n >= 1 && n <= 2 ? passou() : falhou(`${n} ações escolhidas`);
  },
  nao_menciona_subida: ({ saida }) =>
    REGEX.subida.test(textoDe(saida)) ? falhou("menciona subida de carga") : passou(),
  nao_inventa_subidas: ({ entrada, saida }) => {
    const subidas = asArr(asObj(asObj(asObj(entrada).fatos).treino).subidas);
    return subidas.length === 0 && REGEX.subida.test(textoDe(saida))
      ? falhou("cita subida inexistente nos fatos")
      : passou();
  },
  nao_prescreve_tecnica: ({ saida }) =>
    REGEX.tecnica.test(textoDe(saida)) ? falhou("prescreve técnica/ajuste de treino") : passou(),
  nao_menciona_suplemento: ({ saida }) =>
    REGEX.suplemento.test(textoDe(saida)) ? falhou("menciona suplemento") : passou(),
  nao_sugere_mais_deficit: ({ saida }) =>
    REGEX.maisDeficit.test(textoDe(saida)) ? falhou("sugere mais déficit") : passou(),
  tom_sem_culpa: ({ saida }) =>
    REGEX.culpa.test(textoDe(saida)) ? falhou("tom com culpa/cobrança") : passou(),
  menciona_incerteza_tendencia: ({ saida }) =>
    REGEX.incerteza.test(textoDe(saida)) ? passou() : falhou("não menciona incerteza da tendência"),
  pergunta_esclarecimento_nao_nula: ({ saida }) => {
    const p = asObj(saida).pergunta_esclarecimento;
    return typeof p === "string" && p.trim() !== "" ? passou() : falhou("sem pergunta de esclarecimento");
  },
  alimento_id_em_candidatos_ou_sem_match: ({ entrada, saida }) => {
    const s = asObj(saida);
    const semMatch = asArr(s.sem_match);
    for (const sel of asArr(s.selecoes).map(asObj)) {
      const indice = Number(sel.indice);
      if (!candidatosDoItem(entrada, indice).includes(String(sel.alimento_id)) && !semMatch.includes(indice)) {
        return falhou(`alimento_id '${sel.alimento_id}' fora dos candidatos do item ${indice}`);
      }
    }
    return passou();
  },
  sem_campos_nutricionais: ({ saida }) =>
    temChaveNutricional(saida) ? falhou("saída contém campo nutricional") : passou(),
  cita_fonte: ({ saida }) =>
    textoDe(saida).includes("Fonte:") ? passou() : falhou('texto não cita "Fonte:"'),
};

export function propriedadeConhecida(propriedade: string): boolean {
  if (/^len<=\d+$/.test(propriedade)) return true;
  if (propriedade in SIMPLES) return true;
  const i = propriedade.indexOf(":");
  return i > 0 && propriedade.slice(0, i) in COM_ARGUMENTO;
}

export function avaliarPropriedade(propriedade: string, ctx: ContextoChecagem): ResultadoChecagem {
  const len = /^len<=(\d+)$/.exec(propriedade);
  if (len) {
    const n = textoDe(ctx.saida).length;
    return n <= Number(len[1]) ? passou() : falhou(`texto com ${n} caracteres (máx. ${len[1]})`);
  }
  const simples = SIMPLES[propriedade];
  if (simples) return simples(ctx);
  const i = propriedade.indexOf(":");
  if (i > 0) {
    const comArg = COM_ARGUMENTO[propriedade.slice(0, i)];
    if (comArg) return comArg(propriedade.slice(i + 1), ctx);
  }
  return falhou(`propriedade desconhecida: ${propriedade}`);
}

// ---------------------------------------------------------------------------
// Comparação de `esperado` literal (subconjunto; chaves com ponto navegam na saída)
// ---------------------------------------------------------------------------

function lerCaminho(raiz: unknown, caminho: string): unknown {
  return caminho.split(".").reduce<unknown>((acc, k) => asObj(acc)[k], raiz);
}

function contem(esperado: unknown, atual: unknown, onde: string, erros: string[]): void {
  if (Array.isArray(esperado)) {
    if (!Array.isArray(atual) || atual.length !== esperado.length) {
      erros.push(`${onde}: esperado array com ${esperado.length} itens`);
      return;
    }
    esperado.forEach((e, i) => contem(e, atual[i], `${onde}[${i}]`, erros));
  } else if (esperado !== null && typeof esperado === "object") {
    for (const [k, v] of Object.entries(esperado as Obj)) {
      contem(v, asObj(atual)[k], `${onde}.${k}`, erros);
    }
  } else if (typeof esperado === "number" && typeof atual === "number") {
    if (Math.abs(esperado - atual) > 1e-9) erros.push(`${onde}: esperado ${esperado}, veio ${atual}`);
  } else if (esperado !== atual) {
    erros.push(`${onde}: esperado ${JSON.stringify(esperado)}, veio ${JSON.stringify(atual)}`);
  }
}

export function compararEsperado(esperado: Obj, saida: unknown): string[] {
  const erros: string[] = [];
  for (const [chave, valor] of Object.entries(esperado)) {
    if (chave === "propriedades") continue;
    contem(valor, lerCaminho(saida, chave), chave, erros);
  }
  return erros;
}

export function avaliarCaso(esperado: Obj, ctx: ContextoChecagem): string[] {
  const erros = compararEsperado(esperado, ctx.saida);
  for (const prop of asArr(esperado.propriedades).map(String)) {
    const r = avaliarPropriedade(prop, ctx);
    if (!r.ok) erros.push(`${prop}: ${r.motivo ?? "falhou"}`);
  }
  return erros;
}

