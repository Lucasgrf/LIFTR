# Checklist de Design Critique e QA — LIFTR

Aplicar em mudanças que alterem `app/lib/**`. A direção visual é definida em [`docs/design.md`](../../docs/design.md); marca e tokens estão em [`brand-guide.md`](brand-guide.md).

## 1. Design Critique

1. Observar a rota, a tarefa e o contexto de uso antes de opinar.
2. Distinguir evidência de hipótese; citar screenshot, estado, código ou regra que sustenta o achado.
3. Relatar cada achado como **Observação → Impacto → Recomendação**.
4. Priorizar: `Blocker` (impede tarefa/dados), `Major` (prejudica uso ou acessibilidade), `Minor` (inconsistência), `Suggestion` (refino opcional).

## 2. Lista de revisão

### Composição e hierarquia

- [ ] A ação e informação prioritárias da tela aparecem na primeira dobra.
- [ ] Fichas/baralho aparecem onde ajudam a compreender treino/fila; não viram decoração universal.
- [ ] Listas usam agrupamento e pauta adequados, sem card em volta de cada linha.
- [ ] Conteúdo secundário não disputa com sessão ativa, registro ou CTA principal.
- [ ] Ações frequentes são alcançáveis com uma mão e ações destrutivas ficam distintas.

### Marca e sistema visual

- [ ] Cores seguem papel/tintas/cartões/noite de `docs/design.md`; cores de cartão não codificam status.
- [ ] Wordmark está em minúsculas e símbolo é a rampa aprovada; proporções e área de respiro preservadas.
- [ ] Familjen Grotesk e pesos disponíveis são usados; números comparáveis são tabulares.
- [ ] Pauta, raio, divisores e superfícies são consistentes; sem textura literal de papel, glow ou decoração gratuita.
- [ ] Cada combinação de texto/superfície cumpre WCAG AA; não presumir contraste só pelo token.

### Componentes, comportamento e estados

- [ ] Componentes existentes e APIs são reutilizados; `core/widgets` não importa `features/**`.
- [ ] Ações assíncronas mostram feedback e impedem duplo toque/registro duplicado.
- [ ] Estados relevantes cobertos: carregando, vazio, erro, offline/pendente, inválido, desabilitado e sucesso.
- [ ] Erros dizem o que ocorreu e o próximo passo; só afirmam salvamento local após confirmação.
- [ ] Registro, steppers e estados importantes permanecem imediatos e compreensíveis sem motion.
- [ ] WhatsApp, nutrição e outras capacidades futuras não são apresentadas como existentes no app.

### Acessibilidade, responsividade e estabilidade

- [ ] Todo controle tem alvo mínimo `48×48dp`, foco visível e `Semantics` nomeada.
- [ ] Não há significado comunicado só por cor; gráficos têm unidade, período, legenda e resumo textual.
- [ ] `MediaQuery.disableAnimationsOf(context)` é respeitado em animações explícitas.
- [ ] Não há clipping com conteúdo PT-BR longo, nomes extensos, números altos ou teclado aberto.
- [ ] Validar larguras `320`, `360/375`, `412/430dp` e tablet aplicável, com escala de texto `1.3×`.
- [ ] Tema claro/noite mantém contraste e reconhecibilidade das fichas.

## 3. Severidade

| Nível | Critério | Exemplo |
|---|---|---|
| Blocker | Impede tarefa essencial, causa perda/duplicidade ou falha de acessibilidade grave | Série duplicada após toque repetido; CTA inacessível |
| Major | Prejudica compreensão ou operação de forma relevante | Carga sem unidade; contraste insuficiente; timer sem estado de pausa |
| Minor | Inconsistência observável, sem bloquear tarefa | Pauta ou alinhamento divergente entre telas equivalentes |
| Suggestion | Refino opcional sem impacto funcional demonstrável | Ajuste óptico de tracking |

## 4. Fechamento de PR

- [ ] Resolver todos os `Blocker` e `Major` ou registrar claramente o motivo e a decisão.
- [ ] Confirmar estados e fluxos afetados; registrar limitações conhecidas.
- [ ] Aplicar o fluxo e os comandos de verificação de `AGENTS.md` pertinentes ao tipo de mudança.
