# Auditoria e Remediação de Frontend — LIFTR (`feat/frontend-audit-fixes`)

> **Registro histórico:** descreve a direção e as decisões vigentes na auditoria original. A referência visual atual está em [`docs/design.md`](../../docs/design.md); use este arquivo apenas para contexto das mudanças anteriores.

Este documento consolida todas as entregas, decisões arquiteturais e de UI, itens N/A, bloqueadores de publicação, dívidas técnicas e o roteiro final de verificação em aparelho físico para a branch `feat/frontend-audit-fixes`.

---

## 1. Resumo das Mudanças por Fase

| Fase | Foco Principal | Entregas & Commits Chave |
| --- | --- | --- |
| **Fase 0 — Limpeza & Roteamento** | Remoção de módulos mortos e rotas órfãs | Remoção de rotas órfãs, módulo morto de metas/nutrição/calendário e 11 widgets sem uso; fallback de rotas desconhecidas via `GoRouter.onException` para `/` (`e36f439`..`a123f62`). |
| **Fase 1 — Design System & Tokens** | Paleta, tipografia, componentes base e motion | Tokens Dark (`#0D0D0F` / `#1A1A1F` / `#72A987` com `onPrimary = #0D0D0F`) e Light (`#315B43` com `onPrimary = #F2F2F0`) em conformidade WCAG AA/AAA; escala tipográfica `Geist` com piso `11sp` e `FontFeature.tabularFigures()`; evolução de `AppButton` e `AppInput`; `AppMotion` respeitando `MediaQuery.disableAnimationsOf`; baseline de goldens `375dp` dark/light (`d044c84`..`d290020`). |
| **Fase 2 — Sessão de Treino & Acessibilidade** | Performance na sessão, alvos `48dp` e proteção contra perda | Extração do leaf widget `SessionElapsedText` (`PERF-01`); steppers `>= 48dp` com reflow responsivo; `Material` + `Ink` para ripples; picker inline de exercício; `PopScope` ao sair da sessão ativa; linhas compactas por estado em `LoggedSetRow`; correção de concorrência undo/restore vs outbox e diálogo de saída/descarte de edição inválida (`9ff79d0`..`cf91720`). |
| **Fase 3 — Formulários, Erros & Auth PKCE** | Mensagens PT-BR, decimais e fluxo completo de Auth | `userFacingMessage` PT-BR + `appErrorLogger`; escopo estrito de `kOfflineDataSafetyNote`; preservação de descansos personalizados no template; parsing numérico PT-BR tratando `.` sempre como decimal com validação de faixa inline; fluxo completo de reset de senha PKCE (`ResetPasswordScreen`, `liftr://reset-password`, `flutter_deeplinking_enabled = false`), tratamento de link expirado e `emailRedirectTo: liftr://auth-callback` no `signUp` com aviso de mesmo dispositivo (`2305ebc`..`08a07e9`). |
| **Fase 4 — Padronização de Sheets, Diálogos & Listas** | Coesão de modais, diálogos destrutivos e agrupamento | Introdução e migração completa para `showLiftrSheet` (`20` sheets), `showLiftrConfirmDialog` e `LiftrListGroup`; tratamento explícito de teclado (`viewInsets.bottom`) e `viewPadding.bottom` sem duplicação; goldens `375dp` para 5 sheets migrados (`6c68345`..`a44639a`, `dd287e2`). |
| **Fase 5 — Responsividade, Layout & Plataforma** | Breakpoints `320dp`–`412dp` @ `2.0x` e `SafeArea` | `LayoutBuilder` no `OnboardingScreen` e `ConfigureSetsScreen` sem branches por `textScaler` nem larguras mágicas; `ResponsiveContainer` padronizado; `SafeArea` nas telas principais, formulário e detalhe; substituição de `FittedBox` em texto no gráfico de 7 dias por scroll horizontal + `Semantics` completo; ocultação de atualizador fora do Android (`cd70f11`..`7c8641b`). |
| **Fase 6 — Fluxos Destrutivos, Offline & Robustez** | Segurança de estado, filtros e ciclo de vida | Confirmação em exclusões (cardio, avatar, série, troca de programa); troca de preset atômica em `SwitchProgramSheet` com rollback e log via `appErrorLogger`; remoção de avatar com limpeza prévia de `auth.userMetadata` e leitura exclusiva do auth; filtro muscular estrito pelo músculo primário; trava de orientação retrato no celular e `TARGETED_DEVICE_FAMILY = 1` (iPhone-only) no iOS; pull-to-refresh com `AlwaysScrollableScrollPhysics`, preservação de cache e `userFacingMessage` (`8c6f1e9`..`2eb5c4c`). |
| **Fase 7 — Visualização, A11y Avançada & Pesagem** | Leitor de tela, gráficos desacoplados e pesagem diária | `Tooltip` em todos os `IconButton`; semântica completa no heatmap com múltiplas sessões no mesmo dia; desacoplamento de gráficos (`ChartPoint` / `ChartSeries`); contraste WCAG AA para séries 1RM/info (`colors.info`); progresso real em `TodayExercisePreviewCard`; upsert diário de pesagem no onboarding e ao editar peso em `Dados corporais`, com CTA no estado vazio da aba `Peso` (`1de6d26`..`78a4c8f`). |
| **Fase 8 — Polimento Visual, Copy PT-BR & Performance** | Higiene tipográfica, glossário e cache/virtualização | Remoção de eyebrows redundantes e padronização em sentence case; `LiftrEyebrow` centralizando caixa alta no componente (`ebbb8d8`); glossário PT-BR, pluralização, labels de enum sem vazamentos de código/vendor (`copy_01`); remoção de I/O síncrono no `build`, `cacheWidth`/`cacheHeight` em imagens, hoisting de `DateFormat`, virtualização de listas e verificação via `phase8_polish_copy_perf_test.dart` (`22da280`..`3bdc69b`). |
| **Ajustes Finais** | Integridade WhatsApp, timezone de pesagem, release & banco | Ocultação da seção `WhatsApp Coach` sem fonte real de sincronização no app (`5667cb0`); cálculo do dia de pesagem no fuso local do aparelho (convertido para limites UTC na query), guarda de onboarding não-bloqueante e atualização condicional apenas quando o peso muda (`d6aa9f5`); widget `LiftrEyebrow` (`ebbb8d8`); ocultação de `"Simular modo offline"` em builds release (`97b072d`); trava no `build.gradle.kts` para assinatura release (`a308088`); log de `upsert` em `user_profiles` (`6bcb83a`), `display_name` nullable em produção + validação de payload (`1781bf6`) e migração reconciliando *schema drift* (`ca7c708`). |

