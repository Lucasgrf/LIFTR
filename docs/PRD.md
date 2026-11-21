# App de Academia — Documento de Produto (PRD)

> Nome do produto: **provisório**. Versão do documento: 0.2 · 03/11/2026
> Status: decisões de arquitetura fechadas (ADRs 001–005), pronto para Sprint 0.

## Sumário

1. Visão e tese
2. Escopo: MVP e backlog
3. Conceitos de domínio
4. Regras de negócio
5. Telas do app
6. WhatsApp
7. Arquitetura e modelo de dados
8. Camada de IA (RAG, guardrails, avaliação)
9. Skills do sistema
10. Requisitos funcionais
11. Requisitos não funcionais
12. Épicos e user stories
13. Processo (SDLC + ágil)
14. Riscos, decisões e questões em aberto

---

## 1. Visão e tese

**Tese:** *Abro o app, ele me diz o que treinar hoje, eu treino, e o resto acontece no WhatsApp.*

**Problema.** Apps de academia existentes falham por atrito: registrar dieta é cansativo, programas fixos por dia da semana quebram quando você falta, e o iniciante não sabe quando aumentar a carga.

**Público.** Primeiro usuário: o próprio desenvolvedor. Público-alvo do desenho: iniciantes e intermediários que treinam musculação 2 a 6 vezes por semana.

**Princípios de design**

| # | Princípio | Consequência prática |
|---|---|---|
| P1 | Cada coisa tem um lugar só | Treino no app; dieta, peso e relatórios no WhatsApp |
| P2 | A vida real não pune | Programa é uma fila em rotação, não um calendário |
| P3 | Progresso visível e objetivo | Dupla progressão com barra de "faltam X reps" |
| P4 | Consistência > precisão | Dieta só com proteína e calorias; tendência de peso, não peso do dia |
| P5 | LLM só onde precisa | Cálculos são determinísticos; o LLM interpreta e redige, nunca calcula |
| P6 | Toda escrita é confirmada | Cada registro via WhatsApp recebe confirmação corrigível |

**O que o app NÃO faz (anti-escopo)**

- Não tem feed social, ranking ou seguidores.
- Não tem tela de diário alimentar nem busca manual de alimentos (isso é WhatsApp).
- Não tem biblioteca de 500 exercícios com vídeo; tem uma lista curada por slot.
- Não dá conselho médico, não diagnostica lesões e não prescreve suplementos ou medicamentos.
- Não conversa sobre assuntos fora de treino, dieta e peso.

**Teste de toda feature nova:** ela melhora o fluxo "ver treino → treinar → registrar no WhatsApp → receber feedback"? Se não, vai pro backlog ou some.

---

## 2. Escopo: MVP e backlog

### MVP (v1.0)

- Onboarding: perfil corporal, objetivo, experiência, dias por semana, escolha de estilo.
- Programas: Full Body, Upper/Lower, PPL, híbrido UL+Full e ABCDE, a partir de templates com slots.
- Fila em rotação com próximo treino, pular e escolher manualmente.
- Execução do treino em séries retas, timer de descanso, marcação de aquecimento.
- Dupla progressão com sugestão de carga, piso, platô e barra de progresso.
- Tela Progresso: status por exercício, histórico, peso com média móvel, heatmap de consistência.
- WhatsApp: registrar refeição (texto e foto), registrar peso, corrigir último registro, mudar objetivo, perguntar "quanto falta hoje".
- Mensagens automáticas: resumo pós-treino, lembrete de proteína (máx. 1/dia), relatório semanal.
- Metas nutricionais: cálculo inicial por fórmula, TDEE adaptativo, ajuste semanal com travas.
- Plataforma de IA: roteador de intenção, RAG de alimentos, guardrails, validação de saída, logs e evals.

### Backlog (pós-MVP)

| Item | Observação |
|---|---|
| Pirâmide crescente/decrescente | Progressão pela série mais pesada ou mais leve conforme o tipo |
| Top set + back-off | Back-offs como % da série principal |
| Drop set | Apenas registro, sem regra própria |
| Responder dúvidas (RAG em base curada) | Skill `responder-duvida`, já especificada |
| Integração Health Connect / HealthKit | Sono, passos, FC; correlações no relatório |
| Fotos de progresso | Câmera com silhueta guia, comparação lado a lado |
| Deload programado e periodização | Hoje só existe deload reativo ao platô |
| 1RM estimado | Opcional para intermediários |
| Relatório mensal | Comparativo de blocos de treino |
| Exportação de dados (CSV/JSON) | Portabilidade |

---

## 3. Conceitos de domínio

| Conceito | Definição |
|---|---|
| **Programa** | Um estilo (ex.: Upper/Lower) instanciado com N sessões em ordem de rotação |
| **Fila** | Sequência circular das sessões do programa. O app sempre aponta para o próximo item |
| **Sessão-modelo** | Ex.: "Upper A". Lista ordenada de slots |
| **Slot** | Padrão de movimento com parâmetros: tipo (composto/isolado), séries alvo, faixa de reps, descanso. Ex.: "Empurrar horizontal composto, 3 séries, 8–12" |
| **Exercício** | Movimento concreto que preenche um slot (ex.: supino inclinado com halteres). Tem imagem genérica e, opcionalmente, foto da academia do usuário |
| **Equipamento** | Barra, halter, máquina, cabo, peso corporal. Define os incrementos de carga possíveis |
| **Treino realizado** | Execução de uma sessão-modelo numa data |
| **Série** | Registro individual: peso, reps, tipo (`valida` ou `aquecimento`), ordem |
| **Status de progressão** | Estado de um exercício após cada treino: `subir`, `manter`, `carga_alta`, `travado` |

**Invariantes**

