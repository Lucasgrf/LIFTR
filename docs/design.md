# LIFTR — Sistema visual e plano de redesign por tela

> **Fonte visual principal do produto.** Define a direção apresentada em `files.zip` (`liftr-identidade-v3.html` e SVGs associados) e como aplicá-la às telas existentes. O escopo funcional é determinado pelo código, pelo PRD e pelas rotas atuais; este documento não torna funcionalidades futuras disponíveis.
>
> **Hierarquia das referências:** comportamento e escopo: código e `docs/PRD.md`; direção visual: este documento e `docs/design/brand-guide.md`; critérios de revisão: `docs/design/design-qa-checklist.md`; execução técnica: `AGENTS.md`. Se um documento antigo divergir da identidade descrita aqui, atualize-o para esta direção.

## 1. Produto e ideia visual

O LIFTR ajuda a decidir o que treinar, executar a sessão sem atrito, registrar o que aconteceu e entender a evolução. O principal contexto é a academia: atenção dividida, uso com uma mão, números que precisam ser lidos depressa e conexão que pode falhar.

A metáfora visual própria do produto é a **ficha de treino**:

- Uma sessão prescrita é uma ficha: o aplicativo escreve nome, ordem e faixas de trabalho.
- O usuário registra cargas, repetições e pesagens em “caneta”.
- Um treino concluído recebe o carimbo **Feito**.
- Um programa é um **baralho** de fichas em fila rotativa, sem agenda fixa por dia da semana.
- A **rampa** representa dupla progressão: repetições avançam dentro da faixa; ao alcançar o topo, a carga sobe e a faixa recomeça.

O resultado deve parecer um instrumento de treino pessoal bem editado, com referências a formulários impressos sem simular papel envelhecido. A composição é editorial e legível, com poucas superfícies, linhas de pauta discretas e cores usadas com significado.

## 2. Princípios da marca

- **Método antes de motivação:** apresentar a próxima ação, a prescrição e os dados antes de adjetivos ou celebrações.
- **Precisão acessível:** números e unidades claros, comparação fácil e explicação humana para recomendações.
- **Consistência sem culpa:** a fila gira; descanso e interrupções não são apresentados como falha moral.
- **Marca própria:** ficha, rampa, baralho e carimbo são os elementos distintivos. Evitar clichês de halteres, músculos, fogo, neon e dashboards genéricos.
- **Craft contido:** alinhar tipografia, linhas e controles com precisão. Usar movimento apenas para feedback, mudança de contexto ou conclusão significativa.

### 2.1 Voz

O LIFTR fala como quem preenche e explica a ficha: frase direta, verbo claro e números específicos. Não dá bronca, não promete resultado e não usa celebração exagerada.

| Evitar | Preferir |
|---|---|
| “Parabéns! Você arrasou!” | “Feito. 22 de 25 séries em 84 min.” |
| “Você está estagnado.” | “Rosca de punho está em 15 kg há 4 treinos.” |
| “Erro de sincronização.” | “Sem internet. O treino continua salvo neste aparelho.” *(somente após confirmar persistência local)* |
| “Iniciar treino” | “Começar Lower B” |

## 3. Identidade: rampa, wordmark e aplicações

### 3.1 Símbolo: a rampa

Usar o traço ascendente em degraus dos SVGs do pacote como símbolo proprietário. Ele condensa dupla progressão, em vez de representar genericamente um gráfico de analytics. Manter desenho geométrico simples, leitura em tamanhos pequenos, versão monocromática e contraste por contexto. Não inclinar ou redesenhar o símbolo como barras paralelas/monólito.

### 3.2 Wordmark

- Escrever **liftr** em minúsculas.
- Usar Familjen Grotesk como base, com desenho compacto e legível; os SVGs fornecidos são o ponto de partida para preservar o detalhe autoral do `f` e `t`.
- Refinar kerning e proporções opticamente, sem itálico esportivo ou códigos visuais de suplementos.
- Manter lockup horizontal e símbolo isolado. Preparar variantes para papel, ficha colorida e modo noite.
- Respeitar respiro ao redor da marca e nunca recompor o wordmark com fonte arbitrária na interface.

### 3.3 Ícone e aplicações

O ícone do app usa a rampa, sem wordmark. Preparar exportações vetoriais e raster nos tamanhos exigidos pelas plataformas, verificar legibilidade em miniatura e testar fundos papel, cartão e noite. A abertura pode desenhar a rampa uma única vez, com movimento curto e dispensável. Notificações e materiais externos devem manter as mesmas cores de papel e tinta.

