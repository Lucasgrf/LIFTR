# LIFTR — direção visual e implementação tela a tela

> **Referência visual obrigatória:** `liftr-identidade-v3.html`, fornecido pelo usuário em `Videos/LIFTR/files`. Este HTML define a composição, tipografia, cores, marca, controles, textos de exemplo, estados e proporções do app. Em caso de divergência, corrigir o app e este documento para refletir o HTML. O arquivo não é uma inspiração genérica: suas telas devem ser reproduzidas visualmente.

## 1. Objetivo e critério de parada

Reimplementar as telas do app para que a apresentação corresponda ao HTML, sem preservar componentes do design anterior apenas por conveniência. A referência de comparação das telas móveis é um viewport de **390 × 844 px**, com largura útil de 390 px, tipografia Familjen Grotesk e conteúdo em português.

O trabalho só pode ser considerado pronto quando cada tela do HTML e cada rota existente tiver sido capturada no mesmo tamanho, revisada lado a lado e ajustada. A hierarquia, alinhamento, tamanho, cor, espaçamento, raios, ícones, textos e comportamento visível precisam coincidir com a referência. Uma tela apenas “inspirada” no HTML não atende ao pedido. Não fazer merge enquanto houver diferença visual pendente.

Nas telas sem equivalente explícito no HTML, reaproveitar diretamente seus padrões: papel claro/noite, ficha colorida, linhas de pauta, tinta azul para entradas do usuário, carimbo de conclusão, lista editorial, folhas de seleção e navegação inferior. A tela nova deve parecer uma continuação do mesmo app, sem componente visual do design antigo.

## 2. Fundamentos extraídos do HTML

### 2.1 Marca

- Nome escrito `liftr`, sempre em minúsculas.
- Símbolo: rampa ascendente em três degraus, conforme o SVG embutido no HTML. Preservar path, proporção, peso e terminais arredondados.
- Wordmark: desenho vetorial embutido no símbolo `#wm`; não substituir por texto digitado nem por fonte de sistema.
- Lockup: símbolo e wordmark horizontal quando houver espaço; símbolo isolado em ícone compacto.
- A rampa representa a progressão dupla. Não usar halteres, músculos, gráficos genéricos ou outros símbolos no lugar da marca.
- Ajustar exportações Android/iOS para corresponder aos vetores do HTML. Validar área de proteção, alinhamento e leitura em tamanho real.

### 2.2 Paleta e semântica

| Papel | Claro | Noite |
|---|---|---|
| Fundo | `#F4F5F0` | `#151A2E` |
| Superfície secundária | `#E7E9E2` | `#1F2640` |
| Texto principal | `#17191E` | `#F4F5F0` |
| Texto auxiliar | `#4F545C` | `#A9B0C2` |
| Tinta do usuário | `#1C3FAA` | `#8FA8FF` |
| Carimbo | `#B8281F` | `#FF8A7A` |
| Botão primário | `#17191E` | `#F4F5F0` |
| Texto do botão primário | `#F4F5F0` | `#151A2E` |

Fichas: amarelo `#F3D55B`, lilás `#CDB9E8`, azul `#A8C7EF`, água `#9ED9C9` e salmão `#F5A992`. A cor identifica o treino, nunca seu estado ou resultado. Fichas coloridas continuam coloridas no tema noite.

### 2.3 Tipografia, geometria e ritmo

- Familjen Grotesk 400/500/600/700, incluída no app para uso offline.
- Escala do HTML: `13 / 15 / 17 / 20 / 28 / 40 / 64 px`; números comparáveis usam algarismos tabulares.
- Raios do HTML: `6 / 12 / 20 px`; pílula apenas quando a função pedir.
- Fundo fosco e chapado; linhas de pauta discretas. Sem gradiente decorativo, glow, sombras pesadas, moldura em cada linha ou cards repetidos.
- Botão primário tem 56 px de altura e raio 12 px. Ícone compacto tem desenho de contorno com traço 1,5 px. Foco usa contorno de 2 px na tinta.
- Nav inferior tem três destinos: Hoje, Treino, Progresso; ícone e rótulo, sem indicador de seleção separado do desenho/contraste do destino.
- Alvos Flutter continuam com pelo menos 48 dp; acomodar o alvo sem alterar a geometria visual do ícone.

