# ADR-002: Integração com WhatsApp via porta WhatsAppGateway e escolha da Evolution API no MVP

- **Status:** Aceito
- **Data:** 03/11/2026
- **Contexto:** PRD §6, §7.3, §14, RNF-04, RNF-11, RNF-13, US-40

## Contexto e Problema

O WhatsApp é a interface única para registro de refeições (texto e foto), pesagens, mudança de objetivo, lembretes de proteína, resumos pós-treino e relatórios semanais.

Existiam duas alternativas principais de provedor para o MVP:
1. **Evolution API (auto-hospedada via Docker):** Simples de configurar com um chip dedicado, gratuita e sem restrição da janela de 24h para envio de mensagens proativas (como o relatório de domingo ou lembrete de proteína quando o usuário não interagiu nas últimas 24h), porém baseada em protocolo não oficial (risco de bloqueio do número se usado para spam).
2. **Meta WhatsApp Cloud API (oficial):** Sem risco de banimento arbitrário, mas exige verificação Meta Business e aprovação prévia de *Utility Templates* tarifados para qualquer mensagem ativa enviada fora da janela de 24h de atendimento.

## Decisão

### 1. Porta Hexagonal `WhatsAppGateway`
Toda comunicação com o WhatsApp em `supabase/functions/_shared/whatsapp/` ocorre exclusivamente através da interface `WhatsAppGateway`:
- `enviarTexto(destino: string, texto: string, opcoes?: { idCorrelacao?: string }): Promise<Result<MensagemEnviada, ErroWhatsApp>>`
- `baixarMidia(midiaIdOuUrl: string): Promise<Result<Uint8Array, ErroWhatsApp>>`
- `parsearWebhook(req: Request): Promise<Result<EventoWebhookWhatsApp | null, ErroWhatsApp>>`

### 2. Implementações para o MVP
1. **`EvolutionWhatsAppGateway` (Padrão no MVP):**
   - Conecta a uma instância da Evolution API rodando em Docker (ambiente local no dev / VPS em produção) com **chip dedicado** exclusivamente para o bot.
   - Permite enviar tanto respostas imediatas quanto mensagens ativas (resumo pós-treino, lembrete de proteína e relatório semanal) usando os templates de texto do próprio backend (`_shared/templates/`).
2. **`FakeWhatsAppGateway` (Testes e Desenvolvimento Local):**
   - Implementação em memória injetada nos testes das Edge Functions (`deno test`), gravando todas as mensagens enviadas para asserções determinísticas sem rede.

### 3. Webhook Não-Bloqueante
- A Edge Function `whatsapp-webhook` valida o token/origem do webhook, extrai o evento via `WhatsAppGateway.parsearWebhook()`, aplica o gate de entrada (whitelist de número, tamanho e rate limit) e dispara o `orquestrador` de forma assíncrona com `EdgeRuntime.waitUntil(...)`, retornando `200 OK` imediatamente ao provedor para evitar retentativas duplicadas por timeout.

## Consequências

- **Positivas:**
  - Zero atrito burocrático no MVP para validar o produto com o primeiro usuário.
  - Caso o projeto escale para múltiplos usuários e migre para a API oficial, basta implementar `CloudApiWhatsAppGateway` respeitando a interface `WhatsAppGateway` (zero alteração no `orquestrador` ou nas skills).
- **Negativas / Mitigação:**
  - Risco de desconexão ou bloqueio na API não oficial → mitigado pelo uso de chip dedicado, envio apenas para números na whitelist que optaram pelo vínculo (opt-in) e baixíssimo volume de mensagens proativas (máx. 1 lembrete/dia + 1 relatório/semana).