- O histórico pertence ao **exercício**, não ao programa. Trocar de programa não apaga nada.
- Cada série é salva individualmente (prepara o terreno para pirâmide sem migração).
- Séries de aquecimento nunca entram no cálculo de progressão nem no volume.
- A fila nunca "atrasa": faltar não gera pendência, apenas mantém o próximo item.

**Estilos e templates**

| Estilo | Dias/semana | Sessões na fila |
|---|---|---|
| Full Body | 2–3 | Full A, Full B (opcional Full C) |
| Upper/Lower | 4 | Upper A, Lower A, Upper B, Lower B |
| PPL | 3 ou 6 | Push, Pull, Legs |
| Híbrido UL + Full | 5 | Upper, Lower, Full, Upper, Lower |
| ABCDE | 5 | Peito, Costas, Pernas, Ombros, Braços |

Sugestão automática no onboarding: 2–3 dias → Full Body; 4 → Upper/Lower; 5 → Híbrido; 6 → PPL. O usuário sempre pode escolher outro.

---

## 4. Regras de negócio

Todas as regras desta seção são **funções puras e determinísticas**, com testes unitários. Nenhuma delas passa por LLM.

### 4.1 Dupla progressão (séries retas)

**Parâmetros por slot/exercício:** `series_alvo` (padrão 3), `faixa_min`, `faixa_max`.

Faixas padrão por tipo de slot:

| Tipo | Faixa |
|---|---|
| Composto pesado (agachamento, terra, supino reto com barra) | 6–10 |
| Composto geral | 8–12 |
| Isolado | 10–15 |

**Elegibilidade.** Só avalia o treino se o número de séries válidas for igual a `series_alvo` e todas tiverem o mesmo peso. Caso contrário, status = `manter` sem sugestão de mudança.

**Algoritmo (após cada treino, por exercício):**

```
validas = séries do tipo 'valida', em ordem
total = soma(reps)
alvo_total = series_alvo * faixa_max
progresso = total / alvo_total            # usado na barra "faltam X reps"

se todas as reps >= faixa_max:
    status = SUBIR
    proximo_peso = proximo_incremento(equipamento, peso_atual)
senão se validas[0].reps < faixa_min:
    status = CARGA_ALTA
    proximo_peso = peso_intermediario_ou_anterior(equipamento, peso_atual)
senão se ultimas_3_sessoes_mesmo_peso e total não aumentou em nenhuma delas:
    status = TRAVADO
    sugestoes = [reduzir ~10% arredondado ao incremento, trocar exercício do slot]
senão:
    status = MANTER
    proximo_peso = peso_atual
```

**Incrementos.** Cada equipamento tem uma lista de pesos possíveis ou um passo (ex.: barra +2,5 kg no total; halter de 2 em 2 kg; máquina conforme placas). Se desconhecido, o app pergunta uma vez ou infere dos pesos já registrados. `proximo_incremento` retorna sempre um peso **existente**.

**Barra de progresso.** Exibida na tela Hoje e em Progresso: "33 de 36 reps — faltam 3 para subir a carga".

**Status agregado (tela Progresso).** `subindo` se a carga aumentou nas últimas 4 semanas; `travado` se o status atual é TRAVADO; caso contrário `estável`.

### 4.2 Tendência de peso

- Média móvel exponencial ponderada pelo tempo (lida com pesagens irregulares).
- Taxa de mudança calculada sobre a **tendência**, nunca sobre pesagens isoladas.
- Confiança da tendência: alta com ≥ 3 pesagens/semana; baixa com menos (o texto do feedback reflete isso).
- Pesagem com diferença > 3 kg da tendência pede confirmação antes de salvar.
- Faixa válida de entrada: 30–300 kg.

### 4.3 Metas nutricionais

**Gasto inicial (fórmula):**

- Mifflin-St Jeor: homens `10·peso + 6,25·altura − 5·idade + 5`; mulheres `10·peso + 6,25·altura − 5·idade − 161`.
- Se % de gordura informado: Katch-McArdle `370 + 21,6 · massa_magra_kg`.
- TDEE = TMB × fator de atividade (1,2 / 1,375 / 1,55 / 1,725), considerando treino + rotina.

**Ritmo alvo por objetivo:**

| Objetivo | Iniciante | Intermediário |
|---|---|---|
| Bulking | ~1–1,5% do peso/mês | ~0,5–1% do peso/mês |
| Cutting | ~0,5–1% do peso/semana | ~0,5–0,75% do peso/semana |
| Manutenção | tendência estável ±1–2% | idem |

Delta calórico diário = `ritmo_kg_semana × 7700 / 7`.

**Proteína:** 1,6–2,2 g/kg. Padrão: 2,0 g/kg no cutting, 1,8 g/kg nos demais. Para IMC ≥ 30, usar peso de referência (peso alvo) no cálculo.

**TDEE adaptativo** (ativa com ≥ 14 dias, ≥ 10 dias com refeições registradas e ≥ 6 pesagens):

```
tdee_observado = media_kcal_registrada − (Δtendencia_kg × 7700 / dias)
tdee_estimado  = suavizar(tdee_anterior, tdee_observado)   # EMA
```

Erro sistemático do registro (ex.: LLM subestima porções) é absorvido pela calibração.

**Ajuste de meta:** no máximo 1×/semana (junto ao relatório), em passos de até ±200 kcal.

### 4.4 Travas de segurança nutricional

| Trava | Regra |
|---|---|
| Piso calórico | Meta nunca abaixo de max(TMB, 1500 kcal homens / 1200 kcal mulheres) |
| Teto de déficit | Ritmo de cutting limitado a 1%/semana |
| Alerta de perda rápida | Perda > 1,5%/semana por 2 semanas seguidas → mensagem de alerta e congelamento de novos cortes |
| Objetivo irrealista | Peso alvo com IMC < 18,5 é recusado |
| Mudança de objetivo | Só via função determinística + confirmação explícita do usuário |
| LLM e metas | O LLM nunca altera metas; apenas comunica o que o motor calculou |

