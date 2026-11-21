/**
 * Porta `WhatsAppGateway` (ADR-002) + implementações `EvolutionWhatsAppGateway` e
 * `FakeWhatsAppGateway`.
 */
import { z } from "../deps.ts";
import { decodeBase64 } from "jsr:@std/encoding@1/base64";
import { err, ok, type Result } from "../domain/result.ts";

export type ErroWhatsApp =
  | { tipo: "nao_autorizado"; mensagem: string }
  | { tipo: "payload_invalido"; mensagem: string }
  | { tipo: "provedor"; mensagem: string };

export type EventoWebhookWhatsApp = {
  idMensagem: string;
  /** Somente dígitos, com DDI (ex.: 5511999999999). */
  numero: string;
  texto: string;
  midia?: { id: string; tipo: "imagem" };
  recebidoEm: Date;
};

export type MensagemEnviada = { idMensagem: string | null };

export interface WhatsAppGateway {
  enviarTexto(
    destino: string,
    texto: string,
    opcoes?: { idCorrelacao?: string },
  ): Promise<Result<MensagemEnviada, ErroWhatsApp>>;
  baixarMidia(
    idMensagem: string,
  ): Promise<Result<{ dados: Uint8Array; mimeType: string }, ErroWhatsApp>>;
  /** Devolve `null` para eventos que devem ser ignorados (mensagens próprias, status, grupos...). */
  parsearWebhook(req: Request): Promise<Result<EventoWebhookWhatsApp | null, ErroWhatsApp>>;
}

export function somenteDigitos(jidOuNumero: string): string {
  return jidOuNumero.split("@")[0].replace(/\D/g, "");
}

// ---------------------------------------------------------------------------
// Evolution API
// ---------------------------------------------------------------------------

export type OpcoesEvolution = {
  baseUrl: string;
  apiKey: string;
  instancia: string;
  webhookToken: string;
  fetchFn?: typeof fetch;
};

const PayloadEvolution = z.object({
  event: z.string(),
  data: z.object({
    key: z.object({
      remoteJid: z.string(),
      fromMe: z.boolean().optional(),
      id: z.string(),
    }),
    message: z.object({
      conversation: z.string().optional(),
      extendedTextMessage: z.object({ text: z.string().optional() }).optional(),
      imageMessage: z.object({ caption: z.string().optional() }).optional(),
    }).optional(),
    messageTimestamp: z.union([z.number(), z.string()]).optional(),
  }),
});

const RespostaMidia = z.object({ base64: z.string(), mimetype: z.string().optional() });

// TODO(US-40): validar formatos de payload/endpoints contra a versão da Evolution API em uso.
export class EvolutionWhatsAppGateway implements WhatsAppGateway {
  readonly #o: OpcoesEvolution;

  constructor(opcoes: OpcoesEvolution) {
    this.#o = opcoes;
  }

