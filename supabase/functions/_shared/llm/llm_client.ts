/**
 * Porta `LlmClient` (ADR-003) + utilitários compartilhados pelas implementações:
 * carregador de skills, isolamento do conteúdo do usuário, validação Zod com retentativas e log.
 */
import { z } from "../deps.ts";
import { err, ok, type Result } from "../domain/result.ts";
import type { NomeSkill } from "../schemas/index.ts";

export type ModeloLlm = "gemini-2.5-flash" | "gemini-2.5-pro";

export type ErroLlm =
  | { tipo: "provedor"; mensagem: string }
  | { tipo: "validacao"; mensagem: string; tentativas: number };

export type ImagemEntrada = { mimeType: string; dados: Uint8Array };

export type ChamadaSkill<T> = {
  skill: NomeSkill;
  /** Conteúdo enviado como JSON; campos de texto do usuário são isolados em <mensagem_usuario>. */
  entrada: unknown;
  schema: z.ZodType<T>;
  modelo?: ModeloLlm;
  imagem?: ImagemEntrada;
  idCorrelacao?: string;
  usuarioId?: string;
};

export interface LlmClient {
  executarSkill<T>(chamada: ChamadaSkill<T>): Promise<Result<T, ErroLlm>>;
  gerarEmbedding(texto: string): Promise<Result<number[], ErroLlm>>;
}

// ---------------------------------------------------------------------------
// Log de chamadas (tabela llm_chamada)
// ---------------------------------------------------------------------------

export type LogLlmChamada = {
  skill: NomeSkill;
  versaoSkill: string;
  modelo: string;
  tokens: number | null;
  latenciaMs: number;
  entradaHash: string;
  saida: unknown;
  validacaoOk: boolean;
  erro: string | null;
  tentativas: number;
  idCorrelacao?: string;
  usuarioId?: string;
};

export type RegistradorLlm = (log: LogLlmChamada) => Promise<void>;

// ---------------------------------------------------------------------------
// Skills
// ---------------------------------------------------------------------------

export type SkillCarregada = { nome: NomeSkill; versao: string; prompt: string };
export type CarregadorSkill = (nome: NomeSkill) => Promise<SkillCarregada>;

const REGEX_VERSAO = /^#\s.*?·\s*(v\d+(?:\.\d+)*)/m;

export function extrairVersaoSkill(markdown: string): string | null {
  return REGEX_VERSAO.exec(markdown)?.[1] ?? null;
}

function removerFrontmatter(markdown: string): string {
  return markdown.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, "");
}

/** Prompt de sistema = POLITICA.md + SKILL.md da intenção (skills/README.md). */
export function criarCarregadorSkill(
  baseDir: string,
  ler: (caminho: string) => Promise<string> = (p) => Deno.readTextFile(p),
): CarregadorSkill {
  const base = baseDir.replace(/\/+$/, "");
  const cache = new Map<NomeSkill, SkillCarregada>();
  return async (nome) => {
    const emCache = cache.get(nome);
    if (emCache) return emCache;
    const [politica, skill] = await Promise.all([
      ler(`${base}/_compartilhado/POLITICA.md`),
      ler(`${base}/${nome}/SKILL.md`),
    ]);
    const versao = extrairVersaoSkill(skill);
    if (versao === null) {
      throw new Error(`skills/${nome}/SKILL.md: versão não encontrada no título (ex.: "· v0.1")`);
    }
    const carregada: SkillCarregada = {
      nome,
      versao,
      prompt: `${politica.trim()}\n\n---\n\n${removerFrontmatter(skill).trim()}`,
    };
    cache.set(nome, carregada);
    return carregada;
  };
}

// ---------------------------------------------------------------------------
// Conteúdo do usuário é dado (AGENTS.md regra 5)
// ---------------------------------------------------------------------------

const CAMPOS_CONTEUDO_USUARIO = ["mensagem_usuario", "descricao_imagem", "pergunta"] as const;

function neutralizarTags(texto: string): string {
  return texto.replace(/<\/?mensagem_usuario>/gi, "");
}