---

## 2. Decisões Arquiteturais e de UI

1. **Auth PKCE + Isolamento de Deep Links no GoRouter:**
   - `authFlowType` é PKCE; o GoRouter mantém `flutter_deeplinking_enabled = false` (`AndroidManifest.xml` / `Info.plist`) para não interceptar `liftr://reset-password` e `liftr://auth-callback` antes do `supabase_flutter`.
   - Links de negócio futuros devem ser roteados pelo `AppLinks` listener em coordenação explícita com o estado de sessão/recuperação.
2. **Parsing Numérico PT-BR Estrito:**
   - Ponto (`.`) e vírgula (`,`) são tratados **exclusivamente como separador decimal** (`"1.000"` → `1,0`; `"2.500"` → `2,5`) para evitar ambiguidade perigosa em cargas de treino, acompanhado de validação inline de faixa (carga `0–1000 kg`, peso corporal `20–400 kg`, altura `100–250 cm`).
3. **Resiliência Offline & Nota de Segurança de Dados:**
   - `kOfflineDataSafetyNote` (`"Seus treinos continuam salvos neste aparelho."`) só aparece em erros remotos onde a persistência local/outbox realmente garantiu o registro; nunca é exibida quando a falha nasce no datasource local.
4. **Orientação & Dispositivo Alvo:**
   - No **iOS**, o alvo foi restrito a iPhone (`TARGETED_DEVICE_FAMILY = "1"`), sem suporte a iPad/orientações extras no `Info.plist`. No **Android**, `android:screenOrientation="portrait"` (combinado com `SystemChrome.setPreferredOrientations`) trava a orientação em retrato para todo o app — **incluindo tablets Android**, priorizando ergonomia unilateral durante o treino.
5. **Unidade da Fonte de Verdade do Avatar:**
   - A UI lê exclusivamente `auth.userMetadata['avatar_url']`, que é limpo antes da deleção do arquivo no Storage; falhas ao apagar o arquivo no Storage são apenas logadas para evitar o retorno fantasma da foto removida.