**Refino de marca previsto:** revisar os quatro SVGs do pacote para limpar paths/viewBox, alinhamento, espessuras e área de proteção; conferir acessibilidade de contraste e renderização em tamanhos reais; registrar versões aprovadas e usos incorretos. Não criar novos conceitos de logo antes dessa revisão.

## 4. Sistema visual

### 4.1 Cores e papéis

As cores se dividem em base, tintas de autoria e cartões de treino. Cartões identificam uma ficha; não indicam sucesso, alerta ou erro.

| Token | Valor | Papel |
|---|---|---|
| Papel | `#F4F5F0` | Fundo claro principal |
| Papel secundário | `#E7E9E2` | Superfícies neutras secundárias |
| Grafite | `#17191E` | Texto e informação prescrita pelo app |
| Cinza | `#4F545C` | Texto auxiliar no tema claro; validar contraste por tamanho |
| Caneta | `#1C3FAA` | Cargas, repetições e dados inseridos pelo usuário no tema claro |
| Carimbo | `#B8281F` | Marca “Feito” no tema claro |
| Noite | `#151A2E` | Fundo do tema escuro |
| Noite elevada | `#1F2640` | Superfície neutra secundária escura |
| Texto noite | `#F4F5F0` | Texto principal no tema escuro |
| Texto auxiliar noite | `#A9B0C2` | Metadados no tema escuro |
| Caneta noite | `#8FA8FF` | Dados inseridos pelo usuário no tema escuro |
| Carimbo noite | `#FF8A7A` | Marca “Feito” no tema escuro |

| Cor do cartão | Valor | Identificação ilustrativa |
|---|---|---|
| Amarelo | `#F3D55B` | Ficha de treino |
| Lilás | `#CDB9E8` | Ficha de treino |
| Azul | `#A8C7EF` | Ficha de treino |
| Água | `#9ED9C9` | Ficha de treino |
| Salmão | `#F5A992` | Ficha de treino |

As cores de cartão devem manter texto legível e não podem ser o único identificador de um treino. Parear com nome e posição na fila. Status usam texto, ícone e/ou padrão; nunca inferir “subindo” ou “travado” pela cor do cartão.

O modo claro é a apresentação-base do conceito. No modo noite, o fundo muda para azul de tinta e **as fichas preservam a cor própria**. Não converter a interface inteira para uma tela preta com acento neon.

**Acessibilidade cromática:** conferir contraste WCAG AA para cada par de texto/superfície antes de codificar. A paleta do HTML é referência, não dispensa cálculo. Quando um par não cumprir contraste, ajustar o tom daquele papel ou trocar a cor do texto sem mudar o significado semântico da cor.

### 4.2 Tipografia e números

- Família principal: **Familjen Grotesk**, pesos 400, 500, 600 e 700, empacotada no app para funcionamento offline.
- Escala de referência do protótipo: `13`, `15`, `17`, `20`, `28`, `40` e `64sp`. Adaptar títulos grandes para largura disponível e escala de acessibilidade; não fixar alturas que cortem conteúdo.
- Números comparáveis e mutáveis usam algarismos tabulares: cargas, reps, séries, volume, duração, datas e gráficos.
- Usar caixa alta apenas para o carimbo quando necessário. Preferir títulos em caixa de frase.
- Confirmar licença, arquivo de fonte, pesos reais e fallback antes de incluir a família no pacote.

### 4.3 Geometria, pauta e superfícies

- Raios característicos do conceito: `6`, `12` e `20px`, aplicados com consistência; controles e cartões podem ter raios diferentes quando a função justificar.
- Linhas de pauta e divisores finos estruturam a ficha. Não colocar cada linha de uma lista dentro de um card separado.
- Fichas usam cor chapada e tipografia grafite; sugerem papel-cartão por forma, pauta e hierarquia — sem textura raster, papel amassado ou sombra pesada.
- A pilha de fichas pode aparecer como bordas escalonadas e discretas, preservando leitura e área de toque.
- A área útil deve respeitar SafeArea, teclado e largura estreita. Ações frequentes mantêm alvo mínimo de `48×48dp`, inclusive ícones compactos.

### 4.4 Ícones, gráficos e motion

- Ícones de UI mantêm grade e traço consistentes. Ícones de ação têm nome acessível e alvo de toque adequado.
- Gráficos respondem a uma pergunta. A rampa pode ser usada como visual de progressão; linha plana pontilhada pode indicar estabilidade. Sempre incluir texto, unidade, período e resumo acessível.
- O carimbo “Feito” é o principal momento de celebração visual. A rampa pode se desenhar na abertura. Trocas de estado e navegação usam transições curtas; steppers e registro de série respondem imediatamente.
- Toda animação respeita a preferência do sistema por movimento reduzido. O estado final continua compreensível sem animação.

