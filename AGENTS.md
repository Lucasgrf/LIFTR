# AGENTS.md — Instruções de Engenharia para Agentes de Código (LIFTR)

Este arquivo orienta qualquer agente ou colaborador de IA que atue neste repositório.

## 1. Estrutura do Repositório

- `app/` — Aplicativo mobile Flutter (Clean Architecture, Riverpod, Drift SQLite, Freezed, GoRouter).
- `supabase/` — Migrações Postgres, seeds e Edge Functions em Deno (`whatsapp-webhook`, `orquestrador`, `cron-relatorio-semanal`).
- `skills/` e `evals/` — **Uso exclusivo do backend WhatsApp em runtime (Deno).** Não coloque skills de agente de código, design ou documentação de frontend dentro de `skills/` para não interferir no pipeline `deno test supabase/functions evals`.
- `docs/` — Especificações de arquitetura, PRD, ADRs e documentação oficial do Design System em `docs/design/`.

---

## 2. Mandato Obrigatório para Frontend (`app/lib/**`)

**Antes de criar ou editar qualquer tela, widget, tema ou asset em `app/`**, leia obrigatoriamente:
1. [`docs/design.md`](docs/design.md) — direção visual vigente e plano tela a tela.
2. [`docs/design/brand-guide.md`](docs/design/brand-guide.md) — marca, cores, tipografia, formas e componentes.
3. [`docs/design/anti-ai-slop-playbook.md`](docs/design/anti-ai-slop-playbook.md) — práticas de composição, craft, acessibilidade e revisão.
4. [`docs/design/design-qa-checklist.md`](docs/design/design-qa-checklist.md) — Design Critique, estados e Hard Finish Gate.

### Guardrails Inegociáveis de UI
- **Cores:** Papel `#F4F5F0`, superfícies `#E7E9E2`, noite azul `#151A2E`/`#1F2640`, tintas grafite `#17191E`, caneta `#1C3FAA` e carimbo `#B8281F` (variantes noite documentadas em `docs/design.md`). Cartões coloridos identificam fichas e nunca status. Conferir contraste WCAG AA de cada combinação; não assumir que os valores da referência já passam.
- **Superfícies & Geometria:** Fichas chapadas, pauta e divisores discretos; evitar cardite, textura literal de papel, sombra pesada, glow neon, gradiente decorativo e ícones rotacionados sem função. Raios de referência `6 / 12 / 20`.
- **Tipografia:** Usar **Familjen Grotesk** conforme disponibilidade/licença do asset. Usar `FontFeature.tabularFigures()` em números comparáveis/mutáveis. Manter a marca `liftr` em minúsculas.
- **Separação de Camadas:** Widgets em `app/lib/core/widgets/` nunca devem importar arquivos ou entidades de `app/lib/features/**`.
- **Motion & Acessibilidade:** Toda animação respeita `MediaQuery.disableAnimationsOf(context)`. Registro de série/stepper é imediato. Todo controle interativo deve ter alvo `>= 48x48dp`, `Semantics` explícito e suportar viewport `320px` + `textScaler 1.3x` sem overflow.
- **Resiliência:** Toda alteração de estado de rede ou persistência na sessão deve preservar o modo offline-first (`SessionLocalDataSource` / Drift / `OfflineBannerWidget`) e impedir duplo registro acidental.

---

## 3. Verificação Padrão Antes de Concluir Qualquer Tarefa

### Alterações no Flutter (`app/`)
```bash
cd app
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

### Alterações em Edge Functions, Evals ou Documentação Compartilhada
```bash
deno lint
deno task check
deno test --allow-read --allow-env supabase/functions evals
```

### Git Workflow
- Seguir **GitHub Flow**: branch atômica a partir da `main` atualizada, commits semânticos e PR direcionado a `main`.
- Em ambientes sandbox sem `gh`/credenciais no container, finalizar commitando na branch e reportando os comandos exatos de `git push` / `gh pr create` para execução no host.