  async enviarTexto(
    destino: string,
    texto: string,
  ): Promise<Result<MensagemEnviada, ErroWhatsApp>> {
    try {
      const resp = await (this.#o.fetchFn ?? fetch)(
        `${this.#o.baseUrl}/message/sendText/${this.#o.instancia}`,
        {
          method: "POST",
          headers: { "content-type": "application/json", apikey: this.#o.apiKey },
          body: JSON.stringify({ number: somenteDigitos(destino), text: texto }),
        },
      );
      if (!resp.ok) return err({ tipo: "provedor", mensagem: `Evolution HTTP ${resp.status}` });
      const corpo = await resp.json().catch(() => null) as { key?: { id?: string } } | null;
      return ok({ idMensagem: corpo?.key?.id ?? null });
    } catch (e) {
      return err({ tipo: "provedor", mensagem: e instanceof Error ? e.message : "falha de rede" });
    }
  }

  async baixarMidia(
    idMensagem: string,
  ): Promise<Result<{ dados: Uint8Array; mimeType: string }, ErroWhatsApp>> {
    try {
      const resp = await (this.#o.fetchFn ?? fetch)(
        `${this.#o.baseUrl}/chat/getBase64FromMediaMessage/${this.#o.instancia}`,
        {
          method: "POST",
          headers: { "content-type": "application/json", apikey: this.#o.apiKey },
          body: JSON.stringify({ message: { key: { id: idMensagem } } }),
        },
      );
      if (!resp.ok) return err({ tipo: "provedor", mensagem: `Evolution HTTP ${resp.status}` });
      const parsed = RespostaMidia.safeParse(await resp.json());
      if (!parsed.success) {
        return err({ tipo: "provedor", mensagem: "resposta de mídia inesperada" });
      }
      return ok({
        dados: decodeBase64(parsed.data.base64),
        mimeType: parsed.data.mimetype ?? "image/jpeg",
      });
    } catch (e) {
      return err({ tipo: "provedor", mensagem: e instanceof Error ? e.message : "falha de rede" });
    }
  }

  async parsearWebhook(
    req: Request,
  ): Promise<Result<EventoWebhookWhatsApp | null, ErroWhatsApp>> {
    if (req.headers.get("x-webhook-token") !== this.#o.webhookToken) {
      return err({ tipo: "nao_autorizado", mensagem: "token de webhook inválido" });
    }
    const corpo = await req.json().catch(() => null) as unknown;
    const parsed = PayloadEvolution.safeParse(corpo);
    if (!parsed.success) {
      return err({ tipo: "payload_invalido", mensagem: "payload do webhook não reconhecido" });
    }
    const { event, data } = parsed.data;
    if (event.toLowerCase().replace("_", ".") !== "messages.upsert") return ok(null);
    if (data.key.fromMe === true) return ok(null);
    if (!data.key.remoteJid.endsWith("@s.whatsapp.net")) return ok(null); // ignora grupos/broadcast

    const msg = data.message;
    const texto = msg?.conversation ?? msg?.extendedTextMessage?.text ?? msg?.imageMessage?.caption ??
      "";
    const temImagem = msg?.imageMessage !== undefined;
    if (texto === "" && !temImagem) return ok(null);

    const ts = Number(data.messageTimestamp);
    return ok({
      idMensagem: data.key.id,
      numero: somenteDigitos(data.key.remoteJid),
      texto,
      midia: temImagem ? { id: data.key.id, tipo: "imagem" } : undefined,
      recebidoEm: Number.isFinite(ts) && ts > 0 ? new Date(ts * 1000) : new Date(),
    });
  }
}

// ---------------------------------------------------------------------------
// Fake (testes)
// ---------------------------------------------------------------------------

export class FakeWhatsAppGateway implements WhatsAppGateway {
  readonly enviadas: Array<{ destino: string; texto: string; idCorrelacao?: string }> = [];
  readonly midias = new Map<string, { dados: Uint8Array; mimeType: string }>();
  falharEnvio = false;

  enviarTexto(
    destino: string,
    texto: string,
    opcoes?: { idCorrelacao?: string },
  ): Promise<Result<MensagemEnviada, ErroWhatsApp>> {
    if (this.falharEnvio) {
      return Promise.resolve(err({ tipo: "provedor", mensagem: "falha simulada" }));
    }
    this.enviadas.push({ destino, texto, idCorrelacao: opcoes?.idCorrelacao });
    return Promise.resolve(ok({ idMensagem: `fake-${this.enviadas.length}` }));
  }

  baixarMidia(
    idMensagem: string,
  ): Promise<Result<{ dados: Uint8Array; mimeType: string }, ErroWhatsApp>> {
    const midia = this.midias.get(idMensagem);
    return Promise.resolve(
      midia ? ok(midia) : err({ tipo: "provedor", mensagem: "mídia inexistente" }),
    );
  }

  /** Aceita um JSON `{ idMensagem, numero, texto, midia? }` no corpo. */
  async parsearWebhook(
    req: Request,
  ): Promise<Result<EventoWebhookWhatsApp | null, ErroWhatsApp>> {
    const corpo = await req.json().catch(() => null) as
      | { idMensagem?: string; numero?: string; texto?: string; midia?: { id: string; tipo: "imagem" } }
      | null;
    if (!corpo?.idMensagem || !corpo.numero) {
      return err({ tipo: "payload_invalido", mensagem: "payload fake inválido" });
    }
    return ok({
      idMensagem: corpo.idMensagem,
      numero: corpo.numero,
      texto: corpo.texto ?? "",
      midia: corpo.midia,
      recebidoEm: new Date(),
    });
  }
}

