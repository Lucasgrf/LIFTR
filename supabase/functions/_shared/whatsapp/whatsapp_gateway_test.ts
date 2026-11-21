import { assert, assertEquals } from "jsr:@std/assert@1";
import { EvolutionWhatsAppGateway, somenteDigitos } from "./whatsapp_gateway.ts";

const gateway = (fetchFn?: typeof fetch) =>
  new EvolutionWhatsAppGateway({
    baseUrl: "http://evolution.test",
    apiKey: "k",
    instancia: "inst",
    webhookToken: "segredo",
    fetchFn,
  });

const webhook = (corpo: unknown, token = "segredo") =>
  new Request("http://fn.test/whatsapp-webhook", {
    method: "POST",
    headers: { "x-webhook-token": token, "content-type": "application/json" },
    body: JSON.stringify(corpo),
  });

const upsert = (key: object, message: object) => ({
  event: "messages.upsert",
  data: { key, message, messageTimestamp: 1793674800 },
});

Deno.test("somenteDigitos remove sufixo do JID", () => {
  assertEquals(somenteDigitos("5511999999999@s.whatsapp.net"), "5511999999999");
});

Deno.test("webhook: token inválido é rejeitado", async () => {
  const r = await gateway().parsearWebhook(webhook({}, "errado"));
  assert(!r.ok);
  assertEquals(r.erro.tipo, "nao_autorizado");
});

Deno.test("webhook: mensagem de texto vira evento", async () => {
  const r = await gateway().parsearWebhook(
    webhook(upsert({ remoteJid: "5511999999999@s.whatsapp.net", fromMe: false, id: "A1" }, {
      conversation: "me pesei hoje, 80kg",
    })),
  );
  assert(r.ok && r.valor !== null);
  assertEquals(r.valor.numero, "5511999999999");
  assertEquals(r.valor.texto, "me pesei hoje, 80kg");
  assertEquals(r.valor.recebidoEm.getTime(), 1793674800 * 1000);
});

Deno.test("webhook: imagem com legenda carrega mídia", async () => {
  const r = await gateway().parsearWebhook(
    webhook(upsert({ remoteJid: "5511999999999@s.whatsapp.net", id: "B2" }, {
      imageMessage: { caption: "almoço" },
    })),
  );
  assert(r.ok && r.valor !== null);
  assertEquals(r.valor.midia, { id: "B2", tipo: "imagem" });
  assertEquals(r.valor.texto, "almoço");
});

Deno.test("webhook: ignora mensagens próprias, grupos e outros eventos", async () => {
  const propria = await gateway().parsearWebhook(
    webhook(upsert({ remoteJid: "5511999999999@s.whatsapp.net", fromMe: true, id: "C" }, {
      conversation: "oi",
    })),
  );
  assert(propria.ok && propria.valor === null);

  const grupo = await gateway().parsearWebhook(
    webhook(upsert({ remoteJid: "1203630@g.us", id: "D" }, { conversation: "oi" })),
  );
  assert(grupo.ok && grupo.valor === null);

  const outro = await gateway().parsearWebhook(
    webhook({ event: "connection.update", data: { key: { remoteJid: "x@s.whatsapp.net", id: "E" } } }),
  );
  assert(outro.ok && outro.valor === null);
});

Deno.test("enviarTexto: chama o endpoint da instância com a apikey", async () => {
  let chamada: { url: string; apikey: string | null; corpo: unknown } | null = null;
  const fake: typeof fetch = (input, init) => {
    chamada = {
      url: String(input),
      apikey: new Headers(init?.headers).get("apikey"),
      corpo: JSON.parse(String(init?.body)),
    };
    return Promise.resolve(new Response(JSON.stringify({ key: { id: "ZZ" } }), { status: 200 }));
  };
  const r = await gateway(fake).enviarTexto("5511999999999@s.whatsapp.net", "oi");
  assert(r.ok);
  assertEquals(r.valor.idMensagem, "ZZ");
  assertEquals(chamada, {
    url: "http://evolution.test/message/sendText/inst",
    apikey: "k",
    corpo: { number: "5511999999999", text: "oi" },
  });
});

