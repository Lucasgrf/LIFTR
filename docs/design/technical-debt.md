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
- **Impacto adicional:** Essa UI também é a saída manual para o usuário remover eventuais planos órfãos/incompletos caso uma falha de rollback em `SwitchProgramSheet` impeça a exclusão automática (`deleteTrainingPlan`).
- **Ação futura:** Expor a opção de excluir plano (por exemplo em `TrainingPlanDetailScreen` e/ou `SwitchProgramSheet`), protegida por `showLiftrConfirmDialog(..., isDestructive: true)` e tratando a reativação de outro plano caso o plano ativo seja excluído.

## 9. [Backlog — Integração Backend] Seção WhatsApp Coach oculta nas Configurações

- **Contexto:** O backend WhatsApp (Deno) mantém `public.perfil` (`whatsapp_numero`, `horario_relatorio`, `silencio_inicio`, `silencio_fim`), enquanto o aplicativo Flutter lê e persiste hoje `public.user_profiles` + `SharedPreferences` local e ainda não possui fluxo real de vinculação/OTP nem sincronização desses campos.
- **Decisão nesta branch:** A seção **WhatsApp** foi ocultada em `Configurações` (`SettingsScreen`) para evitar exibir um estado enganoso (`"Não conectado"` ou horários locais não sincronizados) para usuários que já utilizam o bot no WhatsApp.
- **Ação futura:** Conectar o app à tabela/endpoint autoritativo do vínculo WhatsApp (lendo `whatsapp_numero` mascarado e preferências de `perfil`/RPC dedicada) e implementar fluxo real de vinculação/verificação antes de reexibir a seção em `SettingsScreen`.

## 10. [Prioridade Alta — Banco de Dados] Esquemas paralelos entre App Flutter e Bot WhatsApp (`user_profiles` / `weight_entries` vs `perfil` / `pesagem`)

- **Contexto e consequência:** O aplicativo Flutter lê e grava em `public.user_profiles` (`20261121000004_post_first_use_fixes.sql`) e `public.weight_entries` (`20261121000001_flutter_app_schema.sql`), enquanto o backend/bot do WhatsApp (Deno, `supabase/functions/_shared/repo/supabase_repo.ts`) utiliza `public.perfil` e `public.pesagem` (`20261103000001_schema_inicial.sql`), tabela que já possui `origem text not null default 'whatsapp' check (origem in ('app', 'whatsapp', 'foto'))`. Como consequência direta, **a aba Peso no app não exibe pesagens registradas via WhatsApp**, e os dados cadastrais/fisiológicos dos dois canais divergem silenciosamente.
- **Sobreposição de colunas (verificada via migrações SQL e datasources):**
  - **`public.user_profiles` vs `public.perfil`:**
    - `id` ↔ `usuario_id` (ambos `uuid PK` referenciando `auth.users(id)`)
    - `biological_sex` (`text`, sem `CHECK`; app envia em inglês) ↔ `sexo` (`text check (in ('masculino', 'feminino'))`)
    - `age` (`integer`) ↔ `nascimento` (`date` — divergência de modelo)
    - `height_cm` (**nota de esquema:** `ProfileRemoteDataSource` tenta ler/gravar `height_cm` em `user_profiles` dentro de `try/catch` best-effort, porém `20261121000004_post_first_use_fixes.sql` não declara essa coluna) ↔ `altura_cm` (`numeric(5,1) check (between 100 and 250)`)
    - `body_fat_percent` (`numeric(4,1)`) ↔ `percentual_gordura` (`numeric(4,1) check (between 3 and 70)`)
    - `goal` (`bulking | cutting | maintenance`) ↔ `objetivo` (`bulking | cutting | manutencao`)
    - `experience` (`beginner | intermediate | advanced`) ↔ `experiencia` (`iniciante | intermediario` — sem `avancado` no `CHECK`)
    - `activity_level` (`sedentary | lightlyActive | moderatelyActive | veryActive`) ↔ `atividade` (`sedentario | leve | moderado | alto`)
    - `created_at` ↔ `criado_em`
    - *Exclusivas de `user_profiles`:* `display_name`, `avatar_url`, `avatar_storage_path`, `weight_kg`, `updated_at`.
    - *Exclusivas de `perfil`:* `fuso`, `whatsapp_numero` (`unique`), `horario_relatorio`, `silencio_inicio`, `silencio_fim`, `sinal_transtorno_alimentar`.
  - **`public.weight_entries` vs `public.pesagem`:**
    - `id` ↔ `id` (`uuid PK`)
    - `user_id` ↔ `usuario_id` (`uuid not null default auth.uid()`)
    - `weight` (`numeric(5,2)`, sem `CHECK` no SQL; app valida `20–400 kg`) ↔ `peso_kg` (`numeric(5,2) check (between 30 and 300)`)
    - `measured_at` (`timestamptz`) ↔ `data` (`date` — divergência de granularidade temporal)
    - `created_at` ↔ `criado_em` (`timestamptz`)
    - *Exclusiva de `weight_entries`:* `notes` (`text`).
    - *Exclusiva de `pesagem`:* `origem` (`'app' | 'whatsapp' | 'foto'`).
    - Nenhuma das duas tabelas possui `UNIQUE` por usuário/dia hoje (ambas têm apenas índices não-únicos: `idx_weight_entries_user_date` e `pesagem_usuario_data_idx`).
