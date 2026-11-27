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
- **Fase 3 — Formulários, Erros & Auth PKCE:** Tradutor `userFacingMessage` PT-BR + `appErrorLogger`; nota de segurança offline (`"Seus treinos continuam salvos neste aparelho."`) restrita a falhas remotas com persistência local garantida; preservação de descansos personalizados no template (`100s`); parsing numérico PT-BR tratando `.` sempre como separador decimal com validação inline de faixa; fluxo completo de reset de senha PKCE (`ResetPasswordScreen`, `liftr://reset-password`) e `emailRedirectTo: liftr://auth-callback` no `signUp` com orientação de mesmo dispositivo.
- **Fase 4 — Padronização de Sheets, Diálogos & Listas:** Migração completa para `showLiftrSheet` (`20` sheets), `showLiftrConfirmDialog` e `LiftrListGroup`, tratamento explícito de teclado/SafeArea sem duplicação de padding e goldens `375dp` para 5 sheets migrados (`a44639a`).
- **Fase 5 — Responsividade, Layout & Plataforma:** Uso de `LayoutBuilder` sem heurísticas por `textScaler`/largura fixa (`OnboardingScreen`, `ConfigureSetsScreen`), `ResponsiveContainer`, cobertura de `SafeArea`, scroll horizontal + `Semantics` completo no gráfico de 7 dias em `2.0x`, e ocultação do atualizador fora do Android.
- **Fase 6 — Fluxos Destrutivos, Offline & Robustez:** Confirmação destrutiva em cardio, avatar, séries e troca de programa; ativação atômica de preset no `SwitchProgramSheet` com rollback e log; avatar lido exclusivamente de `auth.userMetadata` com limpeza antes da remoção no Storage; filtro muscular estrito pelo músculo primário (`Ombros`); trava de orientação retrato (iOS iPhone-only via `TARGETED_DEVICE_FAMILY = "1"`; Android trava também tablets); pull-to-refresh com `AlwaysScrollableScrollPhysics`, preservação de cache e `userFacingMessage`.
- **Fase 7 — Visualização, A11y Avançada & Pesagem:** `Tooltip` em todos os `IconButton`; semântica completa multi-sessão no heatmap; desacoplamento de gráficos (`ChartPoint` / `ChartSeries`); contraste WCAG AA para séries 1RM/info (`colors.info`); progresso real em `TodayExercisePreviewCard`; upsert diário de pesagem no onboarding (não bloqueante) e na edição de `Dados corporais` (apenas quando o peso muda, calculado no fuso local) + CTA no estado vazio da aba `Progresso → Peso`.
- **Fase 8 — Polimento Visual, Copy PT-BR & Performance:** Padronização de headers em sentence case e componente único `LiftrEyebrow`; glossário PT-BR, pluralização e remoção de vazamentos técnicos/vendor; eliminação de I/O síncrono no `build`, `cacheWidth`/`cacheHeight`, hoisting de `DateFormat` e virtualização de listas.
- **Ajustes Finais:** Ocultação da seção WhatsApp Coach sem fonte backend sincronizada nas Configurações (`5667cb0`), guarda em release para ocultar `"Simular modo offline"` (`97b072d`), log de falhas de `upsert` em `user_profiles` via `appErrorLogger` (`6bcb83a`), trava em `build.gradle.kts` exigindo assinatura release sem fallback para `debug` (`a308088`), e consolidação documental + inventário de `catch (_)` em `docs/design/`.

---

## 2. Verificação Automatizada

Executada sobre o código Dart final de `app/` (`6bcb83a`) e build Android (`a308088`):

- `flutter analyze --no-fatal-infos --no-fatal-warnings`: aprovado sem erros ou warnings; zero issues nos arquivos alterados em `6bcb83a`.
- `flutter test`: `+488: All tests passed!` (incluindo baseline dark/light `375dp`, sheets migrados, `Peso` e gráficos da Fase 7, guarda release de `"Simular modo offline"`, log de upsert de perfil e verificações da Fase 8).
- Gradle offline (`app/android/app/build.gradle.kts`): `./gradlew :app:assembleRelease --offline` assina normalmente com `app/android/key.properties` (`CN=LIFTR`, `SHA-256: db7f763c...`) e falha explicitamente com `GradleException` quando as credenciais release estão ausentes (`ANDROID_KEYSTORE_PATH` inexistente); compatibilidade com `.github/workflows/release-apk.yml` verificada por leitura do workflow.

---

## 3. Riscos Conhecidos