---

## 5. Telas do app

**Navegação:** 3 abas (Hoje, Progresso, Programa) + Configurações no ícone de perfil.

### Onboarding (meta: treinando em ≤ 2 minutos)

1. Dados corporais: sexo, idade, altura, peso, % gordura (opcional).
2. Objetivo: bulking, cutting, manutenção.
3. Experiência: iniciante, intermediário.
4. Atividade fora da academia.
5. Dias por semana → sugestão de estilo → confirmação.
6. Conectar WhatsApp (pode pular e fazer depois).

### Hoje

- Nome da sessão (ex.: "Lower A") e posição na fila.
- Lista de exercícios com carga sugerida, faixa e barra "faltam X reps".
- Toque na série = marcar concluída com reps; long-press = marcar aquecimento.
- Timer de descanso inicia ao marcar a série.
- Trocar exercício do slot: abre lista com imagens, ordenada por já usados → sugeridos.
- Ao finalizar: tela de resumo com subidas de carga comemoradas; dispara resumo no WhatsApp.

### Progresso

1. **Exercícios** com status (subindo / estável / travado) e barra. Toque → histórico com gráfico de carga de trabalho e lista de sessões.
2. **Peso corporal**: linha da tendência em destaque, pesagens diárias apagadas ao fundo.
3. **Consistência**: heatmap de dias treinados.

### Programa

- Fila visível com o próximo destacado; pular ou escolher manualmente.
- Editar sessão: adicionar/remover slots, séries e faixa.
- Indicador discreto de séries/semana por grupo muscular.
- Trocar programa (histórico preservado).

### Configurações

- Perfil e objetivo; equipamentos e incrementos; WhatsApp (conectar, horário do relatório, horário silencioso); exportar dados (backlog).

---

## 6. WhatsApp

### 6.1 Intenções suportadas

| Intenção | Exemplo | Quem responde |
|---|---|---|
| `registrar_refeicao` | "almocei 150g de frango, arroz e feijão, uma concha de cada" / foto | Skill `registrar-refeicao` + template |
| `registrar_peso` | "me pesei hoje, 80kg" | Skill `registrar-peso` (extração) + template |
| `corrigir_ultimo` | "foram 200g de frango" | Roteador + skill do registro original |
| `mudar_objetivo` | "quero começar um cutting" | Motor determinístico + confirmação |
| `consultar_dia` | "quanto falta de proteína?" | Consulta SQL + template |
| `confirmar` / `cancelar` | "sim", "pode", "não" | Fluxo pendente (ex.: mudança de objetivo) |
| `saudacao` | "oi" | Template |
| `fora_de_escopo` | "me ajuda com meu código" | Template fixo |
| `saude_sensivel` | dor, lesão, remédio, sinais de transtorno alimentar | Template de segurança fixo |
| `duvida_treino_dieta` | "quanto descanso entre séries?" | MVP: template "em breve"; v2: skill `responder-duvida` |

### 6.2 Confirmação de todo registro

```
Registrei: frango grelhado (150g), arroz branco (~1 concha, 100g), feijão (~1 concha, 86g).
~52g de proteína · ~610 kcal
Hoje: 98/160g de proteína · 1.420/2.600 kcal
(responda corrigindo se algo estiver errado)
```

`~` indica porção assumida ou estimativa por foto.

### 6.3 Feedback de peso com contexto do objetivo

> Registrei 80kg. Sua tendência subiu 3kg este mês, acima do ritmo ideal pra você (0,8 a 1,2kg). Vou reduzir sua meta em 200 kcal a partir de amanhã.

### 6.4 Mensagens automáticas

| Mensagem | Gatilho | Limite |
|---|---|---|
| Resumo pós-treino | Treino finalizado e sincronizado | 1 por treino |
| Lembrete de proteína | Horário configurado, só se < 70% da meta | 1 por dia |
| Relatório semanal | Domingo, horário configurado | 1 por semana |

Horário silencioso configurável. Nenhuma outra mensagem proativa no MVP.

### 6.5 Relatório semanal (estrutura)

1. **Treino:** sessões feitas, cargas que subiram, exercícios travados.
2. **Dieta:** dias que bateu proteína e calorias.
3. **Peso:** tendência vs. semana anterior e vs. ritmo alvo; ajuste de meta, se houver.
4. **Próxima semana:** 1–2 ações escolhidas de uma lista gerada pelo motor de regras.

Limite: cabe numa tela de celular (~900 caracteres).

---

## 7. Arquitetura e modelo de dados

### 7.1 Visão geral

```
Flutter (offline-first)
  Drift/SQLite local · Riverpod · domínio puro em Dart
        │ sync (outbox)
        ▼
Supabase
  Postgres (+ pg_trgm, pgvector) · Auth · Storage (fotos)
  Edge Functions (TypeScript/Deno) · pg_cron
        │ webhooks                      │ chamadas
        ▼                               ▼
Adaptador WhatsApp                  Orquestrador de IA
(Evolution API ou Cloud API)        roteador → skill → validação → template
```

**Onde cada regra roda**

| Regra | Onde | Motivo |
|---|---|---|
| Dupla progressão | App (Dart) | Precisa funcionar offline na academia; status é persistido e sincronizado |
| Tendência de peso, TDEE, metas | Backend (TS) | Depende de dados do WhatsApp; roda em cron semanal |
| Cálculo de macros de refeição | Backend (SQL/TS) | Determinístico a partir de IDs de alimentos + gramas |

### 7.2 Modelo de dados (resumo)

