import { z } from "../deps.ts";
import { encodeBase64 } from "jsr:@std/encoding@1/base64";
import { err, ok, type Result } from "../domain/result.ts";
import type { NomeSkill } from "../schemas/index.ts";
import {
  type CarregadorSkill,
  type ChamadaSkill,
  type ErroLlm,
  executarComRetentativas,
  type GerarTexto,
  type LlmClient,
  type ModeloLlm,
  type RegistradorLlm,
} from "./llm_client.ts";

const BASE_URL = "https://generativelanguage.googleapis.com/v1beta";
export const MODELO_EMBEDDING = "text-embedding-004";
export const DIMENSAO_EMBEDDING = 768;

/** Flash para classificação/extração/visão; Pro para redação sobre fatos (ADR-003). */
export function modeloPadrao(skill: NomeSkill): ModeloLlm {
  return skill === "resumo-pos-treino" || skill === "relatorio-semanal"
    ? "gemini-2.5-pro"
    : "gemini-2.5-flash";
}

function temperaturaPadrao(skill: NomeSkill): number {
  return skill === "resumo-pos-treino" || skill === "relatorio-semanal" ? 0.3 : 0.1;
}

const RespostaGemini = z.object({
  candidates: z.array(
    z.object({
      content: z.object({ parts: z.array(z.object({ text: z.string().optional() })) }),
    }),
  ).min(1),
  usageMetadata: z.object({ totalTokenCount: z.number().optional() }).optional(),
});

const RespostaEmbedding = z.object({
  embedding: z.object({ values: z.array(z.number()) }),
});

export type OpcoesGemini = {
  apiKey: string;
  carregarSkill: CarregadorSkill;
  registrar?: RegistradorLlm;
  fetchFn?: typeof fetch;
};

export class GeminiLlmClient implements LlmClient {
  readonly #opcoes: OpcoesGemini;

  constructor(opcoes: OpcoesGemini) {
    this.#opcoes = opcoes;
  }

  async executarSkill<T>(chamada: ChamadaSkill<T>): Promise<Result<T, ErroLlm>> {
    const skill = await this.#opcoes.carregarSkill(chamada.skill);
    const modelo = chamada.modelo ?? modeloPadrao(chamada.skill);
    const executar = (m: ModeloLlm) =>
      executarComRetentativas({
        chamada,
        skill,
        modelo: m,
        gerar: this.#gerar(temperaturaPadrao(chamada.skill)),
        registrar: this.#opcoes.registrar,
      });

    const resultado = await executar(modelo);
    // Falha do provedor no Pro → tenta uma vez no Flash (ADR-003).
    if (!resultado.ok && resultado.erro.tipo === "provedor" && modelo === "gemini-2.5-pro") {
      return executar("gemini-2.5-flash");
    }
    return resultado;
  }

  async gerarEmbedding(texto: string): Promise<Result<number[], ErroLlm>> {
    const resp = await this.#post(`${BASE_URL}/models/${MODELO_EMBEDDING}:embedContent`, {
      model: `models/${MODELO_EMBEDDING}`,
      content: { parts: [{ text: texto }] },
    });
    if (!resp.ok) return resp;
    const parsed = RespostaEmbedding.safeParse(resp.valor);
    if (!parsed.success) {
      return err({ tipo: "provedor", mensagem: "resposta de embedding inesperada" });
    }
    const valores = parsed.data.embedding.values;
    if (valores.length !== DIMENSAO_EMBEDDING) {
      return err({
        tipo: "provedor",
        mensagem: `embedding com ${valores.length} dimensões (esperado ${DIMENSAO_EMBEDDING})`,
      });
    }
    return ok(valores);
  }

  #gerar(temperatura: number): GerarTexto {
    return async ({ sistema, usuario, modelo, imagem }) => {
      const partes: Array<Record<string, unknown>> = [{ text: usuario }];
      if (imagem) {
        partes.push({ inline_data: { mime_type: imagem.mimeType, data: encodeBase64(imagem.dados) } });
      }
      const resp = await this.#post(`${BASE_URL}/models/${modelo}:generateContent`, {
        systemInstruction: { parts: [{ text: sistema }] },
        contents: [{ role: "user", parts: partes }],
        generationConfig: { temperature: temperatura, responseMimeType: "application/json" },
      });
      if (!resp.ok) return resp;
      const parsed = RespostaGemini.safeParse(resp.valor);
      if (!parsed.success) {
        return err({ tipo: "provedor", mensagem: "resposta do Gemini em formato inesperado" });
      }
      const texto = parsed.data.candidates[0].content.parts.map((p) => p.text ?? "").join("");
      return ok({ texto, tokens: parsed.data.usageMetadata?.totalTokenCount });
    };
  }

  async #post(url: string, corpo: unknown): Promise<Result<unknown, ErroLlm>> {
    const fetchFn = this.#opcoes.fetchFn ?? fetch;
    try {
      const resp = await fetchFn(url, {
        method: "POST",
        headers: { "content-type": "application/json", "x-goog-api-key": this.#opcoes.apiKey },
        body: JSON.stringify(corpo),
      });
      if (!resp.ok) {
        return err({ tipo: "provedor", mensagem: `Gemini HTTP ${resp.status}` });
      }
      return ok(await resp.json() as unknown);
    } catch (e) {
      return err({
        tipo: "provedor",
        mensagem: e instanceof Error ? e.message : "falha de rede ao chamar o Gemini",
      });
    }
  }
}

