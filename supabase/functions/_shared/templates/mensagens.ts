/**
 * Templates determinísticos (AGENTS.md: o LLM nunca redige confirmações de registro).
 * Textos de usuário do backend vivem aqui e em mais lugar nenhum.
 */

const nf = new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 1 });
const nfInt = new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 0 });

export const fmt = (n: number): string => nf.format(n);
export const fmtInt = (n: number): string => nfInt.format(n);

// ---------------------------------------------------------------------------
// Confirmação de refeição (PRD §6.2)
// ---------------------------------------------------------------------------

export type ItemConfirmacao = {
  nome: string;
  gramas: number;
  /** Medida caseira usada (ex.: "1 concha"), quando houver. */
  medida?: string;
  /** Porção assumida ou estimada por foto → prefixo "~". */
  assumida: boolean;
};

export type TotaisDia = {
  proteinaG: number;
  kcal: number;
  metaProteinaG: number;
  metaKcal: number;
};

export function confirmacaoRefeicao(params: {
  itens: ItemConfirmacao[];
  proteinaRefeicaoG: number;
  kcalRefeicao: number;
  dia: TotaisDia;
}): string {
  const itens = params.itens.map((i) => {
    const til = i.assumida ? "~" : "";
    const detalhe = i.medida
      ? `${til}${i.medida}, ${fmtInt(i.gramas)}g`
      : `${til}${fmtInt(i.gramas)}g`;
    return `${i.nome} (${detalhe})`;
  }).join(", ");
  const { dia } = params;
  return [
    `Registrei: ${itens}.`,
    `~${fmtInt(params.proteinaRefeicaoG)}g de proteína · ~${fmtInt(params.kcalRefeicao)} kcal`,
    `Hoje: ${fmtInt(dia.proteinaG)}/${fmtInt(dia.metaProteinaG)}g de proteína · ${fmtInt(dia.kcal)}/${
      fmtInt(dia.metaKcal)
    } kcal`,
    "(responda corrigindo se algo estiver errado)",
  ].join("\n");
}

// ---------------------------------------------------------------------------
// Confirmação de peso (skills/registrar-peso/SKILL.md)
// ---------------------------------------------------------------------------

export type SituacaoPeso =
  | { tipo: "dentro_do_ritmo"; variou: "subiu" | "caiu" | "ficou estável"; delta: number }
  | { tipo: "acima_bulking"; delta: number; ajusteMeta: string }
  | { tipo: "abaixo_bulking"; delta: number; ajusteMeta: string }
  | { tipo: "cutting_rapido" }
  | { tipo: "poucos_dados" };

export function confirmacaoPeso(params: {
  pesoKg: number;
  periodo: string;
  faixa: string;
  situacao: SituacaoPeso;
}): string {
  const peso = fmt(params.pesoKg);
  const { situacao: s, periodo, faixa } = params;
  switch (s.tipo) {
    case "dentro_do_ritmo":
      return `Registrei ${peso}kg. Sua tendência ${s.variou} ${fmt(s.delta)}kg ${periodo}, dentro do ritmo pra você (${faixa}). Segue assim.`;
    case "acima_bulking":
      return `Registrei ${peso}kg. Sua tendência subiu ${fmt(s.delta)}kg ${periodo}, acima do ritmo ideal (${faixa}). ${s.ajusteMeta}`.trim();
    case "abaixo_bulking":
      return `Registrei ${peso}kg. Sua tendência subiu ${fmt(s.delta)}kg ${periodo}, abaixo do ritmo (${faixa}). ${s.ajusteMeta}`.trim();
    case "cutting_rapido":
      return `Registrei ${peso}kg. Você está perdendo mais rápido que o recomendado (${faixa}). Vou segurar novos cortes na meta.`;
    case "poucos_dados":
      return `Registrei ${peso}kg. Ainda tenho poucas pesagens pra calcular sua tendência; tenta se pesar umas 3 vezes por semana, de manhã e em jejum.`;
  }
}

// ---------------------------------------------------------------------------
// Mensagens fixas
// ---------------------------------------------------------------------------

export const MENSAGENS = {
  saudacao:
    "Oi! Me manda o que você comeu ou seu peso do dia que eu registro por aqui.",
  foraDeEscopo:
    "Eu só ajudo com seus treinos, suas refeições e seu peso. Me manda uma refeição ou uma pesagem que eu registro.",
  saudeSensivel:
    "Isso é um assunto de saúde e eu não consigo orientar sobre isso. Vale conversar com um profissional de saúde de confiança.",
  transtornoAlimentar:
    "Obrigado por contar. Eu não sou a pessoa certa para te orientar nisso, e cuidar de você vem primeiro. Procurar um profissional de saúde pode ajudar bastante. Por enquanto, vou pausar sugestões de dieta.",
  duvidaEmBreve:
    "Responder dúvidas de treino e dieta ainda não está disponível, mas está nos planos.",
  erroFallback: "Não consegui entender direito. Pode reformular?",
  semAutorizacao: "Este número não está autorizado a usar o assistente.",
  textoLongo: "Sua mensagem ficou grande demais. Pode resumir em até 1.000 caracteres?",
  limiteMensagens: "Recebi muitas mensagens em pouco tempo. Tenta de novo daqui a pouco.",
  emBreve: "Essa função ainda não está disponível por aqui, mas já está a caminho.",
} as const;

