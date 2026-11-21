/**
 * Cron do relatório semanal (PRD §6.5). Disparado pelo pg_cron.
 * TODO(US-30): montar fatos, ações candidatas, redigir (skill relatorio-semanal), validar números
 * e enviar. Na Sprint 0 é apenas o ponto de entrada.
 */
Deno.serve(() =>
  new Response(JSON.stringify({ erro: "não implementado (US-30)" }), {
    status: 501,
    headers: { "content-type": "application/json" },
  })
);

