# Skills do sistema

Módulos de instrução usados **pelo backend em runtime** (não pelo agente de código). Cada pasta tem:

```
<skill>/
├── SKILL.md          frontmatter (name, description) + entrada, saída, regras, exemplos
└── evals/casos.jsonl casos dourados rodados no CI
```

## Como o orquestrador usa

1. Monta o prompt de sistema = `_compartilhado/POLITICA.md` + `SKILL.md` da intenção.
2. Envia a entrada da skill como JSON, com o conteúdo do usuário dentro de `<mensagem_usuario>`.
3. Valida a resposta contra o schema Zod correspondente (`supabase/functions/_shared/schemas/<skill>.ts`).
4. Grava `llm_chamada` com `skill` e `versao` (lida do título do SKILL.md, ex.: `v0.1`).

## Versionamento

Qualquer mudança em SKILL.md → incrementar a versão no título → rodar `npm run evals -- --skill <nome>`. Regressão em métrica do PRD §8.5 bloqueia o merge.

## Evals

Casos com `esperado` literal comparam campos. Casos com `propriedades` usam checadores nomeados (ex.: `numeros_subconjunto_fatos`, `len<=400`) implementados em `evals/checadores.ts`.
