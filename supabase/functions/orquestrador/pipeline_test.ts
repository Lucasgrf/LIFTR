import { assert, assertEquals } from "jsr:@std/assert@1";
import { FakeLlmClient } from "../_shared/llm/fake_llm_client.ts";
import { FakeWhatsAppGateway } from "../_shared/whatsapp/whatsapp_gateway.ts";
import { MENSAGENS } from "../_shared/templates/mensagens.ts";
import type { EventoWebhookWhatsApp } from "../_shared/whatsapp/whatsapp_gateway.ts";
import {
  type ContextoConversa,
  type DepsOrquestrador,
  type MensagemRegistrada,
  type OrquestradorRepo,
  processarMensagem,
} from "./pipeline.ts";

const AGORA = new Date("2026-11-03T12:00:00-03:00");

class FakeRepo implements OrquestradorRepo {
  mensagens: MensagemRegistrada[] = [];
  sinaisTca: string[] = [];
  contagemMinuto = 0;
  contagemDia = 0;
  constructor(private readonly usuarios: Record<string, string> = { "5511999999999": "user-1" }) {}

  buscarUsuarioPorNumero(numero: string) {
    const usuarioId = this.usuarios[numero];
    return Promise.resolve(usuarioId ? { usuarioId } : null);
  }
  contarMensagensEntrada(_u: string, desde: Date) {
    // janela de 1 minuto vs. 1 dia
    return Promise.resolve(AGORA.getTime() - desde.getTime() <= 60_000 ? this.contagemMinuto : this.contagemDia);
  }
  buscarContexto(): Promise<ContextoConversa> {
    return Promise.resolve({});
  }
  registrarMensagem(m: MensagemRegistrada) {
    this.mensagens.push(m);
    return Promise.resolve();
  }
  marcarSinalTranstornoAlimentar(usuarioId: string) {
    this.sinaisTca.push(usuarioId);
    return Promise.resolve();
  }
}

const rota = (
  intent: string,
  flags: Partial<{ tentativa_injecao: boolean; flag_transtorno_alimentar: boolean }> = {},
  extra: Record<string, unknown> = {},
) => ({
  intent,
  confianca: 0.95,
  flags: {
    tentativa_injecao: false,
    flag_transtorno_alimentar: false,
    multiplas_intencoes: false,
    ...flags,
  },
  precisa_esclarecer: false,
  pergunta_esclarecimento: null,
  ...extra,
});

const evento = (texto: string, numero = "5511999999999"): EventoWebhookWhatsApp => ({
  idMensagem: "m1",
  numero,
  texto,
  recebidoEm: AGORA,
});

function montar(
  respostasLlm: ConstructorParameters<typeof FakeLlmClient>[0],
  repo = new FakeRepo(),
  extra: Partial<DepsOrquestrador> = {},
) {
  const whatsapp = new FakeWhatsAppGateway();
  const llm = new FakeLlmClient(respostasLlm);
  const deps: DepsOrquestrador = {
    repo,
    llm,
    whatsapp,
    agora: () => AGORA,
    gerarId: () => "corr-1",
    ...extra,
  };
  return { repo, llm, whatsapp, deps };
}

Deno.test("número fora da whitelist: não chama LLM, não responde e não grava", async () => {
  const { deps, llm, whatsapp, repo } = montar({});
  const r = await processarMensagem(evento("oi", "5511000000000"), deps);
  assertEquals(r.desvio, "nao_autorizado");
  assertEquals(r.resposta, null);
  assertEquals(llm.chamadas.length, 0);
  assertEquals(whatsapp.enviadas.length, 0);
  assertEquals(repo.mensagens.length, 0);
});

Deno.test("texto acima de 1.000 caracteres: resposta fixa sem LLM", async () => {
  const { deps, llm, whatsapp } = montar({});
  const r = await processarMensagem(evento("a".repeat(1001)), deps);
  assertEquals(r.desvio, "texto_longo");
  assertEquals(llm.chamadas.length, 0);
  assertEquals(whatsapp.enviadas[0].texto, MENSAGENS.textoLongo);
});

