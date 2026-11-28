# Playbook de design e craft — LIFTR

Este playbook traduz para Flutter os princípios das sete referências usadas no estudo do LIFTR. Ele apoia a direção visual vigente em [`docs/design.md`](../../docs/design.md); não substitui o briefing, o produto ou as regras de acessibilidade.

> `skills/` na raiz é reservado às skills de runtime do WhatsApp em Deno. Mantenha práticas de design e instruções de frontend em `docs/design/` e `AGENTS.md`.

## 1. Referências aplicadas

### ThinkUI

Começar pela tarefa real e pelo contexto de uso. Para o LIFTR: encontrar a próxima ficha, ler prescrição, registrar série com uma mão e retomar offline. Usar estruturas consistentes e SVGs limpos; não importar template SaaS genérico.

### Anti UI Slop

- **Antes de construir:** ler marca, rotas, tokens e componentes existentes; listar estados antes do layout principal.
- **Ao modificar:** preservar contratos de domínio e comportamento persistente.
- **Ao polir:** remover ruído, cardite, desalinhamentos e hierarquias que dificultem leitura rápida.
- **Ao simplificar:** revelar dados secundários por etapa, sem esconder ação importante.
- **Ao revisar:** conferir contraste, overflow, toque, semântica, erros, vazios e offline.

### Taste Skill

Manter as escolhas de taste coerentes com o modelo de ficha:

- `DESIGN_VARIANCE = 3/10`: posição previsível para ações repetidas de treino.
- `MOTION_INTENSITY = 2/10`: movimento raro, rápido e funcional.
- `VISUAL_DENSITY = 6/10`: listas e métricas escaneáveis; espaço em torno de ações primárias.

Evitar padrões genéricos, paleta de status sem semântica, cards idênticos em grade e variações sem justificativa de função.

### Emil Design Engineering

Antes de animar, perguntar: com que frequência a ação ocorre, qual é seu propósito, a interação continua disponível e como o sistema de movimento reduzido será respeitado? Stepper e registro de série são imediatos. Rampa de abertura e carimbo de conclusão são os momentos de marca previstos. Ao revisar um componente, registrar **Antes / Depois / Por quê**.

### Vercel Web Design Guidelines

Aplicar à UI Flutter: semântica nomeada, áreas de toque adequadas, contraste validado, layout elástico, textos escaláveis, estados completos, pluralização e mensagens recuperáveis. Gráficos expõem unidade, período, legenda e descrição textual.

### Impeccable

Usar vocabulário e revisão deliberada para avaliar hierarquia, ritmo, densidade, voz e padrões repetidos. Cada refinamento deve responder a um problema observado e respeitar a ficha, a rampa e o baralho do LIFTR; os comandos não são justificativa para trocar a direção visual.

### Make Interfaces Feel Better

Usar craft de tipografia, alinhamento óptico, números tabulares, limites, estados de foco/pressão e transições de entrada/saída para melhorar a sensação da interface. Corrigir primeiro problemas de estrutura e acessibilidade; microdetalhes não devem encobrir defeitos funcionais.

## 2. Fluxo de trabalho para uma mudança de UI

1. **Observe:** identifique a tarefa, a rota, o estado e o momento de uso.
2. **Consulte:** use `docs/design.md`, `brand-guide.md`, tokens e implementação existente.
3. **Mapeie:** descreva estado padrão e estados relevantes: carregando, vazio, erro, offline/pendente, inválido, desabilitado e sucesso.
4. **Componha:** priorize conteúdo e ação; use ficha/baralho quando o conceito semântico se aplica, e não como decoração universal.
5. **Refine:** cheque hierarquia tipográfica, alinhamento de números, pauta, contraste e uso de cor.
6. **Revise:** siga `design-qa-checklist.md`; anote evidência, impacto e recomendação.

## 3. Hard Finish Gate

Em toda mudança visual:

1. Sem overflow ou clipping em larguras `320`, `360/375`, `412/430dp` e tablet quando a tela suportar.
2. Sem truncamento crítico com escala de texto `1.3×`; nomes longos e números grandes permanecem compreensíveis.
3. Ações interativas têm alvo `48×48dp`, rótulo acessível e feedback perceptível.
4. Nenhum estado depende somente de cor, animação ou háptica.
5. Nenhum dado local é declarado salvo antes da persistência confirmar; ações repetidas não duplicam registros.
6. Compatibilidade entre tema claro e noite, teclado, SafeArea e movimento reduzido.

## 4. Limites

- A metáfora de ficha não deve alterar a fila rotativa, prescrição, cálculo de progressão ou dados registrados.
- Cores de fichas identificam treinos, não sucesso/erro/tendência.
- Não sugerir integração WhatsApp no app, diário de nutrição ou itens FUTURO como funcionalidade atual.
- Não adicionar skills ao diretório de runtime Deno.
