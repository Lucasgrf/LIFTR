# Personal Fitness OS — Architecture Decision Records (ADR)

## ADR-001: Flutter como framework mobile

**Status:** ✅ Aceito  
**Data:** 2024-01-15  
**Contexto:** Precisamos de um framework cross-platform para iOS + Android, com boa performance e possibilidade de web no futuro.

### Opções consideradas
1. **Flutter (Dart)** — Cross-platform, widgets customizáveis, single codebase
2. **React Native / Expo** — Ecossistema JavaScript/TypeScript, grande comunidade
3. **Kotlin Multiplatform** — Compartilha lógica, UI nativa por plataforma

### Decisão
Flutter, por preferência do desenvolvedor, excelente suporte a widgets customizáveis, single codebase para iOS + Android + Web, e SDK oficial do Supabase.

### Consequências
- (+) Um único codebase para todas as plataformas
- (+) Design system 100% customizável (sem limitações de componentes nativos)
- (+) Hot reload para desenvolvimento rápido
- (-) Dart não é tão ubíquo quanto TypeScript
- (-) Menor ecossistema de pacotes comparado a JavaScript

---

## ADR-002: Supabase como backend

**Status:** ✅ Aceito  
**Data:** 2024-01-15  
**Contexto:** Dev solo precisa de um backend gerenciado com autenticação, banco relacional e storage, com custo baixo.

### Opções consideradas
1. **Supabase** — PostgreSQL gerenciado + Auth + Storage + Realtime
2. **Firebase** — NoSQL (Firestore), Auth, Storage, Functions
3. **API própria (Node/Python)** — Controle total, mais trabalho

### Decisão
Supabase, por oferecer PostgreSQL (melhor para dados relacionais e históricos), free tier generoso, Row Level Security nativo, e SDK oficial para Flutter.

### Consequências
- (+) PostgreSQL relacional para dados altamente estruturados
- (+) RLS nativo para segurança por usuário
- (+) Free tier suficiente para uso pessoal
- (+) Pode escalar para Pro se necessário
- (-) Dependência de serviço terceiro
- (-) Menos serverless functions que Firebase
- Mitigação: Supabase é open-source, pode ser self-hosted se necessário

---

## ADR-003: Clean Architecture com feature-first

**Status:** ✅ Aceito  
**Data:** 2024-01-15  
**Contexto:** O app terá muitos módulos (treino, nutrição, corpo, metas). Precisamos de uma arquitetura que escale sem acoplamento.

### Decisão
Clean Architecture com organização feature-first:
- **Domain layer** — Dart puro, zero dependências de framework
- **Data layer** — Implementações de repositórios, DTOs, data sources
- **Presentation layer** — Screens, widgets, state management

Cada feature é autocontida dentro de `lib/features/<nome>/`.

### Consequências
- (+) Regras de negócio testáveis sem mock de framework
- (+) Motor de progressão completamente isolado
- (+) Features independentes, podem evoluir separadamente
- (-) Mais boilerplate que uma abordagem simples (ex: MVC)
- (-) Curva de aprendizado para manter disciplina de camadas
- Mitigação: Code generation (freezed, riverpod_generator) reduz boilerplate

---

## ADR-004: Riverpod para state management

**Status:** ✅ Aceito  
**Data:** 2024-01-15  
**Contexto:** Precisamos de state management reativo, testável e sem dependência de BuildContext.

### Opções consideradas
1. **Riverpod** — Compile-safe, sem BuildContext, auto-dispose
2. **BLoC** — Event-driven, muito usado em enterprise
3. **Provider** — Simples, mas menos features

### Decisão
Riverpod com code generation (`riverpod_annotation` + `riverpod_generator`).

### Consequências
- (+) Compile-safe — erros pegos em tempo de compilação
- (+) Sem BuildContext — providers acessíveis em qualquer lugar
- (+) Auto-dispose — recursos liberados automaticamente
- (+) Testável — providers facilmente overridden
- (-) Code generation adiciona complexidade ao build
- (-) Documentação menos extensa que BLoC

---

## ADR-005: Dart 3 sealed classes para error handling

**Status:** ✅ Aceito  
**Data:** 2024-01-15  
**Contexto:** Precisamos de error handling type-safe que funcione com pattern matching.

### Decisão
Usar `sealed class Result<S, F>` com `Success` e `Failure`, aproveitando pattern matching do Dart 3 (`switch` com `case`).

### Alternativa rejeitada
`fpdart` — muito funcional para o time, overkill para o caso de uso.

---

## ADR-006: Dark mode como padrão

**Status:** ✅ Aceito  
**Data:** 2024-01-15  
**Contexto:** App de fitness usado em academias (ambientes com iluminação variável) e durante períodos de descanso.

### Decisão
Dark mode como tema padrão, com suporte a light mode via ThemeExtension.

### Justificativa
- Economiza bateria em telas OLED
- Melhor para ambientes de academia
- Estética moderna e associada a apps de fitness
- Reduz fadiga visual durante uso prolongado

---

## ADR-007: Histórico imutável (append-only)

**Status:** ✅ Aceito  
**Data:** 2024-01-15  
**Contexto:** O sistema precisa preservar todos os dados históricos sem sobrescrever registros antigos.

### Decisão
- Performances de treino são **append-only** — nunca editadas
- Configurações (planos, exercícios) são **versionadas** com `updated_at`
- Deletions são **soft delete** com `deleted_at`
- Substituições de exercício preservam referência ao exercício anterior

### Consequências
- (+) Qualquer dado pode ser rastreado até sua origem
- (+) "Qual era minha carga há 30 dias?" sempre tem resposta
- (+) Possibilita análise de tendências e insights futuros
- (-) Banco cresce mais rápido
- Mitigação: Para uso pessoal, PostgreSQL lida bem com anos de dados

---

## ADR-008: Motor de progressão determinístico

**Status:** ✅ Aceito  
**Data:** 2024-01-15  
**Contexto:** A progressão de carga é o core do produto. Deve ser previsível e transparente.

### Decisão
Motor baseado em regras explícitas no domain layer:
- Regras avaliadas a partir do histórico de performances
- Sempre mostra o **motivo** da sugestão
- Nunca assume que aumento é obrigatório
- Cobertura de testes unitários: 100%

### IA futura
IA será adicionada como **camada opcional sobre dados estruturados**, nunca como substituta do motor determinístico.

---

## ADR-009: Estratégia de offline

**Status:** 🟡 Provisório  
**Data:** 2024-01-15  
**Contexto:** O app será usado em academias com conectividade variável.

### Decisão (MVP)
- **Online-first** com cache local via Drift (SQLite)
- Leituras: cache-first com sync em background
- Escritas: fila local quando offline, sync na reconexão

### Decisão (Futuro — Fase 4)
- Avaliar **PowerSync** para sync bidirecional automático
- PowerSync integra nativamente com Supabase + PostgreSQL
- Decisão final depende da complexidade do esquema de dados nessa fase

---

## ADR-010: Monorepo único

**Status:** ✅ Aceito  
**Data:** 2024-01-15  
**Contexto:** Dev solo, um app, um backend.

### Decisão
Monorepo único com:
- `lib/` — Código Flutter
- `supabase/` — Migrations, functions, config
- `docs/` — Documentação

### Justificativa
- Simplicidade para dev solo
- Migrations e código no mesmo commit
- Um único `git log` para toda a história
- Não justifica a complexidade de repos separados para um desenvolvedor
