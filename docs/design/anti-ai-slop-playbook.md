# Playbook Anti-AI-Slop — LIFTR Frontend Engineering

Este documento traduz e consolida as **5 skills de engenharia de design** adotadas pelo LIFTR para eliminar o padrão genérico de interfaces geradas por IA (*"AI slop"*: fonte Inter padrão, acento roxo `#6C63FF`, cards idênticos em grade, glows neon, gradientes decorativos, estados incompletos e animações gratuitas).

> **Separação de diretórios no repositório:**
> A pasta [`skills/`](../../skills/README.md) na raiz pertence **exclusivamente às skills de runtime do agente WhatsApp em Deno** (testadas pelo CI com `deno test supabase/functions evals`). **Nunca** adicione skills de design ou instruções de agente de código dentro de `skills/`. Todas as diretrizes de interface e agentes de desenvolvimento vivem em `docs/design/` e `AGENTS.md`.

---

## 1. As 5 Skills Anti-AI-Slop

### 1.1 Anti UI Slop (`uizze.com` / `anti-ui-slop`)
- **Foco:** Processo *context-first* (ler marca, tokens e componentes reais do projeto antes de escrever UI), playbooks dedicados por intenção e validação final rigorosa (*Hard Finish Gate*).
- **Playbooks aplicados ao LIFTR:**
  - `new-work`: Antes de criar tela/componente, verificar se já existe equivalente em `app/lib/core/widgets/` ou na feature; definir estados (`loading`, `empty`, `error`, `offline`, `disabled`) antes do layout feliz.
  - `operate`: Ao mexer em tela existente, preservar arquitetura de tokens (`AppColors`, `FitnessColors`, `AppRadius`, `AppSpacing`, `AppMotion`) e contratos de domínio.
  - `polish`: Remover ruído visual ("cardite", bordas coloridas em excesso, sombras difusas), ajustar alinhamento tabular e hierarquia de leitura em academia.
  - `distill`: Reduzir profundidade de navegação e revelar informação secundária progressivamente (*Progressive Disclosure*).
  - `audit`: Inspecionar o código contra os critérios reais de layout, contraste, overflow e interatividade antes de considerar pronto.
- **Hard Finish Gate (obrigatório em todo PR de UI):**
  1. Zero clipping ou overflow horizontal/vertical em viewports estreitos (`320px`, `375px`, `430px`) e tablets (`768px`).
  2. Zero quebra ou truncamento crítico sob `textScaler` até `1.3x`.
  3. Zero controle inerte ou sem feedback visual/tátil imediato.
  4. Zero texto dinâmico sem tratamento para nomes longos de exercício ou números altos.

---

### 1.2 ThinkUI (`thinkui.xyz` — MCP)
- **Foco:** Ancorar decisões de UI em fluxos reais de produto, primitivas estruturadas e SVGs geométricos limpos, em vez de deixar o agente "inventar de memória" um template SaaS genérico.
- **Uso no ecossistema de agentes:**
  - Servidor MCP hospedado: `https://thinkui.xyz/mcp` (quando conectado em um cliente compatível com MCP, consultar padrões reais de fluxo, tabelas densas, steppers numéricos, estados vazios e diagramas vetoriais limpos antes de prototipar).
  - Mesmo offline/sem MCP conectado, aplicar o princípio central do ThinkUI no LIFTR: **partir da tarefa física real** (mãos suadas na academia, registro rápido com uma mão, leitura rápida entre séries) e usar primitivas padronizadas + SVGs vetoriais limpos (*Monólito Dinâmico* e *Modular Vector Kinematics*), nunca ícones raster ou ilustrações genéricas.

---

### 1.3 Taste Skill (`github.com/Leonxlnx/taste-skill`)
- **Foco:** Calibração explícita de gosto estético *antes* de escrever código por meio de três mostradores (*dials*), evitando que a IA recorra à estética padrão de dashboard SaaS.
- **Instalação opcional em ambientes locais de agente:**
  ```bash
  npx skills add Leonxlnx/taste-skill
  ```
- **Dials oficiais calibrados para o LIFTR (*Technical Humanism*):**
  - `DESIGN_VARIANCE = 3/10`: Alta disciplina estrutural e previsibilidade ergonômica. Na academia o usuário não quer layouts experimentais nem surpresas de posição; controles frequentes ficam sempre no mesmo lugar.
  - `MOTION_INTENSITY = 2/10`: Movimento seco, rápido e funcional. Proibido transformar ações de treino em vitrine animada.
  - `VISUAL_DENSITY = 6/10`: Denso e escaneável em séries, carga e análise de progresso; respiro generoso em ações primárias e fluxo de início de sessão.
