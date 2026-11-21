/**
 * Pipeline do orquestrador (PRD §8.2). Dependências entram por parâmetro:
 * `{ repo, llm, whatsapp, agora }` (AGENTS.md). Nada de relógio global nem I/O direto.
 *
 * Estágios: gate de entrada → roteador → desvio por política → handler da intenção → log.
 * Handlers das intenções de registro (peso, refeição, metas...) entram nas próximas sprints.
 */
import type { LlmClient } from "../_shared/llm/llm_client.ts";
import { type Intent, type RoteadorIntencao, RoteadorIntencaoSchema } from "../_shared/schemas/index.ts";
import { MENSAGENS } from "../_shared/templates/mensagens.ts";
import type { EventoWebhookWhatsApp, WhatsAppGateway } from "../_shared/whatsapp/whatsapp_gateway.ts";

export const LIMITE_TEXTO = 1000;

export type ContextoConversa = {
  ultimo_registro?: { tipo: "refeicao" | "peso"; ha_minutos: number; resumo?: string };
  acao_pendente?: { tipo: string; resumo?: string };
};

export type MensagemRegistrada = {
  usuarioId: string;
  direcao: "entrada" | "saida";
  conteudo: string;
  intent?: Intent;
  idCorrelacao: string;
  criadaEm: Date;
};

/** Porta de persistência do orquestrador (implementada com Supabase em `_shared/repo`). */
export interface OrquestradorRepo {
  /** Whitelist: devolve `null` para números não vinculados a um usuário. */
  buscarUsuarioPorNumero(numero: string): Promise<{ usuarioId: string } | null>;
  contarMensagensEntrada(usuarioId: string, desde: Date): Promise<number>;
  buscarContexto(usuarioId: string, agora: Date): Promise<ContextoConversa>;
  registrarMensagem(mensagem: MensagemRegistrada): Promise<void>;
  marcarSinalTranstornoAlimentar(usuarioId: string): Promise<void>;
}

export type LimitesRate = { porMinuto: number; porDia: number };
export const LIMITES_PADRAO: LimitesRate = { porMinuto: 10, porDia: 200 };

export type ContextoHandler = {
  evento: EventoWebhookWhatsApp;
  usuarioId: string;
  roteamento: RoteadorIntencao;
  idCorrelacao: string;
};
/** Handler de uma intenção; devolve o texto de resposta. */
export type HandlerIntencao = (ctx: ContextoHandler) => Promise<string>;

export type DepsOrquestrador = {
  repo: OrquestradorRepo;
  llm: LlmClient;
  whatsapp: WhatsAppGateway;
  agora: () => Date;
  limites?: LimitesRate;
  /** TODO(US-22, US-20, US-24, US-25): registrar handlers conforme as sprints 4–6. */
  handlers?: Partial<Record<Intent, HandlerIntencao>>;
  gerarId?: () => string;
};

export type DesvioPolitica =
  | "nao_autorizado"
  | "texto_longo"
  | "rate_limit"
  | "fora_de_escopo"
  | "saude_sensivel"
  | "transtorno_alimentar"
  | "falha_roteamento"
  | "esclarecimento"
  | "nao_implementado";

export type ResultadoProcessamento = {
  idCorrelacao: string;
  intent?: Intent;
  desvio?: DesvioPolitica;
  resposta: string | null;
  enviada: boolean;
};

