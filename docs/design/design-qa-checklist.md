# Checklist de Design Critique & Design QA — LIFTR

Documento operacional baseado nos **Capítulos 26 e 27** do estudo de design do LIFTR e nas diretrizes de verificação das **5 skills anti-AI-slop**. Deve ser aplicado em toda revisão de PR que altere `app/lib/**`.

---

## 1. Processo de Design Critique (Cap. 26)

1. **Observar antes de opinar (60s):** verificar propósito da tela, público e momento de uso (planejamento vs. execução na academia vs. análise).
2. **Evidência vs. Hipótese:** registrar explicitamente quando uma observação vem de métrica/heurística/regra WCAG versus quando é hipótese a testar.
3. **Formato obrigatório de comentário (`O -> I -> R`):**
   - **Observation:** o que está acontecendo na interface (com arquivo e linha ou screenshot).
   - **Impact:** por que isso prejudica a tarefa, compreensão, acessibilidade ou identidade do LIFTR.
   - **Recommendation:** ajuste concreto usando tokens/componentes do sistema.
4. **Classificação de prioridade:** `Blocker` | `Major` | `Minor` | `Suggestion`.

---

## 2. Inspeção em 6 Camadas (Cap. 27)

### Camada 1 — Estrutura & Composição
- [ ] A informação prioritária da tarefa (ex.: série atual, carga/reps, CTA principal) domina visualmente a primeira dobra.
- [ ] Agrupamento segue proximidade lógica sem abuso de cards aninhados ("cardite").
- [ ] Ações principais de sessão estão acessíveis com uma mão (zona inferior/polegar), longe de ações destrutivas.

### Camada 2 — Hierarquia & UX Writing
- [ ] Máximo de 5 níveis tipográficos (`Display`, `Heading`, `Body`, `Label`, `Numeric`); dados numéricos usam `FontFeature.tabularFigures()`.
- [ ] Unidades (`kg`, `reps`, `s`, `min`, `kcal`) e períodos estão sempre explícitos.
- [ ] Microcopy segue tom *Technical Humanism*: objetivo, sem motivação exagerada, sem expor exceção técnica crua sem caminho de recuperação.
- [ ] Pluralização correta (`1 série`, `2 séries`, `1 exercício`, `2 exercícios`).

### Camada 3 — Tokens & Identidade Visual (*Taste + Brand Guide*)
- [ ] Zero cores hex hardcoded nas telas ou widgets; tudo vem de `context.appColors`, `context.fitnessColors`, `context.appRadius`, `context.appSpacing`, `context.appMotion`.
- [ ] Zero cor roxa SaaS (`#6C63FF`), zero fonte `Inter`, zero glow neon (`BoxShadow` colorido em botões/badges), zero gradiente decorativo central.
- [ ] Raios respeitam a escala `0 / 4 / 8 / 12 / 16 / 999`.
- [ ] Símbolo (`Monólito Dinâmico`) e wordmark preservam proporção e área de respiro (`1x`).

### Camada 4 — Componentes & Arquitetura
- [ ] Componentes genéricos (`app/lib/core/widgets/`) **não importam** entidades de domínio (`features/**`).
- [ ] Padrões repetidos reutilizam primitivas existentes em vez de duplicar código local.
- [ ] Botões e ações assíncronas possuem proteção contra duplo toque (`isLoading` / disabled em voo).

### Camada 5 — Comportamento, Motion & Estados (*Emil + Vercel*)
- [ ] Matriz completa de estados validada: `Loading`, `Empty`, `Error` (com garantia dos dados locais + retry), `Offline` (com fila pendente), `Success` e `Disabled`.
- [ ] Animações usam `AppMotion` (`Cubic(0.23, 1.0, 0.32, 1.0)`, `< 260ms`); ações repetitivas de treino não têm animações bloqueantes.
- [ ] Toda animação explícita respeita `MediaQuery.disableAnimationsOf(context)` e preserva estado visual final sem depender de movimento.
- [ ] Timer de descanso cobre `idle`, `running`, `paused`, `completed` e `dismissed`.

### Camada 6 — Acessibilidade, Responsividade & Edge Cases (*Hard Finish Gate*)
- [ ] Contraste verificado: textos normais `>= 4.5:1`, texto grande/ícones `>= 3.0:1`, `onPrimary = #0D0D0F` sobre `#72A987` no Dark e `#F2F2F0` sobre `#315B43` no Light.
- [ ] Nenhum significado comunicado apenas por cor (usar ícone, texto, rótulo ou traço tracejado em gráficos).
- [ ] Todos os alvos interativos têm hit area mínima de `48x48dp` (ou espaçamento seguro em controles compactos validados).
- [ ] Botões iconográficos, avatares e controles customizados possuem `Semantics(label: ..., button: true)`.
- [ ] Layout testado sem overflow/clipping com:
  - Nomes longos de exercícios (ex.: `"Supino Inclinado com Halteres no Banco 30° Articulado"`).
  - Números altos (`180,5 kg`, `20 reps`, `14.520 kg`).
  - Larguras `320px`, `375px`, `430px` e tablet `768px`.
  - `MediaQuery.textScalerOf` em `1.3x`.

---

## 3. Classificação de Severidade de Bugs Visuais (S1–S4)

| Severidade | Critério | Exemplos concretos no LIFTR |
|---|---|---|
| **S1 — Critical** | Bloqueia tarefa essencial, causa perda/duplicação de dados ou impede concluir treino | Botão de registrar série cortado em `320px`; toque duplo grava série duplicada; dados perdidos ao ficar offline; contraste ilegível em ação crítica |
| **S2 — Major** | Prejudica compreensão, fluxo ou acessibilidade de forma relevante | Campo de carga sem unidade ou ambíguo; timer sem feedback de pausa/conclusão; gráfico sem escala/período; alvo de toque `< 44dp` em ação frequente; contraste `< 4.5:1` em texto secundário |
| **S3 — Minor** | Inconsistência perceptível de sistema ou composição com impacto limitado | Espaçamento fora da escala de `4px`; radius inconsistente entre cards equivalentes; ícone desalinhado em linha |
| **S4 — Cosmetic** | Ajuste fino estético sem impacto funcional | Pequeno desvio de tracking tipográfico; microajuste de opacidade em divisor |

---

## 4. Portão Final de Verificação (Comandos Obrigatórios)

```bash
cd app
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

> **Critério de aprovação:** `0` erros no analyzer, `100%` dos testes passando (sem testes pulados ou assertions relaxadas) e todos os itens `S1` e `S2` deste checklist resolvidos.
