/**
 * O orquestrador é uma biblioteca (`pipeline.ts`) chamada em processo pelo `whatsapp-webhook` e pelo
 * cron. Esta função existe só para que o diretório seja uma Edge Function válida; ela não é
 * invocada por HTTP.
 */
Deno.serve(() =>
  new Response(JSON.stringify({ erro: "uso interno" }), {
    status: 405,
    headers: { "content-type": "application/json" },
  })
);

