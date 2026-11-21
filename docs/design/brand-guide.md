# LIFTR Brand Guide & Design System v2

> Documento operacional que consolida o **Brand Guide v1.0** e os estudos de UI/UX, tokens, arquitetura de componentes, microcopy, resiliência e motion do LIFTR em decisões concretas de engenharia de interface.

---

## 1. Estratégia de Marca & Personalidade

- **Brand Essence:** *Physical health through consistent progress.*
- **Tagline:** *Train. Track. Evolve.*
- **Filosofia:** *Care for your body. Understand your progress. Keep going.*
- **Posicionamento:** O LIFTR ocupa o território entre tecnologia, treinamento físico e saúde. A musculação é tratada como ferramenta para construir força, capacidade física e saúde sustentável — um produto confiável para treinar com propósito e medir evolução real, sem depender de motivação artificial.

### Atributos Centrais

| Atributo | Definição operacional na UI |
|---|---|
| **Precisão** | Clareza, método, medição exata e decisões apoiadas por dados (algarismos tabulares, metas explícitas de dupla progressão, escalas consistentes). |
| **Vitalidade** | Saúde, energia e capacidade física para viver melhor, expressa em contraste limpo e uso contido de Verde Botânico sem agressividade visual. |
| **Consistência** | Evolução construída ao longo do tempo, sem atalhos, com fila rotativa sem punições e conforto de uso após meses na academia. |

---

## 2. Direção de Arte — *Technical Humanism*

Combina precisão técnica, geometria e estrutura modular com uma experiência humana, acessível e orientada à saúde.

| Território Técnico | Território Humano |
|---|---|
| Métricas e dados | Saúde e bem-estar |
| Precisão e estrutura | Vitalidade e energia |
| Progressão mensurável | Evolução pessoal |
| Método | Sustentabilidade a longo prazo |

### Regras Visuais Fundamentais
- Geometria intencional e composição modular.
- Contraste controlado e **superfícies predominantemente foscas**.
- **Hierarquia por luminância de superfície**, evitando bordas coloridas excessivas.
- **Cantos levemente suavizados**, sem excesso de arredondamento.
- Elementos decorativos mínimos e leitura rápida sob iluminação de academia (foco mobile, uso com uma mão).

### Anti-Identidade (Explicitamente Proibido)
- Estética agressiva de bodybuilding ou suplementos pré-treino.
- Clichês fitness (halteres, bíceps, silhuetas humanas ou folhas usadas como logo/símbolo da marca).
- Cyberpunk, neon excessivo ou **glow decorativo** (como `BoxShadow` colorido em botões ou halos radiais).
- Gradientes como elemento visual central ou de preenchimento de cards.
- Gamificação infantil ou wellness excessivamente espiritualizado.
- Dashboard empresarial frio e impessoal ou visual SaaS genérico (*Inter + roxo elétrico + grade padrão de 3 cards*).

---

## 3. Sistema de Identidade: Símbolo, Wordmark & App Icon

### 3.1 Símbolo — *Monólito Dinâmico (Progressive Monolith)*
Três barras geométricas paralelas em paralelogramo representando progressão estruturada em etapas (formando sutilmente um "L" ascendente, sem parecer um gráfico literal de analytics ou barra/haltere).

- **Construção geométrica:**
  - Inclinação lateral: **`12°`**.
  - Raio de canto interno: **`r = 8%`** da largura do módulo base.
  - Proporções de altura/largura dos 3 segmentos ascendentes: **`A : B : C = 1 : 1.25 : 1.50`**.
  - Espaçamento vertical/diagonal entre segmentos: **`0.22 × A`**.
- **Requisitos:** legibilidade validada até **`16px`**, funcionamento isolado sem wordmark, validação prévia em monocromático preto/branco e zero dependência de sombras, brilho ou gradientes.

### 3.2 Wordmark — *Esportiva Controlada*
- **Construção:** sans-serif geométrica em negrito, itálico controlado a **`12°`** (alinhado ao eixo do Monólito Dinâmico) e proporções compactas — evitando códigos de automobilismo ou suplemento.
- **Kerning óptico calibrado:** `L 1.00 | I 0.42 | F 0.92 | T 0.88 | R 1.08`.
- **Composição principal (lockup horizontal):** símbolo à esquerda (`4x` de largura) + wordmark à direita (`14x` de largura), altura total `5x`, área de respiro mínima de **`1x`** em todos os quatro lados.
- **Variantes previstas:** horizontal principal, símbolo isolado, monocromática branca, monocromática escura, positiva (fundo claro) e negativa (fundo escuro).

