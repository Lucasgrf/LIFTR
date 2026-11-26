# Dívida Técnica — Frontend LIFTR

Registro de dívidas técnicas identificadas durante a execução da auditoria de frontend, mantidas intencionalmente fora do escopo atual para execução dedicada após as fases planejadas.

## 1. Substituir `GestureDetector` com `onTap` vazio por `TapRegion` / `onTapOutside`

- **Contexto:** Na sessão de treino (`WorkoutSessionScreen`, `SessionExerciseCard`, `RestTimerWidget` e `LoggedSetRow`), o recolhimento de uma série expandida manualmente ao tocar fora usa `GestureDetector` (`HitTestBehavior.translucent` / `HitTestBehavior.opaque` com `onTap: () {}`) para interceptar ou absorver eventos de toque na árvore do `Stack`.
- **Problema:** Interceptadores no-op dependem da ordem no `Stack` e de `HitTestBehavior` explícito para evitar que toques no `RestTimerWidget` ou no padding da linha expandida acionem `collapseSignal`.
- **Ação futura:** Substituir os `GestureDetector` com `onTap: () {}` por `TapRegion` / `onTapOutside` com um `groupId` compartilhado entre a área da série expandida e o `RestTimerWidget`.

## 2. Modularizar `logged_set_row.dart` (~2.2k linhas)

- **Contexto:** `app/lib/features/workout_session/presentation/widgets/logged_set_row.dart` concentra hoje o modo compacto, o modo expandido (com drop-set e cardio), o stepper tátil e o diálogo numérico.
- **Ação futura:** Dividir `logged_set_row.dart` em widgets dedicados e coesos (`compact`, `expanded` e `numeric_dialog`) em uma tarefa exclusiva de refatoração estrutural sem alteração visual, protegida pelos testes e goldens existentes (`baseline_goldens_test.dart`).

## 3. [Prioridade Alta] Erros em produção não são registrados remotamente (`appErrorLogger`)

- **Contexto:** Hoje o projeto não possui SDK de crash reporting configurado (Sentry ou Firebase Crashlytics ausentes do `pubspec.yaml` e de `app/lib/**`), e `appErrorLogger` em `app/lib/core/errors/user_facing_message.dart` grava apenas via `dart:developer` `log()`.
- **Impacto:** Exceções capturadas e traduzidas para o usuário em builds `release` não são enviadas para um coletor remoto de telemetria.
- **Ação futura:** Integrar um SDK de crash reporting (Sentry ou Crashlytics) e conectar `appErrorLogger` ao SDK em modo `kReleaseMode` em uma tarefa dedicada de observabilidade.

## 4. Decisão arquitetural: estado de recuperação de senha não é persistido após fechamento do app

- **Contexto:** `passwordRecoveryPendingProvider` em `app/lib/routing/app_router.dart` é mantido apenas em memória enquanto a sessão de recuperação emitida por `AuthChangeEvent.passwordRecovery` está ativa no fluxo PKCE.
- **Comportamento intencional:** Se o usuário fechar o app antes de concluir a definição da nova senha em `ResetPasswordScreen`, ao reabrir ele voltará ao fluxo normal (`/login`) e poderá solicitar um novo link via `"Esqueci minha senha"`.

## 5. Deep links de negócio desabilitados no GoRouter (`flutter_deeplinking_enabled = false`)

- **Contexto:** Tanto `app/android/app/src/main/AndroidManifest.xml` (`flutter_deeplinking_enabled = false`) quanto `app/ios/Runner/Info.plist` (`FlutterDeepLinkingEnabled = false`) desativam o tratamento automático de deep links pelo GoRouter no aplicativo inteiro para evitar conflito com os callbacks PKCE do `supabase_flutter` (`liftr://reset-password` e `liftr://auth-callback`).
- **Impacto:** O GoRouter não intercepta nem navega automaticamente quando URLs externas (`liftr://...` ou App/Universal Links HTTPS) abrem o app — somente o SDK Supabase Auth consome esses links hoje.
- **Como novos links devem ser tratados no futuro:**
  1. Manter as flags `flutter_deeplinking_enabled` / `FlutterDeepLinkingEnabled` como `false` (não reativar o roteamento cego do GoRouter, para não quebrar a troca do código PKCE pelo `supabase_flutter`).
  2. Registrar um único listener de `app_links` no bootstrap do app (`getInitialLink()` + `uriLinkStream`) que **ignore explicitamente** os URIs reservados de autenticação (`liftr://reset-password` e `liftr://auth-callback`) e faça parse/validação apenas dos caminhos de negócio (ex.: `/training/import`, `/session/...`), roteando-os imperativamente via `goRouterProvider` (`router.go(...)` / `router.push(...)`).
  3. Para notificações locais ou push, rotear pelo payload estruturado ao tocar na notificação, também diretamente via `router.go(...)` / `router.push(...)`.
  4. Declarar no `AndroidManifest.xml` e no `Info.plist` / Associated Domains apenas os hosts/caminhos suportados explicitamente pelo listener.

