/** Implementação do `OrquestradorRepo` sobre Supabase (service role; RLS não se aplica). */
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
import type {
  ContextoConversa,
  MensagemRegistrada,
  OrquestradorRepo,
} from "../../orquestrador/pipeline.ts";
import type { LogLlmChamada } from "../llm/llm_client.ts";

export function criarClienteServico(url: string, serviceRoleKey: string): SupabaseClient {
  return createClient(url, serviceRoleKey, { auth: { persistSession: false } });
}

const JANELA_CORRECAO_MIN = 120;

export class SupabaseOrquestradorRepo implements OrquestradorRepo {
  readonly #db: SupabaseClient;

  constructor(db: SupabaseClient) {
    this.#db = db;
  }

  async buscarUsuarioPorNumero(numero: string): Promise<{ usuarioId: string } | null> {
    const { data, error } = await this.#db
      .from("perfil")
      .select("usuario_id")
      .eq("whatsapp_numero", numero)
      .maybeSingle();
    if (error) throw new Error(`perfil: ${error.message}`);
    return data ? { usuarioId: data.usuario_id as string } : null;
  }

  async contarMensagensEntrada(usuarioId: string, desde: Date): Promise<number> {
    const { count, error } = await this.#db
      .from("mensagem")
      .select("id", { count: "exact", head: true })
      .eq("usuario_id", usuarioId)
      .eq("direcao", "entrada")
      .gte("criada_em", desde.toISOString());
    if (error) throw new Error(`mensagem: ${error.message}`);
    return count ?? 0;
  }

  async buscarContexto(usuarioId: string, agora: Date): Promise<ContextoConversa> {
    const contexto: ContextoConversa = {};
    const limite = new Date(agora.getTime() - JANELA_CORRECAO_MIN * 60_000).toISOString();

    const [refeicao, pesagem, pendente] = await Promise.all([
      this.#db.from("refeicao").select("registrada_em, texto_original")
        .eq("usuario_id", usuarioId).gte("registrada_em", limite)
        .order("registrada_em", { ascending: false }).limit(1).maybeSingle(),
      this.#db.from("pesagem").select("criado_em, peso_kg")
        .eq("usuario_id", usuarioId).gte("criado_em", limite)
        .order("criado_em", { ascending: false }).limit(1).maybeSingle(),
      this.#db.from("acao_pendente").select("tipo, payload")
        .eq("usuario_id", usuarioId).gt("expira_em", agora.toISOString())
        .order("criada_em", { ascending: false }).limit(1).maybeSingle(),
    ]);

    const candidatos: Array<{ quando: Date; tipo: "refeicao" | "peso"; resumo?: string }> = [];
    if (refeicao.data) {
      candidatos.push({
        quando: new Date(refeicao.data.registrada_em as string),
        tipo: "refeicao",
        resumo: (refeicao.data.texto_original as string | null) ?? undefined,
      });
    }
    if (pesagem.data) {
      candidatos.push({
        quando: new Date(pesagem.data.criado_em as string),
        tipo: "peso",
        resumo: `${pesagem.data.peso_kg}kg`,
      });
    }
    candidatos.sort((a, b) => b.quando.getTime() - a.quando.getTime());
    if (candidatos[0]) {
      contexto.ultimo_registro = {
        tipo: candidatos[0].tipo,
        ha_minutos: Math.round((agora.getTime() - candidatos[0].quando.getTime()) / 60_000),
        resumo: candidatos[0].resumo,
      };
    }
    if (pendente.data) {
      const payload = pendente.data.payload as { resumo?: string } | null;
      contexto.acao_pendente = { tipo: pendente.data.tipo as string, resumo: payload?.resumo };
    }
    return contexto;
  }

  async registrarMensagem(m: MensagemRegistrada): Promise<void> {
    const { error } = await this.#db.from("mensagem").insert({
      usuario_id: m.usuarioId,
      direcao: m.direcao,
      conteudo: m.conteudo,
      intent: m.intent ?? null,
      correlacao_id: m.idCorrelacao,
      criada_em: m.criadaEm.toISOString(),
    });
    if (error) throw new Error(`mensagem: ${error.message}`);
  }

  async marcarSinalTranstornoAlimentar(usuarioId: string): Promise<void> {
    const { error } = await this.#db.from("perfil")
      .update({ sinal_transtorno_alimentar: true })
      .eq("usuario_id", usuarioId);
    if (error) throw new Error(`perfil: ${error.message}`);
  }
}

/** Registrador de `llm_chamada` (RNF-11). */
export function criarRegistradorLlm(db: SupabaseClient) {
  return async (log: LogLlmChamada): Promise<void> => {
    const { error } = await db.from("llm_chamada").insert({
      usuario_id: log.usuarioId ?? null,
      correlacao_id: log.idCorrelacao ?? null,
      skill: log.skill,
      versao_skill: log.versaoSkill,
      modelo: log.modelo,
      tokens: log.tokens,
      latencia_ms: log.latenciaMs,
      entrada_hash: log.entradaHash,
      saida: log.saida ?? null,
      validacao_ok: log.validacaoOk,
      erro: log.erro,
    });
    if (error) throw new Error(`llm_chamada: ${error.message}`);
  };
}