- **Lista de clichés explicitamente banidos no LIFTR:**
  - Tipografia `Inter` genérica sem hierarquia tabular -> usar **Geist** com `FontFeature.tabularFigures()`.
  - Acento roxo/índigo elétrico (`#6C63FF`) -> usar **Verde Botânico `#72A987`** (Dark) e **`#315B43`** (Light) como acento funcional sobre base Carvão/Grafite.
  - Cards com gradiente radial no canto, ícones rotacionados (`-3°`/`-4°`) e `BoxShadow` colorido/neon.
  - "Cardite" (colocar cada linha de lista dentro de um card com borda própria quando divisores sutis sobre uma única superfície funcionam melhor).
  - Paleta arco-íris saturada em grupos musculares e gráficos decorativos sem pergunta clara.

---

### 1.4 Emil Design Engineering (`github.com/emilkowalski/skills` — `emil-design-eng`)
- **Foco:** Micro-craft, física tátil de interação e engenharia de motion ("gosto se treina com intenção").
- **As 4 perguntas obrigatórias antes de animar qualquer elemento:**
  1. **Com que frequência o usuário executa essa ação?** Ações de alta frequência (incrementar kg/reps, marcar série concluída, alternar segmento) exigem resposta imediata (`<= 140ms` ou `0ms`), nunca animações longas.
  2. **Qual é o propósito funcional?** (`Feedback`, `Continuidade`, `Atenção` ou `Significado`). Se não serve a nenhum desses quatro, remova.
  3. **Qual curva e duração traduzem firmeza sem parecer mole ou lento?** Curva padrão `Cubic(0.23, 1.0, 0.32, 1.0)` (*ease-out* rápido que assenta com precisão) e teto estrito `< 260ms` dentro do treino.
  4. **Bloqueia o próximo toque ou ignora acessibilidade?** Toda interação continua clicável durante a transição e respeita `MediaQuery.disableAnimationsOf(context)`.
- **Padrões táteis no LIFTR:**
  - Feedback de toque em botão primário (`AppButton`): micro-escala sutil (`0.985` por `140ms` em `AppMotion.fast`) + feedback háptico proporcional (`HapticFeedback.selectionClick` em ajustes, `lightImpact` em ações confirmadas).
  - Toda revisão de componente deve seguir o formato **Before / After / Why** (o que era genérico/problemático -> o que foi feito -> por que melhora a experiência real).

---

### 1.5 Vercel Web Design Guidelines (`github.com/vercel-labs/agent-skills` — `web-design-guidelines`)
- **Foco:** Auditoria rigorosa arquivo-a-arquivo e linha-a-linha contra regras verificáveis de acessibilidade, semântica, resiliência de estados e integridade visual.
- **Tradução direta das diretrizes para Flutter no LIFTR:**
  1. **Semântica & Leitores de Tela:** todo botão de ícone, avatar clicável, card navegável e controle customizado envolve `Semantics(label: ..., button: true)` com nome claro da ação; gráficos expõem descrição textual resumida via `Semantics`.
  2. **Alvos de toque (`>= 48x48dp`):** mesmo quando o ícone visual tem `16–20dp` (como o botão fechar de banner ou ação de chip), a área clicável precisa respeitar mínimo `48x48dp` (ou `44dp` com margem sem competição adjacente em áreas compactas verificadas).
  3. **Contraste WCAG 2.1 AA/AAA verificado:** nunca texto branco sobre `#72A987` (`2.42:1`, reprovado) nem `#72A987` claro como texto sobre fundo claro (`2.49:1`, reprovado). Usar `onPrimary = #0D0D0F` sobre `#72A987` (`7.16:1` AAA) no Dark e `#315B43` (`7.10:1` AAA) no Light.
  4. **Redução de movimento:** checar `MediaQuery.disableAnimationsOf(context)` em toda animação explícita e `AnimatedSwitcher`/`TweenAnimationBuilder`.
  5. **Escalabilidade tipográfica e tabular:** usar `FontFeature.tabularFigures()` em números mutáveis/comparáveis, evitar alturas fixas rígidas em contêineres com texto variável (preferir `minHeight` + `Flexible`/`Expanded`) e suportar `textScaler` até `1.3x`.
  6. **Completude de estados:** toda tela conectada a dados deve cobrir explicitamente `loading` (skeleton sem brilho neon), `empty` (explicação + próximo passo), `error` (causa humana + segurança dos dados locais + retry), `offline` (banner persistente com contador de pendências), `partial` e `disabled`/`in-flight` (proteção contra duplo toque).
  7. **Microcopy & Pluralização:** PT-BR consistente (`1 série` vs `2 séries`), unidades sempre explícitas (`kg`, `reps`, `min`, `kcal`), zero erro cru de exceção exposto diretamente ao usuário sem contexto de recuperação.