### 3.3 App Icon
- **Símbolo isolado** (Monólito Dinâmico sem wordmark).
- Container em **Carvão (`#0D0D0F`)** com símbolo em **Verde Botânico (`#72A987`)** — sem brilho, sem gradiente decorativo e compatível com adaptive icons do Android e máscaras iOS.

---

## 4. Sistema Cromático (Dark-First + Light Mode)

O sistema é **dark-first**: Carvão e Grafite sustentam a interface; Verde Botânico identifica marca, ações principais e estados significativos (nunca decoração gratuita). A identidade deve continuar funcional em monocromático.

### 4.1 Primitivos de Marca

| Primitivo | Hex | Papel |
|---|---|---|
| `Botanical Green` | `#72A987` | Acento principal de marca (Dark Mode) |
| `Deep Botanical` | `#315B43` | Acento botânico de alto contraste (Light Mode e cabeçalhos) |
| `Charcoal` | `#0D0D0F` | Base escura principal |
| `Graphite` | `#1A1A1F` | Superfície de cards e containers primários |
| `Titanium` | `#8E8E98` | Texto secundário e metadados |
| `Bone White` | `#F2F2F0` | Texto principal de alto contraste em fundo escuro |

### 4.2 Tokens Semânticos & Verificação WCAG 2.1

> **Regra crítica de contraste (WCAG AA/AAA validado matematicamente):**
> 1. Texto claro (`#F2F2F0`) sobre Verde Botânico (`#72A987`) resulta em **`2.42:1` (FAIL)** e é **proibido**. No Dark Mode, o texto sobre botões/superfícies `primary` deve ser **`onPrimary = #0D0D0F` (`7.16:1` AAA)**.
> 2. Verde Botânico claro (`#72A987`) como texto/ação sobre fundo claro (`#F5F5F3`) resulta em **`2.49:1` (FAIL)** e é **proibido**. No Light Mode, `primary` mapeia para **`#315B43` (`7.10:1` AAA)** com **`onPrimary = #F2F2F0` (`6.92:1` AA+)**.

| Token Semântico (`AppColors`) | Dark Mode | Contraste verificado (Dark) | Light Mode | Contraste verificado (Light) |
|---|---|---|---|---|
| `background` | `#0D0D0F` | Base Carvão | `#F5F5F3` | Base Osso Claro |
| `surfaceSubtle` | `#141418` | Degrau sutil | `#ECECE8` | Degrau sutil |
| `surface` | `#1A1A1F` | Base Grafite | `#FFFFFF` | Base Branca |
| `surfaceElevated` | `#222228` | Superfície elevada | `#FFFFFF` | Superfície elevada |
| `surfaceVariant` | `#2A2A32` | Controles/steppers | `#E3E3DE` | Controles/steppers |
| `textPrimary` | `#F2F2F0` | `17.32:1` (Carvão) / `15.46:1` (Grafite) / `14.11:1` (`#222228`) **AAA** | `#0D0D0F` | `17.79:1` (Osso) / `19.42:1` (Branco) **AAA** |
| `textSecondary` | `#8E8E98` | `5.98:1` (Carvão) / `5.34:1` (Grafite) / `4.88:1` (`#222228`) **AA** | `#52525B` | `7.08:1` (Osso) / `7.73:1` (Branco) **AAA** |
| `textTertiary` | `#858590` | `5.32:1` (Carvão) / `4.75:1` (Grafite) **AA** | `#64646E` | `5.85:1` (Branco) **AA** |
| `primary` | `#72A987` | `7.16:1` (Carvão) / `6.39:1` (Grafite) **AA/AAA** | `#315B43` | `7.10:1` (Osso) / `7.75:1` (Branco) **AAA** |
| `primaryPressed` | `#5E9473` | `5.51:1` com `#0D0D0F` **AA** | `#264835` | Estado pressionado escuro |
| `primaryLight` *(accent text)* | `#93C4A5` | `8.82:1` (Grafite) / `7.71:1` (`primaryMuted`) **AAA** | `#315B43` | `7.10:1` (Osso) **AAA** |
| `primaryMuted` | `#1B2921` | Fundo sutil botânico | `#E4EFE8` | Fundo sutil botânico |
| `onPrimary` | `#0D0D0F` | `7.16:1` em `#72A987` **AAA** | `#F2F2F0` | `6.92:1` em `#315B43` **AA+** |
| `border` / `borderSubtle` | `#26262E` / `#1E1E24` | Separação contida | `#DFDFDA` / `#EAEAE5` | Separação contida |
| `success` | `#72A987` | Igual a `primary` (Dark) | `#315B43` | Igual a `primary` (Light) |
| `warning` | `#D4A154` | `7.45:1` (Grafite) **AAA** | `#9A6700` | `4.87:1` (Branco) **AA** |
| `danger` | `#D96B6B` | `5.17:1` (Grafite) **AA** | `#B93838` | `5.70:1` (Branco) **AA** |
| `info` | `#6E9EC7` | `6.09:1` (Grafite) **AA** | `#2B5E8A` | `6.84:1` (Branco) **AA** |

