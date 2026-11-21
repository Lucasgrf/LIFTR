# Implementation Plan: <feature name>

STATUS:
DRAFT | READY | IN PROGRESS | DONE | BLOCKED

PLAN ID:
<unique-plan-id>

VERSION:
<version>

DATE:
<YYYY-MM-DD>

AUTHOR:
<name>

RELATED REQUIREMENT:
<path>

RELATED SPEC:
<path to docs/specs/<feature>.md>

## 1. Objective

<Resultado técnico necessário para implementar a spec.>

## 2. Architectural context

- Feature/module: <lib/features/<feature>>
- Layers involved: <presentation, domain, data, infrastructure>
- Dependency direction: <allowed direction>
- Existing patterns to reuse: <files or patterns>
- ADRs that apply: <ADR paths>

## 3. Design

### Components

| Component | Layer | Responsibility | Existing or new |
|---|---|---|---|
| <name> | <layer> | <responsibility> | <existing/new> |

### Data flow

<Descreva o fluxo entre UI, estado, use case, repository, data source e serviços externos, quando aplicável.>

### Contracts

<Interfaces, requests, responses, events ou contratos que serão criados ou alterados.>

### Data changes

<Migrations, tabelas, cache, estado ou “none”.>

## 4. Implementation boundaries

### In scope

- <mudança necessária>

### Out of scope

- <mudança explicitamente excluída>

### Files expected to change

- Create: <file>
- Modify: <file>
- Must not modify: <file or glob>

## 5. Task decomposition

Cada task deve ter um único objetivo técnico e seguir docs/sdd/templates/TASK.md.

| Order | Task ID | Objective | Files | Depends on | Verification |
|---:|---|---|---|---|---|
| 1 | <AREA-001> | <one objective> | <few files> | None | <check> |
| 2 | <AREA-002> | <one objective> | <few files> | <AREA-001> | <check> |

## 6. Dependency graph

<TASK-001> → <TASK-002> → <TASK-003>

Explique qualquer dependência que não seja linear.

## 7. Verification strategy

| Level | Behavior covered | Test/check | Owner task |
|---|---|---|---|
| Unit | <behavior> | <command or test> | <TASK-ID> |
| Integration | <behavior or “none”> | <command or test> | <TASK-ID> |
| End-to-end | <behavior or “none”> | <command or test> | <TASK-ID> |

Defina também os checks de qualidade aplicáveis:

- Compilation: <command>
- Static analysis / lint: <command>
- Tests: <command>
- Manual verification: <steps or “none”>

## 8. Risks and mitigations

| Risk | Impact | Likelihood | Mitigation | Trigger |
|---|---|---|---|---|
| <risk> | <impact> | Low/Medium/High | <mitigation> | <condition> |

## 9. Rollout and rollback

- Rollout: <how the change becomes available>
- Feature flag: <flag or “none”>
- Migration order: <order or “none”>
- Rollback: <safe rollback procedure>

## 10. Open decisions

### DEC-001 — <decision>

- Question: <question>
- Options: <options>
- Decision: <decision or “OPEN”>
- Reason: <reason>
- Related ADR: <path or “none”>

Não marque o plan como READY enquanto uma decisão necessária estiver OPEN.

## 11. Definition of ready

- [ ] A spec está READY e não há conflito de autoridade.
- [ ] A arquitetura e os padrões existentes foram consultados.
- [ ] As fronteiras de arquivos e camadas estão definidas.
- [ ] As dependências estão ordenadas.
- [ ] Cada task tem critérios de aceitação e verificação.
- [ ] Ambiguidades bloqueadoras foram resolvidas.
