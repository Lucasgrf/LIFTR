# Personal Fitness OS — Arquitetura do Sistema

## Visão Geral

A arquitetura segue o padrão **Clean Architecture** adaptado para Flutter, com separação clara entre camadas e responsabilidades. Cada feature é um módulo independente que segue a mesma estrutura interna.

```mermaid
graph TB
    subgraph "Presentation Layer"
        Screens["Screens / Pages"]
        Widgets["Widgets"]
        Controllers["Controllers / Notifiers"]
    end

    subgraph "Domain Layer"
        UseCases["Use Cases"]
        Entities["Entities"]
        RepoInterfaces["Repository Interfaces"]
    end

    subgraph "Data Layer"
        Repositories["Repository Implementations"]
        RemoteDS["Remote Data Source (Supabase)"]
        LocalDS["Local Data Source (Drift/SQLite)"]
        Models["Data Models (DTOs)"]
    end

    subgraph "External"
        Supabase["Supabase (PostgreSQL + Auth + Storage)"]
        SQLite["SQLite Local"]
    end

    Screens --> Controllers
    Controllers --> UseCases
    UseCases --> RepoInterfaces
    Repositories -.->|implements| RepoInterfaces
    Repositories --> RemoteDS
    Repositories --> LocalDS
    RemoteDS --> Supabase
    LocalDS --> SQLite
    Models --> RemoteDS
    Models --> LocalDS
    Entities --> UseCases

    style Screens fill:#6C5CE7,color:#fff
    style Controllers fill:#6C5CE7,color:#fff
    style Widgets fill:#6C5CE7,color:#fff
    style UseCases fill:#00B894,color:#fff
    style Entities fill:#00B894,color:#fff
    style RepoInterfaces fill:#00B894,color:#fff
    style Repositories fill:#0984E3,color:#fff
    style RemoteDS fill:#0984E3,color:#fff
    style LocalDS fill:#0984E3,color:#fff
    style Models fill:#0984E3,color:#fff
    style Supabase fill:#3ECF8E,color:#fff
    style SQLite fill:#FF6B35,color:#fff
```

---

## Camadas

### 1. Presentation Layer (Roxo)

**Responsabilidade:** Interface do usuário e estado da UI.

| Componente | Papel |
|-----------|-------|
| **Screens** | Páginas completas (DashboardScreen, WorkoutScreen) |
| **Widgets** | Componentes reutilizáveis da feature |
| **Controllers/Notifiers** | Gerenciam estado da UI via Riverpod. Chamam use cases |

**Regras:**
- Nunca acessa banco de dados ou API diretamente
- Nunca contém regras de negócio (ex: lógica de progressão)
- Apenas chama use cases e reage ao estado

### 2. Domain Layer (Verde)

**Responsabilidade:** Regras de negócio puras, independentes de framework.

| Componente | Papel |
|-----------|-------|
| **Entities** | Objetos de domínio imutáveis (Exercise, Workout, WeightEntry) |
| **Use Cases** | Operações de negócio (RecordWorkoutSession, CalculateProgression) |
| **Repository Interfaces** | Contratos abstratos que a camada de dados implementa |

**Regras:**
- Zero dependências de Flutter, Supabase ou qualquer pacote externo
- Dart puro — pode ser testado unitariamente sem mocks de framework
- **É aqui que vivem as regras de progressão de carga**

### 3. Data Layer (Azul)

**Responsabilidade:** Acesso a dados e transformação.

| Componente | Papel |
|-----------|-------|
| **Repository Impls** | Implementam as interfaces do domínio |
| **Remote Data Source** | Comunicação com Supabase (queries, inserts, RPC) |
| **Local Data Source** | Cache local SQLite via Drift |
| **Models (DTOs)** | Data Transfer Objects para serialização/deserialização |

**Regras:**
- Transforma DTOs ↔ Entities
- Decide se busca do cache local ou da API remota
- Implementa estratégia de sync/cache

---

## Padrão por Feature

Cada feature segue a mesma estrutura:

