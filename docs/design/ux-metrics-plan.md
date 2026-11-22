# Plano de Métricas UX — LIFTR (Capítulo 31)

Este documento define a taxonomia mínima de eventos de UX e métricas operacionais do **LIFTR** para medir atrito durante o treino na academia, sem violar a privacidade do usuário ou degradar o fluxo offline-first.

---

## 1. Princípios de Medição
1. **Privacidade estrita:** Nunca enviar dados pessoais identificáveis (e-mail, nome livre, fotos corporais, anotações pessoais livres) para SDKs de terceiros.
2. **Offline-first sem bloqueio:** Registrar métricas apenas de forma assíncrona e em lote no Supabase/telemetria própria; falhas de rede nunca bloqueiam gravações locais no SQLite/Drift.
3. **Orientado à ação:** Todo evento existe para responder a uma hipótese objetiva de usabilidade no ambiente real de academia (uma mão ocupada, tela molhada, luz forte ou conexão instável).

---

## 2. Taxonomia de Eventos

| Evento | Trigger | Propriedades Permitidas | Pergunta / Hipótese |
| --- | --- | --- | --- |
| `session_started` | Início de sessão de treino | `source` (`today_banner`, `training_queue`, `workout_detail`), `exercise_count`, `offline` | Qual ponto de entrada inicia a maior parte das sessões? |
| `first_set_logged` | Primeira série marcada como concluída na sessão | `seconds_from_session_start`, `offline` | O atleta registra a primeira série em `< 90s` após abrir o app? |
| `rest_timer_paused` | Toque em **Pausar descanso** | `remaining_seconds`, `step_seconds` | Com que frequência o aparelho/equipamento ocupado exige pausa do cronômetro? |
| `rest_timer_adjusted` | Toque em `-15s` ou `+15s` | `delta_seconds`, `status` (`running`, `paused`) | O padrão global de `180s` atende a maioria das séries ou precisa ajuste por categoria? |
| `rest_timer_skipped` | Toque em **Pular** | `remaining_seconds`, `elapsed_ratio` | Usuários pulam descanso cedo demais em isoladores? |
| `set_edited_after_log` | Correção de carga/reps ou remoção logo após concluir | `field` (`weight`, `reps`, `rir`, `type`, `delete`), `seconds_since_log` | `_TactileStepper` / drop-sets têm erro de toque em telas pequenas? |
| `offline_queue_synced` | Flush bem-sucedido da outbox offline | `queued_ops`, `duration_ms`, `failed_attempts` | Quantas sessões dependem de recuperação offline na academia? |
| `progression_suggestion_applied` | Série registrada mantendo carga sugerida pelo motor | `progression_type` (`increase`, `maintain`, `decrease`), `applied` (`true`/`false`) | Qual a taxa de adoção das recomendações de dupla progressão? |

---

## 3. KPIs e Limiares de Saúde

| Métrica | Meta / Alvo | Sinal de Alerta |
| --- | --- | --- |
| **Time-to-First-Set** (mediana) | `<= 60s` após abrir sessão | `> 120s` (fricção na seleção/expansão do card) |
| **Taxa de edição pós-registro (`< 15s`)** | `< 8%` das séries | `> 15%` (alvos pequenos ou incremento incorreto) |
| **Confiabilidade da Outbox Offline** | `>= 99.5%` de entregas sem perda | Qualquer erro silencioso ou duplicação |
| **Adoção de Subida de Carga (`increase`)** | `>= 70%` | `< 45%` (sugestão agressiva ou pouco visível na série) |
| **Conclusão natural vs Pulo do Timer** | Mediana de conclusão `>= 60%` do tempo | `> 75%` pulados antes de `50%` |

---

## 4. Roadmap de Instrumentação

1. **Estágio A — Log local em tabela leve (Drift / analytics queue):** Armazenar eventos agregáveis sem bloquear UI nem exigir dependências pesadas.
2. **Estágio B — Flush oportunista no `syncPendingOperations`:** Enviar lote junto ao sync de sessão autenticada quando houver conectividade.
3. **Estágio C — Painel de retenção e regressão visual:** Cruzar `set_edited_after_log` com largura de viewport para detectar regressões de layout em futuras versões.