### 2.4 Padrões de conteúdo

- **Ficha:** cartão chapado com nome, ordem na fila, dados prescritos em grafite e registro anterior em tinta azul.
- **Pauta:** linhas finas separam exercícios e períodos, em vez de cartões individuais.
- **Baralho:** cartões coloridos sobrepostos verticalmente, com ordem explícita e primeira ficha em evidência.
- **Carimbo:** contorno duplo vermelho, inclinação de −8°, “Feito” e data; animação breve somente ao concluir.
- **Progresso:** rampa por exercício; calendário com iniciais do treino concluído; peso em tinta azul e faixa da meta hachurada.
- **Voz:** direta e descritiva, sem culpa, grito motivacional, emoji decorativo ou promessa de resultado.

## 3. Telas explícitas do HTML — reprodução obrigatória

As telas abaixo são os alvos visuais de referência. Implementar estados equivalentes com dados reais da aplicação; os nomes e números do protótipo servem para comparação inicial.

| Tela do HTML | Estrutura visual e comportamento a reproduzir | Rota/área Flutter |
|---|---|---|
| **Hoje** | Data e ações de perfil/configuração no topo; ficha colorida com posição, estado “próxima da fila”, título grande, resumo, três exercícios com prescrição em grafite e último registro em azul, pilha das próximas fichas, último treino, semana carimbada, cardio, CTA fixo e nav inferior. Rolagem preserva o dock. | `/` |
| **Escolher a ficha de hoje** | Folha sobe sobre Hoje; scrim escuro; puxador; título e fechar; “Pular” move a primeira ao fim; lista de fichas coloridas sobrepostas e seleção por rádio, ordem e resumo visíveis. Seleção troca ficha, borda do baralho e CTA. | sheet de `/` |
| **Ficha completa** | Voltar e editar no topo; uma ficha amarela com título e foco; tabela única com Exercício/Série/Reps/Carga, cabeçalho uma vez e grupos separados por pauta; CTA fixo e nav inferior. | detalhe de `/training/:planId/workout/:workoutId` |
| **Registro do treino** | Data e voltar; ficha salmão com posição, duração, título, resumo, carimbo “Feito”, linhas de exercícios com carga total em grafite e registros em azul; nota de comparação e sincronização. | `/session/:sessionId/summary` |
| **Treino** | Título, programa ativo e trocar programa; seção “O baralho”; primeira carta mais alta, restantes parcialmente sobrepostas, ordem/nome/resumo e alça de reordenação; trocar cor; ações Nova ficha/Compartilhar; nav inferior. | `/training` |
| **Progresso — Exercícios** | Título e tabs sublinhadas; explicação curta da rampa; filtros compactos; linhas sem card, exercício/carga/faixa/status textual à esquerda e rampa à direita. Travado usa linha plana pontilhada, sem cor de alerta. | `/history`, aba Exercícios |
| **Progresso — Consistência** | Título e tabs sublinhadas; resumo semanal/mensal e explicação; mês com calendário e iniciais dentro de carimbos circulares. | `/history`, aba Consistência |
| **Progresso — Peso** | Título/tabs; peso grande em tinta; tendência e intervalo-alvo; filtros de período; superfície para gráfico e estado de amostra insuficiente; faixa hachurada; ação de registro preservando fonte/capacidade real. | `/history`, aba Peso |
| **Hoje — tema noite** | Mesma composição de Hoje, fundo azul-noite, superfícies elevadas noturnas, tinta clara, carimbo claro e fichas mantendo cores originais. | `/` no tema escuro |
| **Primeiro acesso** | Data/perfil; mensagem “Nenhuma ficha ainda”; ficha sem cor preenchida com pauta e explicação; botões “Montar programa” e “Colar código de programa”; nav inferior. | `/` e estado vazio de `/training` |
| **Abertura** | Fundo papel, rampa desenhada sobre pauta e wordmark vetorial abaixo; duração inferior a um segundo e sem animação quando movimento estiver reduzido. | splash nativo/app start |

O HTML também apresenta notificação, cartão de compartilhamento e mensagem gerada como exemplos externos. Eles orientam os assets e textos correspondentes, mas não criam uma integração nova no app. Notificações devem usar nome da ficha e meta de progressão verificável; compartilhamento de programa mantém baralho colorido e wordmark; mensagem é escrita na voz da pessoa que compartilha.