### 4.3 Paleta de Domínio e Data Visualization (`FitnessColors`)
Cores de domínio têm papel funcional (Cap. 15 e Seção 13):
- `progressUp`: `#72A987` (Dark) / `#315B43` (Light) — meta de reps batida / progressão de carga.
- `progressSteady`: `#8E8E98` (Dark) / `#52525B` (Light) — manutenção estável.
- `progressStalled`: `#D4A154` (Dark) / `#9A6700` (Light) — atenção/platô (âmbar sóbrio).
- `dropSetTag` / `progressDown`: `#C98A5B` (`6.00:1` em Grafite, `6.72:1` em Carvão) / `#9A5528` Light (`5.67:1` em Branco) — séries de alta intensidade/drop-set sem confundir com erro vermelho.
- `warmupTag` / `progressNeutral`: `#6E9EC7` (Dark) / `#2B5E8A` (Light).
- `timerActive`: `#72A987` (Dark) / `#315B43` (Light) — sem usar roxo.
- **Volume muscular (`WeeklyMuscleVolumeCard`):** proibido o esquema arco-íris por músculo. Utilizar escala funcional monocromática/botânica: **Verde Botânico** para grupos dentro da faixa semanal recomendada e **Titânio / Neutro** para os demais, sempre acompanhado do valor numérico em séries válidas.

---

## 5. Tipografia, Espaçamento & Geometria

### 5.1 Família Tipográfica de UI — **Geist**
- Família open-source (licença SIL OFL) empacotada offline em `app/assets/fonts/`: `Geist-Regular.ttf` (400), `Geist-Medium.ttf` (500), `Geist-SemiBold.ttf` (600), `Geist-Bold.ttf` (700).
- **Regra numérica:** aplicar `FontFeature.tabularFigures()` em **toda métrica mutável ou comparável** (carga em kg, repetições, séries, timers, volume, datas, percentuais e eixos de gráfico).

### 5.2 Os 5 Níveis Tipográficos

| Nível | Tokens Flutter (`TextTheme`) | Tamanhos base | Uso |
|---|---|---|---|
| **Display** | `displayLarge`, `displayMedium` | `32–40px` (`36` / `30`) | Títulos principais ("Hoje", treino atual, hero numérico EMA) |
| **Heading** | `headlineLarge`, `headlineMedium`, `titleLarge`, `titleMedium` | `18–28px` | Cabeçalhos de tela, nomes de exercícios e seções |
| **Body** | `bodyLarge`, `bodyMedium`, `bodySmall` | `12–16px` (`16` / `14` / `12`) | Descrições, orientações, histórico |
| **Label** | `labelLarge`, `labelMedium`, `labelSmall`, `eyebrow` | `11–14px` | Botões, tags, colunas, metadados |
| **Numeric** | Variantes com `tabularFigures` | Conforme contexto | Steppers (`kg`/`reps`), cronômetros, séries, eixos |

### 5.3 Escala de Espaçamento (Base `4px`)
`4` (`space.1`) · `8` (`space.2`) · `12` (`space.3`) · `16` (`space.4`) · `20` (`space.5`) · `24` (`space.6`) · `32` (`space.8`) · `40` (`space.10`) · `48` (`space.12`) px.

### 5.4 Escala de Raios (Contida)
Alinhada à diretriz de *cantos levemente suavizados*:
- `none`: `0px` (barras de progresso edge-to-edge no topo da sessão)
- `xs`: `4px` (badges técnicos, células de heatmap, tags compactas)
- `small`: `8px` (inputs, chips internos, botões compactos, steppers)
- `medium`: `12px` (botões primários/secundários, tiles, containers internos)
- `large` / `xl`: `16px` (cards principais, hero banner, bottom sheets)
- `full`: `999px` (apenas para avatares circulares e alça/pill estritamente necessária)