---

## 2. Auditoria Inicial do Codebase Atual (Before / After / Why)

Mapeamento real dos principais desvios identificados nos arquivos de `app/lib/`:

| # | Before (estado atual no código) | After (alvo da revitalização) | Why (Brand Guide + Skills) |
|---|---|---|---|
| 1 | `primary: #6C63FF` e `primaryLight: #B7B3FF` em [app_colors.dart](../../app/lib/core/theme/app_colors.dart) e `timerActive: #6C63FF` em [fitness_colors.dart](../../app/lib/core/theme/fitness_colors.dart) | Paleta **Verde Botânico `#72A987`** (Dark) / **`#315B43`** (Light) sobre **Carvão `#0D0D0F`**, **Grafite `#1A1A1F`**, **Titânio `#8E8E98`** e **Branco Osso `#F2F2F0`** | Elimina o clichê "roxo SaaS" e aplica integralmente o sistema cromático do Brand Guide. |
| 2 | `onPrimary: #FFFFFF` com possível contraste insuficiente em verde claro; `textTertiary: #63636E` e `#8E8E9E` abaixo de `4.5:1` | `onPrimary: #0D0D0F` no Dark (`7.16:1` AAA) e `#F2F2F0` no Light (`6.92:1` AA+); `textTertiary: #858590` no Dark (`4.75:1` AA) e `#64646E` no Light (`5.85:1` AA) | Vercel Guidelines + Cap. 10: contraste validado por fórmula antes do código, legibilidade sob luz forte de academia. |
| 3 | `BoxShadow(blurRadius: 18)` colorido em [app_button.dart](../../app/lib/core/widgets/app_button.dart); halo radial + ícone inclinado `-4°`/`-3°` com `blurRadius: 30` em [today_workout_banner.dart](../../app/lib/features/dashboard/presentation/widgets/today_workout_banner.dart) e [session_summary_screen.dart](../../app/lib/features/workout_session/presentation/screens/session_summary_screen.dart) | Superfícies foscas estratificadas por luminância (`#0D0D0F` -> `#1A1A1F` -> `#222228`), acento estrutural fino (`2–3px`) sem glow nem rotação gratuita | Brand Guide Seção 2 & 3 (*Technical Humanism*): proibição explícita de neon, glow decorativo e gradientes centrais. |
| 4 | Fonte `Inter` em [app_typography.dart](../../app/lib/core/theme/app_typography.dart) e `app/pubspec.yaml` | Fonte **Geist** empacotada offline (`400/500/600/700`) com `tabularFigures` em métricas e escala formal de 5 níveis | Brand Guide Seção 9 + Taste Skill: escapa do padrão "Inter + roxo" com neutralidade geométrica e precisão numérica. |
| 5 | Raios grandes (`14`, `18`, `24`) em [app_radius.dart](../../app/lib/core/theme/app_radius.dart) e `StadiumBorder` em [app_shell.dart](../../app/lib/routing/app_shell.dart) | Escala técnica (`0 / 4 / 8 / 12 / 16 / 999`) e barra de navegação com marcador linear técnico em `#72A987` | Brand Guide Seção 3 & Cap. 22: cantos levemente suavizados, sem excesso de arredondamento. |
| 6 | Cores arco-íris em [fitness_colors.dart](../../app/lib/core/theme/fitness_colors.dart) (`#F43F5E`, `#3B82F6`, `#A855F7`...) para músculos em [weekly_muscle_volume_card.dart](../../app/lib/features/training/presentation/widgets/weekly_muscle_volume_card.dart) | Escala monocromática funcional: Verde Botânico para faixa-alvo atingida e Titânio para base neutra + contagem explícita de séries | Brand Guide Seção 13 & Cap. 15: cor comunica função e estado, não decoração por grupo. |
| 7 | Texto `'LIFTR'` + quadrado colorido em [login_screen.dart](../../app/lib/features/auth/presentation/screens/login_screen.dart) e [register_screen.dart](../../app/lib/features/auth/presentation/screens/register_screen.dart); `app/assets/icons/` vazio | Símbolo vetorial **Monólito Dinâmico** (`liftr_monolith.svg`), componente `LiftrWordmark` com proporções e kerning óptico documentados + novo App Icon Android | Brand Guide Seções 5–8 & 15: identidade própria consistente entre splash/auth e ícone do sistema. |
| 8 | Chips/controles pequenos (`34px` em [progress_weight_view.dart](../../app/lib/features/history/presentation/widgets/progress_weight_view.dart), `22px` em [weight_evolution_chart.dart](../../app/lib/core/widgets/charts/weight_evolution_chart.dart), `28x28` em [offline_banner_widget.dart](../../app/lib/core/widgets/offline_banner_widget.dart)) e eixos `9px` em [exercise_load_progression_chart.dart](../../app/lib/core/widgets/charts/exercise_load_progression_chart.dart) | Alvos de toque `>= 48x48dp` (inclusive expandindo área clicável invisível em ícones compactos) e fonte mínima `11sp` tabular em eixos de gráfico + legenda textual/semântica | Cap. 10, 27, 29 + Vercel Guidelines: ergonomia com uma mão na academia e legibilidade acessível. |
| 9 | Animações espalhadas sem tokens (`240ms`, `260ms`, `280ms`, curvas variadas) e [rest_timer_widget.dart](../../app/lib/features/workout_session/presentation/widgets/rest_timer_widget.dart) sem estado de pausa | `AppMotion` (`ThemeExtension`) com `Cubic(0.23, 1.0, 0.32, 1.0)`, press tátil sutil, timer com 5 estados (`idle / running / paused / completed / dismissed`) | Emil Design Eng + Cap. 12 & 30: movimento consistente, funcional e não bloqueante. |
| 10 | Cardite em listas de exercícios ([dashboard_screen.dart](../../app/lib/features/dashboard/presentation/screens/dashboard_screen.dart)) e ícones genéricos `fitness_center_rounded` no catálogo | Agrupamento de lista limpa com divisores sutis + fundação **Modular Vector Kinematics** (8 SVGs por padrão de movimento inspirados em Otl Aicher) | Brand Guide Seção 12 + Cap. 06: estrutura por superfície e tipografia em vez de cards excessivos, com linguagem visual própria para exercícios. |