- **Situação de dados (consulta apenas de esquema/código, sem acesso ao banco de produção):**
  - `supabase/seed/seed.sql` popula apenas catálogos globais (`equipamento`, `exercicio`, `alimento`, `medida_caseira`), sem inserir linhas em nenhuma das 4 tabelas.
  - Pelo código ativo, o app Flutter escreve em `user_profiles` e `weight_entries`, enquanto `supabase_repo.ts` consulta/atualiza `perfil` e consulta `pesagem` (embora o contrato da tabela e `skills/registrar-peso/SKILL.md` já existam, ainda não há `insert` em `pesagem` nas Edge Functions atuais). Antes de escolher/executar a migração, executar consulta de contagem de linhas e interseção de usuários (`perfil`/`user_profiles` e `pesagem`/`weight_entries`) no ambiente alvo.
- **Opções de unificação:**
  - **Opção 1 — Adotar `perfil` e `pesagem` como fonte única (migrando o app Flutter):**
    - Estender `perfil` com as colunas de UI (`display_name`, `avatar_url`, `avatar_storage_path`, `updated_at`) e alinhar `experiencia`/`age` vs `nascimento`; estender `pesagem` com `notes`, opcionalmente `measured_at`, revisar o `CHECK` de faixa (`30..300` vs `20..400`) e aplicar `UNIQUE (usuario_id, data)`. Fazer backfill de `user_profiles`/`weight_entries` (`origem = 'app'`), apontar os datasources do Flutter para `perfil`/`pesagem` com tradução de enums e aposentar as tabelas paralelas após janela de transição.
    - *Prós:* fonte única de verdade sem sincronização dupla; aproveita `origem ('app' | 'whatsapp' | 'foto')` e `fuso`; aba Peso passa a exibir pesagens do WhatsApp/foto nativamente; simplifica a futura seção WhatsApp Coach e a Edge Function de exclusão de conta.
    - *Contras:* exige alteração nos datasources/DTOs do Flutter, mapeamento de enums PT-BR ↔ EN, decisão de modelo entre `age` e `nascimento` e período de transição para não quebrar builds antigas já instaladas.
  - **Opção 2 — View unificada ou sincronização (triggers / Edge Function) mantendo os dois pares:**
    - Manter `user_profiles`/`weight_entries` para o app e `perfil`/`pesagem` para o bot, usando uma `VIEW` (`UNION ALL`/`JOIN`) para leitura na aba Peso ou triggers bidirecionais sincronizando escritas entre as tabelas.
    - *Prós:* preserva compatibilidade imediata com builds antigas do app sem alterar o bot nesta etapa; permite adoção incremental apenas de leitura via `VIEW`.
    - *Contras:* uma `VIEW` sozinha não resolve deduplicação diária nem edição pelo app de uma pesagem vinda do WhatsApp; triggers bidirecionais entre esquemas com enums, granularidades (`timestamptz` vs `date`, `age` vs `nascimento`) e `CHECK`s distintos são frágeis, sujeitos a loops/conflitos e mantêm o custo permanente de dois esquemas.

