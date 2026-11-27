# PR: `feat/frontend-audit-fixes` → `main`

> **Título sugerido:** `feat(app): auditoria completa de UX/UI, acessibilidade, Auth PKCE e resiliência offline (Fases 0–8)`
> **Estratégia de merge recomendada:** **Merge sem squash (Merge Commit padrão)**.
> Os commits desta branch são atômicos por assunto e por fase (Fases 0 a 8 + ajustes finais), com atualizações de goldens pareadas às respectivas mudanças de UI. Preservar o histórico completo mantém a rastreabilidade de design/código, facilita `git bisect` e permite `git revert` pontual sem perder o contexto das fases.

---

## 1. Resumo das Mudanças por Fase

Para o consolidado completo com hashes de commit, decisões arquiteturais e itens N/A, consulte [`docs/design/frontend-audit-summary.md`](frontend-audit-summary.md).

- **Fase 0 — Limpeza & Roteamento:** Remoção de rotas órfãs, módulos mortos (metas/nutrição/calendário) e 11 widgets não utilizados; fallback de rotas desconhecidas via `GoRouter.onException` para `/`.
- **Fase 1 — Design System & Tokens:** Paleta Dark (`#0D0D0F` / `#1A1A1F` / `#72A987` com `onPrimary = #0D0D0F`) e Light (`#315B43` com `onPrimary = #F2F2F0`) em conformidade WCAG; escala `Geist` com piso `11sp` e `FontFeature.tabularFigures()`; evolução de `AppButton` / `AppInput`; `AppMotion` respeitando `MediaQuery.disableAnimationsOf`; baseline de goldens `375dp` dark/light.
- **Fase 2 — Sessão de Treino & Acessibilidade:** Extração do leaf `SessionElapsedText` (`PERF-01`); alvos mínimos `48dp` e reflow; ripples `Material + Ink`; picker inline de exercício; `PopScope` em sessão ativa; densidade por estado em `LoggedSetRow`; correção de concorrência undo/restore vs outbox e diálogo de saída/descarte de edição inválida.
- **Fase 3 — Formulários, Erros & Auth PKCE:** Tradutor `userFacingMessage` PT-BR + `appErrorLogger`; nota de segurança offline restrita a falhas remotas com persistência local garantida; preservação de descansos personalizados no template; parsing numérico PT-BR tratando `.` sempre como separador decimal com validação inline de faixa; fluxo completo de reset de senha PKCE (`ResetPasswordScreen`, `liftr://reset-password`) e `emailRedirectTo: liftr://auth-callback` no `signUp` com orientação de mesmo dispositivo.
- **Fase 4 — Padronização de Sheets, Diálogos & Listas:** Migração completa para `showLiftrSheet` (`20` sheets), `showLiftrConfirmDialog` e `LiftrListGroup`, tratamento explícito de teclado/SafeArea sem duplicação de padding e goldens `375dp` para 5 sheets migrados.
- **Fase 5 — Responsividade, Layout & Plataforma:** Uso de `LayoutBuilder` sem heurísticas por `textScaler`/largura fixa (`OnboardingScreen`, `ConfigureSetsScreen`), `ResponsiveContainer`, cobertura de `SafeArea`, scroll horizontal + `Semantics` completo no gráfico de 7 dias em `2.0x`, e ocultação do atualizador fora do Android.
- **Fase 6 — Fluxos Destrutivos, Offline & Robustez:** Confirmação destrutiva em cardio, avatar, séries e troca de programa; ativação atômica de preset no `SwitchProgramSheet` com rollback e log; avatar lido exclusivamente de `auth.userMetadata` com limpeza antes da remoção no Storage; filtro muscular estrito pelo músculo primário; trava de orientação retrato no celular e `TARGETED_DEVICE_FAMILY = "1"` (iPhone-only); pull-to-refresh com `AlwaysScrollableScrollPhysics`, preservação de cache e `userFacingMessage`.
- **Fase 7 — Visualização, A11y Avançada & Pesagem:** `Tooltip` em todos os `IconButton`; semântica completa multi-sessão no heatmap; desacoplamento de gráficos (`ChartPoint` / `ChartSeries`); contraste WCAG AA para séries 1RM/info (`colors.info`); progresso real em `TodayExercisePreviewCard`; upsert diário de pesagem no onboarding (não bloqueante) e na edição de `Dados corporais` (apenas quando o peso muda, calculado no fuso local) + CTA no estado vazio da aba `Peso`.
- **Fase 8 — Polimento Visual, Copy PT-BR & Performance:** Padronização de headers em sentence case e componente único `LiftrEyebrow`; glossário PT-BR, pluralização e remoção de vazamentos técnicos/vendor; eliminação de I/O síncrono no `build`, `cacheWidth`/`cacheHeight`, hoisting de `DateFormat` e virtualização de listas.
- **Ajustes Finais:** Ocultação da seção WhatsApp Coach sem fonte backend sincronizada nas Configurações e consolidação documental em `docs/design/`.

