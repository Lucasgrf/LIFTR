# Auditoria e Remediação de Frontend — LIFTR (`feat/frontend-audit-fixes`)

Este documento consolida todas as entregas, decisões arquiteturais e de UI, itens N/A, bloqueadores de publicação, dívidas técnicas e o roteiro final de verificação em aparelho físico para a branch `feat/frontend-audit-fixes`.

---

## 1. Resumo das Mudanças por Fase

| Fase | Foco Principal | Entregas & Commits Chave |
| --- | --- | --- |
| **Fase 0 — Limpeza & Roteamento** | Remoção de módulos mortos e rotas órfãs | Remoção de rotas órfãs, módulo morto de metas/nutrição/calendário e 11 widgets sem uso; fallback de rotas desconhecidas via `GoRouter.onException` para `/` (`e36f439`..`a123f62`). |
| **Fase 1 — Design System & Tokens** | Paleta, tipografia, componentes base e motion | Tokens Dark (`#0D0D0F` / `#1A1A1F` / `#72A987` com `onPrimary = #0D0D0F`) e Light (`#315B43` com `onPrimary = #F2F2F0`) em conformidade WCAG AA/AAA; escala tipográfica `Geist` com piso `11sp` e `FontFeature.tabularFigures()`; evolução de `AppButton` e `AppInput`; `AppMotion` respeitando `MediaQuery.disableAnimationsOf`; baseline de goldens `375dp` dark/light (`d044c84`..`d290020`). |
| **Fase 2 — Sessão de Treino & Acessibilidade** | Performance na sessão, alvos `48dp` e proteção contra perda | Extração do leaf widget `SessionElapsedText` (`PERF-01`); steppers `>= 48dp` com reflow responsivo; `Material` + `Ink` para ripples; picker inline de exercício; `PopScope` ao sair da sessão ativa; linhas compactas por estado em `LoggedSetRow`; correção de concorrência undo/restore vs outbox e diálogo de saída/descarte de edição inválida (`9ff79d0`..`cf91720`). |
| **Fase 3 — Formulários, Erros & Auth PKCE** | Mensagens PT-BR, decimais e fluxo completo de Auth | `userFacingMessage` PT-BR + `appErrorLogger`; escopo estrito de `kOfflineDataSafetyNote`; preservação de descansos personalizados no template; parsing numérico PT-BR tratando `.` sempre como decimal com validação de faixa inline; fluxo completo de reset de senha PKCE (`ResetPasswordScreen`, `liftr://reset-password`, `flutter_deeplinking_enabled = false`), tratamento de link expirado e `emailRedirectTo: liftr://auth-callback` no `signUp` com aviso de mesmo dispositivo (`2305ebc`..`08a07e9`). |
| **Fase 4 — Padronização de Sheets, Diálogos & Listas** | Coesão de modais, diálogos destrutivos e agrupamento | Introdução e migração completa para `showLiftrSheet` (`20` sheets), `showLiftrConfirmDialog` e `LiftrListGroup`; tratamento explícito de teclado (`viewInsets.bottom`) e `viewPadding.bottom` sem duplicação; goldens `375dp` para 5 sheets migrados (`6c68345`..`a4639a`, `dd287e2`). |
| **Fase 5 — Responsividade, Layout & Plataforma** | Breakpoints `320dp`–`412dp` @ `2.0x` e `SafeArea` | `LayoutBuilder` no `OnboardingScreen` e `ConfigureSetsScreen` sem branches por `textScaler` nem larguras mágicas; `ResponsiveContainer` padronizado; `SafeArea` nas telas principais, formulário e detalhe; substituição de `FittedBox` em texto no gráfico de 7 dias por scroll horizontal + `Semantics` completo; ocultação de atualizador fora do Android (`cd70f11`..`7c8641b`). |
| **Fase 6 — Fluxos Destrutivos, Offline & Robustez** | Segurança de estado, filtros e ciclo de vida | Confirmação em exclusões (cardio, avatar, série, troca de programa); troca de preset atômica em `SwitchProgramSheet` com rollback e log via `appErrorLogger`; remoção de avatar com limpeza prévia de `auth.userMetadata` e leitura exclusiva do auth; filtro muscular estrito pelo músculo primário; trava de orientação retrato no celular e `TARGETED_DEVICE_FAMILY = 1` (iPhone-only) no iOS; pull-to-refresh com `AlwaysScrollableScrollPhysics`, preservação de cache e `userFacingMessage` (`8c6f1e9`..`2eb5c4c`). |
| **Fase 7 — Visualização, A11y Avançada & Pesagem** | Leitor de tela, gráficos desacoplados e pesagem diária | `Tooltip` em todos os `IconButton`; semântica completa no heatmap com múltiplas sessões no mesmo dia; desacoplamento de gráficos (`ChartPoint` / `ChartSeries`); contraste WCAG AA para séries 1RM/info (`colors.info`); progresso real em `TodayExercisePreviewCard`; upsert diário de pesagem no onboarding e ao editar peso em `Dados corporais`, com CTA no estado vazio da aba `Peso` (`1de6d26`..`78a4c8f`). |
| **Fase 8 — Polimento Visual, Copy PT-BR & Performance** | Higiene tipográfica, glossário e cache/virtualização | Remoção de eyebrows redundantes e padronização em sentence case; `LiftrEyebrow` centralizando caixa alta no componente (`ebbb8d8`); glossário PT-BR, pluralização, labels de enum sem vazamentos de código/vendor (`copy_01`); remoção de I/O síncrono no `build`, `cacheWidth`/`cacheHeight` em imagens, hoisting de `DateFormat`, virtualização de listas e verificação via `phase8_polish_copy_perf_test.dart` (`22da280`..`3bdc69b`). |
| **Ajustes Finais** | Integridade WhatsApp, timezone de pesagem & documentação | Ocultação da seção `WhatsApp Coach` sem fonte real de sincronização no app (`5667cb0`); cálculo do dia de pesagem no fuso local do aparelho (convertido para limites UTC na query), guarda de onboarding não-bloqueante e atualização condicional apenas quando o peso muda (`d6aa9f5`); widget `LiftrEyebrow` (`ebbb8d8`); este consolidado. |