```
lib/features/training/
├── data/
│   ├── datasources/
│   │   ├── training_remote_datasource.dart
│   │   └── training_local_datasource.dart
│   ├── models/
│   │   ├── training_plan_model.dart
│   │   └── workout_model.dart
│   └── repositories/
│       └── training_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── training_plan.dart
│   │   └── workout.dart
│   ├── repositories/
│   │   └── training_repository.dart          # Interface abstrata
│   └── usecases/
│       ├── create_training_plan.dart
│       ├── get_active_training_plan.dart
│       ├── get_today_workout.dart
│       └── reorder_exercises.dart
│
└── presentation/
    ├── screens/
    │   ├── training_plan_screen.dart
    │   ├── workout_detail_screen.dart
    │   └── create_training_plan_screen.dart
    ├── widgets/
    │   ├── exercise_card.dart
    │   ├── set_row.dart
    │   └── workout_summary_card.dart
    └── providers/
        ├── training_providers.dart
        └── workout_state.dart
```

---

## State Management — Riverpod

O Riverpod foi escolhido por ser:
- **Compile-safe** — erros de estado são pegos em tempo de compilação
- **Testável** — providers podem ser overridden em testes
- **Reativo** — UI reage automaticamente a mudanças de estado
- **Sem BuildContext** — providers são independentes da árvore de widgets

### Tipos de Providers

```mermaid
graph LR
    subgraph "Riverpod Providers"
        FP["FutureProvider"] -->|"Dados assíncronos"| API["Supabase Query"]
        SP["StreamProvider"] -->|"Dados em tempo real"| RT["Realtime Subscription"]
        NP["NotifierProvider"] -->|"Estado mutável"| State["UI State"]
        P["Provider"] -->|"Dados síncronos"| Computed["Valores computados"]
    end
```

### Exemplo de Fluxo

```
UserTapsStartWorkout
    ↓
WorkoutSessionNotifier.start(workoutId)
    ↓
StartWorkoutSessionUseCase.execute(workoutId)
    ↓
WorkoutSessionRepository.createSession(...)
    ↓
SupabaseRemoteDataSource.insert('workout_sessions', ...)
    ↓
State atualizado → UI reage automaticamente
```

---

## Fluxo de Dados — Registro de Treino

```mermaid
sequenceDiagram
    actor User
    participant UI as Workout Screen
    participant Notifier as Session Notifier
    participant UC as RecordSet UseCase
    participant Repo as Session Repository
    participant Remote as Supabase
    participant Local as SQLite Cache

    User->>UI: Registra série (60kg, 10 reps, RIR 2)
    UI->>Notifier: recordSet(exerciseId, setData)
    Notifier->>UC: execute(setData)
    UC->>UC: Valida dados (carga > 0, reps > 0)
    UC->>Repo: saveSet(setData)
    
    alt Online
        Repo->>Remote: INSERT INTO exercise_performances
        Remote-->>Repo: Success
        Repo->>Local: Cache set data
    else Offline
        Repo->>Local: Queue for sync
        Local-->>Repo: Saved locally
    end
    
    Repo-->>UC: SetRecorded
    UC-->>Notifier: Success
    Notifier-->>UI: State updated
    UI-->>User: ✓ Série registrada, próxima série
```

---

## Motor de Progressão — Arquitetura

O motor de progressão é **puro domínio** — sem dependência de UI ou banco de dados.

```mermaid
graph TD
    subgraph "Input"
        History["Histórico de Performances"]
        Config["Configuração do Exercício"]
        Rules["Regras de Progressão"]
    end

    subgraph "Progression Engine (Domain)"
        Analyzer["Performance Analyzer"]
        Evaluator["Rule Evaluator"]
        Recommender["Recommendation Builder"]
    end

    subgraph "Output"
        Suggestion["Sugestão de Carga"]
        Reason["Motivo da Sugestão"]
        Confidence["Nível de Confiança"]
    end

    History --> Analyzer
    Config --> Analyzer
    Analyzer --> Evaluator
    Rules --> Evaluator
    Evaluator --> Recommender
    Recommender --> Suggestion
    Recommender --> Reason
    Recommender --> Confidence

    style Analyzer fill:#00B894,color:#fff
    style Evaluator fill:#00B894,color:#fff
    style Recommender fill:#00B894,color:#fff
```

