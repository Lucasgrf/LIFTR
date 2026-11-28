# LIFTR — Guia de marca e sistema visual

> Guia operacional resumido. A especificação e o plano tela a tela estão em [`docs/design.md`](../../docs/design.md). A referência visual original está em `files.zip` (`liftr-identidade-v3.html` e os quatro SVGs de marca). Em caso de divergência visual, seguir `docs/design.md` e atualizar este guia.

## 1. Essência e personalidade

- **Essência:** treino com método e evolução que se entende.
- **Personalidade:** precisa, direta, acessível, sem julgamento e sem exagero motivacional.
- **Metáfora:** ficha de treino escrita pelo app, preenchida pelo usuário e carimbada ao concluir. A fila de fichas gira como um baralho; não depende de calendário semanal fixo.
- **Tom:** números antes de adjetivos, verbo claro e próximo passo explícito. Nunca culpar o usuário ou prometer resultado.

## 2. Elementos proprietários

### Rampa

O símbolo de marca é a linha ascendente em degraus dos arquivos `liftr-simbolo.svg` e `liftr-icone.svg`. Ela representa dupla progressão: reps sobem dentro da faixa e a carga avança ao chegar ao topo. Preservar o desenho de origem e sua leitura em tamanho pequeno. Não substituir por monólito, halter, músculo, folha ou gráfico genérico.

### Wordmark

Usar `liftr` em minúsculas. Os SVGs `liftr-marca.svg` e `liftr-marca-noite.svg` são as referências de lockup. Manter Familjen Grotesk como família da identidade e refinar kerning, proporção e alinhamento sem aparência de marca de suplemento ou automobilismo. Não reconstruir o wordmark com texto de sistema.

### Uso da marca

- Símbolo isolado para ícone/situações compactas; lockup horizontal quando houver espaço.
- Manter área de respiro; testar positivo e negativo sobre papel, ficha e noite.
- Revisar `viewBox`, bounds, path, peso visual, legibilidade em miniatura, exportações iOS/Android e contraste antes de atualizar assets do app.
- A animação da rampa na abertura é opcional, breve e respeita movimento reduzido.

## 3. Cores e significado

| Papel | Claro | Noite |
|---|---|---|
| Fundo | Papel `#F4F5F0` | Azul noite `#151A2E` |
| Superfície secundária | Papel `#E7E9E2` | Noite elevada `#1F2640` |
| Texto | Grafite `#17191E` | Papel `#F4F5F0` |
| Texto auxiliar | Cinza `#4F545C` | `#A9B0C2` |
| Dados inseridos pelo usuário | Caneta `#1C3FAA` | Caneta noite `#8FA8FF` |
| Conclusão | Carimbo `#B8281F` | Carimbo noite `#FF8A7A` |

**Cartões de treino:** amarelo `#F3D55B`, lilás `#CDB9E8`, azul `#A8C7EF`, água `#9ED9C9` e salmão `#F5A992`. A cor distingue fichas; não significa status. Sempre exibir junto nome/ordem. Estados usam texto, ícone e/ou padrão além da cor.

Validar contraste WCAG AA de cada combinação antes da implementação. Se uma combinação falhar, ajustar o tom usado para texto ou superfície. Não assumir que a paleta do HTML por si só comprova acessibilidade. O tema noite usa fundo azul de tinta; as fichas coloridas mantêm a identidade.

## 4. Tipografia, forma e composição

- **Família:** Familjen Grotesk, pesos 400/500/600/700, empacotada para uso offline após confirmar licença e arquivos.
- **Escala de referência:** `13 / 15 / 17 / 20 / 28 / 40 / 64sp`; adaptar a largura, conteúdo e escala de texto, sem clipping.
- **Números:** algarismos tabulares para carga, reps, séries, tempo, volume, datas, percentuais e eixos.
- **Raios:** `6 / 12 / 20px` como escala da direção visual. Reservar pílula/círculo para avatar ou caso funcional apropriado.
- **Pauta:** divisores discretos, linhas de ficha e superfícies chapadas. Evitar card para cada linha, textura literal de papel e sombra pesada.
- **Ficha:** cartão colorido, texto prescrito em grafite, registros em caneta e carimbo de conclusão.
- **Baralho:** bordas escalonadas discretas comunicam a fila. A posição e o nome continuam visíveis sem depender da cor.

## 5. Componentes e arquitetura

1. **Fundação:** tokens de papel/noite/cartões/tintas, Familjen Grotesk, espaçamento, raios, motion, rampa e wordmark.
2. **Core UI:** botões, campos, linhas agrupadas, divisores, sheets, navegação, feedback offline/loading/empty/error. Widgets de `app/lib/core/widgets/` permanecem agnósticos de domínio e não importam `features/**`.
3. **Padrões de produto:** ficha/baralho, linha de prescrição e registro, stepper, mini-rampa, calendário carimbado, resumo e gráficos.
4. **Templates:** acesso, Hoje, planejamento, sessão focada, progresso, biblioteca e perfil/configurações.

Antes de criar um componente, procurar o equivalente existente, definir seus estados e validar conteúdo longo, ambos os temas e dimensões de toque. Dados e registros atuais não devem mudar por uma troca visual.

## 6. Movimento e interação

- Registro de série e stepper são imediatos e não podem aguardar animação.
- Rampa na abertura e carimbo ao concluir podem receber motion curto, cada um com propósito único.
- Outras transições devem ser breves, interrompíveis e preservar o estado final quando movimento estiver reduzido.
- Nenhum estado crítico depende de animação, háptica ou cor para ser compreendido.

## 7. Acessibilidade e resiliência

- Alvo de interação mínimo `48×48dp`, rótulos semânticos e foco visível.
- Validar contraste WCAG AA, leitores de tela, conteúdo PT-BR longo, viewport `320dp` e escala de texto `1.3×`.
- Estados conectados a dados cobrem loading, vazio, erro, offline/pendente, inválido, sucesso e desabilitado conforme o fluxo.
- Preservar offline-first, autosave e proteção contra duplo registro. Só afirmar que algo foi salvo localmente após confirmação da persistência.

## 8. Revisão de marca prevista

A revisão visual mantém a rampa e o wordmark enviados, conferindo paths, área de proteção, pesos, kerning, contraste, ícone e usos em tela. O pacote não autoriza inventar logotipo, integração ou capacidade funcional. Mudanças aprovadas nos SVGs precisam ser incluídas em commit próprio e refletidas nos assets Android/iOS correspondentes.