---

## 3. Roadmap de Execução (GitHub Flow — PRs Atômicos)

1. **Fase 0 (`docs/design-system-and-skills`):** Documentação do Brand Guide, Playbook das 5 Skills, Design QA Checklist e `AGENTS.md`.
2. **Fase 1 (`feat/design-tokens-and-brand-assets`):** Fonte **Geist**, `AppColors`, `FitnessColors`, `AppTypography`, `AppRadius`, `AppMotion`, `AppTheme`, SVG `LiftrBrandMark`/`LiftrWordmark` e App Icon Android.
3. **Fase 2 (`feat/core-ui-revitalization`):** Revitalização de `AppButton`, `AppCard`, `AppInput`, `LiftrProgressBar`, estados (`Empty`/`Error`/`Loading`/`Offline`/`Update`), `LiftrBadge`, `LiftrSheetHeader` e `AppShell`.
4. **Fase 3 (`feat/gym-flows-revitalization`):** Revitalização dos fluxos críticos de academia: **Hoje** (`DashboardScreen`), **Sessão Ativa** (`WorkoutSessionScreen`, `SessionExerciseCard`, `LoggedSetRow`, `RestTimerWidget` 5 estados) e **Resumo Pós-Treino** (`SessionSummaryScreen`).
5. **Fase 4 (`feat/training-progress-identity-revitalization`):** Revitalização de **Treino** (`TrainingListScreen`, `WorkoutDetailScreen`, `WeeklyMuscleVolumeCard`), **Progresso & Gráficos** (`HistoryScreen`, `Progress*View`, charts), **Auth/Onboarding/Perfil/Configurações** e revisão completa de UX Writing.
6. **Fase 5 (`feat/vector-kinematics-and-design-qa`):** Fundação **Modular Vector Kinematics** (8 diagramas SVG Otl Aicher + `ExerciseDiagram`), auditoria final de Design Critique/Design QA em todos os viewports (`320/375/430/768px`, `textScaler 1.3x`) e plano de instrumentação de métricas UX.