## 5. Navegação e escopo do produto

O shell autenticado tem três destinos fixos: **Hoje**, **Treino** e **Progresso**. Perfil e Configurações são rotas secundárias. A sessão ativa é focada e não exibe a navegação inferior.

```text
Não autenticado: /login · /register · /reset-password · /onboarding
Hoje: /
Treino: /training · /training/new · /training/ai-generator · /training/:planId
  /training/:planId/add-workout · /training/:planId/workout/:workoutId
  /training/:planId/workout/:workoutId/add-exercise
  /training/:planId/workout/:workoutId/exercise/:exerciseId/configure-sets
Sessão: /session/:sessionId · /session/:sessionId/summary
Progresso: /history · /weekly-comparison
Biblioteca: /exercises · /exercises/new · /exercises/:exerciseId
Conta: /profile · /settings
```

O app prioriza treino, programa, execução, progressão e histórico. Nutrição detalhada, registro de refeições, peso enviado pelo WhatsApp e relatório semanal pertencem ao canal de WhatsApp no MVP. Não desenhar integração app/WhatsApp como disponível: o HTML contém aplicações externas e exemplos conceituais, mas o app ainda não tem vínculo sincronizado confiável.

## 6. Plano tela a tela

Para cada item, manter comportamento e dados existentes e aplicar a linguagem de ficha, papel e tinta. Desenhar os estados alternativos e overlays citados junto com o estado principal.

### A. Acesso e primeiros passos

1. **Login `/login`:** wordmark no topo, formulário sobre papel, campos e foco bem definidos, CTA grafite de alto contraste. Prever validação, loading, credenciais inválidas, confirmação pendente, offline e recuperação. A composição continua confortável com teclado aberto.
2. **Cadastro `/register`:** mesma estrutura do login; separar envio do estado “Confirme seu e-mail”. Usar copy concisa e manter retorno ao login.
3. **Redefinição `/reset-password`:** ficha de formulário curta; diferenciar link válido, expirado/ausente, senha divergente, envio e sucesso.
4. **Onboarding `/onboarding`:** sequência de fichas/formulários com indicador de progresso discreto. Preservar as seis etapas e valores ao voltar; não converter em calendário semanal fixo. Seleções por cartão/chip com estado textual claro.

### B. Shell, Hoje e fila

5. **Shell autenticado:** navegação inferior com Hoje, Treino e Progresso; seleção reconhecível por ícone preenchido/estado e rótulo. Banner de offline/sincronização acima do conteúdo quando necessário.
6. **Hoje `/`:** ficha principal do próximo treino, nome em destaque, posição no baralho, exercícios prescritos e últimas cargas registradas em caneta. Abaixo: fichas seguintes em bordas escalonadas, resumo da semana, último treino e no máximo um insight. CTA fixo “Começar [treino]”. Criar estados com/sem treino, sessão em andamento, offline e dados parciais.
7. **Escolher treino de hoje (sheet):** lista de fichas com posição, nome e resumo; ação explícita para mover a ficha atual ao fim da fila. Troca selecionada reflete imediatamente cor/nome no CTA, com confirmação apenas se exigida pela regra atual.
8. **Primeiro acesso/Hoje vazio:** ficha em branco com pauta e explicação breve; ações para montar programa ou colar/importar código compatível. Não usar ilustração genérica.

### C. Treino, programas e prescrição