## 4. Plano para todas as rotas e superfícies existentes

### Acesso e primeiros passos

- **Login `/login`:** usar fundo papel, wordmark vetorial, título editorial, campos sobre superfície neutra, linhas/contorno de foco na tinta e botão primário grafite. Preservar validação, loading, erro, recuperação e teclado; não reutilizar cabeçalho ou cartões do design antigo.
- **Cadastro `/register`:** mesma família de formulário do login, hierarquia/tamanhos e estados; confirmação de e-mail em superfície textual clara.
- **Redefinição `/reset-password`:** formulário curto no mesmo template, estados de link inválido, loading, sucesso e recuperação.
- **Onboarding `/onboarding`:** fichas de formulário pautadas, uma pergunta principal por etapa, escolhas com papel-cartão/chips do HTML e progresso discreto. Preservar conteúdo e valores ao voltar.

### Hoje, treino e programa

- **Shell autenticado:** reproduzir os três itens do dock do HTML e o fundo do app. Banner offline/atualização ocupa uma linha editorial acima do conteúdo, sem cartão decorativo e sem deslocar o dock de forma inconsistente.
- **Hoje `/`:** reproduzir a tela explicitamente; manter ordem rotativa e CTA conectado ao treino real. Em vazio, aplicar ficha pautada em branco e ações do protótipo.
- **Ficha completa:** converter detalhe do treino numa tabela agrupada dentro de uma ficha, com o cabeçalho uma vez; manter editar/iniciar e dados reais.
- **Lista de programas `/training`:** aplicar o baralho do HTML. Reordenação atual continua funcional por alça; cor de cada ficha pode ser alterada sem mudar significado de status. Exportar, importar e IA ficam como ações secundárias de texto/linha.
- **Criar programa `/training/new`:** formulário em papel com campos pautados, seleção de ativação explícita e CTA primário; remover cards de formulário repetidos.
- **Detalhe do programa `/training/:planId`:** título e metadados na composição de Treino; sessões em baralho colorido, resumo de volume como lista e ação de adicionar ficha.
- **Adicionar sessão `/training/:planId/add-workout`:** formulário pautado com nome, ordem, duração e orientação; preservar rascunho e erros junto aos campos.
- **Adicionar exercício `/training/:planId/workout/:workoutId/add-exercise`:** catálogo em lista editorial, busca/filtros como chips do HTML; diagramas SVG existentes mantêm desenho e cores, sem card por exercício.
- **Configurar séries `.../configure-sets`:** uma ficha com colunas/linhas para aquecimento, séries válidas, repetições, carga, descanso e RIR; diferenciação textual, sem cartões para cada série.
- **Gerador IA `/training/ai-generator`:** dividir fluxo existente em fichas simples no mesmo sistema; seleções com chips/linhas e resultado em lista de fichas editáveis; manter todas as capacidades e estados reais, sem porcentagens inventadas.
- **Importar/exportar/trocar programa:** sheets no padrão da folha de Hoje: puxador, título, fechar, conteúdo em pauta, ação primária e feedback claro.

### Sessão e registro

- **Sessão ativa `/session/:sessionId`:** tela focada sem dock; cabeçalho curto e uma seção pautada por exercício, prescrição em grafite e valores registrados em tinta. Steppers continuam imediatos; timer, autosave e offline preservados.
- **Trocar exercício:** folha no mesmo padrão de seleção, com busca e alternativas em linhas agrupadas.
- **Finalizar/descartar:** diálogo curto com texto, consequência e ação nomeada; seguir cor de botão primário/secundário do HTML.
- **Resumo `/session/:sessionId/summary`:** usar a tela Registro do HTML e seus dados reais, carimbo, pautas, comparação e sincronização.

### Progresso, biblioteca e conta