---

## 6. Arquitetura de Componentes & Governança (Cap. 22–24)

### 6.1 Hierarquia em 5 Camadas
1. **Foundations:** `AppColors`, `FitnessColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppMotion`, `LiftrBrandMark`, `ExerciseDiagram`.
2. **Core UI (`app/lib/core/widgets/`):** `AppButton`, `AppCard`, `AppInput`, `LiftrProgressBar`, `LiftrBadge`, `LiftrSheetHeader`, `EmptyStateWidget`, `ErrorStateWidget`, `LoadingWidget`, `OfflineBannerWidget`. **Regra inviolável:** Core UI é 100% agnóstico de domínio e **nunca** importa modelos de `features/**`.
3. **Fitness Components:** `SessionExerciseCard`, `LoggedSetRow`, `RestTimerWidget`, `TodayWorkoutBanner`, `LastCompletedWorkoutCard`, `ExerciseCard`, `WeeklyMuscleVolumeCard`.
4. **Patterns:** Fluxo de registro com referência anterior + drop-set inline, busca/filtros de biblioteca, gráficos contextualizados, seleção de fila rotativa.
5. **Templates (Fluxos principais):** *Hoje*, *Treino Ativo*, *Planejamento / Fila*, *Biblioteca de Exercícios*, *Progresso* e *Perfil & Configurações*.

### 6.2 Governança Enxuta
- **Antes de criar um componente:** (1) verificar se existe em `core/widgets/`, (2) avaliar parametrização de variante existente, (3) definir API e todos os estados obrigatórios (`default`, `loading`, `empty`, `error`, `disabled`), (4) validar em viewport real.
- **Classificação de mudanças:** `Patch` (correções sem quebra) · `Minor` (nova variante/capacidade compatível) · `Major` (quebra de contrato ou troca de token/componente base).

---

## 7. Iconografia & *Modular Vector Kinematics* (Seções 11–12)

### 7.1 Iconografia de UI
- Usar família base consistente com traço uniforme (`Icons.*_rounded` em Flutter) para ações cotidianas — nunca redesenhar ícones triviais sem necessidade.
- **Conceitos proprietários candidatos (SVG compartilhando grid e stroke):** dupla progressão, carga, aquecimento, fila de treino, platô, volume muscular, histórico e sincronização.

### 7.2 Sistema Visual de Exercícios — *Modular Vector Kinematics*
Inspirado nos pictogramas de **Otl Aicher (Munique 1972)**: figuras anatômicas geométricas simplificadas construídas sobre um rig modular comum em **SVG offline-first** (evitando fotos heterogêneas ou ilustrações de estilos conflitantes).

- **Hierarquia fixa em 4 camadas no SVG:**
  1. **Corpo (silhueta articulada):** Branco Osso / Titânio em preenchimento limpo.
  2. **Equipamento (barra, haltere, polia, banco):** Grafite/contorno neutro para leitura estrutural.
  3. **Músculo-alvo:** destacado em **Verde Botânico (`#72A987` / `#315B43`)** (cor funcional).
  4. **Vetor de movimento:** seta/arco geométrico fino indicando trajetória da carga.
- **Escopo inicial (MVP):** 8 diagramas modulares por **padrão de movimento** cobrindo 100% da biblioteca no componente `ExerciseDiagram`:
  `push_horizontal` · `push_vertical` · `pull_horizontal` · `pull_vertical` · `squat` · `hinge` · `core_carry` · `isolation`.

---

## 8. Linguagem de Motion (`AppMotion` — Cap. 12 & 30)

Todo movimento precisa cumprir ao menos uma das **4 funções**: `Feedback`, `Continuidade`, `Atenção` ou `Significado`. Se remover a animação deixa a interação mais rápida e clara na academia, remova.

- **Tokens (`AppMotion` `ThemeExtension`):**
  - `instant`: `0ms` (steppers de carga/reps, marcação de série repetitiva, ou quando `MediaQuery.disableAnimationsOf(context)` for `true`)
  - `fast`: `140ms` (scale tátil de botão `0.985`, seleção de chip/segmento, toggle)
  - `standard`: `220ms` (expansão de exercício, entrada do timer de descanso, troca de passo)
  - `emphasis`: `260ms` (bottom sheets, transição de conclusão de sessão)
  - **Curva padrão (`easeOutExpo`):** `Cubic(0.23, 1.0, 0.32, 1.0)` — entrada ágil que assenta com precisão.

