/**
 * Runner das evals. Uso:
 *   deno task evals                          # todas as skills (precisa de GEMINI_API_KEY)
 *   deno task evals -- --skill registrar-refeicao
 *   deno task evals:dry                      # valida casos, fixtures e checadores, sem LLM
 */
import { z } from "../supabase/functions/_shared/deps.ts";
import { GeminiLlmClient } from "../supabase/functions/_shared/llm/gemini_llm_client.ts";
import {
  type ChamadaSkill,
  criarCarregadorSkill,
  extrairVersaoSkill,
} from "../supabase/functions/_shared/llm/llm_client.ts";
import {
  criarRegistrarRefeicaoEtapaBSchema,
  criarRelatorioSemanalSchema,
  NOMES_SKILL,
  type NomeSkill,
  RegistrarPesoSchema,
  RegistrarRefeicaoEtapaASchema,
  ResponderDuvidaSchema,
  ResumoPosTreinoSchema,
  RoteadorIntencaoSchema,
} from "../supabase/functions/_shared/schemas/index.ts";
import { avaliarCaso, propriedadeConhecida } from "./checadores.ts";

const CasoSchema = z.object({
  id: z.string().min(1),
  etapa: z.enum(["A", "B"]).optional(),
  // Objeto inline ou caminho de fixture JSON relativo a skills/<skill>/evals/.
  entrada: z.union([z.string(), z.record(z.unknown())]),
  esperado: z.record(z.unknown()),
});
type Caso = z.infer<typeof CasoSchema>;

type Obj = Record<string, unknown>;

const RAIZ = Deno.cwd();
const DIR_SKILLS = `${RAIZ}/skills`;

// ---------------------------------------------------------------------------
// Carregamento
// ---------------------------------------------------------------------------

async function listarSkills(): Promise<NomeSkill[]> {
  const nomes: string[] = [];
  for await (const e of Deno.readDir(DIR_SKILLS)) {
    if (e.isDirectory && !e.name.startsWith("_")) nomes.push(e.name);
  }
  return nomes.sort().filter((n): n is NomeSkill => (NOMES_SKILL as readonly string[]).includes(n));
}

async function carregarCasos(skill: NomeSkill): Promise<{ casos: Caso[]; problemas: string[] }> {
  const caminho = `${DIR_SKILLS}/${skill}/evals/casos.jsonl`;
  const problemas: string[] = [];
  const casos: Caso[] = [];
  const linhas = (await Deno.readTextFile(caminho)).split("\n").filter((l) => l.trim() !== "");
  linhas.forEach((linha, i) => {
    let bruto: unknown;
    try {
      bruto = JSON.parse(linha);
    } catch {
      problemas.push(`${skill}: linha ${i + 1} não é JSON`);
      return;
    }
    const r = CasoSchema.safeParse(bruto); // validado imediatamente
    if (r.success) casos.push(r.data);
    else problemas.push(`${skill}: linha ${i + 1} inválida (${r.error.issues[0]?.message})`);
  });
  return { casos, problemas };
}

async function resolverEntrada(skill: NomeSkill, caso: Caso): Promise<Obj> {
  if (typeof caso.entrada !== "string") return caso.entrada;
  const texto = await Deno.readTextFile(`${DIR_SKILLS}/${skill}/evals/${caso.entrada}`);
  const parsed = z.record(z.unknown()).safeParse(JSON.parse(texto));
  if (!parsed.success) throw new Error(`fixture ${caso.entrada} não é um objeto JSON`);
  return parsed.data;
}

// ---------------------------------------------------------------------------
// Montagem da chamada por skill
// ---------------------------------------------------------------------------

function montarChamada(skill: NomeSkill, caso: Caso, entrada: Obj): ChamadaSkill<unknown> {
  switch (skill) {
    case "roteador-intencao":
      return { skill, entrada, schema: RoteadorIntencaoSchema };
    case "registrar-peso":
      return { skill, entrada, schema: RegistrarPesoSchema };
    case "resumo-pos-treino":
      return { skill, entrada, schema: ResumoPosTreinoSchema };
    case "responder-duvida":
      return { skill, entrada, schema: ResponderDuvidaSchema };
    case "relatorio-semanal": {
      const ids = (Array.isArray(entrada.acoes_candidatas) ? entrada.acoes_candidatas : [])
        .map((a) => String((a as Obj).id));
      return { skill, entrada, schema: criarRelatorioSemanalSchema(ids) };
    }
    case "registrar-refeicao": {
      if (caso.etapa !== "B") return { skill, entrada, schema: RegistrarRefeicaoEtapaASchema };
      const candidatos: Record<number, string[]> = {};
      for (const item of Array.isArray(entrada.itens) ? entrada.itens as Obj[] : []) {
        candidatos[Number(item.indice)] = (Array.isArray(item.candidatos) ? item.candidatos as Obj[] : [])
          .map((c) => String(c.alimento_id));
      }
      return { skill, entrada, schema: criarRegistrarRefeicaoEtapaBSchema(candidatos) };
    }
  }
}