### Regras de Progressão (Exemplos)

```dart
// Pseudocódigo — a lógica real será implementada no domain layer
enum ProgressionAction { increase, maintain, decrease }

ProgressionAction evaluate({
  required List<SetPerformance> lastSessionSets,
  required RepRange targetRepRange,    // ex: 6-10
  required RirRange targetRirRange,    // ex: 1-2
  required bool goodExecution,
}) {
  final allHitTopOfRange = lastSessionSets.every(
    (s) => s.reps >= targetRepRange.max
  );
  final rirInRange = lastSessionSets.every(
    (s) => s.rir >= targetRirRange.min && s.rir <= targetRirRange.max
  );

  if (allHitTopOfRange && rirInRange && goodExecution) {
    return ProgressionAction.increase;
  }
  
  if (!goodExecution || lastSessionSets.any((s) => s.rir < targetRirRange.min)) {
    return ProgressionAction.decrease;
  }
  
  return ProgressionAction.maintain;
}
```

---

## Navegação

```mermaid
graph TD
    subgraph "Bottom Navigation"
        Today["🏠 Hoje"]
        Training["🏋️ Treino"]
        Nutrition["🍽️ Nutrição"]
        Body["📊 Corpo"]
        Goals["🎯 Metas"]
    end

    Today --> Dashboard["Dashboard"]
    Today --> QuickActions["Ações Rápidas"]

    Training --> PlanList["Programas"]
    Training --> ActiveWorkout["Treino Ativo"]
    Training --> ExerciseLibrary["Exercícios"]
    Training --> WorkoutHistory["Histórico"]

    Nutrition --> DailyLog["Registro Diário"]
    Nutrition --> MealLog["Refeições"]
    Nutrition --> NutritionGoals["Metas Nutricionais"]

    Body --> WeightLog["Peso"]
    Body --> Measurements["Medidas"]
    Body --> ProgressPhotos["Fotos"]

    Goals --> ActiveGoals["Metas Ativas"]
    Goals --> GoalHistory["Histórico de Metas"]
```

Navegação via **GoRouter** com deep linking:

```
/                          → Dashboard (Hoje)
/training                  → Lista de programas
/training/:planId          → Detalhes do programa
/training/:planId/workout/:workoutId  → Treino específico
/session/:sessionId        → Sessão de treino ativa
/nutrition                 → Registro nutricional
/body                      → Dados corporais
/body/weight               → Histórico de peso
/goals                     → Metas
/history                   → Timeline geral
```

---

## Tratamento de Erros

```mermaid
graph LR
    subgraph "Error Types"
        NE["NetworkError"]
        AE["AuthError"]
        VE["ValidationError"]
        SE["StorageError"]
        UE["UnexpectedError"]
    end

    subgraph "Handling"
        Result["Result<T, Failure>"]
        ErrorUI["Error UI (Snackbar, Dialog)"]
        Retry["Retry Logic"]
        Log["Error Logging"]
    end

    NE --> Result
    AE --> Result
    VE --> Result
    SE --> Result
    UE --> Result

    Result --> ErrorUI
    Result --> Retry
    Result --> Log
```

Usar um tipo `Result<Success, Failure>` (ou `Either`) para propagar erros de forma type-safe, sem exceptions não tratadas.

---

## Testes

| Tipo | O que testa | Onde | Cobertura alvo |
|------|------------|------|---------------|
| **Unit** | Entities, Use Cases, Regras de progressão | `test/features/*/domain/` | 90%+ |
| **Widget** | Componentes visuais isolados | `test/features/*/presentation/` | 70%+ |
| **Integration** | Fluxos completos (registrar treino, etc.) | `test/integration/` | Fluxos críticos |
| **Golden** | Snapshots visuais de widgets | `test/golden/` | Componentes chave |

> [!IMPORTANT]
> O motor de progressão **DEVE** ter cobertura de testes unitários próxima de 100%. É a parte mais crítica do sistema e precisa ser previsível.
