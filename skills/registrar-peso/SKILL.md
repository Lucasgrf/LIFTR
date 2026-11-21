---
name: registrar-peso
description: Extrai peso corporal, unidade e data de uma mensagem ou foto de balança. Use sempre que o roteador classificar registrar_peso, ou corrigir_ultimo quando o último registro for uma pesagem. Apenas extrai; a tendência, a taxa e o feedback vêm do backend.
---

# Registrar peso · v0.1

## Princípio

Esta é a skill mais simples de propósito. O LLM só extrai o número e a data. **Tudo que o usuário lê na resposta vem de template com fatos calculados pelo backend.** Isso elimina a chance de o modelo inventar "você ganhou 3kg".

## Entrada

```json
{
  "mensagem_usuario": "ontem me pesei e deu 80,4",
  "descricao_imagem": null,
  "hoje": "2026-11-02"
}
```

## Saída

```json
{
  "peso": 80.4,
  "unidade": "kg | lb",
  "data": "2026-11-01",
  "condicao": "jejum | apos_comer | nao_informada",
  "precisa_esclarecer": false,
  "pergunta_esclarecimento": null
}
```

## Regras

1. Aceite vírgula ou ponto decimal. "80,4", "80.4" e "80 e 400" → 80.4.
2. "Hoje", sem data, ou foto → `data = hoje`. "Ontem" → hoje − 1. Datas relativas além de 7 dias → peça confirmação.
3. Sem unidade → `kg`. "lb", "libras" → `lb` (o backend converte).
4. Mais de um número possível ("80 ou 81, não lembro") → `precisa_esclarecer: true`.
5. Não comente se o peso é bom ou ruim. Não escreva texto para o usuário.

## Validação no backend (determinística)

- Fora de 30–300 kg → rejeita e pede para confirmar.
- Diferença > 3 kg da tendência atual → salva como pendente e pergunta "Confirma 85kg? Sua tendência está em 80,6kg."

## Templates de resposta (backend)

| Situação | Template |
|---|---|
| Dentro do ritmo | "Registrei {peso}kg. Sua tendência {variou} {delta}kg {periodo}, dentro do ritmo pra você ({faixa}). Segue assim." |
| Acima do ritmo (bulking) | "Registrei {peso}kg. Sua tendência subiu {delta}kg {periodo}, acima do ritmo ideal ({faixa}). {ajuste_meta}" |
| Abaixo do ritmo (bulking) | "Registrei {peso}kg. Sua tendência subiu {delta}kg {periodo}, abaixo do ritmo ({faixa}). {ajuste_meta}" |
| Cutting rápido demais | "Registrei {peso}kg. Você está perdendo mais rápido que o recomendado ({faixa}). Vou segurar novos cortes na meta." |
| Poucos dados | "Registrei {peso}kg. Ainda tenho poucas pesagens pra calcular sua tendência; tenta se pesar umas 3 vezes por semana, de manhã e em jejum." |