6. **Seção WhatsApp Coach Oculta nas Configurações:**
   - O app Flutter lê `public.user_profiles` + preferências locais, enquanto o bot WhatsApp lê `public.perfil` (`whatsapp_numero`, `horario_relatorio`, `silencio_inicio`, `silencio_fim`). Sem vínculo OTP/backend no app, exibir "Não conectado" induziria quem já usa o WhatsApp ao erro; a seção permanece oculta até existir sincronização real.
7. **Eyebrows Centralizados em `LiftrEyebrow`:**
   - Callers passam copy em *sentence case*; `LiftrEyebrow` aplica `text.toUpperCase()` sobre `AppTypography.eyebrow(context)` em um único ponto.

---

## 3. Itens N/A e Escopo Deliberadamente Adiado

- **Suporte a iPad / Tablet Landscape:** Marcado como N/A nesta versão (`TARGETED_DEVICE_FAMILY = "1"`, sem orientações paisagem em celular).
- **Novos SDKs de Crash Reporting (Sentry / Crashlytics):** Não adicionados nesta branch; `appErrorLogger` centraliza o log e aguarda integração futura.
- **UI de Exclusão de Planos de Treino:** `deleteTrainingPlanUseCaseProvider` foi mantido no domínio (e utilizado pelo rollback atômico do `SwitchProgramSheet`), mas sem UI de gerenciamento manual nesta branch.
- **Sincronização do Vínculo WhatsApp Coach & Unificação de `perfil`/`pesagem` vs `user_profiles`/`weight_entries`:** Adiado para decisão dedicada de banco/backend ([Seção 10 de technical-debt.md](technical-debt.md#L70)) por envolver enums/endpoints e fluxo OTP (auditoria em produção confirmou `perfil`/`pesagem` ainda ausentes no banco e `weight_entries` com `0` linhas).
- **Migração SQL de unicidade em `weight_entries`:** Proposta e documentada em [technical-debt.md](technical-debt.md#L112), **NÃO aplicada e bloqueada** até a decisão de unificação da Seção 10.

---

## 4. Bloqueadores de Publicação & Dívidas Técnicas

Todos os bloqueadores e pendências técnicas estão detalhados com contexto, impacto e solução esperada em [**docs/design/technical-debt.md**](technical-debt.md).

### Bloqueadores de Publicação (Impeditivos para Loja)
1. **Exclusão de Conta no Aplicativo (Apple App Store `5.1.1(v)` & Google Play Data Safety):** Não existe fluxo de exclusão de conta/dados pelo usuário nem endpoint Edge Function dedicado com `service_role`. Ver [Seção 6 de technical-debt.md](technical-debt.md#L37).
2. **Atualizador Próprio de APK / Sideload (`REQUEST_INSTALL_PACKAGES` — Google Play):** O `AppUpdateService` faz download/instalação direta de APK via GitHub Releases, proibido nas builds distribuídas pela Play Store. Necessário desativar via flavor/`--dart-define` na build de loja e migrar para Play In-App Updates API. Ver [Seção 7 de technical-debt.md](technical-debt.md#L46).

### Dívidas Técnicas e Itens de Backlog
- **Prioridade Máxima (Release Android):** Trava contra fallback para `debug` aplicada em `build.gradle.kts` (`a308088`), porém exige preservação rigorosa da chave atual (`CN=LIFTR`, `SHA-256: db7f763c...`) e **backup offline obrigatório fora do GitHub**, pois Secrets do Actions não podem ser lidos de volta ([Seção 12](technical-debt.md#L139)).
- **Alta Prioridade:** `appErrorLogger` sem envio remoto em release ([Seção 3](technical-debt.md#L16)); **esquemas paralelos App Flutter vs Bot WhatsApp** (`user_profiles`/`weight_entries` com `1`/`0` linhas em produção vs `perfil`/`pesagem` ausentes no banco real — [Seção 10](technical-debt.md#L70)).
- **Resolvidos na Branch (Banco de Dados / Perfil):** `height_cm` confirmada em produção e incompatibilidade de `user_profiles.display_name NOT NULL` corrigida em produção + testes (`1781bf6`, [Seção 13](technical-debt.md#L157)); *schema drift* entre `supabase/migrations/` e produção totalmente reconciliado em Postgres 17 e aplicado em produção (`ca7c708`, [Seção 15](technical-debt.md#L216)).
- **Auditoria de Exceções (`catch (_)` / vazios):** `41` ocorrências mapeadas em `data/**` e `providers/**` (`14 suspeitas`, incluindo leitura da outbox em `session_local_datasource.dart` e `deleteStandaloneCardio`) ([Seção 14](technical-debt.md#L168)).
- **Arquitetura & Roteamento:** Estado de recuperação PKCE não persistido após reinício do app ([Seção 4](technical-debt.md#L22)); `flutter_deeplinking_enabled = false` exigindo roteamento explícito no listener para novos links ([Seção 5](technical-debt.md#L27)).
- **Banco de Dados & Backend:** Seção WhatsApp Coach oculta por ausência de endpoint/tabela compartilhada no app ([Seção 9](technical-debt.md#L64)); falta de `UNIQUE` diário atômico em `weight_entries` — **não aplicar antes da decisão de unificação da Seção 10** ([Seção 11](technical-debt.md#L112)).
- **Manutenibilidade & UI:** Substituir `GestureDetector` vazio por `TapRegion` ([Seção 1](technical-debt.md#L5)); modularizar `logged_set_row.dart` ([Seção 2](technical-debt.md#L11)); UI dedicada para excluir planos de treino e eventual plano órfão ([Seção 8](technical-debt.md#L58)).

---

## 5. Roteiro de Teste Manual em Aparelho Físico (Android & iPhone)

> **Pré-requisito:** Build de QA configurada com os Redirect URLs ativos no projeto Supabase de teste e aparelho em orientação retrato.

1. **Cadastro, Confirmação de E-mail & Autofill (`RegisterScreen` / `LoginScreen`):**
   - Criar conta nova com e-mail válido e senha forte.
   - Confirmar exibição da tela *"Confirme seu e-mail"* com a instrução *"Abra o link neste celular"*.
   - Abrir o link (`liftr://auth-callback`) **no mesmo aparelho** em dois estados: com o app **fechado** (cold start) e com o app **em segundo plano** → validar entrada no onboarding/app autenticado.
   - Reutilizar o mesmo link depois de expirado/consumido → confirmar mensagem amigável em PT-BR sem crash.
   - Ao realizar **login** com e-mail e senha, confirmar o prompt nativo de **autofill / salvar credenciais** do Android/iOS ao concluir a autenticação.
2. **Redefinição de Senha & Deep Links (`LoginScreen` → `ResetPasswordScreen`):**
   - Tocar em *"Esqueci minha senha"*, informar e-mail e enviar → confirmar que o botão desabilita durante o envio e exibe mensagem neutra (*"Se houver uma conta com esse e-mail, enviaremos um link"*).
   - Abrir o link recebido (`liftr://reset-password`) **no mesmo aparelho** em dois estados: com o app **fechado** (cold start) e com o app **em segundo plano** → confirmar abertura da `ResetPasswordScreen`.
   - Definir nova senha, confirmar retorno ao fluxo autenticado e repetir o fluxo com link expirado validando mensagem PT-BR e caminho para solicitar novo link.
3. **Sessão de Treino & Leitor de Tela (TalkBack no Android / VoiceOver no iPhone):**
   - Iniciar um treino no fluxo principal, ativar TalkBack/VoiceOver.
   - Verificar leitura dos headers semânticos, botões steppers `+`/`-` (`>= 48dp`), troca de exercício no picker inline e cronômetro de descanso (`LiftrEyebrow` + controles).
   - Tentar voltar (`PopScope`) com séries registradas → confirmar diálogo de proteção.
4. **Séries Compactas, Drop-Set, Edição Inválida & Desfazer (Online e Offline):**
   - **Séries compactas & autosave:** concluir uma série confirmando a transição para linha compacta; tocar nela para expandir, editar carga/reps e tocar em outra série validando **autosave**; expandir outra série e **rolar a lista** confirmando que a linha expandida **não recolhe** durante a rolagem.
   - **Drop-set compacto:** adicionar drop-set em um exercício e concluir a série validando a exibição compacta legível sem overflow.
   - **Edição inválida:** editar uma série colocando `reps = 0` e tentar recolher → confirmar aviso/bloqueio de salvamento inválido; tocar em *"Descartar alterações"* e confirmar restauração do valor anterior. Repetir deixando `reps = 0` pendente e tentar finalizar/sair do treino → confirmar diálogo bloqueando/protegendo contra perda silenciosa.
   - **Desmarcar + *"Desfazer"* do SnackBar:** desmarcar uma série concluída e tocar em *"Desfazer"* no SnackBar **online**; repetir o mesmo fluxo em **Modo Avião** (offline), restaurar a conexão e aguardar a sincronização da outbox confirmando que a série permanece íntegra e sem duplicatas no servidor.
5. **Sheets com Teclado Aberto & SafeArea / Barra de Gestos:**
   - Abrir `SwapExerciseSheet` (trocar exercício na sessão) e focar o campo de busca para abrir o teclado virtual.
   - Confirmar que o campo de busca permanece visível, a lista de exercícios rola suavemente sem conflito com o gesto de arrastar para fechar e não há espaçamento duplicado acima do teclado nem sobreposição com a barra de navegação inferior / notch.
   - Repetir com `ImportPlanSheet` e `LogCardioModal` (entradas numéricas com teclado).
6. **Vírgula e Ponto em Campos Numéricos & Faixas:**
   - Na sessão (`LoggedSetRow`) e em `Perfil → Dados corporais`: digitar `"80,5"`, `"80.5"`, `"1.000"` e `"2.500"`.
   - Validar que `"1.000"` salva/exibe como `1` kg (nunca `1000` kg) e `"2.500"` como `2,5`.
   - Informar carga `> 1000` kg, peso corporal `< 20` ou `> 400` kg, ou altura `< 100` ou `> 250` cm → confirmar erro inline em PT-BR bloqueando o salvamento.
7. **Modo Offline & Pull-to-Refresh:**
   - Em build **release**, confirmar em `Configurações → Sincronização offline e dados` que o toggle *"Simular modo offline"* **não aparece** (visível apenas em debug ou `--dart-define=ENABLE_OFFLINE_SIMULATION=true`).
   - Ativar **Modo Avião** no aparelho e navegar pelas abas **`Hoje`**, **`Treino`** e **`Progresso`**.
   - Fazer pull-to-refresh em listas já carregadas e vazias → confirmar que dados em cache permanecem visíveis e aparece SnackBar com mensagem amigável + *"Mostrando dados salvos."* (sem perda de scroll nem tela branca).
   - Registrar séries offline na sessão, restaurar rede e validar sincronização da outbox.
8. **Pesagem Diária & Aba `Progresso → Peso`:**
   - Em conta nova sem histórico de peso: completar o onboarding com peso `78,4` kg → abrir **`Progresso → Peso`** e confirmar entrada do dia atual com `78,4` kg.
   - Testar onboarding em Modo Avião → confirmar que a falha de gravação remota não impede concluir o onboarding.
   - Abrir `Perfil → Dados corporais`, alterar outro campo (ex.: idade) **sem mexer no peso** e salvar → confirmar em **`Progresso → Peso`** que o registro do dia mantém o valor e a hora anteriores sem criar entrada duplicada (repetindo em Modo Avião, confirmar que o salvamento conclui sem erro de pesagem); em seguida alterar o peso para `78,9` kg e salvar → confirmar atualização da entrada do dia para `78,9` kg sem duplicar a data no gráfico (validar também à noite, após 21h BRT / UTC-3).
   - Em conta sem pesagens, tocar no botão do `EmptyStateWidget` em **`Progresso → Peso`** → confirmar abertura direta do sheet `Dados corporais`.
9. **Troca de Programa (`SwitchProgramSheet`) & Simulação de Rollback:**
   - Trocar de programa/preset normalmente com rede ativa → confirmar diálogo `showLiftrConfirmDialog`, criação completa de todos os treinos e ativação final.
   - Em ambiente de teste com falha forçada de rede após iniciar criação (ou corte imediato de conectividade no meio da criação dos treinos): validar que o programa incompleto **não fica ativo** e é desfeito via rollback com feedback claro em PT-BR.
10. **Acessibilidade de Fonte Máxima em Celular Pequeno:**
    - Ajustar o tamanho da fonte do sistema para o **máximo** nas configurações de acessibilidade de um celular pequeno (~360dp Android / iPhone SE).
    - Percorrer **`Hoje`**, **`Treino`**, **`Progresso`** (todas as sub-abas), **`Perfil`**, **`Configurações`** e uma **sessão ativa** confirmando ausência de textos cortados, botões inacessíveis ou overflows visuais.
11. **Atualizador de APK no Android (Build Sideload):**
    - Em Android com versão anterior instalada (build sideload), acessar `Configurações → Atualizações do app`, baixar a atualização, validar verificação SHA-256 e abertura do instalador do sistema.
    - No iPhone, confirmar que nenhuma seção/aviso de atualização APK aparece.
12. **Checklist Complementar de Fluxos:**
    - **Gerador com IA offline:** com Modo Avião ligado, abrir o gerador de treinos com IA e validar estado/mensagem offline em PT-BR sem travamentos.
    - **Descanso personalizado de `100s`:** abrir um template com descanso em `100s` (opção personalizada), editar outro campo sem alterar o descanso, salvar e confirmar que `100s` foi preservado.
    - **Foto de perfil:** adicionar uma foto, removê-la confirmando o diálogo destrutivo, validar retorno às iniciais e fechar/reabrir o app confirmando que a foto removida não reaparece.
    - **Filtro `"Ombros"` & `"Limpar busca"`:** na biblioteca de exercícios, selecionar `"Ombros"` e conferir que lista apenas exercícios com ombro/deltoide como músculo **primário**; digitar busca sem resultado e tocar em `"Limpar busca"`.
    - **Temas Claro e Escuro:** alternar entre Claro e Escuro em `Configurações` e inspecionar **`Hoje`**, **`Treino`**, **`Progresso`** (incluindo série 1RM dos gráficos) e modais confirmando contraste e legibilidade.

---

## 6. Ações Manuais Pendentes Fora do Código

1. **Painel do Supabase (Authentication → URL Configuration):**
   - Cadastrar os seguintes **Redirect URLs** permitidos:
     - `liftr://reset-password`
     - `liftr://auth-callback`
2. **Privacidade, Dados e Compliance de Lojas (Pré-submissão):**
   - Publicar **Política de Privacidade** oficial acessível por URL pública, informando explicitamente:
     - o **envio de dados ao Google (Gemini API)** durante a geração/importação de treinos com IA;
     - o **tratamento de dados pessoais sensíveis de saúde** (peso, gordura corporal, sexo biológico, medidas corporais, histórico de treinos) conforme a **LGPD**.
   - Publicar **URL web de solicitação de exclusão de conta/dados** (exigida pelo formulário Data Safety do Google Play e vinculada ao futuro endpoint de exclusão do app).
   - Implementar a Edge Function + fluxo in-app de exclusão de conta antes da submissão às lojas ([Seção 6](technical-debt.md#L37)).
3. **Assinatura e Builds de Release (Android & iOS):**
   - **Android:** Preservar a keystore atual de produção (`CN=LIFTR`, `SHA-256: db7f763cb8ac32a16e78b05252f03e3b10f006e5d6e598216551a7a24412ffb3`) em `app/android/key.properties` e no Google Play App Signing (**nunca trocar a chave**, sob risco de quebrar atualizações dos usuários atuais), mantendo **backup offline seguro da keystore e das senhas fora do GitHub** (Secrets do Actions não podem ser lidos de volta — [Seção 12](technical-debt.md#L139)). Criar flavor/flag de loja desativando o atualizador de APK e removendo `REQUEST_INSTALL_PACKAGES` ([Seção 7](technical-debt.md#L46)).
   - **iOS:** Configurar Team ID, certificados de distribuição e provisioning profiles no Xcode / App Store Connect para o bundle configurado (`TARGETED_DEVICE_FAMILY = "1"`).
4. **Banco de Dados & Backend WhatsApp (Pós-branch):**
   - Decidir a estratégia de unificação dos esquemas paralelos (`user_profiles`/`weight_entries` já ativos em produção com `1`/`0` linhas vs `perfil`/`pesagem` ainda ausentes em produção — [Seção 10](technical-debt.md#L70)).
   - Somente após a decisão da Seção 10, revisar e aplicar a migração SQL de unicidade diária e coluna `source` na tabela definitiva ([Seção 11](technical-debt.md#L112)).
   - Implementar fluxo de vínculo OTP e sincronização entre WhatsApp e o app Flutter antes de reexibir a seção nas Configurações ([Seção 9](technical-debt.md#L64)).