| Tabela | Campos principais |
|---|---|
| `perfil` | sexo, nascimento, altura_cm, objetivo, experiencia, atividade, fuso, whatsapp_numero |
| `metas` | vigente_desde, kcal, proteina_g, origem (`formula`/`adaptativo`), tdee_estimado |
| `equipamento` | tipo, incrementos (array ou passo) |
| `exercicio` | nome, padrao_movimento, tipo, equipamento_id, imagem_url, foto_usuario_url, grupos_musculares |
| `programa` | estilo, ativo, criado_em |
| `sessao_modelo` | programa_id, nome, ordem_fila |
| `slot` | sessao_modelo_id, ordem, padrao_movimento, tipo, series_alvo, faixa_min, faixa_max, descanso_s, exercicio_atual_id |
| `fila_estado` | programa_id, proxima_sessao_modelo_id |
| `treino` | sessao_modelo_id, inicio, fim |
| `serie` | treino_id, exercicio_id, ordem, peso, reps, tipo |
| `status_progressao` | exercicio_id, treino_id, status, proximo_peso, progresso |
| `pesagem` | data, peso_kg, origem |
| `refeicao` | registrada_em, texto_original, foto_url, confirmada |
| `refeicao_item` | refeicao_id, alimento_id, gramas, porcao_assumida, confianca |
| `alimento` | nome, fonte (`taco`/`off`/`usuario`), kcal_100g, proteina_100g, sinonimos, embedding |
| `medida_caseira` | alimento_id ou categoria, nome (concha, colher de sopa, escumadeira), gramas |
| `mensagem` | direcao, conteudo, intent, criada_em |
| `acao_pendente` | tipo (ex.: mudar_objetivo), payload, expira_em |
| `llm_chamada` | skill, versao_skill, modelo, tokens, latencia_ms, entrada_hash, saida, validacao_ok, erro |

### 7.3 Integração com WhatsApp

Interface única `WhatsAppGateway` (`enviarTexto`, `enviarTemplate`, `receberWebhook`) com duas implementações possíveis. Decisão em ADR-002 (seção 14).

---

## 8. Camada de IA

### 8.1 Princípio central

> **O LLM interpreta linguagem e redige texto. Ele nunca calcula, nunca decide metas e nunca afirma um número que não veio do backend.**

### 8.2 Pipeline de uma mensagem recebida

```
1. Gate de entrada        número na whitelist? tamanho ok? rate limit ok?
2. Roteador               skill roteador-intencao → {intent, confianca, flags}
3. Desvio por política    fora_de_escopo / saude_sensivel → template fixo (sem LLM gerando texto)
4. Skill da intenção      carrega só o SKILL.md dessa intenção (progressive disclosure)
5. Retrieval (se houver)  RAG de alimentos / histórico pessoal
6. Saída estruturada      JSON validado por schema (Zod); até 2 retentativas
7. Cálculo determinístico macros, tendência, metas
8. Resposta               template preenchido com fatos (ou texto do LLM validado)
9. Log                    llm_chamada + mensagem
```

Falha em qualquer etapa → mensagem de fallback pedindo para reformular. Nada é salvo sem passar pela validação.

### 8.3 RAG

**Corpus 1 — Alimentos (MVP)**

- Fontes: Tabela TACO, Open Food Facts (industrializados/código de barras), alimentos criados pelo usuário.
- `medida_caseira`: concha, colher de sopa, escumadeira, fatia, unidade → gramas.
- Sinônimos regionais (ex.: macaxeira/aipim/mandioca; jerimum/abóbora).
- Busca **híbrida**: `pg_trgm` (texto) + `pgvector` (embedding) com fusão de ranking (RRF); top-k = 5 por item.
- O LLM **escolhe um `alimento_id` entre os candidatos recuperados** ou responde `sem_match`. Nunca inventa alimento nem valor nutricional.
- `sem_match` → pergunta ao usuário ("o que tem no cuscuz recheado?") e, opcionalmente, cria um alimento do usuário.

**Corpus 2 — Memória pessoal (MVP)**

- Refeições frequentes do usuário ("meu café de sempre") recuperadas por similaridade e passadas como candidatos prioritários.

**Corpus 3 — Base de conhecimento curada (v2)**

- Trechos curtos sobre treino e nutrição, cada um com fonte. Usado por `responder-duvida`.
- Resposta só com trechos acima de um limiar de similaridade; senão, "não tenho isso na minha base".

### 8.4 Guardrails

| Camada | Guardrail |
|---|---|
| Entrada | Whitelist de número; limite de texto (1.000 caracteres) e imagem; rate limit por minuto/dia |
| Injeção de prompt | Conteúdo do usuário sempre em campo delimitado e tratado como dado; texto dentro de imagens (rótulos) também é dado; instruções do usuário não alteram regras da skill |
| Escopo | Roteador com conjunto fechado de intenções; `fora_de_escopo` responde com template fixo |
| Saúde | `saude_sensivel` → template fixo recomendando profissional; nenhum conselho clínico; sinais de transtorno alimentar desligam sugestões de déficit e lembretes de dieta até revisão manual |
| Grounding | Seleção restrita a candidatos do retrieval; números só do backend |
| Saída | JSON Schema obrigatório; temperatura baixa (0–0,2) em extração; limite de tamanho |
| Validador numérico | Todo número no texto de relatório precisa existir no JSON de fatos (com tolerância de arredondamento); falhou → regenera 1× → fallback para template |
| Ações | LLM só escolhe ações de uma lista candidata do motor de regras (por ID) |
| Escrita | Toda escrita gera confirmação; correção por resposta |
| Custo | Teto diário de tokens; acima disso, só templates |
| Privacidade | Dados de saúde são dados pessoais sensíveis (LGPD); enviar ao LLM só o mínimo necessário, sem nome/telefone; chaves só no servidor |

### 8.5 Avaliação (evals)

