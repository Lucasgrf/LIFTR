# ADR-001: Dupla progressão no app, arquitetura Functional Core/Imperative Shell e sincronização via Transactional Outbox

- **Status:** Aceito
- **Data:** 03/11/2026
- **Contexto:** PRD §4.1, §7.1, RNF-01..05, RNF-08, RNF-12

## Contexto e Problema

O aplicativo precisa funcionar 100% offline dentro da academia (onde o sinal de rede frequentemente falha), exibir a tela **Hoje** em ≤ 1,5 s e registrar séries em ≤ 2 toques sem nunca bloquear a UI esperando rede. Além disso, o cálculo de dupla progressão e avanço da fila circular precisa estar disponível imediatamente ao finalizar o treino para comemorar subidas de carga na tela de resumo.

Precisávamos decidir:
1. Onde o motor de dupla progressão e rotação da fila deve rodar (App vs. Backend).
2. Qual estilo arquitetural e estratégia de geração de código adotar no Flutter para manter o domínio testável (cobertura ≥ 90%) sem criar boilerplate excessivo para um dev solo.
3. Como sincronizar os dados locais com o Supabase garantindo zero perda de dados e disparando o resumo pós-treino no WhatsApp quando houver conexão.

## Decisão

### 1. Estilo Arquitetural no App: *Functional Core, Imperative Shell* + *Feature-First MVVM*
- **`app/lib/domain/` (Functional Core):**
  - Escrito em **Dart 3 nativo** (`sealed class`, `final class`, `records`, *pattern matching* exaustivo).
  - **Zero dependências externas** (sem imports de Flutter, Riverpod ou Drift) e **zero geração de código** (sem `freezed` ou `json_serializable` no domínio).
  - Todas as regras de negócio (dupla progressão, elegibilidade, detecção de platô, sugestão de incremento por equipamento, avanço da fila circular e sugestão de estilo no onboarding) são funções puras e determinísticas que recebem `agora` por parâmetro e retornam `Result<T, ErroDominio>`.
- **`app/lib/data/` (Imperative Shell):**
  - O banco local **Drift (SQLite)** é a única fonte da verdade (*Single Source of Truth*) para a UI.
  - Toda tela lê *streams*/queries do Drift e escreve diretamente no Drift.
- **`app/lib/features/` (Fatias Verticais de UI):**
  - Organizado por telas/fluxos (`hoje/`, `progresso/`, `programa/`, `onboarding/`, `config/`).
  - Gerenciamento de estado com **Riverpod manual** (`Notifier` e `AsyncNotifier`), mantendo o `build_runner` restrito exclusivamente ao Drift.
- **`app/lib/shared/` (Design System, Gráficos e i18n):**
  - Tema **Material 3 Dark-first** (contraste AA, alvos de toque ≥ 48 dp), internacionalização nativa com `gen-l10n` (`.arb` em `pt-BR`), gráficos de evolução/tendência com `fl_chart` e heatmap de consistência em grid customizado leve.

### 2. Sincronização Offline-First via *Transactional Outbox*
- Todas as entidades criadas no cliente (`treino`, `serie`, `status_progressao`, edições em `programa`/`slot`) usam **UUIDs gerados no cliente**.
- Toda mutação local executa uma transação SQLite no Drift que:
  1. Atualiza/insere o registro na tabela local correspondente;
  2. Insere um evento na tabela local `outbox_operacoes` (`id`, `entidade`, `registro_id`, `operacao`, `payload_json`, `criado_em`, `tentativas`).
- Um `SyncWorker` em background consome `outbox_operacoes` em ordem FIFO quando há conectividade e realiza `upsert` idempotente no Supabase.
- Quando o evento de finalização de um `treino` é confirmado no sync, o backend aciona o envio do **resumo pós-treino** no WhatsApp (US-28).

## Consequências

- **Positivas:**
  - Testes de domínio em `app/test/domain/` rodam instantaneamente sem depender de `build_runner` ou mocks de banco.
  - A UI de treino nunca trava por oscilação de internet na academia.
  - Reenvios da outbox são seguros (idempotentes via UUID).
- **Negativas / Trade-offs:**
  - Métodos `copyWith` e igualdade no `domain/` são escritos em Dart 3 puro (mitigado pelo número enxuto de entidades de domínio).
  - Exige manutenção da tabela `outbox_operacoes` e tratamento de retentativas com *exponential backoff*.