- **Progresso `/history`:** tabs horizontais sublinhadas como `.tabs` do HTML, não controle segmentado em cápsula. Implementar as quatro vistas: Exercícios com rampa, Peso com hatch/linha, Consistência com calendário carimbado e Treinos como lista cronológica de fichas concluídas (essa quarta vista não está desenhada e deve usar Registro do treino como referência).
- **Histórico de exercício:** sheet com cabeçalho editorial, período em chips e gráfico de linha/rampa em tinta, unidade e sessões em pauta.
- **Comparação semanal `/weekly-comparison`:** duas listas de fichas/períodos com números tabulares, divisores e texto de variação; não converter em mosaico de cards.
- **Registrar cardio:** sheet com campos em papel, duração/unidade, data e confirmação; sem estimar/sugerir conexão que não exista.
- **Biblioteca `/exercises`:** busca e filtros como chips, lista pautada e ilustrações existentes; vazio e busca vazia seguem ficha em branco e texto do HTML.
- **Detalhe/criar exercício:** conteúdo editorial com diagrama, instruções e notas; formulário com campos agrupados por divisores, validações próximas ao campo.
- **Perfil `/profile`:** nome/avatar e dados em linhas/editorial; dados corporais editados em sheet, sem card para cada métrica.
- **Configurações `/settings`:** grupos de linhas em superfície secundária com divisores; opções de aparência, descanso, incrementos, conta e dados mantêm estados selecionados visíveis.
- **Tema claro/noite:** o HTML define visual exato de Hoje nos dois temas. Aplicar as mesmas cores, superfícies, tipografia, borda e tintas a todas as outras rotas.
- **Exportar dados, seleção de foto e confirmações:** manter interações existentes usando sheets/diálogos e campos/lists do mesmo sistema. Não prometer integrações futuras.

## 5. Plano de execução e commits

1. **Referência e marca:** medir as telas do HTML, atualizar este documento, comparar paths da rampa/wordmark, alinhar SVGs e ícone de app. Commit independente.
2. **Fundação visual:** corrigir tema, escala tipográfica, botões, campos, linhas, tabs, dock e sheets para equivalência ao HTML. Commit independente.
3. **Hoje e baralho:** implementar Hoje, troca de ficha, estado vazio, fila e detalhe de prescrição com dados/provedores existentes. Commits por tela/fluxo.
4. **Sessão e registro:** alinhar sessão ativa, sheets de troca/finalização e resumo com pauta, caneta e carimbo. Commits por fluxo.
5. **Progresso:** implementar tabs sublinhadas, rampas, calendário e gráfico de peso; adicionar consistência à quarta aba sem equivalente visual exato no HTML, seguindo seus padrões. Commits por vista.
6. **Demais rotas:** alinhar onboarding/autenticação, formulários, biblioteca, perfil/configurações, comparação, cardio e gerador. Commits por domínio.
7. **Comparação e revisão:** capturar cada rota em `390×844`, comparar lado a lado com a tela correspondente ou seu padrão mais próximo, corrigir diferença visual e estados responsivos. Só abrir PR com evidência visual e lista das rotas verificadas.

## 6. Hard gate visual e funcional

- Capturas do HTML e Flutter na mesma resolução, densidade e estado; registrar uma captura por rota e tema aplicável.
- Conferir alinhamento de conteúdo, dimensões, cores, fonte/peso, texto, espaçamento, raio, ícones, pauta, dock, sheets e posição de CTA.
- Não aceitar componentes Material genéricos onde o HTML usa desenho próprio, linhas editoriais ou ficha. Não manter elemento do design anterior se divergir.
- Testar telas sem plano/dados, loading/erro/offline, treino ativo, texto ampliado, teclado e viewport estreito depois de atingir a composição-base.
- Preservar navegação, estado local, persistência offline-first, semântica, alvos acessíveis e ausência de duplicação de registros.
- PR pode ser aberto após a implementação e review; merge só depois de todas as diferenças visuais bloqueantes e não bloqueantes terem sido resolvidas. Uma diferença visível significa que ainda não se atingiu o ponto de parada.

## 7. Fontes de projeto

- Referência pixel a pixel: `liftr-identidade-v3.html` fornecido pelo usuário.
- Regras de marca e os sete estudos: [`docs/design/brand-guide.md`](design/brand-guide.md) e [`docs/design/anti-ai-slop-playbook.md`](design/anti-ai-slop-playbook.md).
- Crítica e QA: [`docs/design/design-qa-checklist.md`](design/design-qa-checklist.md).
- Rotas: [`app/lib/routing/app_router.dart`](../app/lib/routing/app_router.dart).