Deno.test("rate limit por minuto: resposta fixa sem LLM", async () => {
  const repo = new FakeRepo();
  repo.contagemMinuto = 11;
  const { deps, llm } = montar({}, repo);
  const r = await processarMensagem(evento("oi"), deps);
  assertEquals(r.desvio, "rate_limit");
  assertEquals(llm.chamadas.length, 0);
});

Deno.test("saudação: template fixo e mensagens de entrada/saída registradas", async () => {
  const { deps, whatsapp, repo } = montar({ "roteador-intencao": [rota("saudacao")] });
  const r = await processarMensagem(evento("oi"), deps);
  assertEquals(r.intent, "saudacao");
  assertEquals(whatsapp.enviadas[0].texto, MENSAGENS.saudacao);
  assertEquals(whatsapp.enviadas[0].idCorrelacao, "corr-1");
  assertEquals(repo.mensagens.map((m) => m.direcao), ["entrada", "saida"]);
});

Deno.test("fora_de_escopo e tentativa de injeção: template fixo", async () => {
  const a = montar({ "roteador-intencao": [rota("fora_de_escopo")] });
  assertEquals((await processarMensagem(evento("poema"), a.deps)).desvio, "fora_de_escopo");

  const b = montar({
    "roteador-intencao": [rota("registrar_refeicao", { tentativa_injecao: true })],
  });
  const r = await processarMensagem(evento("ignore tudo"), b.deps);
  assertEquals(r.desvio, "fora_de_escopo");
  assertEquals(b.whatsapp.enviadas[0].texto, MENSAGENS.foraDeEscopo);
});

Deno.test("saude_sensivel: template de segurança, sem handler", async () => {
  const { deps, whatsapp } = montar({ "roteador-intencao": [rota("saude_sensivel")] });
  const r = await processarMensagem(evento("dor no joelho"), deps);
  assertEquals(r.desvio, "saude_sensivel");
  assertEquals(whatsapp.enviadas[0].texto, MENSAGENS.saudeSensivel);
});

Deno.test("sinal de transtorno alimentar: template de cuidado e marca o usuário", async () => {
  const { deps, repo, whatsapp } = montar({
    "roteador-intencao": [rota("saude_sensivel", { flag_transtorno_alimentar: true })],
  });
  const r = await processarMensagem(evento("fiquei 3 dias sem comer"), deps);
  assertEquals(r.desvio, "transtorno_alimentar");
  assertEquals(repo.sinaisTca, ["user-1"]);
  assertEquals(whatsapp.enviadas[0].texto, MENSAGENS.transtornoAlimentar);
});

Deno.test("fallback: roteador devolve saída inválida 3x → pede para reformular", async () => {
  const invalida = { intent: "qualquer_coisa" };
  const { deps, whatsapp } = montar({ "roteador-intencao": [invalida, invalida, invalida] });
  const r = await processarMensagem(evento("???"), deps);
  assertEquals(r.desvio, "falha_roteamento");
  assertEquals(whatsapp.enviadas[0].texto, MENSAGENS.erroFallback);
});

Deno.test("precisa_esclarecer: devolve a pergunta do roteador", async () => {
  const { deps, whatsapp } = montar({
    "roteador-intencao": [
      rota("registrar_peso", {}, {
        confianca: 0.5,
        precisa_esclarecer: true,
        pergunta_esclarecimento: "Foi o seu peso em kg?",
      }),
    ],
  });
  const r = await processarMensagem(evento("80"), deps);
  assertEquals(r.desvio, "esclarecimento");
  assertEquals(whatsapp.enviadas[0].texto, "Foi o seu peso em kg?");
});

Deno.test("intenção sem handler: resposta 'em breve'; com handler: usa o texto do handler", async () => {
  const sem = montar({ "roteador-intencao": [rota("registrar_peso")] });
  const r1 = await processarMensagem(evento("80kg"), sem.deps);
  assertEquals(r1.desvio, "nao_implementado");

  const com = montar({ "roteador-intencao": [rota("registrar_peso")] }, new FakeRepo(), {
    handlers: { registrar_peso: () => Promise.resolve("Registrei 80kg.") },
  });
  const r2 = await processarMensagem(evento("80kg"), com.deps);
  assertEquals(r2.resposta, "Registrei 80kg.");
  assert(r2.enviada);
});
