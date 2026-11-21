---
name: registrar-refeicao
description: Transforma a descrição de uma refeição (texto livre ou descrição de foto do prato) em itens estruturados com alimento e gramas, escolhendo alimentos apenas entre candidatos recuperados da base (TACO, Open Food Facts, alimentos do usuário). Use sempre que o roteador classificar registrar_refeicao, ou corrigir_ultimo quando o último registro for uma refeição.
---

# Registrar refeição · v0.1

Esta skill roda em **duas etapas**, com o backend no meio. Em nenhuma delas você calcula calorias ou proteína.

```
Etapa A (LLM)      texto/foto → itens mencionados (nome, quantidade, unidade)
Backend            para cada item: busca híbrida → top-5 candidatos + medidas caseiras
Etapa B (LLM)      itens + candidatos → alimento_id + gramas por item
Backend            calcula macros, salva como pendente de confirmação, responde por template
```

## Etapa A — Extração

### Entrada

```json
{
  "mensagem_usuario": "almocei 150g de frango, arroz e feijão, uma concha de cada",
  "descricao_imagem": null,
  "momento": "2026-11-02T12:40:00-03:00"
}
```

### Saída

```json
{
  "refeicao": "almoco | cafe_da_manha | lanche | jantar | ceia | nao_informado",
  "itens": [
    { "texto": "frango", "preparo": "nao_informado", "quantidade": 150, "unidade": "g" },
    { "texto": "arroz", "preparo": "nao_informado", "quantidade": 1, "unidade": "concha" },
    { "texto": "feijão", "preparo": "nao_informado", "quantidade": 1, "unidade": "concha" }
  ],
  "origem": "texto | foto",
  "precisa_esclarecer": false,
  "pergunta_esclarecimento": null
}
```

### Regras da etapa A

1. Um item por alimento. "Arroz e feijão, uma concha de cada" gera 2 itens com 1 concha cada.
2. `unidade` ∈ `g`, `ml`, `unidade`, `fatia`, `concha`, `colher_sopa`, `colher_cha`, `escumadeira`, `copo`, `xicara`, `porcao`, `nao_informada`.
3. Quantidade não dita → `quantidade: null`, `unidade: "nao_informada"`. Não invente quantidade.
4. Preparo só se explícito ("grelhado", "frito", "cozido"). Senão `nao_informado`.
5. Foto: liste os itens visíveis com `unidade: "porcao"` e `quantidade` como estimativa de porções (0.5, 1, 1.5, 2). Marque `origem: "foto"`.
6. Texto ilegível ou ambíguo demais ("comi aquilo de ontem" sem histórico) → `precisa_esclarecer: true`.
7. Não converta para gramas aqui. Isso é da etapa B, com as medidas caseiras do backend.

## Etapa B — Seleção

### Entrada

```json
{
  "itens": [
    {
      "indice": 0,
      "texto": "frango", "preparo": "nao_informado", "quantidade": 150, "unidade": "g",
      "candidatos": [
        { "alimento_id": "taco_409", "nome": "Frango, peito, sem pele, grelhado" },
        { "alimento_id": "taco_410", "nome": "Frango, peito, sem pele, cozido" },
        { "alimento_id": "usr_12", "nome": "Frango do almoço (meu)", "frequencia_uso": 18 }
      ],
      "medidas_caseiras": []
    },
    {
      "indice": 1,
      "texto": "arroz", "quantidade": 1, "unidade": "concha",
      "candidatos": [ { "alimento_id": "taco_3", "nome": "Arroz, tipo 1, cozido" } ],
      "medidas_caseiras": [ { "nome": "concha", "gramas": 100 }, { "nome": "colher_sopa", "gramas": 25 } ]
    }
  ]
}
```

### Saída

```json
{
  "selecoes": [
    { "indice": 0, "alimento_id": "usr_12", "gramas": 150, "porcao_assumida": false, "confianca": 0.9 },
    { "indice": 1, "alimento_id": "taco_3", "gramas": 100, "porcao_assumida": false, "confianca": 0.85 }
  ],
  "sem_match": [],
  "pergunta_esclarecimento": null
}
```

### Regras da etapa B

1. `alimento_id` **precisa** estar na lista `candidatos` daquele item. Qualquer outro valor é inválido.
2. Prefira alimentos do usuário (`usr_*`) com alta `frequencia_uso` quando o nome bater.
3. Preparo não informado → escolha a forma mais comum de consumo (cozido para arroz/feijão; grelhado para peito de frango) e reduza a confiança em 0.1.
4. Gramas: se `unidade = g`, use a quantidade. Se for medida caseira, use **apenas** `medidas_caseiras` fornecidas. Se a medida não estiver na lista, ou `quantidade = null`, use a `porcao` padrão do candidato e marque `porcao_assumida: true`.
5. Nenhum candidato serve → coloque o índice em `sem_match` e escreva uma pergunta curta em `pergunta_esclarecimento` ("O que tinha no cuscuz recheado?").
6. Nunca retorne calorias, proteína ou qualquer valor nutricional.

## Resposta ao usuário (template do backend, não do LLM)

```
Registrei: {item1} ({g1}g), {item2} (~{medida}, {g2}g)...
~{prot}g de proteína · ~{kcal} kcal
Hoje: {prot_dia}/{meta_prot}g de proteína · {kcal_dia}/{meta_kcal} kcal
(responda corrigindo se algo estiver errado)
```

## Correção (`corrigir_ultimo`)

O backend reenvia o registro anterior em `registro_atual` junto com a nova mensagem. Rode a etapa A só sobre a mensagem de correção e devolva **apenas os itens alterados**, com `"acao": "substituir" | "remover" | "adicionar"` e o `indice` original.