export async function processarMensagem(
  evento: EventoWebhookWhatsApp,
  deps: DepsOrquestrador,
): Promise<ResultadoProcessamento> {
  const { repo, llm, whatsapp, agora } = deps;
  const idCorrelacao = (deps.gerarId ?? (() => crypto.randomUUID()))();
  const limites = deps.limites ?? LIMITES_PADRAO;

  const responder = async (
    usuarioId: string | null,
    texto: string,
    extra: { intent?: Intent; desvio?: DesvioPolitica },
  ): Promise<ResultadoProcessamento> => {
    const envio = await whatsapp.enviarTexto(evento.numero, texto, { idCorrelacao });
    if (usuarioId !== null) {
      await repo.registrarMensagem({
        usuarioId,
        direcao: "saida",
        conteudo: texto,
        intent: extra.intent,
        idCorrelacao,
        criadaEm: agora(),
      });
    }
    return { idCorrelacao, ...extra, resposta: texto, enviada: envio.ok };
  };

  // 1. Gate de entrada: whitelist, tamanho, rate limit
  const usuario = await repo.buscarUsuarioPorNumero(evento.numero);
  if (usuario === null) {
    // Número desconhecido: não grava nada e não responde (evita virar canal de spam).
    return { idCorrelacao, desvio: "nao_autorizado", resposta: null, enviada: false };
  }
  const { usuarioId } = usuario;
  const agoraDt = agora();

  await repo.registrarMensagem({
    usuarioId,
    direcao: "entrada",
    conteudo: evento.texto,
    idCorrelacao,
    criadaEm: agoraDt,
  });

  if (evento.texto.length > LIMITE_TEXTO) {
    return responder(usuarioId, MENSAGENS.textoLongo, { desvio: "texto_longo" });
  }
  const [ultimoMinuto, ultimoDia] = await Promise.all([
    repo.contarMensagensEntrada(usuarioId, new Date(agoraDt.getTime() - 60_000)),
    repo.contarMensagensEntrada(usuarioId, new Date(agoraDt.getTime() - 86_400_000)),
  ]);
  if (ultimoMinuto > limites.porMinuto || ultimoDia > limites.porDia) {
    return responder(usuarioId, MENSAGENS.limiteMensagens, { desvio: "rate_limit" });
  }

  // 2. Roteador
  const contexto = await repo.buscarContexto(usuarioId, agoraDt);
  const roteado = await llm.executarSkill({
    skill: "roteador-intencao",
    entrada: {
      mensagem_usuario: evento.texto,
      tem_imagem: evento.midia !== undefined,
      // TODO(US-21): descrição de imagem pela etapa de visão.
      contexto,
    },
    schema: RoteadorIntencaoSchema,
    idCorrelacao,
    usuarioId,
  });
  if (!roteado.ok) {
    return responder(usuarioId, MENSAGENS.erroFallback, { desvio: "falha_roteamento" });
  }
  const roteamento = roteado.valor;
  const { intent, flags } = roteamento;

  // 3. Desvio por política: respostas fixas, sem LLM gerando texto
  if (flags.flag_transtorno_alimentar || intent === "saude_sensivel") {
    if (flags.flag_transtorno_alimentar) await repo.marcarSinalTranstornoAlimentar(usuarioId);
    return responder(
      usuarioId,
      flags.flag_transtorno_alimentar ? MENSAGENS.transtornoAlimentar : MENSAGENS.saudeSensivel,
      {
        intent: "saude_sensivel",
        desvio: flags.flag_transtorno_alimentar ? "transtorno_alimentar" : "saude_sensivel",
      },
    );
  }
  if (intent === "fora_de_escopo" || flags.tentativa_injecao) {
    return responder(usuarioId, MENSAGENS.foraDeEscopo, { intent: "fora_de_escopo", desvio: "fora_de_escopo" });
  }
  if (roteamento.precisa_esclarecer) {
    return responder(usuarioId, roteamento.pergunta_esclarecimento ?? MENSAGENS.erroFallback, {
      intent,
      desvio: "esclarecimento",
    });
  }
  if (intent === "saudacao") return responder(usuarioId, MENSAGENS.saudacao, { intent });
  if (intent === "duvida_treino_dieta") {
    return responder(usuarioId, MENSAGENS.duvidaEmBreve, { intent });
  }

  // 4. Handler da intenção
  const handler = deps.handlers?.[intent];
  if (handler === undefined) {
    return responder(usuarioId, MENSAGENS.emBreve, { intent, desvio: "nao_implementado" });
  }
  let texto: string;
  try {
    texto = await handler({ evento, usuarioId, roteamento, idCorrelacao });
  } catch {
    return responder(usuarioId, MENSAGENS.erroFallback, { intent, desvio: "falha_roteamento" });
  }
  return responder(usuarioId, texto, { intent });
}