9. **Lista de programas `/training`:** baralho aberto, primeira ficha em evidência e demais posições ordenadas. Reordenação tem modo e alças explícitos; cor identifica programa/ficha. Incluir vazio, loading, troca de programa, ações de IA/importar/exportar.
10. **Criar programa `/training/new`:** formulário editorial simples com nome, descrição e escolha de ativação. Separar criação de programa da adição de sessões.
11. **Detalhe do programa `/training/:planId`:** cabeçalho e resumo do programa, fichas ordenadas por fila, volume muscular em apresentação neutra e ação para adicionar sessão. Troca de ativo explica consequência e estados de sucesso/rollback.
12. **Adicionar sessão `/training/:planId/add-workout`:** ficha de formulário com nome, posição, duração e orientações; validação junto ao campo e preservação do rascunho.
13. **Prescrição `/training/:planId/workout/:workoutId`:** uma ficha/tabela agrupada, cabeçalho único e linhas separadas por pauta. Exercício, ordem, séries, faixa, RIR e descanso sem “cardite”. Ação de iniciar fica acessível sem encobrir a lista.
14. **Adicionar exercício `/training/:planId/workout/:workoutId/add-exercise`:** biblioteca pesquisável com filtros e diagramas; após seleção, configuração de aquecimento/séries válidas antes de confirmar. Estado selecionado explícito.
15. **Configurar séries `.../configure-sets`:** linhas de prescrição editáveis sobre superfície única. Distinguir aquecimento e séries válidas por rótulo/ícone, não pela cor do cartão. Para cardio, usar “Duração mínima/máxima” com `min`.
16. **Gerador IA `/training/ai-generator`:** wizard de fichas curtas para foco, equipamento, rotina, prioridades, restrições e revisão. Geração comunica etapas reais, sem porcentagem de certeza inventada. Resultado apresenta fichas editáveis e ações aplicar, gerar outra opção ou ajustar.
17. **Importar, exportar e trocar programa (sheets):** aplicar folhas sobre o contexto atual, preview antes de confirmar, feedback de progresso e saída de cancelamento/erro. Export de programa permanece distinto do JSON de dados pessoais.

### D. Sessão ativa e conclusão

18. **Sessão `/session/:sessionId`:** tela focada sem barra inferior. Cada exercício expande como uma seção de ficha; prescrição em grafite, carga/reps preenchidas em caneta. Priorizar steppers, ação “Feita”, aquecimento e série válida. Conservar timer, autosave e uso offline. Conclusão compacta da série não oculta a capacidade de editar/desfazer.
19. **Trocar exercício (sheet):** busca e alternativas numa folha; indicar exercício atual, alvo/equipamento e efeito da troca. Exigir confirmação explícita quando houver incompatibilidade/impacto.
20. **Finalizar sessão (sheet/diálogo):** resumo simples do que será fechado e coleta de percepção prevista. Rascunho inválido oferece corrigir ou descartar, nunca é removido silenciosamente.
21. **Resumo `/session/:sessionId/summary`:** ficha preenchida com “Feito” carimbado, duração, séries, volume e dados disponíveis. Melhoras registradas em caneta e cálculos em grafite. Animação do carimbo curta, opcional e sem confete. Informar sincronização pendente só com base no estado real.
22. **Descartar treino/confirmar saída:** diálogo direto com nome da ação, consequência e retorno seguro à sessão.

### E. Progresso e cardio

23. **Progresso `/history` — Exercícios:** listas sem cards repetidos; cada linha mostra exercício, carga/faixa, resumo de tendência em texto e mini-rampa. Platô usa traço plano/pontilhado e rótulo, não cor de alerta.
24. **Progresso — Peso:** métrica principal, tendência explicada, período e gráfico em caneta. A faixa de meta pode usar hachura com legenda. Estados vazio, um ponto e série suficiente; CTA respeita a fonte de registro atual.
25. **Progresso — Consistência:** calendário com dias e iniciais/carimbo da ficha concluída; explicar período e múltiplas sessões por dia. Sem heatmap arco-íris e sem linguagem de culpa.
26. **Progresso — Treinos:** histórico cronológico de fichas concluídas com data, duração e resumo; abrir detalhe existente. Essa vista não está desenhada no HTML e deve seguir os padrões de registro e carimbo já definidos.
27. **Histórico de exercício (sheet/modal):** nome, período, gráfico com unidade e sessões cronológicas. Diferenciar registros do usuário de referência/calculado.
28. **Comparação semanal `/weekly-comparison`:** duas fichas/períodos comparáveis, indicadores explícitos de igualdade/variação, unidades e texto explicativo. Semana futura e falta de comparação recebem estados próprios.
29. **Registrar cardio (sheet/modal):** formulário curto de modalidade, duração e data/hora; unidade e teclado adequados; feedback salvo/offline.

### F. Biblioteca de exercícios

30. **Biblioteca `/exercises`:** catálogo em lista pautada, busca, filtros e botão de criar. Diagramas em SVG seguem o sistema existente; não inventar novo estilo de ilustração nesta etapa. Estados de busca vazia distintos de biblioteca vazia.
31. **Detalhe `/exercises/:exerciseId`:** diagrama, nome, músculo e equipamento; instruções e notas em blocos editoriais. A origem do exercício e o efeito de edição ficam explícitos.
32. **Criar exercício `/exercises/new`:** formulário agrupado em seções numa superfície de ficha; campos longos, validações e unidades sem alturas fixas.

### G. Perfil e configurações