export function envolverConteudoUsuario(entrada: unknown): unknown {
  if (entrada === null || typeof entrada !== "object" || Array.isArray(entrada)) return entrada;
  const copia: Record<string, unknown> = { ...(entrada as Record<string, unknown>) };
  for (const campo of CAMPOS_CONTEUDO_USUARIO) {
    const valor = copia[campo];
    if (typeof valor === "string") {
      copia[campo] = `<mensagem_usuario>${neutralizarTags(valor)}</mensagem_usuario>`;
    }
  }
  return copia;
}

export function montarMensagemUsuario(entrada: unknown): string {
  return JSON.stringify(envolverConteudoUsuario(entrada), null, 2);
}

// ---------------------------------------------------------------------------
// Execução com validação e retentativas (até 2 retentativas → fallback por template)
// ---------------------------------------------------------------------------

export type GerarTexto = (args: {
  sistema: string;
  usuario: string;
  modelo: ModeloLlm;
  imagem?: ImagemEntrada;
}) => Promise<Result<{ texto: string; tokens?: number }, ErroLlm>>;

export const MAX_RETENTATIVAS = 2;

/** Parse que nunca é usado sem validação posterior: o chamador sempre aplica o schema Zod. */
export function parseJsonSeguro(texto: string): Result<unknown, string> {
  const limpo = texto.trim().replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "");
  try {
    return ok(JSON.parse(limpo) as unknown);
  } catch (e) {
    return err(`JSON inválido: ${e instanceof Error ? e.message : String(e)}`);
  }
}

export async function hashEntrada(entrada: unknown): Promise<string> {
  const bytes = new TextEncoder().encode(JSON.stringify(entrada) ?? "");
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function resumirIssues(erro: z.ZodError): string {
  return erro.issues.map((i) => `${i.path.join(".") || "(raiz)"}: ${i.message}`).join("; ");
}

export async function executarComRetentativas<T>(params: {
  chamada: ChamadaSkill<T>;
  skill: SkillCarregada;
  modelo: ModeloLlm;
  gerar: GerarTexto;
  maxRetentativas?: number;
  registrar?: RegistradorLlm;
}): Promise<Result<T, ErroLlm>> {
  const { chamada, skill, modelo, gerar, registrar } = params;
  const maxTentativas = (params.maxRetentativas ?? MAX_RETENTATIVAS) + 1;
  const base = montarMensagemUsuario(chamada.entrada);
  const inicio = Date.now();
  let tokens: number | null = null;
  let ultimoErro = "";
  let ultimaSaida: unknown = null;
  let tentativas = 0;
  let resultado: Result<T, ErroLlm> | null = null;

  while (tentativas < maxTentativas && resultado === null) {
    tentativas++;
    const usuario = ultimoErro === ""
      ? base
      : `${base}\n\nSua resposta anterior foi inválida (${ultimoErro}). Responda novamente somente com o JSON válido do schema.`;
    const bruto = await gerar({
      sistema: skill.prompt,
      usuario,
      modelo,
      imagem: chamada.imagem,
    });
    if (!bruto.ok) {
      ultimoErro = bruto.erro.mensagem;
      resultado = err(bruto.erro);
      break;
    }
    if (bruto.valor.tokens !== undefined) tokens = (tokens ?? 0) + bruto.valor.tokens;
    const json = parseJsonSeguro(bruto.valor.texto);
    if (!json.ok) {
      ultimoErro = json.erro;
      continue;
    }
    ultimaSaida = json.valor;
    const validado = chamada.schema.safeParse(json.valor);
    if (validado.success) {
      resultado = ok(validado.data);
    } else {
      ultimoErro = resumirIssues(validado.error);
    }
  }

  const final: Result<T, ErroLlm> = resultado ??
    err({ tipo: "validacao", mensagem: ultimoErro, tentativas });

  if (registrar) {
    await registrar({
      skill: skill.nome,
      versaoSkill: skill.versao,
      modelo,
      tokens,
      latenciaMs: Date.now() - inicio,
      entradaHash: await hashEntrada(chamada.entrada),
      saida: final.ok ? final.valor : ultimaSaida,
      validacaoOk: final.ok,
      erro: final.ok ? null : ultimoErro,
      tentativas,
      idCorrelacao: chamada.idCorrelacao,
      usuarioId: chamada.usuarioId,
    }).catch(() => undefined); // log nunca derruba o fluxo
  }
  return final;
}

