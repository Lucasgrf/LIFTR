# ADR-004: Modelagem de séries individuais e preservação de histórico por exercício

- **Status:** Aceito
- **Data:** 03/11/2026
- **Contexto:** PRD §2, §3, §4.1, §7.2, US-06, US-08, US-13

## Contexto e Problema

No MVP, os treinos utilizam **séries retas** (mesma carga alvo em todas as séries válidas de um exercício). No entanto, o backlog pós-MVP prevê técnicas como pirâmide crescente/decrescente, *top set + back-off* e *drop set*. Além disso, usuários trocam de estilo de programa (ex.: de PPL para Upper/Lower) e realizam séries de aquecimento antes das séries de trabalho.

Se modelássemos a execução de um exercício de forma agregada (ex.: uma linha com `"3x12 @ 30kg"`) ou atrelássemos o histórico ao `slot` do programa atual, teríamos dois problemas graves:
1. Perda de histórico ou quebra de referências quando o usuário edita um slot ou troca de programa (violando US-06).
2. Necessidade de migrations destrutivas no banco local (Drift) e remoto (Supabase) para suportar séries com cargas diferentes ou séries de aquecimento.

## Decisão

### 1. Persistência Individual por Série (`serie`)
- Cada série realizada é salva como uma linha individual na tabela `serie` (tanto no SQLite/Drift quanto no Postgres/Supabase), contendo:
  - `id` (UUID gerado no cliente)
  - `treino_id` (FK para `treino`)
  - `exercicio_id` (FK direta para `exercicio`)
  - `ordem` (inteiro sequencial dentro do exercício no treino)
  - `peso` (numérico em kg)
  - `reps` (inteiro)
  - `tipo` (`'valida'` | `'aquecimento'`)

### 2. Aquecimento Isolado das Regras de Negócio
- Séries com `tipo = 'aquecimento'` são persistidas para registro histórico da sessão, mas são **filtradas na entrada** das funções puras de dupla progressão e cálculo de volume semanal.

### 3. Histórico e Progressão Pertencem ao `exercicio`
- A tabela `status_progressao` (`exercicio_id`, `treino_id`, `status`, `proximo_peso`, `progresso`) referencia diretamente `exercicio_id`, e não o `slot` ou o `programa`.
- Quando o usuário troca de programa (US-06) ou escolhe um exercício já conhecido em outro slot (US-10), o app consulta imediatamente o último `status_progressao` e o histórico de `serie` daquele `exercicio_id`, mantendo a sugestão de carga contínua.

## Consequências

- **Positivas:**
  - Suporte imediato a repetições variadas por série (ex.: `[12, 10, 9]`) e marcação individual de aquecimento (US-08).
  - Compatibilidade futura com pirâmide e *top set + back-off* sem alterar o schema do banco de dados.
  - Liberdade total para o usuário trocar de programa preservando 100% da sua evolução de cargas.
- **Negativas / Trade-offs:**
  - Maior número de linhas na tabela `serie` (cerca de 15–25 linhas por treino realizado, volume irrisório tanto para SQLite quanto para Postgres).