33. **Perfil `/profile`:** composição editorial com avatar, nome, objetivo e resumo de dados. Edição de dados corporais continua em sheet, com privacidade e unidades.
34. **Dados corporais (sheet):** inputs de sexo, peso, altura, idade e percentual opcional; informar faixas aceitas e evitar duplicar pesagem do dia.
35. **Configurações `/settings`:** lista agrupada por Treino, Aparência, Dados e Conta. Linhas com divisores discretos, seleção atual visível e salvamento persistente.
36. **Sheets de descanso, incrementos e tema:** valores como opções claras com foco selecionado; tema explica papel/noite sem distorcer as cores das fichas.
37. **Exportar dados:** exibir que é informação pessoal, preview legível e ação copiar. Não misturar com compartilhamento de ficha/programa.
38. **Sair, foto e outras confirmações:** diálogos compactos, ação nomeada e consequência antes de confirmar; opções não destrutivas são fáceis de alcançar.

### H. Futuro separado do app atual

As propostas abaixo devem ficar numa seção identificada **FUTURO / NÃO IMPLEMENTADO**. Não apresentá-las em rotas existentes nem como integração ativa: medidas corporais por data, fotos de progresso, calendário unificado, insights detalhados, integração WhatsApp Coach no app, Health Connect/HealthKit, deload/periodização, novos modelos de séries, 1RM estimado, relatório mensal, CSV e exclusão de conta/dados. Nutrição e registro conversacional continuam no fluxo de WhatsApp, fora do app no MVP.

## 7. Plano de implementação por fases

1. **Fase 0 — Fundação aprovada:** revisar marca e SVGs; decidir cores/tokens com testes de contraste; empacotar Familjen Grotesk; definir cartões semânticos, pauta, carimbo, rampa e modo noite.
2. **Fase 1 — Primitivas:** tema, tipografia, formulários, linhas/listas, cartões de ficha, botões, sheets, calendário, mini-rampa, carimbo, estados offline/erro/vazio/loading e navegação.
3. **Fase 2 — Fluxo principal:** Hoje, seleção de treino, programa/fila, prescrição, sessão ativa e resumo. Validar que o registro segue imediato e offline-first.
4. **Fase 3 — Progresso e biblioteca:** quatro vistas de progresso, comparativos, cardio, biblioteca, detalhe e criação de exercício.
5. **Fase 4 — Acesso e conta:** login, cadastro, redefinição, onboarding, perfil e configurações.
6. **Fase 5 — Revisão transversal:** revisar cada tela/overlay do mapa, contrastes, conteúdo longo, escalas de texto, modo noite, semantics, teclado, estados e consistência da identidade. Registrar lacunas como itens do roadmap, não como funcionalidades existentes.

Cada fase de código deve ser entregue em mudanças pequenas por fluxo, com comparação antes/depois, screenshots de ambos os temas e revisão do checklist de design. A sequência orienta implementação futura; este documento não altera o app por si só.

## 8. Requisitos transversais de UX e aceite

- Preservar todas as regras atuais de produto, a rotação do baralho e os dados já registrados.
- Offline-first: persistir localmente antes de afirmar que o registro está salvo; mostrar falha e sincronização sem bloquear treino.
- Prevenir duplo registro; não sobrescrever dados localmente modificados sem informar.
- Estados por fluxo: normal, carregando, vazio, erro, offline/pendente, inválido, desabilitado, sucesso e interrupção quando aplicável.
- Alvos interativos de pelo menos `48×48dp`, semântica explícita, contraste validado, significado que não dependa apenas de cor e suporte a `320dp` e escala de texto `1.3×`.
- PT-BR, pluralização correta, unidades explícitas e números tabulares.
- Compor para toque com uma mão, teclado aberto, nomes longos e números grandes.
- Respeitar redução de movimento. Série concluída e alteração numérica não podem depender de animação para parecer imediatas.

## 9. Referências do projeto

- Fonte visual recebida: `files.zip` — `liftr-identidade-v3.html`, `liftr-marca.svg`, `liftr-marca-noite.svg`, `liftr-simbolo.svg`, `liftr-icone.svg`.
- Marca e tokens: `docs/design/brand-guide.md`.
- Práticas de crítica: `docs/design/anti-ai-slop-playbook.md` e `docs/design/design-qa-checklist.md`.
- Auditoria e dívida de interface: `docs/design/frontend-audit-summary.md`, `docs/design/technical-debt.md`.
- Produto e arquitetura: `docs/PRD.md`, `app/lib/routing/app_router.dart` e implementações em `app/lib/features/**/presentation/`.