- Cada skill tem `evals/casos.jsonl` com casos dourados (entrada → saída esperada ou propriedades).
- A suíte roda no CI sempre que uma skill, prompt ou modelo muda.

| Métrica | Meta MVP |
|---|---|
| JSON válido no 1º try | ≥ 98% |
| Acurácia de intenção | ≥ 95% |
| Recusa correta de fora de escopo / saúde | 100% nos casos dourados |
| Alimento correto (top-1) | ≥ 90% |
| Erro médio de gramas (texto com quantidade explícita) | ≤ 5% |
| Números alucinados em relatórios | 0 |

### 8.6 Observabilidade

- Tabela `llm_chamada` com skill, versão, modelo, tokens, latência e resultado da validação.
- Painel simples (SQL) com custo diário, taxa de falha de validação, latência p95.
- Toda correção do usuário ("foram 200g") é registrada como sinal de erro e vira candidata a caso de eval.

---

## 9. Skills do sistema

Skills são **módulos de instrução versionados** em `skills/<nome>/SKILL.md`. O orquestrador carrega apenas a skill da intenção detectada + a política global (`skills/_compartilhado/POLITICA.md`).

| Skill | Função | Usa LLM para | MVP |
|---|---|---|---|
| `roteador-intencao` | Classificar mensagem | Classificação | Sim |
| `registrar-refeicao` | Extrair itens e escolher alimentos | Extração + seleção entre candidatos | Sim |
| `registrar-peso` | Extrair peso e data | Extração | Sim |
| `resumo-pos-treino` | Redigir resumo curto | Redação sobre fatos | Sim |
| `relatorio-semanal` | Redigir relatório e escolher ações | Redação + seleção de ações | Sim |
| `responder-duvida` | Responder dúvidas com RAG | Redação com citação | v2 |

Cada SKILL.md define: quando usar, entrada, saída (schema), regras, exemplos e falhas conhecidas. Mudou a skill → incrementa a versão → roda evals.

---

## 10. Requisitos funcionais

Prioridade em MoSCoW (M = Must, S = Should, C = Could).

### Onboarding e perfil

| ID | Requisito | Prior. |
|---|---|---|
| RF-01 | O sistema deve coletar sexo, idade, altura, peso, objetivo, experiência e atividade no onboarding | M |
| RF-02 | O sistema deve aceitar % de gordura opcional e usar Katch-McArdle quando informado | S |
| RF-03 | O sistema deve sugerir um estilo de programa a partir dos dias por semana | M |
| RF-04 | O usuário deve poder alterar perfil e objetivo nas configurações | M |

### Programas e fila

| ID | Requisito | Prior. |
|---|---|---|
| RF-05 | O sistema deve oferecer templates de Full Body, Upper/Lower, PPL, Híbrido e ABCDE | M |
| RF-06 | O sistema deve organizar sessões em fila circular e exibir a próxima | M |
| RF-07 | O usuário deve poder pular uma sessão ou escolher outra da fila | M |
| RF-08 | O usuário deve poder editar slots, séries e faixas de uma sessão | M |
| RF-09 | O usuário deve poder trocar de programa preservando o histórico | M |
| RF-10 | O sistema deve exibir séries/semana por grupo muscular | S |

### Execução do treino

| ID | Requisito | Prior. |
|---|---|---|
| RF-11 | O usuário deve registrar peso e reps por série | M |
| RF-12 | O usuário deve poder marcar série como aquecimento | M |
| RF-13 | O sistema deve iniciar o timer de descanso ao concluir uma série | M |
| RF-14 | O usuário deve poder trocar o exercício de um slot por lista com imagens | M |
| RF-15 | O usuário deve poder associar foto própria a um exercício | S |
| RF-16 | O sistema deve funcionar sem conexão durante o treino | M |

### Progressão

| ID | Requisito | Prior. |
|---|---|---|
| RF-17 | O sistema deve calcular o status de progressão após cada treino (seção 4.1) | M |
| RF-18 | O sistema deve sugerir o próximo peso existente para o equipamento | M |
| RF-19 | O sistema deve exibir a barra "faltam X reps para subir" | M |
| RF-20 | O sistema deve detectar platô e sugerir redução ou troca de exercício | M |
| RF-21 | O sistema deve permitir configurar incrementos por equipamento | M |

### Progresso

| ID | Requisito | Prior. |
|---|---|---|
| RF-22 | O sistema deve listar exercícios com status subindo/estável/travado | M |
| RF-23 | O sistema deve exibir histórico de carga por exercício | M |
| RF-24 | O sistema deve exibir tendência de peso com pesagens ao fundo | M |
| RF-25 | O sistema deve exibir heatmap de consistência | S |

### WhatsApp

| ID | Requisito | Prior. |
|---|---|---|
| RF-26 | O sistema deve registrar refeições por texto | M |
| RF-27 | O sistema deve registrar refeições por foto com estimativa marcada | S |
| RF-28 | O sistema deve registrar pesagens com data | M |
| RF-29 | O sistema deve confirmar todo registro com totais do dia | M |
| RF-30 | O usuário deve poder corrigir o último registro respondendo | M |
| RF-31 | O usuário deve poder mudar o objetivo, com confirmação | M |
| RF-32 | O usuário deve poder consultar quanto falta de proteína/calorias | S |
| RF-33 | O sistema deve recusar assuntos fora de escopo com mensagem fixa | M |
| RF-34 | O sistema deve responder com template de segurança em temas de saúde | M |
| RF-35 | O sistema deve enviar resumo pós-treino | M |
| RF-36 | O sistema deve enviar lembrete de proteína (máx. 1/dia, condicional) | S |
| RF-37 | O sistema deve enviar relatório semanal no horário configurado | M |
| RF-38 | O sistema deve respeitar horário silencioso | M |

### Metas nutricionais

