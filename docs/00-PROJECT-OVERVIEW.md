# Personal Fitness OS — Project Overview

## Visão

O **Personal Fitness OS** é um sistema pessoal de acompanhamento físico e de treino que centraliza, em uma única aplicação, tudo o que o usuário precisa registrar e acompanhar sobre sua evolução: treinos, exercícios, cargas, repetições, peso corporal, medidas, nutrição, metas e histórico.

Não é uma ficha de academia. É um **sistema operacional de fitness pessoal**.

---

## Problema

Planilhas manuais, apps fragmentados e anotações espalhadas criam uma experiência caótica para quem quer acompanhar sua evolução de forma séria. Falta uma visão unificada que conecte treino, nutrição, corpo e metas em uma linha do tempo coerente.

## Solução

Um app mobile-first (com potencial web) que:

1. **Mostra o que fazer hoje** — treino programado, calorias restantes, meta do dia
2. **Registra tudo durante o treino** — cargas, reps, RIR, descanso, percepção
3. **Sugere progressão inteligente** — baseada em regras determinísticas, não em IA
4. **Conecta tudo por data** — treino ↔ nutrição ↔ peso ↔ medidas ↔ metas
5. **Preserva histórico** — nunca sobrescreve dados antigos silenciosamente

---

## Princípios de Design

| # | Princípio | Descrição |
|---|-----------|-----------|
| 1 | **Simplicidade** | Cada tela resolve um problema. Sem excesso de opções |
| 2 | **Consistência** | Padrões visuais e de interação uniformes em todo o app |
| 3 | **Histórico primeiro** | Tudo é versionado por data. Dados nunca são sobrescritos |
| 4 | **Rastreabilidade** | Qualquer valor pode ser rastreado até sua origem |
| 5 | **Privacidade** | Dados sensíveis (fotos, medidas) com controle do usuário |
| 6 | **Mobile-first** | Projetado para uso com uma mão durante o treino |
| 7 | **Regras explícitas** | Motor de progressão baseado em regras, não em caixa-preta |
| 8 | **Modularidade** | Cada módulo é independente e pode evoluir separadamente |
| 9 | **Evolução gradual** | MVP sólido → features → IA como camada sobre dados estruturados |

---

## Público-alvo

**MVP:** Uso pessoal (single-user)  
**Futuro:** Possibilidade de abrir para amigos/comunidade

---

## Modelo Mental

Tudo no sistema orbita ao redor de uma **linha do tempo pessoal**:

```
Data (2024-01-15)
├── 🏋️ Treino realizado (Upper A)
│   ├── Supino Inclinado: 3x10 @ 60kg, RIR 2
│   ├── Remada Curvada: 3x8 @ 50kg, RIR 1
│   └── ...
├── 🍽️ Nutrição
│   ├── Calorias: 2.350 / 2.500
│   ├── Proteína: 165g / 180g
│   └── Refeições: 4
├── ⚖️ Peso: 82.3 kg
├── 📏 Medidas: cintura 84cm
├── 📷 Foto: front relaxed
└── 🎯 Metas: 3/5 treinos da semana
```

O sistema permite responder perguntas como:
- "Qual era minha carga no supino há 30 dias?"
- "Meu peso está subindo ou descendo?"
- "Minha performance está melhorando?"
- "Quantos treinos fiz este mês?"
- "Qual exercício está estagnado?"

---

## Módulos do Sistema

| Módulo | Descrição | MVP? |
|--------|-----------|------|
| Dashboard | Visão geral do dia: peso, calorias, treino, metas | ✅ |
| Treinos | Criar e gerenciar programas de treinamento | ✅ |
| Registro de Treino | Registrar execução durante o treino | ✅ |
| Progressão | Motor de sugestão de progressão de carga | ✅ |
| Biblioteca de Exercícios | Catálogo de exercícios com detalhes | ✅ |
| Peso Corporal | Registro e análise de peso com médias | ✅ |
| Nutrição | Calorias, macros, refeições | ✅ |
| Metas | Metas mensuráveis com progresso | ✅ |
| Histórico | Navegação temporal por todos os dados | ✅ |
| Medidas Corporais | Registro de medidas por data | 🔜 v1.1 |
| Fotos de Progresso | Fotos organizadas cronologicamente | 🔜 v1.1 |
| Calendário | Visão calendário unificada | 🔜 v1.2 |
| Insights | Regras determinísticas de análise | 🔜 v1.2 |

---

## Objetivo de Longo Prazo

Evoluir para um **personal fitness operating system** que aprende com os dados históricos, identifica padrões e ajuda na tomada de decisão — com IA como **camada sobre dados estruturados**, nunca como substituta da lógica central.

```
Fase 1: MVP determinístico e confiável
Fase 2: Features completas (medidas, fotos, calendário, insights)
Fase 3: IA como camada analítica sobre o histórico
Fase 4: Compartilhamento e comunidade (opcional)
```