---

## 2. Verificação Automatizada

Executada sobre o código final de `app/` (`ebbb8d8`; commits subsequentes alteram apenas documentos em `docs/design/`):

- `flutter analyze --no-fatal-infos --no-fatal-warnings`: `0` novos infos introduzidos na branch (`TOTAL {'INFO': 88}`, `on branch-added lines: 0`).
- `flutter test`: `+485: All tests passed!` (incluindo baseline dark/light `375dp`, sheets migrados, `Peso` e gráficos da Fase 7, e verificações da Fase 8).

---

## 3. Riscos Conhecidos

1. **Esquemas paralelos App vs WhatsApp (`user_profiles`/`weight_entries` vs `perfil`/`pesagem`):** A aba **Peso** do app não exibe pesagens enviadas pelo bot do WhatsApp, e os perfis dos dois canais divergem; além disso, `ProfileRemoteDataSource` faz acesso best-effort à coluna `height_cm`, ainda ausente na migração SQL de `user_profiles`. A migração de unicidade diária em `weight_entries` está **bloqueada até a decisão de unificação** (ver [Seção 10](technical-debt.md#L70) e [Seção 11](technical-debt.md#L108) de `docs/design/technical-debt.md`).
2. **Deep links de negócio no GoRouter (`flutter_deeplinking_enabled = false`):** Desativado no `AndroidManifest.xml` e `Info.plist` para não competir com os callbacks PKCE do `supabase_flutter`. Novos links de negócio exigirão um listener explícito via `app_links` ([Seção 5](technical-debt.md#L27)).
3. **Estado de recuperação PKCE em memória:** Se o usuário fechar o aplicativo após abrir o link de reset antes de salvar a nova senha, será necessário solicitar um novo link ([Seção 4](technical-debt.md#L22)).
4. **Telemetria de erros em release (`appErrorLogger`):** Hoje grava apenas via `dart:developer` `log()`, sem envio remoto (Sentry/Crashlytics) ([Seção 3](technical-debt.md#L16)).
5. **Dívidas estruturais futuras na sessão:** Modularização de `logged_set_row.dart` (~2,2k linhas) e troca de `GestureDetector` vazio por `TapRegion` ([Seções 1–2](technical-debt.md#L5)).

---

## 4. Bloqueadores de Publicação (Impeditivos para Lojas)

> Esta branch resolve UX/UI e robustez do frontend, **mas o app ainda não pode ser submetido à App Store / Google Play** antes de resolver os dois bloqueadores abaixo (ver [technical-debt.md](technical-debt.md#L37)):

1. **Exclusão de conta ausente no app e sem URL web pública:** Exigência obrigatória da Apple (Guideline `5.1.1(v)`) e do Google Play Data Safety ([Seção 6](technical-debt.md#L37)).
2. **Atualizador próprio de APK / sideload (`REQUEST_INSTALL_PACKAGES`):** Proibido para distribuição na Google Play Store; requer flavor/`--dart-define` dedicado desativando o autoatualizador e adoção da Google Play In-App Updates API nas builds de loja ([Seção 7](technical-debt.md#L46)).

---

## 5. Ações Manuais Obrigatórias Antes do Teste em Aparelho

Antes de rodar o QA em Android/iPhone, cadastrar no painel do **Supabase** (**Authentication → URL Configuration → Redirect URLs**):

- `liftr://reset-password`
- `liftr://auth-callback`

As demais ações pré-release (Política de Privacidade, URL web de exclusão de conta, keystore `app/android/key.properties` e signing iOS no App Store Connect) estão detalhadas em [`docs/design/frontend-audit-summary.md`](frontend-audit-summary.md#L110).

---

## 6. Roteiro de Teste Manual

- Executar os 8 cenários críticos descritos na **Seção 5 (Roteiro de Teste Manual em Aparelho Físico — Android & iPhone)** de [`docs/design/frontend-audit-summary.md`](frontend-audit-summary.md#L70) (`docs/design/frontend-audit-summary.md`, linhas 70–106), cobrindo cadastro/confirmação, reset PKCE, sessão com TalkBack/VoiceOver, sheets com teclado, vírgula/ponto e faixas numéricas, offline/pull-to-refresh, pesagem diária e troca de programa com rollback.