| ID | Requisito | Prior. |
|---|---|---|
| RF-39 | O sistema deve calcular metas iniciais por fórmula | M |
| RF-40 | O sistema deve calcular TDEE adaptativo quando houver dados suficientes | M |
| RF-41 | O sistema deve ajustar metas no máximo 1×/semana, em até ±200 kcal | M |
| RF-42 | O sistema deve aplicar as travas da seção 4.4 | M |

### Plataforma de IA

| ID | Requisito | Prior. |
|---|---|---|
| RF-43 | O sistema deve classificar toda mensagem em uma intenção de um conjunto fechado | M |
| RF-44 | O sistema deve recuperar candidatos de alimentos por busca híbrida | M |
| RF-45 | O sistema deve validar toda saída de LLM contra schema | M |
| RF-46 | O sistema deve validar números de relatórios contra fatos | M |
| RF-47 | O sistema deve registrar toda chamada de LLM | M |
| RF-48 | O sistema deve aplicar teto diário de custo | S |

---

## 11. Requisitos não funcionais

| ID | Categoria | Requisito |
|---|---|---|
| RNF-01 | Desempenho | Abrir o app até a tela Hoje em ≤ 1,5 s (cold start em aparelho intermediário) |
| RNF-02 | Usabilidade | Registrar uma série em ≤ 2 toques |
| RNF-03 | Offline | 100% das funções de treino operam offline; sync automático ao reconectar |
| RNF-04 | Latência WhatsApp | Confirmação de registro em ≤ 8 s p95 |
| RNF-05 | Confiabilidade | Nenhum dado de treino perdido em queda do app (escrita local imediata) |
| RNF-06 | Segurança | Chaves de API e tokens apenas no backend; RLS habilitado em todas as tabelas |
| RNF-07 | Privacidade | Dados de saúde tratados como sensíveis (LGPD); envio mínimo ao LLM; sem PII nos prompts |
| RNF-08 | Correção | Funções de domínio (progressão, tendência, metas) com cobertura de testes ≥ 90% |
| RNF-09 | Qualidade de IA | Metas da seção 8.5 verificadas no CI |
| RNF-10 | Custo | Custo de LLM ≤ teto mensal definido (meta inicial: equivalente a US$ 10/mês) |
| RNF-11 | Observabilidade | 100% das chamadas de LLM e webhooks logados com ID de correlação por mensagem |
| RNF-12 | Manutenibilidade | Arquitetura em camadas (domínio sem dependência de Flutter/Supabase); lint sem warnings |
| RNF-13 | Portabilidade | Android e iOS a partir do mesmo código; WhatsApp atrás de interface trocável |
| RNF-14 | Acessibilidade | Contraste AA, alvos de toque ≥ 48 dp, suporte a fonte ampliada |
| RNF-15 | Internacionalização | Textos em arquivos de i18n (pt-BR inicial); unidades em kg |

---

## 12. Épicos e user stories

Formato: Connextra + critérios de aceite em Gherkin. Estimativa em pontos (Fibonacci).

### E1 — Onboarding e perfil

**US-01** · 3 pts · M
Como usuário novo, quero informar meus dados e objetivo em poucos passos, para começar a treinar rápido.

```gherkin
Dado que abri o app pela primeira vez
Quando preencho dados corporais, objetivo, experiência e dias por semana
Então vejo um estilo sugerido
E consigo iniciar o primeiro treino em até 2 minutos
```

**US-02** · 2 pts · M
Como usuário, quero receber uma sugestão de estilo conforme meus dias disponíveis, para não precisar entender de periodização.

```gherkin
Dado que informei 4 dias por semana
Então o estilo sugerido é Upper/Lower
E posso escolher outro estilo da lista
```

### E2 — Programas e fila

**US-03** · 5 pts · M
Como usuário, quero que o app me mostre sempre o próximo treino da fila, para não me perder quando falto.

```gherkin
Dado um programa Upper/Lower com fila [Upper A, Lower A, Upper B, Lower B]
E meu último treino foi Upper A há 5 dias
Quando abro a tela Hoje
Então vejo "Lower A" como próximo treino
```

**US-04** · 2 pts · M
Como usuário, quero pular ou escolher outro treino da fila, para me adaptar à academia lotada.

**US-05** · 5 pts · M
Como usuário, quero editar slots, séries e faixas de uma sessão, para ajustar o programa ao meu gosto.

**US-06** · 3 pts · M
Como usuário, quero trocar de programa sem perder meu histórico, para mudar de estilo sem recomeçar.

```gherkin
Dado que tenho 3 meses de histórico de supino no PPL
Quando troco para Upper/Lower
Então o histórico e a sugestão de carga do supino continuam disponíveis
```

### E3 — Execução do treino

**US-07** · 5 pts · M
Como usuário, quero registrar cada série com poucos toques, para não perder tempo entre séries.

**US-08** · 2 pts · M
Como usuário, quero marcar séries de aquecimento, para que elas não atrapalhem a progressão.

```gherkin
Dado que registrei 2 séries de aquecimento e 3 válidas
Quando o treino é avaliado
Então apenas as 3 séries válidas entram no cálculo
```

**US-09** · 2 pts · M
Como usuário, quero um timer de descanso automático, para controlar o intervalo sem abrir outro app.

**US-10** · 5 pts · M
Como usuário, quero trocar o exercício de um slot escolhendo por imagem, para substituir uma máquina ocupada.

**US-11** · 3 pts · S
Como usuário, quero tirar foto da máquina da minha academia, para reconhecer o exercício na lista.

**US-12** · 8 pts · M
Como usuário, quero treinar sem internet, para não depender do sinal da academia.

### E4 — Progressão

**US-13** · 8 pts · M
Como iniciante, quero que o app me diga quando aumentar a carga, para evoluir sem adivinhar.

