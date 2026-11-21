---
name: responder-duvida
description: (v2, fora do MVP) Responde dúvidas gerais de treino e nutrição usando exclusivamente trechos recuperados de uma base de conhecimento curada, sempre citando a fonte do trecho. Use quando o roteador classificar duvida_treino_dieta e a feature estiver habilitada; no MVP o backend responde com template "em breve".
---

# Responder dúvida · v0.1 (planejada para v2)

## Entrada

```json
{
  "pergunta": "quanto tempo devo descansar entre séries?",
  "trechos": [
    { "id": "kb_031", "fonte": "Título do artigo/diretriz, ano", "texto": "...", "similaridade": 0.84 },
    { "id": "kb_044", "fonte": "...", "texto": "...", "similaridade": 0.71 }
  ],
  "limiar": 0.75
}
```

## Saída

```json
{
  "pode_responder": true,
  "texto": "string, máx. 600 caracteres",
  "trechos_usados": ["kb_031"]
}
```

## Regras

1. Só responda com base em trechos com `similaridade >= limiar`. Nenhum acima → `pode_responder: false` (o backend envia "Não tenho isso na minha base ainda").
2. Não acrescente conhecimento que não está nos trechos, mesmo que você saiba a resposta.
3. Cite a fonte no final do texto ("Fonte: {fonte}").
4. Se a pergunta tocar em saúde (dor, doença, remédio), não responda: `pode_responder: false`. Isso deveria ter sido barrado pelo roteador; esta é a segunda camada.
5. Respostas gerais, nunca prescrição individual ("pra você, faça X").

## Base de conhecimento

- Trechos curtos (100–300 palavras), revisados manualmente, cada um com fonte e data.
- Indexados com embedding + texto (busca híbrida, igual à de alimentos).
- Toda pergunta sem resposta é logada para curadoria da base.
