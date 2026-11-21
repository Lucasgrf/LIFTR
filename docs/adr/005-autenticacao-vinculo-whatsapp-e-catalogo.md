# ADR-005: Autenticação sem atrito (Anonymous Auth), vínculo com WhatsApp por código e catálogo curado (free-exercise-db)

- **Status:** Aceito
- **Data:** 03/11/2026
- **Contexto:** PRD §1, §3, §5, §8.4, §14, RNF-03, RNF-06, RNF-13, US-01, US-10, US-11

## Contexto e Problema

Restavam três questões de arquitetura e produto interligadas:
1. **Autenticação vs. Onboarding ≤ 2 min + RLS:** O requisito RNF-06 exige RLS habilitado em todas as tabelas do Supabase (`auth.uid() = usuario_id`), mas a US-01 exige que um usuário novo preencha seus dados e inicie o primeiro treino em até 2 minutos (inclusive podendo conectar o WhatsApp depois). Além disso, o gate de entrada do WhatsApp (§8.4) exige que apenas números autorizados na whitelist interajam com o bot.
2. **Fonte e Licença das Imagens de Exercícios (§14 Questão #3):** Precisávamos de imagens genéricas claras para o catálogo curado de exercícios por slot sem incorrer em violação de direitos autorais nem exigir atribuições complexas na UI de treino.
3. **Plataforma Alvo Inicial (§14 Questão #4):** Definir a prioridade entre Android e iOS considerando o ambiente de desenvolvimento Linux.

## Decisão

### 1. Supabase Anonymous Auth + Vínculo de WhatsApp por Código Curto
- **Sessão Imediata no App:**
  - Ao abrir o app pela primeira vez, o cliente cria/usa uma sessão via **Supabase Anonymous Auth** (ou mantém um UUID local sincronizado assim que houver rede), garantindo um `usuario_id` (`auth.uid()`) válido para todas as políticas RLS sem exigir e-mail/senha antes do primeiro treino.
  - Em **Configurações**, o usuário pode vincular um e-mail/Google à mesma conta (`linkIdentity`) para backup entre aparelhos.
- **Vínculo e Whitelist do WhatsApp:**
  - Quando o usuário opta por conectar o WhatsApp (no passo 6 do onboarding ou em Configurações), o app gera um código temporário de 6 dígitos na tabela `acao_pendente` (`tipo = 'vincular_whatsapp'`, expiração de 15 minutos) e exibe um botão/link `wa.me` com a mensagem `"CONECTAR <codigo>"`.
  - Ao receber a mensagem no webhook, o backend valida o código, grava `whatsapp_numero` no `perfil` do usuário e ativa automaticamente o número na whitelist.

### 2. Catálogo Curado de Exercícios com `free-exercise-db` (Unlicense)
- O seed inicial (`supabase/seed/`) conterá uma lista curada de **~50 exercícios em português (`pt-BR`)**, mapeados para todos os padrões de movimento (`padrao_movimento`) dos 5 estilos de programa do MVP (Full Body, Upper/Lower, PPL, Híbrido UL+Full e ABCDE).
- As imagens genéricas de cada exercício são extraídas do repositório aberto **`free-exercise-db`**, licenciado sob **The Unlicense (Domínio Público)**, hospedadas no Supabase Storage / assets do app.
- O usuário pode sobrepor a imagem genérica tirando foto do equipamento da sua própria academia (`foto_usuario_url`, US-11).

### 3. Estratégia de Plataforma Mobile: Android-First com Portabilidade iOS
- O desenvolvimento e os testes locais focam em **Android** (compatível nativamente com o ambiente Linux de desenvolvimento).
- Todas as dependências Flutter escolhidas (`drift`, `flutter_riverpod`, `go_router`, `fl_chart`, `supabase_flutter`, `image_picker`) são 100% multiplataforma, permitindo builds iOS via GitHub Actions (`macos-latest`) sem reescrita de código (RNF-13).

## Consequências

- **Positivas:**
  - Onboarding realmente cumprido em menos de 2 minutos sem tela de login bloqueante, mantendo RLS estrito em 100% das tabelas.
  - A posse do número de WhatsApp é provada criptograficamente pelo próprio envio da mensagem `"CONECTAR <codigo>"`, evitando que alguém cadastre o número de terceiros para receber mensagens do bot.
  - Risco jurídico zero com licenças de imagens de exercícios (Domínio Público).
- **Negativas / Trade-offs:**
  - Contas anônimas não vinculadas a e-mail/WhatsApp não podem ser recuperadas se o usuário desinstalar o app e limpar dados locais (mitigado por banner discreto em Configurações incentivando conectar o WhatsApp ou e-mail).