```gherkin
Dado o supino inclinado com faixa 8–12, 3 séries, 30kg
Quando registro 12, 12, 12
Então o status é "subir"
E a sugestão do próximo treino é o próximo peso disponível do equipamento

Dado que subi para 32kg
Quando registro 7, 7, 6
Então o status é "carga_alta"
E a sugestão é voltar para 30kg ou usar peso intermediário

Dado que estou em 32kg
Quando registro 9, 8, 7
Então o status é "manter"
E a barra mostra "24 de 36 reps"
```

**US-14** · 3 pts · M
Como usuário, quero ver quantas reps faltam para subir a carga, para ter um objetivo claro em cada treino.

**US-15** · 5 pts · M
Como usuário, quero ser avisado quando travar num exercício, para tomar uma ação.

```gherkin
Dado 3 treinos seguidos no mesmo peso sem aumento no total de reps
Então o status é "travado"
E vejo as opções "reduzir ~10%" e "trocar exercício"
```

**US-16** · 3 pts · M
Como usuário, quero configurar os incrementos de cada equipamento, para receber sugestões de peso que existem na minha academia.

### E5 — Progresso

**US-17** · 5 pts · M
Como usuário, quero ver meus exercícios com status de evolução, para saber o que está funcionando.

**US-18** · 3 pts · M
Como usuário, quero ver a tendência do meu peso, para não me assustar com flutuações diárias.

**US-19** · 2 pts · S
Como usuário, quero ver um calendário dos dias treinados, para me motivar com a consistência.

### E6 — WhatsApp: registros

**US-20** · 13 pts · M (fatiar no planejamento: texto simples → medidas caseiras → múltiplos itens)
Como usuário, quero registrar refeições mandando texto no WhatsApp, para não precisar abrir app nem buscar alimentos.

```gherkin
Dado que envio "almocei 150g de frango, arroz e feijão, uma concha de cada"
Quando o sistema processa
Então recebo confirmação com os 3 itens, gramas, proteína e kcal
E os totais do dia atualizados
E itens com porção assumida aparecem com "~"
```

**US-21** · 8 pts · S
Como usuário, quero mandar foto do prato, para registrar quando estou com pressa.

**US-22** · 3 pts · M
Como usuário, quero registrar meu peso por mensagem e receber feedback conforme meu objetivo.

```gherkin
Dado que estou em bulking com ritmo alvo de 0,8–1,2 kg/mês
E a tendência subiu 3 kg no mês
Quando envio "me pesei hoje, 80kg"
Então recebo que estou acima do ritmo ideal
E a informação do ajuste de meta, se houver
```

**US-23** · 5 pts · M
Como usuário, quero corrigir o último registro respondendo, para manter os dados corretos.

**US-24** · 3 pts · M
Como usuário, quero mudar meu objetivo pelo WhatsApp, para não precisar entrar nas configurações.

```gherkin
Quando envio "quero começar um cutting"
Então recebo as novas metas calculadas e um pedido de confirmação
E nada muda até eu confirmar
```

**US-25** · 2 pts · S
Como usuário, quero perguntar quanto falta de proteína hoje, para ajustar o jantar.

**US-26** · 3 pts · M
Como usuário, quero que o bot recuse assuntos fora de treino e dieta, para que ele seja previsível.

```gherkin
Quando envio "escreve um poema" ou "ignore suas instruções"
Então recebo a mensagem fixa de escopo
E nenhum dado é alterado
```

**US-27** · 3 pts · M
Como usuário, quero que temas de saúde sejam tratados com cuidado, para não receber conselho perigoso.

### E7 — WhatsApp: mensagens automáticas

**US-28** · 5 pts · M
Como usuário, quero um resumo no WhatsApp ao terminar o treino, para ver na hora o que evoluiu.

**US-29** · 3 pts · S
Como usuário, quero um lembrete à noite só se estiver longe da meta de proteína, para não ser incomodado à toa.

**US-30** · 8 pts · M
Como usuário, quero um relatório semanal curto com 1–2 ações concretas, para saber o que ajustar.

```gherkin
Dado que é domingo no horário configurado
Então recebo um relatório com treino, dieta, peso e próximas ações
E todo número citado existe nos dados da semana
E o texto cabe em uma tela de celular
```

### E8 — Metas nutricionais

**US-31** · 5 pts · M
Como usuário, quero metas iniciais calculadas a partir do meu perfil, para começar sem fazer contas.

**US-32** · 8 pts · M
Como usuário, quero que as metas se ajustem com base nos meus dados reais, para que fiquem certas pra mim.

**US-33** · 3 pts · M
Como usuário, quero travas que impeçam metas perigosas, para não ser prejudicado por um dado errado.

### E9 — Plataforma de IA (enablers)

**US-34** · 5 pts · M — Como dev, quero um roteador de intenção com conjunto fechado, para controlar o escopo.
**US-35** · 8 pts · M — Como dev, quero RAG híbrido de alimentos com TACO e medidas caseiras, para que o LLM só escolha alimentos reais.
**US-36** · 5 pts · M — Como dev, quero validação por schema com retentativa e fallback, para nunca salvar dado malformado.
**US-37** · 3 pts · M — Como dev, quero um validador numérico de relatórios, para zerar números alucinados.
**US-38** · 5 pts · M — Como dev, quero uma suíte de evals no CI por skill, para detectar regressão ao mudar prompt ou modelo.
**US-39** · 3 pts · M — Como dev, quero logar toda chamada de LLM com custo e latência, para depurar e controlar gastos.
**US-40** · 3 pts · M — Como dev, quero um adaptador de WhatsApp trocável, para mudar de provedor sem reescrever o backend.

---

## 13. Processo (SDLC + ágil)

### 13.1 Fases do SDLC