## 6. [BLOQUEADOR DE PUBLICAÇÃO — Prioridade Máxima] Exclusão de conta ausente no aplicativo

- **Impacto / Compliance:** Bloqueia publicação na **App Store** (Apple Guideline `5.1.1(v)` — apps que permitem criação de conta devem oferecer exclusão completa da conta dentro do app) e na **Google Play** (Política de Exclusão de Dados, que exige fluxo no app **e** uma URL web pública para solicitação externa de exclusão de conta/dados).
- **Situação atual:** Não existe botão, diálogo ou backend para excluir a conta do usuário (`auth.users`) no app; `Configurações → Conta` oferece apenas `"Sair da conta"`.
- **Solução esperada (implementar antes de submissão às lojas, NÃO nesta branch):**
  1. **Backend (Edge Function `delete-account`):** autenticar o JWT do usuário logado, executar com `service_role` a remoção dos dados do usuário nas tabelas Postgres e buckets de Storage (ex.: avatar) e chamar `auth.admin.deleteUser(userId)` para apagar o registro em `auth.users`.
  2. **Frontend (`Configurações → Conta → Excluir conta`):** exigir confirmação destrutiva via `showLiftrConfirmDialog(..., isDestructive: true)` (e reautenticação recente quando aplicável), chamar a Edge Function, limpar o banco local Drift / `SharedPreferences` da conta e encerrar a sessão redirecionando para `/login`.
  3. **Portal web (Google Play):** disponibilizar URL web pública autenticada/verificável para solicitar exclusão da conta e dos dados associados sem precisar reinstalar o aplicativo, e cadastrar essa URL no Google Play Console.

## 7. [BLOQUEADOR DE PUBLICAÇÃO NO GOOGLE PLAY — Prioridade Máxima] Atualizador próprio de APK (sideload) e permissão `REQUEST_INSTALL_PACKAGES`

- **Impacto / Compliance:** Apps distribuídos pela Google Play Store **não podem baixar nem instalar binários executáveis (APKs) fora da loja**, e o uso de `REQUEST_INSTALL_PACKAGES` é restrito pela política de segurança da Play Store.
- **Como funciona hoje:**
  1. `AppUpdateService` (`app/lib/core/update/app_update_service.dart`) consulta `https://api.github.com/repos/Lucasgrf/LIFTR/releases/latest` (silenciosamente a cada 6 horas via `AppShell` -> `checkSilentlyIfDue`, e manualmente em `Configurações → Atualizações do app`), selecionando o asset `.apk` (preferindo `arm64`) e o respectivo `.sha256` em `AppUpdateInfo.tryFromGitHubReleaseJson`.
  2. `downloadAndVerifyApk` baixa o APK para `<cacheDir>/updates/liftr-build-<N>.apk`, valida o checksum SHA-256 com `package:crypto` e aciona a instalação via `MethodChannel('com.personalfitnessos.liftr/app_updater')` no `MainActivity.kt` (`canRequestPackageInstalls`, `Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES`, `FileProvider` `${applicationId}.fileprovider` e `Intent.ACTION_VIEW` com `application/vnd.android.package-archive`).
  3. `app/android/app/src/main/AndroidManifest.xml` declara `<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>`.
- **Solução esperada (NÃO implementar nesta branch):**
  1. Separar flavors de distribuição (ex.: `play` vs `direct`/`sideload`) ou flag de build (`--dart-define`).
  2. Na build `play`, omitir `REQUEST_INSTALL_PACKAGES` do manifesto e desativar `AppUpdateService`, banner de atualização e entrada de autoatualização em `SettingsScreen`.
  3. Substituir o mecanismo nas builds da loja pela **Google Play In-App Updates API**.

## 8. [Backlog — Não bloqueador] Ausência de UI para exclusão de planos de treino

- **Contexto:** `deleteTrainingPlanUseCaseProvider` (em `app/lib/features/training/presentation/providers/training_providers.dart`) e os respectivos métodos de domínio/dados existem desde o commit `27eda13`, mas nunca tiveram ponto de chamada na UI.
- **Ação futura:** Expor a opção de excluir plano (por exemplo em `TrainingPlanDetailScreen` e/ou `SwitchProgramSheet`), protegida por `showLiftrConfirmDialog(..., isDestructive: true)` e tratando a reativação de outro plano caso o plano ativo seja excluído.
