import { err, ok, type Result } from "../domain/result.ts";
import type { NomeSkill } from "../schemas/index.ts";
import {
  type ChamadaSkill,
  type ErroLlm,
  executarComRetentativas,
  type LlmClient,
  type RegistradorLlm,
  type SkillCarregada,
} from "./llm_client.ts";

/** Resposta roteirizada: objeto (será serializado) ou string bruta (simula JSON inválido). */
export type RespostaFake = unknown;

/**
 * LlmClient para testes: consome respostas roteirizadas por skill (uma por tentativa), passando
 * pelo mesmo caminho de validação/retentativa das implementações reais.
 */
export class FakeLlmClient implements LlmClient {
  readonly chamadas: Array<{ skill: NomeSkill; entrada: unknown }> = [];
  readonly #filas: Map<NomeSkill, RespostaFake[]>;
  readonly #registrar?: RegistradorLlm;
  readonly #embedding: number[];

  constructor(
    respostas: Partial<Record<NomeSkill, RespostaFake[]>> = {},
    opcoes: { registrar?: RegistradorLlm; embedding?: number[] } = {},
  ) {
    this.#filas = new Map(
      Object.entries(respostas).map(([k, v]) => [k as NomeSkill, [...(v ?? [])]]),
    );
    this.#registrar = opcoes.registrar;
    this.#embedding = opcoes.embedding ?? new Array<number>(768).fill(0);
  }

  async executarSkill<T>(chamada: ChamadaSkill<T>): Promise<Result<T, ErroLlm>> {
    this.chamadas.push({ skill: chamada.skill, entrada: chamada.entrada });
    const skill: SkillCarregada = { nome: chamada.skill, versao: "v0.0-fake", prompt: "" };
    return await executarComRetentativas({
      chamada,
      skill,
      modelo: "gemini-2.5-flash",
      registrar: this.#registrar,
      gerar: () => {
        const proxima = this.#filas.get(chamada.skill)?.shift();
        if (proxima === undefined) {
          return Promise.resolve(
            err({ tipo: "provedor", mensagem: `FakeLlmClient sem resposta para ${chamada.skill}` }),
          );
        }
        const texto = typeof proxima === "string" ? proxima : JSON.stringify(proxima);
        return Promise.resolve(ok({ texto }));
      },
    });
  }

  gerarEmbedding(_texto: string): Promise<Result<number[], ErroLlm>> {
    return Promise.resolve(ok(this.#embedding));
  }
}

