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
1. [`docs/design/brand-guide.md`](docs/design/brand-guide.md) — Identidade (*Technical Humanism*), paleta, tipografia, Monólito Dinâmico, tokens e arquitetura.
2. [`docs/design/anti-ai-slop-playbook.md`](docs/design/anti-ai-slop-playbook.md) — As 5 skills anti-AI-slop calibradas para o LIFTR (Anti UI Slop, ThinkUI, Taste Skill, Emil Design Engineering, Vercel Guidelines).
3. [`docs/design/design-qa-checklist.md`](docs/design/design-qa-checklist.md) — Checklist de Design Critique, 6 camadas de QA e Hard Finish Gate.

### Guardrails Inegociáveis de UI
- **Cores:** Dark-first (`Carvão #0D0D0F`, `Grafite #1A1A1F`, `Titânio #8E8E98`, `Branco Osso #F2F2F0`, `Verde Botânico #72A987` com **`onPrimary = #0D0D0F`**). Tema claro usa **Verde Botânico Profundo `#315B43`** com `onPrimary = #F2F2F0`. **Proibido** roxo genérico (`#6C63FF`), texto branco sobre `#72A987`, cores hex hardcoded fora de `app/lib/core/theme/` e paletas arco-íris em métricas musculares.
- **Superfícies & Geometria:** Superfícies foscas com hierarquia por luminância; **zero glow neon**, **zero gradiente decorativo central**, **zero ícones rotacionados gratuitamente**. Escala de raios contida (`0 / 4 / 8 / 12 / 16 / 999`).
- **Tipografia:** Usar **Geist** com `FontFeature.tabularFigures()` em todos os números comparáveis/mutáveis. Não reintroduzir `Inter`.
- **Separação de Camadas:** Widgets em `app/lib/core/widgets/` nunca devem importar arquivos ou entidades de `app/lib/features/**`.
- **Motion & Acessibilidade:** Toda animação explícita usa tokens de `AppMotion` (`Cubic(0.23, 1.0, 0.32, 1.0)`, `< 260ms`, sem bloqueio em ações de treino) e respeita `MediaQuery.disableAnimationsOf(context)`. Todo controle interativo deve ter alvo `>= 48x48dp`, `Semantics` explícito e suportar viewport `320px` + `textScaler 1.3x` sem overflow.
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