## 11. [Backlog — Banco de Dados — NÃO APLICAR ANTES DA DECISÃO DE UNIFICAÇÃO] Unicidade atômica de `weight_entries` e política com pesagem do WhatsApp

- **Aviso obrigatório:** **NÃO aplicar esta migração antes da decisão de unificação da Seção 10.** Caso a Opção 1 (`pesagem` como fonte única) seja escolhida, a restrição `UNIQUE (usuario_id, data)` deve ser aplicada diretamente em `public.pesagem` e não em `public.weight_entries`.
- **Contexto:** Hoje o aplicativo Flutter grava e lê pesagens em `public.weight_entries` (apenas índice não-único `idx_weight_entries_user_date`), usando read-then-write (`fetchWeightEntriesInRange` no dia civil local + `update`/`insert`), enquanto o backend WhatsApp (Deno) grava em `public.pesagem` (`usuario_id, data, peso_kg, origem`). Por isso, hoje uma edição de peso no perfil não sobrescreve registros de `pesagem`, mas ainda não há garantia atômica contra duplicatas concorrentes em `weight_entries` (ex.: dois dispositivos).
- **Migração SQL proposta (NÃO aplicada nesta branch — revisar antes de executar em produção):**
  ```sql
  -- 1. Adicionar coluna de data local e origem na tabela weight_entries
  alter table public.weight_entries
    add column if not exists measured_date date,
    add column if not exists source text not null default 'app'
      check (source in ('app', 'whatsapp'));

  -- 2. Backfill no fuso do usuário (ou America/Sao_Paulo como fallback)
  update public.weight_entries
  set measured_date = (measured_at at time zone 'America/Sao_Paulo')::date
  where measured_date is null;

  alter table public.weight_entries
    alter column measured_date set not null;

  -- 3. Restrição única atômica (1 pesagem por usuário por dia civil)
  alter table public.weight_entries
    add constraint weight_entries_user_date_unique
    unique (user_id, measured_date);
  ```
- **Decisão pendente ao unificar WhatsApp + App:** definir na cláusula `ON CONFLICT (user_id, measured_date) DO UPDATE` se uma edição manual em `Perfil → Dados corporais` pode atualizar pesagem já vinda do WhatsApp no mesmo dia ou se `source = 'whatsapp'` tem precedência quando mais recente.

## 12. [Prioridade Máxima — Release Android] Fallback silencioso para chave de debug em builds release

- **Chave atual verificada no GitHub Releases (`v0.1.0-build.112`, `liftr-arm64-release.apk`, 2026-11-24):**
  - Verificada com `apksigner verify --verbose --print-certs`:
    - Esquema: `APK Signature Scheme v2` (`v1: false`, `v2: true`)
    - `DN`: `CN=LIFTR, OU=Mobile, O=LIFTR, L=Sao Paulo, ST=SP, C=BR`
    - `SHA-256`: `db7f763cb8ac32a16e78b05252f03e3b10f006e5d6e598216551a7a24412ffb3`
    - `SHA-1`: `5cd3fe57da39f666e5a1577f8881fe12ce5a24ee`
    - `MD5`: `0c524842e3fd3f1a089a0d90627b6e62`
    - Chave: `RSA 2048 bits`
  - Ou seja, as releases geradas pelo CI (`.github/workflows/release-apk.yml`, que define `REQUIRE_RELEASE_SIGNING=true` e decodifica `ANDROID_KEYSTORE_BASE64`) **já são assinadas com keystore dedicada de produção** (não debug).