1. **Assinatura Android & Backup Offline da Keystore:** `app/android/app/build.gradle.kts` agora bloqueia builds release sem credenciais (`a308088`), mas a keystore atual (`CN=LIFTR`, `SHA-256: db7f763cb8ac32a16e78b05252f03e3b10f006e5d6e598216551a7a24412ffb3`) precisa ser preservada na migração para o Play App Signing e ter **backup offline seguro de arquivo + senhas fora do GitHub** (Secrets do Actions não podem ser lidos de volta — [Seção 12](technical-debt.md#L135)).
2. **Possível perda total de sincronização de perfil (`height_cm` em `user_profiles`):** `ProfileRemoteDataSource.saveProfile` envia `height_cm` no `upsert` único de `public.user_profiles`, porém essa coluna não consta nas migrações versionadas (`20261121000004_post_first_use_fixes.sql`). Se confirmado no banco real via `information_schema.columns`, **nenhum dado de perfil foi sincronizado com `public.user_profiles`** — não apenas a altura ([Seção 13](technical-debt.md#L153); erro agora logado em `6bcb83a`).
3. **Esquemas paralelos App vs WhatsApp (`user_profiles`/`weight_entries` vs `perfil`/`pesagem`):** A aba `Progresso → Peso` do app não exibe pesagens enviadas pelo bot do WhatsApp, e os perfis dos dois canais divergem; a migração de unicidade diária em `weight_entries` está **bloqueada até a decisão de unificação** ([Seção 10](technical-debt.md#L70) e [Seção 11](technical-debt.md#L108)).
4. **Orientação retrato em tablets Android:** A trava de retrato no `AndroidManifest.xml` (`android:screenOrientation="portrait"`) e em `main.dart` aplica-se também a tablets Android (no iOS o alvo é iPhone-only).
5. **Deep links no GoRouter & estado PKCE:** `flutter_deeplinking_enabled = false` / `FlutterDeepLinkingEnabled = false` exige listener `app_links` explícito para novos deep links de negócio ([Seção 5](technical-debt.md#L27)); estado de recuperação PKCE em memória exige novo link se o app for fechado antes de salvar a senha ([Seção 4](technical-debt.md#L22)).
6. **Telemetria em release & dívida de tratamento de exceções (`catch (_)`):** `appErrorLogger` grava apenas localmente via `dart:developer` sem Sentry/Crashlytics ([Seção 3](technical-debt.md#L16)); o inventário completo em `data/**` e `providers/**` levantou **14 `catch (_)` / blocos vazios suspeitos** (incluindo parse da outbox em `session_local_datasource.dart` e `deleteStandaloneCardio`) pendentes para sprint de confiabilidade ([Seção 14](technical-debt.md#L173)), além da modularização de `logged_set_row.dart` e `TapRegion` ([Seções 1–2](technical-debt.md#L5)).

---

## 4. Bloqueadores de Publicação (Impeditivos para Lojas)

> Esta branch resolve UX/UI e robustez do frontend, **mas o app ainda não pode ser submetido à App Store / Google Play** antes de resolver os bloqueadores abaixo (ver [`docs/design/technical-debt.md`](technical-debt.md#L37)):

1. **Exclusão de conta ausente no app e sem URL web pública:** Exigência obrigatória da Apple (Guideline `5.1.1(v)`) e do Google Play Data Safety ([Seção 6](technical-debt.md#L37)).
2. **Atualizador próprio de APK / sideload (`REQUEST_INSTALL_PACKAGES`):** Proibido para distribuição na Google Play Store; requer flavor/`--dart-define` dedicado desativando o autoatualizador e adoção da Google Play In-App Updates API nas builds de loja ([Seção 7](technical-debt.md#L46)).

---

## 5. Ações Manuais Obrigatórias Antes do Teste em Aparelho

Antes de rodar o QA em Android/iPhone, cadastrar no painel do **Supabase** (**Authentication → URL Configuration → Redirect URLs**):

- `liftr://reset-password`
- `liftr://auth-callback`

Antes da migração de `height_cm`, verificar o esquema real no SQL Editor (`select column_name from information_schema.columns where table_schema='public' and table_name='user_profiles';`). Para pré-release nas lojas: publicar Política de Privacidade cobrindo **envio de dados ao Google (Gemini API)** na geração com IA e **tratamento de dados sensíveis de saúde pela LGPD**, publicar URL web de exclusão de conta/dados, manter **backup offline fora do GitHub** da keystore atual (`SHA-256: db7f763c...`) + senhas, e configurar signing iOS no App Store Connect (detalhes em [`docs/design/frontend-audit-summary.md`](frontend-audit-summary.md#L131)).

---

## 6. Roteiro de Teste Manual

- Executar todos os cenários descritos na **Seção 5 (Roteiro de Teste Manual em Aparelho Físico — Android & iPhone)** de [`docs/design/frontend-audit-summary.md`](frontend-audit-summary.md#L72) (`docs/design/frontend-audit-summary.md`), incluindo fluxos de auth/deep links (cold start e background), sessão com leitor de tela, edição inválida, séries/drop-set compactos, Desfazer online/offline, fonte máxima do sistema em celular pequeno, sheets com teclado, decimais PT-BR, pesagem diária, troca de programa com rollback, atualizador APK Android (sideload) e checklist complementar.
