# Feature Specification: <feature name>

STATUS:
DRAFT | READY | IN PROGRESS | DONE | BLOCKED

SPEC ID:
<unique-spec-id>

VERSION:
<version>

DATE:
<YYYY-MM-DD>

AUTHOR:
<name>

RELATED REQUIREMENT:
<path to docs/requirements/<feature>.md>

RELATED ARCHITECTURE:
- <path to relevant architecture or ADR>

## 1. Problem

<Qual problema concreto existe? Quem é afetado? Em que contexto?>

## 2. Goal

<Qual resultado observável esta feature deve produzir?>

## 3. Out of scope

- <item explicitamente excluído>

## 4. Actors and use cases

### Actor: <actor>

#### Use case: <name>

- Trigger: <evento que inicia o caso de uso>
- Preconditions: <condições necessárias>
- Main flow:
  1. <passo>
  2. <passo>
- Alternative flows:
  - <variação>
- Postconditions: <estado esperado ao finalizar>

## 5. Functional requirements

### FR-001 — <requirement title>

- Requirement: <comportamento obrigatório>
- Rationale: <por que é necessário>
- Priority: P0 | P1 | P2
- Verification: <como observar ou testar>

### FR-002 — <requirement title>

- Requirement: <comportamento obrigatório>
- Rationale: <por que é necessário>
- Priority: P0 | P1 | P2
- Verification: <como observar ou testar>

## 6. Business rules

### BR-001 — <rule title>

- Rule: <regra explícita>
- Applies when: <condição>
- Result: <efeito esperado>
- Exceptions: <exceções ou “none”>

## 7. User interface and interaction

<Descreva telas, estados, ações, feedback e acessibilidade quando aplicável. Se não houver UI, escreva “Not applicable”.>

### UI states

- Loading: <comportamento>
- Empty: <comportamento>
- Success: <comportamento>
- Error: <comportamento>
- Offline: <comportamento ou “Not applicable”>

## 8. API / contract

<Defina request, response, eventos, interfaces ou contratos. Se não houver, escreva “Not applicable”.>

### <Contract name>

- Input: <schema ou tipo>
- Output: <schema ou tipo>
- Errors: <erros e códigos>
- Compatibility: <impacto em consumidores existentes>

## 9. Data and state changes

- Persistent data: <tabelas, colunas, migrations ou “none”>
- Local state: <estado de UI/cache ou “none”>
- Existing data migration: <estratégia ou “none”>
- History and deletion policy: <append-only, soft delete ou regra aplicável>

## 10. Error handling and edge cases

| Case | Expected behavior | User-visible result | Verification |
|---|---|---|---|
| <case> | <behavior> | <result> | <test/check> |

## 11. Security and privacy

- Authentication: <requirement or “none”>
- Authorization / RLS: <requirement or “none”>
- Sensitive data: <data and handling or “none”>
- Logging: <allowed data and restrictions>

## 12. Acceptance criteria

- [ ] AC-001 — <condição observável>
- [ ] AC-002 — <condição observável>
- [ ] AC-003 — <condição observável>

## 13. Dependencies

- <document, component, task or external dependency>

## 14. Open questions and decisions

### Q-001 — <question>

- Question: <ambiguity>
- Impact: <why it matters>
- Options:
  - A: <interpretation>
  - B: <interpretation>
- Decision: <decision or “OPEN”>
- Decided by: <name or “OPEN”>
- Date: <YYYY-MM-DD or “OPEN”>

Não avance para PLAN enquanto uma pergunta aberta bloquear uma decisão necessária.

## 15. Traceability

| Requirement | Functional requirement | Business rule | Acceptance criterion | Task |
|---|---|---|---|---|
| <REQ-ID> | <FR-ID> | <BR-ID> | <AC-ID> | <TASK-ID> |
