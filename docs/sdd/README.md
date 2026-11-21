# Spec-Driven Development

Esta pasta contém os templates e prompts usados para conduzir o desenvolvimento do Personal Fitness OS em camadas:

Requirement → Spec → Plan → Tasks → Implementation → Verification

## Estrutura

    docs/
    ├── requirements/       Intenção do produto e problema a resolver
    ├── specs/              Comportamento funcional detalhado
    ├── architecture/      Arquitetura, ADRs e decisões técnicas existentes
    ├── plans/              Desenho técnico e plano de implementação
    ├── tasks/              Tasks atômicas executáveis
    └── sdd/
        ├── templates/      SPEC.md, PLAN.md e TASK.md
        └── prompts/        Task Generator e Task Executor

GEMINI.md, na raiz, é a instrução operacional principal do projeto.

## Fluxo de uso

1. Registre o problema ou oportunidade em docs/requirements/<feature>.md.
2. Transforme o requirement em docs/specs/<feature>.md, definindo comportamento observável.
3. Registre decisões, limites técnicos e dependências em docs/plans/<feature>.md.
4. Use docs/sdd/prompts/TASK-GENERATOR.md para decompor o plan em tasks.
5. Salve uma task por arquivo em docs/tasks/<AREA>-<NNN>.md.
6. Execute uma única task por vez usando docs/sdd/prompts/TASK-EXECUTOR.md.
7. Verifique os critérios e registre o resultado no relatório da task.

## Convenções

- Use nomes de feature em kebab-case nos documentos: training-session.md.
- Use IDs de task no formato AREA-NNN: TRAINING-001.
- Não reutilize IDs, mesmo quando uma task for cancelada.
- Mantenha links para os documentos anteriores da cadeia para preservar rastreabilidade.
- Uma task deve ser independente o suficiente para ser implementada sem explicação verbal adicional.
- Critérios de aceitação devem descrever condições observáveis, não intenções vagas.

## Autoridade e conflitos

Os documentos seguem a hierarquia definida em GEMINI.md. Um documento mais baixo na hierarquia não pode contradizer um requisito, uma decisão arquitetural ou uma especificação. Ao detectar conflito ou ambiguidade, marque a execução como BLOCKED e solicite a decisão.

## Status sugeridos

- DRAFT: documento em elaboração.
- READY: documento revisado e pronto para a próxima camada.
- IN PROGRESS: trabalho em andamento.
- DONE: critérios e verificações concluídos.
- BLOCKED: falta informação ou dependência.
- FAILED: houve falha de implementação ou verificação.