---

## 2. Decisões Arquiteturais e de UI

1. **Auth PKCE + Isolamento de Deep Links no GoRouter:**
   - `authFlowType` é PKCE; o GoRouter mantém `flutter_deeplinking_enabled = false` (`AndroidManifest.xml` / `Info.plist`) para não interceptar `liftr://reset-password` e `liftr://auth-callback` antes do `supabase_flutter`.
   - Links de negócio futuros devem ser roteados pelo `AppLinks` listener em coordenação explícita com o estado de sessão/recuperação.
2. **Parsing Numérico PT-BR Estrito:**
   - Ponto (`.`) e vírgula (`,`) são tratados **exclusivamente como separador decimal** (`"1.000"` → `1,0`; `"2.500"` → `2,5`) para evitar ambiguidade perigosa em cargas de treino, acompanhado de validação inline de faixa (carga `0–1000 kg`, peso corporal `20–400 kg`, altura `100–250 cm`).
3. **Resiliência Offline & Nota de Segurança de Dados:**
   - `kOfflineDataSafetyNote` ("Seus dados estão salvos no aparelho...") só aparece em erros remotos onde a persistência local/outbox realmente garantiu o registro; nunca é exibida quando a falha nasce no datasource local.
4. **Orientação & Dispositivo Alvo:**
   - O aplicativo foi travado em modo **retrato apenas para iPhone/Android phone** (`SystemChrome.setPreferredOrientations`, `android:screenOrientation="portrait"`, `TARGETED_DEVICE_FAMILY = "1"`), priorizando ergonomia unilateral durante o treino com cargas.
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
- **Sincronização do Vínculo WhatsApp Coach & Unificação de `pesagem` vs `weight_entries`:** Adiado para sprint de backend/Edge Functions por exigir migração SQL e fluxo de verificação por código (OTP).
- **Migração SQL de `weight_entries`:** Proposta e documentada em [technical-debt.md](technical-debt.md#L70), não aplicada contra o banco nesta branch.

---

## 4. Bloqueadores de Publicação & Dívidas Técnicas

Todos os bloqueadores e pendências técnicas estão detalhados com contexto, impacto e solução esperada em [**docs/design/technical-debt.md**](technical-debt.md).

### Bloqueadores de Publicação (Impeditivos para Loja)
1. **Exclusão de Conta no Aplicativo (Apple App Store `5.1.1(v)` & Google Play Data Safety):** Não existe fluxo de exclusão de conta/dados pelo usuário nem endpoint Edge Function dedicado com `service_role`. Ver [Seção 6 de technical-debt.md](technical-debt.md#L37).
2. **Atualizador Próprio de APK / Sideload (`REQUEST_INSTALL_PACKAGES` — Google Play):** O `AppUpdateService` faz download/instalação direta de APK via GitHub Releases, proibido nas builds distribuídas pela Play Store. Necessário desativar via flavor/`--dart-define` na build de loja e migrar para Play In-App Updates API. Ver [Seção 7 de technical-debt.md](technical-debt.md#L46).

### Dívidas Técnicas e Itens de Backlog
- **Alta Prioridade:** `appErrorLogger` sem envio remoto em release ([Seção 3](technical-debt.md#L16)).
- **Arquitetura & Roteamento:** Estado de recuperação PKCE não persistido após reinício do app ([Seção 4](technical-debt.md#L22)); `flutter_deeplinking_enabled = false` exigindo roteamento explícito no listener para novos links ([Seção 5](technical-debt.md#L27)).
- **Banco de Dados & Backend:** Seção WhatsApp Coach oculta por ausência de endpoint/tabela compartilhada no app ([Seção 9](technical-debt.md#L64)); falta de `UNIQUE (user_id, measured_date)` em `weight_entries` e definição de precedência com `public.pesagem` do WhatsApp ([Seção 10](technical-debt.md#L70)).
- **Manutenibilidade & UI:** Substituir `GestureDetector` vazio por `TapRegion` ([Seção 1](technical-debt.md#L5)); modularizar `logged_set_row.dart` ([Seção 2](technical-debt.md#L11)); UI dedicada para excluir planos de treino e eventual plano órfão ([Seção 8](technical-debt.md#L58)).

---

## 5. Roteiro de Teste Manual em Aparelho Físico (Android & iPhone)

> **Pré-requisito:** Build de QA configurada com os Redirect URLs ativos no projeto Supabase de teste e aparelho em orientação retrato.

1. **Cadastro e Confirmação de E-mail (`RegisterScreen`):**
   - Criar conta nova com e-mail válido e senha forte.
   - Confirmar exibição da tela *"Confirme seu e-mail"* com a instrução *"Abra o link neste celular"*.
   - Abrir o e-mail **no mesmo aparelho** e tocar no link de confirmação (`liftr://auth-callback`) → validar entrada no onboarding/app autenticado.
   - Reutilizar o mesmo link depois de expirado/consumido → confirmar mensagem amigável em PT-BR sem crash.
2. **Redefinição de Senha (`LoginScreen` → `ResetPasswordScreen`):**
   - Tocar em *"Esqueci minha senha"*, informar e-mail e enviar → confirmar que o botão desabilita durante o envio e exibe mensagem neutra (*"Se houver uma conta com esse e-mail, enviaremos um link"*).
   - Abrir o link recebido (`liftr://reset-password`) no mesmo aparelho → confirmar abertura da `ResetPasswordScreen`.
   - Definir nova senha, confirmar retorno ao fluxo autenticado e repetição do fluxo testando link expirado com caminho para solicitar novo link.
3. **Sessão de Treino & Leitor de Tela (TalkBack no Android / VoiceOver no iPhone):**
   - Iniciar um treino no fluxo principal, ativar TalkBack/VoiceOver.
   - Verificar leitura dos headers semânticos, botões steppers `+`/`-` (`>= 48dp`), troca de exercício no picker inline, conclusão de séries (transição compacta de linhas) e cronômetro de descanso (`LiftrEyebrow` + controles).
   - Tentar voltar (`PopScope`) com séries registradas → confirmar diálogo de proteção; concluir e desfazer uma série (`Undo`) observando ausência de duplicação ou erro ao reconectar.
4. **Sheets com Teclado Aberto & SafeArea / Barra de Gestos:**
   - Abrir `SwapExerciseSheet` (trocar exercício na sessão) e focar o campo de busca para abrir o teclado virtual.
   - Confirmar que o campo de busca permanece visível, a lista de exercícios rola suavemente sem conflito com o gesto de arrastar para fechar e não há espaçamento duplicado acima do teclado nem sobreposição com a barra de navegação inferior / notch.
   - Repetir com `ImportPlanSheet` e `LogCardioModal` (entradas numéricas com teclado).
5. **Vírgula e Ponto em Campos Numéricos & Faixas:**
   - Na sessão (`LoggedSetRow`) e em `Perfil → Dados corporais`: digitar `"80,5"`, `"80.5"`, `"1.000"` e `"2.500"`.
   - Validar que `"1.000"` salva/exibe como `1` kg (nunca `1000` kg) e `"2.500"` como `2,5`.
   - Informar carga `> 1000` kg, peso corporal `< 20` ou `> 400` kg, ou altura `< 100` ou `> 250` cm → confirmar erro inline em PT-BR bloqueando o salvamento.
6. **Modo Offline & Pull-to-Refresh:**
   - Ativar Modo Avião (ou alternar *"Simular modo offline"* nas Configurações), navegar pelas abas Treino, Histórico e Corpo.
   - Fazer pull-to-refresh em listas já carregadas e vazias → confirmar que dados em cache permanecem visíveis e aparece SnackBar com mensagem amigável + *"Mostrando dados salvos."* (sem perda de scroll nem tela branca).
   - Registrar séries offline na sessão, restaurar rede e validar sincronização da outbox.
7. **Pesagem Diária & Aba Peso:**
   - Em conta nova sem histórico de peso: completar o onboarding com peso `78,4` kg → abrir aba `Corpo → Peso` e confirmar entrada do dia atual.
   - Testar onboarding com rede desligada → confirmar que falha na gravação de peso não impede concluir o onboarding.
   - Abrir `Perfil → Dados corporais`, salvar **sem mudar o peso** → nenhuma chamada de gravação redundante; em seguida alterar o peso para `78,9` kg e salvar → confirmar atualização da mesma entrada diária (sem duplicar o dia no gráfico nem depender do horário UTC à noite, ex. após 21h BRT).
   - Em conta sem pesagens, tocar no botão do `EmptyStateWidget` da aba `Peso` → confirmar abertura do sheet `Dados corporais`.
8. **Troca de Programa (`SwitchProgramSheet`) & Simulação de Rollback:**
   - Trocar de programa/preset normalmente com rede ativa → confirmar diálogo `showLiftrConfirmDialog`, criação completa de todos os treinos e ativação final.
   - Em ambiente de teste com falha forçada de rede após iniciar criação (ou corte imediato de conectividade no meio da criação dos treinos): validar que o programa incompleto **não fica ativo** e é desfeito via rollback com feedback claro em PT-BR.

---

## 6. Ações Manuais Pendentes Fora do Código

1. **Painel do Supabase (Authentication → URL Configuration):**
   - Cadastrar os seguintes **Redirect URLs** permitidos:
     - `liftr://reset-password`
     - `liftr://auth-callback`
2. **Privacidade, Dados e Compliance de Lojas (Pré-submissão):**
   - Publicar **Política de Privacidade** oficial acessível por URL pública.
   - Publicar **URL web de solicitação de exclusão de conta/dados** (exigida pelo formulário Data Safety do Google Play e vinculada ao futuro endpoint de exclusão do app).
   - Implementar a Edge Function + fluxo in-app de exclusão de conta antes da submissão às lojas ([Seção 6](technical-debt.md#L37)).
3. **Assinatura e Builds de Release (Android & iOS):**
   - **Android:** Gerar o keystore de produção e criar `app/android/key.properties` no ambiente seguro de build/CI (`app/android/app/build.gradle.kts` atualmente faz fallback para `debug` quando ausente). Criar flavor/flag de loja desativando o atualizador de APK e removendo `REQUEST_INSTALL_PACKAGES` ([Seção 7](technical-debt.md#L46)).
   - **iOS:** Configurar Team ID, certificados de distribuição e provisioning profiles no Xcode / App Store Connect para o bundle configurado (`TARGETED_DEVICE_FAMILY = "1"`).
4. **Banco de Dados & Backend WhatsApp (Pós-branch):**
   - Revisar e aplicar em janela controlada a migração SQL proposta para unicidade diária e coluna `source` em `public.weight_entries` ([Seção 10](technical-debt.md#L70)), além da política de unificação/precedência com `public.pesagem`.
   - Implementar fluxo de vínculo OTP e sincronização entre `public.perfil` (WhatsApp) e o app Flutter antes de reexibir a seção nas Configurações ([Seção 9](technical-debt.md#L64)).
