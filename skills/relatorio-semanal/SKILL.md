---
name: relatorio-semanal
description: Redige o relatório semanal de domingo no WhatsApp a partir de um JSON de fatos (treino, dieta, peso e ajuste de meta) e escolhe 1 ou 2 ações de uma lista de candidatas gerada pelo motor de regras. Use sempre que o cron semanal disparar o relatório, ou quando o usuário pedir explicitamente o relatório da semana.
---

# Relatório semanal · v0.1

## Princípio

O motor de regras (backend) já decidiu **o que é relevante** e **quais ações fazem sentido**. Você decide **como contar** e **quais 1–2 ações priorizar**. Você não cria ações novas.

## Entrada

```json
{
  "fatos": {
    "periodo": "27/10 a 02/11",
    "objetivo": "bulking",
    "treino": {
      "sessoes_feitas": 4, "sessoes_planejadas": 4,
      "subidas": [ { "exercicio": "Agachamento", "de": 80, "para": 82.5 } ],
      "travados": [ { "exercicio": "Supino reto", "semanas": 3 } ]
    },
    "dieta": {
      "dias_registrados": 6,
      "dias_meta_proteina": 3, "meta_proteina_g": 160,
      "dias_meta_kcal": 5, "meta_kcal": 2800
    },
    "peso": {
      "tendencia_atual": 80.6, "variacao_semana": 0.4,
      "ritmo_alvo_semana": "0,2 a 0,3", "status_ritmo": "acima",
      "confianca": "alta"
    },
    "ajuste_meta": { "aplicado": true, "kcal_antes": 2800, "kcal_depois": 2650 }
  },
  "acoes_candidatas": [
    { "id": "A1", "texto_base": "priorizar proteína nos fins de semana", "prioridade": 0.9 },
    { "id": "A2", "texto_base": "manter o supino e observar após melhorar a proteína", "prioridade": 0.7 },
    { "id": "A3", "texto_base": "se pesar 3x por semana", "prioridade": 0.3 }
  ]
}
```

## Saída

```json
{
  "texto": "string, máx. 900 caracteres",
  "acoes_escolhidas": ["A1", "A2"],
  "numeros_citados": [4, 82.5, 3, 160, 80.6, 0.4, 2650]
}
```

## Estrutura do texto

1. **Treino** (1–2 linhas): sessões feitas, subidas de carga, travados.
2. **Dieta** (1 linha): dias que bateu proteína e kcal.
3. **Peso** (1–2 linhas): tendência, comparação com o ritmo alvo, ajuste de meta se `aplicado`.
4. **Próxima semana** (1–2 linhas): as ações escolhidas, reescritas em tom natural, sem mudar o sentido.

## Regras

1. Todo número do texto deve estar em `fatos` e em `numeros_citados`. O validador rejeita o texto se não bater.
2. `acoes_escolhidas` deve conter 1 ou 2 IDs de `acoes_candidatas`. Prefira maior `prioridade`, mas pode trocar se duas ações forem redundantes.
3. Não relacione causas que não estão nos fatos. Se o motor de regras colocou "manter o supino e observar após melhorar a proteína", você pode conectar proteína e supino; caso contrário, não.
4. `confianca: "baixa"` no peso → diga que a tendência ainda é incerta.
5. Sem culpa, sem drama: "3 de 7 dias" é dado, não fracasso.
6. Sem conselhos médicos, suplementos ou mudanças de treino que não vieram das ações.

## Exemplo de saída

```
Semana 27/10 a 02/11
Treino: 4 de 4 sessões. Agachamento subiu pra 82,5kg. O supino está parado há 3 semanas.
Dieta: bateu a proteína (160g) em 3 dias e as calorias em 5.
Peso: tendência em 80,6kg, +0,4kg na semana, um pouco acima do ritmo. Ajustei sua meta pra 2.650 kcal.
Próxima semana: foca em bater a proteína também no fim de semana. Mantém o supino como está e vemos se ele destrava com a proteína em dia.
```
