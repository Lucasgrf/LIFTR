/** Erros como valores no domínio (AGENTS.md). */
export type Result<T, E> = { ok: true; valor: T } | { ok: false; erro: E };

export function ok<T>(valor: T): Result<T, never> {
  return { ok: true, valor };
}

export function err<E>(erro: E): Result<never, E> {
  return { ok: false, erro };
}