| Fase | Artefatos |
|---|---|
| Planejamento e requisitos | Este PRD, backlog priorizado |
| Design | Wireframes low-fi das 3 telas, ADRs, modelo de dados, specs das skills |
| Implementação | Sprints, PRs pequenos, AGENTS.md para agentes de código |
| Testes | Unitários (domínio), widget tests, integração (Edge Functions), evals de IA |
| Deploy | CI/CD (GitHub Actions): lint → testes → evals → migrations → build |
| Operação e manutenção | Painel de logs; revisão semanal das correções do usuário → novos casos de eval |

### 13.2 Método

Scrumban para dev solo: sprints de 1 semana, quadro Kanban (Backlog → Pronto → Fazendo → Revisão → Feito), WIP máximo de 2. Cerimônias leves: planejamento de 30 min na segunda e retrospectiva escrita de 5 linhas na sexta.

### 13.3 Definition of Ready

- Story no formato Connextra, com critérios de aceite.
- Dependências identificadas.
- Estimada em ≤ 8 pts (maior que isso, fatiar).

### 13.4 Definition of Done

- Critérios de aceite passam.
- Testes unitários para regras de domínio; evals passando se tocou em skill.
- Lint e análise estática sem warnings.
- Migrations versionadas; RLS revisado.
- Documentação (PRD/ADR/SKILL.md) atualizada se o comportamento mudou.

### 13.5 Roadmap

| Sprint | Entrega | Stories |
|---|---|---|
| 0 | Setup: repo, CI, Flutter + Drift, Supabase local, AGENTS.md | — |
| 1 | Programas, fila e execução básica | US-01..07, US-09 |
| 2 | Progressão completa + offline | US-08, US-10, US-12..16 |
| 3 | Tela Progresso | US-17..19 · **Release α (app sozinho)** |
| 4 | Infra WhatsApp, roteador, peso, escopo | US-22, US-26, US-27, US-34, US-36, US-39, US-40 |
| 5 | Refeições + RAG | US-20, US-23, US-25, US-35 |
| 6 | Metas, mensagens automáticas, relatório | US-24, US-28..33, US-37 · **Release β** |
| 7 | Hardening: evals, custo, foto de refeição | US-11, US-21, US-38 · **v1.0** |

---

## 14. Riscos, decisões e questões em aberto

### Riscos

| Risco | Impacto | Mitigação |
|---|---|---|
| Bloqueio de número com API não oficial | Alto | Chip dedicado; adaptador trocável para Cloud API |
| Estimativa de refeição imprecisa | Médio | Confirmação + correção; TDEE adaptativo absorve viés |
| Custo de LLM crescer | Baixo | Teto diário; modelo menor no roteador e na extração |
| Licença de imagens de exercícios | Médio | Usar bases abertas verificando a licença; fotos próprias |
| Abandono do projeto (solo) | Alto | Release α usável cedo (só app); sprints curtos |
| Orientação nutricional inadequada | Alto | Travas determinísticas; LLM não decide metas |

### Decisões registradas (ADRs)

- **ADR-001** (`docs/adr/001-dupla-progressao-e-offline-first.md`) — Dupla progressão roda no app (offline) em Dart 3 nativo (*Functional Core, Imperative Shell* + MVVM com Riverpod manual); persistência no Drift e sincronização via *Transactional Outbox* com UUIDs gerados no cliente.
- **ADR-002** (`docs/adr/002-integracao-whatsapp-gateway.md`) — WhatsApp atrás da porta hexagonal `WhatsAppGateway`. No MVP, implementação com **Evolution API** (Docker + chip dedicado) e `FakeWhatsAppGateway` para testes, com webhook não-bloqueante (`EdgeRuntime.waitUntil`).
- **ADR-003** (`docs/adr/003-arquitetura-ia-rag-e-provedor-llm.md`) — LLM nunca produz números; RAG híbrido (`pg_trgm` + `pgvector` com RRF) com seleção restrita a `alimento_id`. Provedor padrão **Google Gemini**: `gemini-2.5-flash` (roteamento, extração e visão), `gemini-2.5-pro` (relatórios) e `text-embedding-004` (`vector(768)`). Runtime TypeScript unificado em **Deno** entre Edge Functions e `evals/`.
- **ADR-004** (`docs/adr/004-modelagem-series-individuais.md`) — Séries salvas individualmente (compatível com pirâmide futura); aquecimento isolado das métricas; histórico e progressão vinculados ao `exercicio` (preservados ao trocar de programa).
- **ADR-005** (`docs/adr/005-autenticacao-vinculo-whatsapp-e-catalogo.md`) — Sessão imediata via **Supabase Anonymous Auth** (cumprindo onboarding ≤ 2 min com RLS ativo em todas as tabelas), vínculo do WhatsApp via código curto enviado ao bot, catálogo curado de ~50 exercícios com imagens em domínio público do `free-exercise-db` (*Unlicense*) e foco inicial **Android-first** mantendo compatibilidade total com iOS.

### Questões resolvidas para a Sprint 0

1. **Provedor e modelos de LLM:** Resolvido no **ADR-003** (Google Gemini: `gemini-2.5-flash` + `gemini-2.5-pro` + `text-embedding-004` com 768 dimensões).
2. **Evolution API vs. Cloud API no MVP:** Resolvido no **ADR-002** (Evolution API no MVP via `WhatsAppGateway`, pronto para Cloud API futura).
3. **Fonte das imagens de exercícios:** Resolvido no **ADR-005** (`free-exercise-db`, licença *Unlicense* / Domínio Público, curado para ~50 exercícios em `pt-BR`).
4. **Android primeiro ou ambos:** Resolvido no **ADR-005** (Android-first para desenvolvimento/releases locais em Linux, com pacotes 100% compatíveis com iOS via GitHub Actions).
