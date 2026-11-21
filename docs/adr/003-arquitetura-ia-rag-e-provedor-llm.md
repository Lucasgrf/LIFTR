# ADR-003: Arquitetura da camada de IA, RAG com seleção por ID e escolha do Google Gemini

- **Status:** Aceito
- **Data:** 03/11/2026
- **Contexto:** PRD §4.2–4.4, §8, §9, §14, RNF-08..11, US-34..39

## Contexto e Problema

O sistema utiliza LLMs para interpretar mensagens de texto e fotos de refeições no WhatsApp, extrair pesagens e redigir resumos/relatórios semanais. Porém, LLMs sofrem de alucinação aritmética e nutricional se tiverem liberdade para inventar calorias, proteínas ou metas.

Precisávamos definir:
1. Como garantir por construção que o LLM nunca calcule nem invente dados nutricionais.
2. Qual arquitetura adotar no `orquestrador` para validação, retentativas, guardrails e testes.
3. Qual provedor e modelos de LLM/Embeddings adotar como implementação concreta do `LlmClient` e qual dimensão configurar no `pgvector`.
4. Como unificar o código de validação Zod entre o runtime das Edge Functions e o runner de `evals/`.

## Decisão

### 1. Separação Estrita: LLM Interpreta/Redige, Backend Calcula
- **Proibição de cálculo no LLM:** Nenhum valor de caloria, proteína, TDEE, tendência de peso ou meta é aceito a partir da resposta do modelo. As únicas grandezas numéricas extraídas por LLM são:
  - Peso corporal informado pelo usuário na skill `registrar-peso` (validado na faixa 30–300 kg e confrontado com a tendência).
  - Quantidades/gramas ou medidas caseiras informadas na skill `registrar-refeicao`.
- **Grounding por ID no RAG Híbrido:**
  - A busca de alimentos combina `pg_trgm` (similaridade textual + sinônimos regionais) e `pgvector` (busca semântica) com *Reciprocal Rank Fusion* (RRF), retornando os *top-5* candidatos por item mencionado, além das refeições frequentes do usuário.
  - O schema Zod da skill `registrar-refeicao` exige que o `alimento_id` escolhido pertença estritamente ao conjunto de IDs enviados no contexto (ou retorne `sem_match`). O cálculo de kcal e proteína é feito em SQL/TypeScript multiplicando `gramas` pelos valores da Tabela TACO/alimento cadastrado.
- **Validador Numérico de Relatórios:**
  - Nas skills `relatorio-semanal` e `resumo-pos-treino`, todo número presente no texto redigido pelo LLM é extraído por regex e comparado contra o JSON de fatos determinísticos enviado na entrada. Se houver qualquer número não presente nos fatos, a saída é rejeitada (regenera 1× → fallback para template determinístico).

### 2. Pipeline do Orquestrador com Injeção Explícita e Schemas Zod
- O `orquestrador` é estruturado como uma pipeline pura em estágios que recebe suas portas por parâmetro (`{ repo, llm, whatsapp, agora }`).
- Todo conteúdo enviado pelo usuário é isolado dentro da tag `<mensagem_usuario>` e tratado como dado.
- Toda chamada de LLM é validada contra o schema Zod da respectiva skill (`supabase/functions/_shared/schemas/<skill>.ts`). Em caso de falha de schema, o adaptador realiza até **2 retentativas** passando o erro de validação antes de acionar o template de fallback.
- Toda chamada (sucesso ou falha) é registrada na tabela `llm_chamada` com versão da skill, modelo, tokens, latência e status de validação.

### 3. Provedor e Modelos de LLM (`LlmClient`)
A implementação padrão `GeminiLlmClient` utiliza a família **Google Gemini**:
- **Classificação, Extração e Visão (`roteador-intencao`, `registrar-peso`, `registrar-refeicao`):** `gemini-2.5-flash` (temperatura `0.0`–`0.1`, *Structured Outputs* nativo + validação Zod).
- **Redação sobre Fatos (`relatorio-semanal`, `resumo-pos-treino`):** `gemini-2.5-pro` (com fallback automático para `gemini-2.5-flash` se atingir limite de latência/custo).
- **Embeddings para RAG (`alimento.embedding`):** `text-embedding-004` com dimensão fixada em **`vector(768)`** no Postgres (`pgvector`).

### 4. Runtime TypeScript Unificado em Deno (`supabase/` e `evals/`)
- Tanto `supabase/functions/` quanto o runner de avaliação em `evals/` executam sobre **Deno**.
- Isso permite que `evals/` importe diretamente os schemas Zod, os checadores de propriedades (`evals/checadores.ts`), os prompts de `skills/<nome>/SKILL.md` e o `LlmClient` de `supabase/functions/_shared/` sem duplicação de código ou conflito de *bundlers*.
- Um `package.json` e um `Makefile` na raiz expõem os scripts padronizados (`npm run evals`, `npm run evals -- --skill <nome>`).

## Consequências

- **Positivas:**
  - Risco zero de números alucinados em cálculos nutricionais ou relatórios.
  - Custo operacional muito baixo (amplamente dentro da meta de US$ 10/mês do RNF-10) graças ao uso de `gemini-2.5-flash` nas tarefas de alta frequência e *progressive disclosure* (carregando apenas o `SKILL.md` da intenção detectada).
  - Mesma pilha de tipos e validação Zod compartilhada entre produção e CI de evals.
- **Negativas / Trade-offs:**
  - Mudar para um modelo de embedding com dimensão diferente de 768 no futuro exigirá migration e reindexação da tabela `alimento` (mitigado pelo fato de a base TACO ter ~600 itens, reindexável em segundos).

