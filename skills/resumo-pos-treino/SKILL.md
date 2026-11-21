---
name: resumo-pos-treino
description: Redige o resumo curto enviado no WhatsApp quando um treino é finalizado, usando somente os fatos calculados pelo app (cargas que subiram, status de progressão, platôs). Use sempre que o backend receber o evento treino_finalizado.
---

# Resumo pós-treino · v0.1

## Entrada

```json
{
  "fatos": {
    "sessao": "Lower A",
    "duracao_min": 58,
    "exercicios": [
      { "nome": "Agachamento livre", "status": "subir", "peso": 80, "proximo_peso": 82.5, "reps": [10, 10, 10] },
      { "nome": "Leg press", "status": "manter", "peso": 160, "progresso": "33/36" },
      { "nome": "Cadeira flexora", "status": "travado", "peso": 45, "sessoes_travado": 3 }
    ],
    "subidas_de_carga": 1,
    "proxima_sessao": "Upper B"
  }
}
```

## Saída

```json
{
  "texto": "string, máx. 400 caracteres",
  "numeros_citados": [80, 82.5, 33, 36, 45]
}
```

## Regras

1. Comece pelo que **subiu** (comemorar é o ponto). Depois o que está perto ("faltam 3 reps"). Por último, no máximo um item travado.
2. Só cite números presentes em `fatos`. Liste todos em `numeros_citados` (o validador confere).
3. Item travado: apenas avise e diga que o app mostra as opções. Não sugira treino, técnica ou suplemento.
4. Termine com a próxima sessão da fila.
5. Máximo 400 caracteres e no máximo 1 emoji.
6. Nenhuma subida e nada perto → foque em consistência ("treino registrado, {sessao} feito").

## Exemplo de saída

```
Lower A feito em 58 min. Agachamento fechou 3x10 com 80kg: próximo treino é 82,5kg 💪
Leg press tá em 33 de 36 reps, falta pouco.
Cadeira flexora está parada há 3 treinos; no app tem opções pra destravar.
Próximo: Upper B.
```