| Interação do LIFTR | Propósito | Propriedade | Duração | Curva | Regra crítica |
|---|---|---|---|---|---|
| Incrementar `kg` / `reps` | Feedback tátil | Estado + haptic | `0ms` | — | Nunca atrasar toques consecutivos |
| Concluir série | Feedback | Estado + opacidade + haptic | `140ms` (`fast`) | `easeOutExpo` | Estado concluído visível sem depender da animação |
| Cronômetro de descanso | Transição de estado | Slide curto + opacidade | `220ms` (`standard`) | `easeOutExpo` | Cobrir 5 estados: `idle`, `running`, `paused`, `completed`, `dismissed` |
| Expandir exercício | Continuidade | Altura + rotação chevron | `220ms` (`standard`) | `easeOutExpo` | Interrompível ao tocar outro card |
| Abrir Bottom Sheet | Contexto espacial | Posição vertical | `260ms` (`emphasis`) | `easeOutExpo` | Preservar contexto subjacente |
| Concluir treino | Significado | Estado + escala sutil | `260ms` (`emphasis`) | `easeOutExpo` | Celebração contida; sem confete ou glow |

---

## 9. UX Writing, Data Viz, Resiliência, Mobile & Métricas

### 9.1 UX Writing (*Technical Humanism* — Cap. 21)
- **Tom:** direto, claro, humano e disciplinado. Sem jargões desnecessários, sem exclamação exagerada em cada título e sem culpar o usuário em erros.
- **Padrão por situação:**
  - *Erro de conexão / sync:* explicitar **(1) o que falhou**, **(2) que os dados continuam salvos localmente no aparelho** e **(3) qual a próxima ação** (`Tentar novamente` ou `Continuar offline`).
  - *Empty state:* declarar o que falta e oferecer o próximo passo direto (ex.: *"Nenhuma sessão concluída ainda. Conclua seu primeiro treino para acompanhar sua evolução."*).
  - *Ações destrutivas:* nome específico no verbo do botão (`Descartar treino`, `Remover exercício`), descrevendo a consequência antes da confirmação.

### 9.2 Visualização de Dados (Cap. 10 & 15)
- Todo gráfico deve responder a uma **pergunta clara** (ex.: *estou evoluindo carga/1RM neste exercício?* · *qual a tendência semanal do meu peso?* · *estou mantendo frequência mensal?*).
- Exibir explicitamente **métrica, unidade (`kg`, `séries`, `min`) e período selecionado**.
- **Acessibilidade além da cor:** diferenciar múltiplas séries por padrão de linha/ponto (linha contínua vs. tracejada/pontos discretos), usar legenda visível e fornecer `Semantics(label: ...)` resumindo a tendência em texto. Eixos sempre com fonte mínima `11sp` tabular.

### 9.3 UX Resiliente na Academia (Cap. 28)
1. **Perdeu internet:** sessão continua normalmente em SQLite/outbox local com banner discreto.
2. **Série registrada:** feedback visual e háptico instantâneo; proteção contra duplo clique em requisições em voo.
3. **App em segundo plano / fechado:** estado da sessão e timestamp do timer preservados.
4. **Falha parcial / conflito:** dados locais nunca são sobrescritos silenciosamente; pendências visíveis para reenvio automático ou manual ao reconectar.
5. **Matriz obrigatória de telas:** `Normal` · `No data (Empty)` · `Offline` · `Invalid input` · `Interrupted` · `Repeated action` · `Partial failure`.

### 9.4 Arquitetura Mobile & Telemetria UX Planejada (Cap. 29 & 31)
- **Navegação principal:** 3 destinos fixos enxutos (`Hoje` · `Treino` · `Progresso`), mantendo `WorkoutSessionScreen` em modo focado sem bottom bar competitiva.
- **Ergonomia:** ações críticas no terço inferior (alcance de uma mão); mínimo `48x48dp` de toque; `SafeArea` e comportamento explícito com teclado virtual aberto.
- **Taxonomia de eventos UX (Cap. 31 — futura instrumentação):**
  `workout_started` · `exercise_selected` · `set_logged` · `set_edit_requested` · `rest_timer_started` · `workout_completed` · `workout_abandoned`.
  - Métricas-chave acompanhadas: `Task Success Rate`, `Time on Task` (tempo para registrar uma série), `Error Rate`, `Abandonment` e `Retention` (North Star conceitual: sessões de treino concluídas e registradas com consistência por usuários ativos, respeitando privacidade e sem métricas manipulativas).