// ---------------------------------------------------------------------------
// Execução
// ---------------------------------------------------------------------------

async function validarEstrutura(skills: NomeSkill[]): Promise<string[]> {
  const problemas: string[] = [];
  for (const skill of skills) {
    const md = await Deno.readTextFile(`${DIR_SKILLS}/${skill}/SKILL.md`);
    if (extrairVersaoSkill(md) === null) problemas.push(`${skill}: SKILL.md sem versão no título`);

    const { casos, problemas: p } = await carregarCasos(skill);
    problemas.push(...p);
    if (casos.length === 0) problemas.push(`${skill}: nenhum caso`);

    const ids = new Set<string>();
    for (const caso of casos) {
      if (ids.has(caso.id)) problemas.push(`${skill}/${caso.id}: id duplicado`);
      ids.add(caso.id);
      try {
        const entrada = await resolverEntrada(skill, caso);
        montarChamada(skill, caso, entrada);
      } catch (e) {
        problemas.push(`${skill}/${caso.id}: ${e instanceof Error ? e.message : String(e)}`);
      }
      const props = Array.isArray(caso.esperado.propriedades) ? caso.esperado.propriedades : [];
      for (const prop of props.map(String)) {
        if (!propriedadeConhecida(prop)) problemas.push(`${skill}/${caso.id}: checador desconhecido '${prop}'`);
      }
    }
  }
  return problemas;
}

async function rodarEvals(skills: NomeSkill[]): Promise<boolean> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    console.error("GEMINI_API_KEY ausente. Use --dry-run para validar sem chamar o LLM.");
    return false;
  }
  const llm = new GeminiLlmClient({ apiKey, carregarSkill: criarCarregadorSkill(DIR_SKILLS) });
  let tudoOk = true;
  for (const skill of skills) {
    const { casos } = await carregarCasos(skill);
    let aprovados = 0;
    for (const caso of casos) {
      const entrada = await resolverEntrada(skill, caso);
      const resultado = await llm.executarSkill(montarChamada(skill, caso, entrada));
      if (!resultado.ok) {
        console.log(`  ✗ ${caso.id}: ${resultado.erro.tipo} — ${resultado.erro.mensagem}`);
        continue;
      }
      const erros = avaliarCaso(caso.esperado, { entrada, saida: resultado.valor });
      if (erros.length === 0) aprovados++;
      else erros.forEach((e) => console.log(`  ✗ ${caso.id}: ${e}`));
    }
    console.log(`${skill}: ${aprovados}/${casos.length}`);
    // TODO(US-38): aplicar as metas do PRD §8.5 (JSON válido no 1º try, acurácia de intenção...).
    if (aprovados !== casos.length) tudoOk = false;
  }
  return tudoOk;
}

function lerArgs(args: string[]): { skills: string[]; dryRun: boolean } {
  const skills: string[] = [];
  let dryRun = false;
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === "--dry-run") dryRun = true;
    else if (a === "--skill" && args[i + 1]) skills.push(args[++i]);
    else if (a.startsWith("--skill=")) skills.push(a.slice("--skill=".length));
  }
  return { skills, dryRun };
}

async function main(): Promise<number> {
  const { skills: pedidas, dryRun } = lerArgs(Deno.args);
  const todas = await listarSkills();
  const desconhecidas = pedidas.filter((s) => !todas.includes(s as NomeSkill));
  if (desconhecidas.length > 0) {
    console.error(`Skill(s) desconhecida(s): ${desconhecidas.join(", ")}. Disponíveis: ${todas.join(", ")}`);
    return 2;
  }
  const alvo = pedidas.length > 0 ? pedidas as NomeSkill[] : todas;

  if (dryRun) {
    const problemas = await validarEstrutura(alvo);
    if (problemas.length > 0) {
      problemas.forEach((p) => console.error(`✗ ${p}`));
      return 1;
    }
    console.log(`OK: ${alvo.length} skills validadas (casos, fixtures e checadores).`);
    return 0;
  }
  return (await rodarEvals(alvo)) ? 0 : 1;
}

if (import.meta.main) Deno.exit(await main());