- **Bug / Risco crítico em `app/android/app/build.gradle.kts` (linhas 52–77):**
  - Quando `REQUIRE_RELEASE_SIGNING` não é `"true"` e `app/android/key.properties` / variáveis `ANDROID_KEYSTORE_*` estão ausentes (ex.: build local `flutter build apk --release`), `buildTypes.release` faz **fallback silencioso para `signingConfigs.getByName("debug")`**.
  - **Impacto:** Trocar a chave de assinatura (seja por fallback acidental para debug, seja ao gerar nova keystore ao publicar na Play Store) **quebra a atualização de todos os usuários atuais** (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`), exigindo desinstalação manual (com risco de perda de sessões/outbox locais ainda não sincronizadas). A keystore atual (`SHA-256: db7f763c...`) precisa ser preservada e reutilizada/importada no Google Play App Signing.
- **Mudança proposta em `app/android/app/build.gradle.kts` (NÃO aplicada nesta branch):**
  ```kotlin
  val isReleaseTaskRequested = gradle.startParameter.taskNames.any {
      it.contains("Release", ignoreCase = true)
  }
  if (isReleaseTaskRequested && !hasReleaseSigning) {
      throw GradleException(
          "Release signing credentials are missing. Configure app/android/key.properties " +
              "or ANDROID_KEYSTORE_PATH/PASSWORD/ALIAS/KEY_PASSWORD env vars.",
      )
  }

  buildTypes {
      release {
          if (hasReleaseSigning) {
              signingConfig = signingConfigs.getByName("release")
          }
      }
  }
  ```

## 13. [Prioridade Alta — Bug de Perda de Dados] Coluna `height_cm` ausente em `user_profiles` quebra o upsert remoto de perfil

- **Persistência verificada no código (independente da unificação da Seção 10):**
  - **Local (`SharedPreferences`):** `heightCm` é persistido localmente em `UserSettings` (`app/lib/features/settings/presentation/providers/settings_providers.dart`).
  - **`auth.userMetadata`:** Nunca grava `heightCm` (`ProfileRemoteDataSource.saveProfile` envia apenas `name` no auth; `fetchProfile` apenas lê `meta['heightCm']` como fallback se existir).
  - **Servidor (`public.user_profiles`):** `ProfileController.syncSettingsToRemote()` envia `heightCm: settings.heightCm` para `ProfileRemoteDataSource.saveProfile()`, que executa um único `upsert` com `'height_cm': ?heightCm` junto com `display_name`, `biological_sex`, `age`, `weight_kg`, `body_fat_percent`, `goal`, `experience` e `activity_level`. Porém, `20261121000004_post_first_use_fixes.sql` (e demais migrações em `supabase/migrations/`) **não declara a coluna `height_cm` em `public.user_profiles`**.
- **Impacto (perda silenciosa de dados):** Em bancos provisionados pelas migrações versionadas, o PostgREST rejeita **todo o `upsert`** (`PGRST204` — coluna desconhecida `height_cm`), e o `catch (_)` em `app/lib/features/profile/data/datasources/profile_remote_datasource.dart` engole a exceção sem logar. Como consequência, a altura **e todos os demais dados corporais/perfil** desse upsert não chegam ao servidor e são perdidos ao trocar de aparelho ou reinstalar o app.
- **Migração SQL proposta (NÃO aplicada nesta branch):**
  ```sql
  alter table public.user_profiles
    add column if not exists height_cm integer
    check (height_cm between 100 and 250);
  ```
- **Correção complementar futura no app:** substituir o `catch (_)` silencioso em `ProfileRemoteDataSource.saveProfile` por registro via `appErrorLogger` para expor erros de schema drift em `upsert`.
