/**
 * Entrada de mensagens do WhatsApp (ADR-002). Valida o token, responde 200 imediatamente e processa
 * em segundo plano com `EdgeRuntime.waitUntil` para evitar retentativas por timeout do provedor.
 */
import { criarCarregadorSkill } from "../_shared/llm/llm_client.ts";
import { GeminiLlmClient } from "../_shared/llm/gemini_llm_client.ts";
import { EvolutionWhatsAppGateway } from "../_shared/whatsapp/whatsapp_gateway.ts";
import {
  criarClienteServico,
  criarRegistradorLlm,
  SupabaseOrquestradorRepo,
} from "../_shared/repo/supabase_repo.ts";
import { processarMensagem } from "../orquestrador/pipeline.ts";

declare const EdgeRuntime: { waitUntil(promessa: Promise<unknown>): void } | undefined;

function env(nome: string): string {
  const valor = Deno.env.get(nome);
  if (!valor) throw new Error(`variável de ambiente ausente: ${nome}`);
  return valor;
}

Deno.serve(async (req) => {
  const whatsapp = new EvolutionWhatsAppGateway({
    baseUrl: env("EVOLUTION_API_URL"),
    apiKey: env("EVOLUTION_API_KEY"),
    instancia: env("EVOLUTION_INSTANCE"),
    webhookToken: env("WHATSAPP_WEBHOOK_TOKEN"),
  });

  const evento = await whatsapp.parsearWebhook(req);
  if (!evento.ok) {
    const status = evento.erro.tipo === "nao_autorizado" ? 401 : 400;
    return new Response(JSON.stringify({ erro: evento.erro.mensagem }), { status });
  }
  if (evento.valor === null) return new Response("ignorado", { status: 200 });

  const db = criarClienteServico(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"));
  // TODO(US-34): empacotar skills/ junto da função no deploy (static_files); SKILLS_DIR aponta para a pasta.
  const llm = new GeminiLlmClient({
    apiKey: env("GEMINI_API_KEY"),
    carregarSkill: criarCarregadorSkill(Deno.env.get("SKILLS_DIR") ?? "./skills"),
    registrar: criarRegistradorLlm(db),
  });

  const processamento = processarMensagem(evento.valor, {
    repo: new SupabaseOrquestradorRepo(db),
    llm,
    whatsapp,
    agora: () => new Date(),
  }).catch((e) => console.error("falha no orquestrador", e));

  if (typeof EdgeRuntime !== "undefined") EdgeRuntime.waitUntil(processamento);
  else await processamento; // execução local fora do runtime do Supabase

  return new Response("ok", { status: 200 });
});

