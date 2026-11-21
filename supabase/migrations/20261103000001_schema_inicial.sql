-- Schema inicial (PRD §7.2). RLS em todas as tabelas (RNF-06 / AGENTS.md regra 7).
-- IDs de entidades sincronizáveis do treino são UUID gerados no cliente (ADR-001).
-- IDs de catálogo (equipamento, exercicio, alimento) são text: 'taco_3', 'ex_supino_reto', 'usr_<uuid>'.

create extension if not exists pg_trgm with schema extensions;
create extension if not exists vector with schema extensions;

-- ---------------------------------------------------------------------------
-- Perfil e metas
-- ---------------------------------------------------------------------------

create table perfil (
  usuario_id uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  sexo text check (sexo in ('masculino', 'feminino')),
  nascimento date,
  altura_cm numeric(5, 1) check (altura_cm between 100 and 250),
  percentual_gordura numeric(4, 1) check (percentual_gordura between 3 and 70),
  objetivo text check (objetivo in ('bulking', 'cutting', 'manutencao')),
  experiencia text check (experiencia in ('iniciante', 'intermediario')),
  atividade text check (atividade in ('sedentario', 'leve', 'moderado', 'alto')),
  fuso text not null default 'America/Sao_Paulo',
  whatsapp_numero text unique,
  horario_relatorio time,
  silencio_inicio time,
  silencio_fim time,
  -- Sinais de transtorno alimentar desligam déficit e lembretes até revisão manual (PRD §8.4).
  sinal_transtorno_alimentar boolean not null default false,
  criado_em timestamptz not null default now()
);

create table metas (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  vigente_desde date not null,
  kcal integer not null check (kcal > 0),
  proteina_g integer not null check (proteina_g > 0),
  origem text not null check (origem in ('formula', 'adaptativo')),
  tdee_estimado numeric(7, 1),
  criado_em timestamptz not null default now()
);
create index metas_usuario_vigencia_idx on metas (usuario_id, vigente_desde desc);

-- ---------------------------------------------------------------------------
-- Catálogo de treino (linhas globais têm usuario_id nulo)
-- ---------------------------------------------------------------------------

create table equipamento (
  id text primary key,
  usuario_id uuid references auth.users (id) on delete cascade,
  tipo text not null check (tipo in ('barra', 'halter', 'maquina', 'cabo', 'peso_corporal')),
  nome text not null,
  -- Passo fixo (ex.: 2.5) OU lista explícita de pesos existentes (PRD §4.1, US-16).
  passo numeric(6, 2) check (passo > 0),
  incrementos numeric(6, 2)[]
);

create table exercicio (
  id text primary key,
  usuario_id uuid references auth.users (id) on delete cascade,
  nome text not null,
  padrao_movimento text not null,
  tipo text not null check (tipo in ('composto_pesado', 'composto', 'isolado')),
  equipamento_id text references equipamento (id),
  imagem_url text,
  -- TODO(US-11): exercícios globais são somente leitura; foto própria exigirá cópia por usuário.
  foto_usuario_url text,
  grupos_musculares text[] not null default '{}'
);
create index exercicio_padrao_idx on exercicio (padrao_movimento);

-- ---------------------------------------------------------------------------
-- Programa, fila e execução
-- ---------------------------------------------------------------------------

create table programa (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  estilo text not null check (estilo in ('full_body', 'upper_lower', 'ppl', 'hibrido', 'abcde')),
  ativo boolean not null default true,
  criado_em timestamptz not null default now()
);
create unique index programa_ativo_unico_idx on programa (usuario_id) where ativo;

create table sessao_modelo (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  programa_id uuid not null references programa (id) on delete cascade,
  nome text not null,
  ordem_fila integer not null check (ordem_fila >= 0),
  unique (programa_id, ordem_fila)
);

create table slot (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  sessao_modelo_id uuid not null references sessao_modelo (id) on delete cascade,
  ordem integer not null check (ordem >= 0),
  padrao_movimento text not null,
  tipo text not null check (tipo in ('composto_pesado', 'composto', 'isolado')),
  series_alvo integer not null default 3 check (series_alvo > 0),
  faixa_min integer not null check (faixa_min > 0),
  faixa_max integer not null,
  descanso_s integer not null default 90 check (descanso_s >= 0),
  exercicio_atual_id text references exercicio (id),
  check (faixa_max >= faixa_min),
  unique (sessao_modelo_id, ordem)
);

create table fila_estado (
  programa_id uuid primary key references programa (id) on delete cascade,
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  proxima_sessao_modelo_id uuid references sessao_modelo (id) on delete set null
);

-- O histórico pertence ao exercício, não ao programa (PRD §3, ADR-004):
-- apagar uma sessão-modelo não apaga o treino realizado.
create table treino (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  sessao_modelo_id uuid references sessao_modelo (id) on delete set null,
  inicio timestamptz not null,
  fim timestamptz
);
create index treino_usuario_inicio_idx on treino (usuario_id, inicio desc);

-- Uma linha por série (AGENTS.md regra 8). Aquecimento nunca entra em progressão/volume.
create table serie (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  treino_id uuid not null references treino (id) on delete cascade,
  exercicio_id text not null references exercicio (id),
  ordem integer not null check (ordem >= 0),
  peso numeric(6, 2) not null check (peso >= 0),
  reps integer not null check (reps >= 0),
  tipo text not null default 'valida' check (tipo in ('valida', 'aquecimento')),
  unique (treino_id, exercicio_id, ordem)
);
create index serie_exercicio_idx on serie (usuario_id, exercicio_id);

create table status_progressao (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  exercicio_id text not null references exercicio (id),
  treino_id uuid not null references treino (id) on delete cascade,
  status text not null check (status in ('subir', 'manter', 'carga_alta', 'travado')),
  proximo_peso numeric(6, 2),
  progresso numeric(5, 4) check (progresso >= 0),
  unique (treino_id, exercicio_id)
);
create index status_progressao_exercicio_idx on status_progressao (usuario_id, exercicio_id);

-- ---------------------------------------------------------------------------
-- Peso e dieta
-- ---------------------------------------------------------------------------

create table pesagem (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  data date not null,
  peso_kg numeric(5, 2) not null check (peso_kg between 30 and 300),
  origem text not null default 'whatsapp' check (origem in ('app', 'whatsapp', 'foto')),
  criado_em timestamptz not null default now()
);
create index pesagem_usuario_data_idx on pesagem (usuario_id, data desc);

create table alimento (
  id text primary key,
  usuario_id uuid references auth.users (id) on delete cascade,
  nome text not null,
  fonte text not null check (fonte in ('taco', 'off', 'usuario')),
  kcal_100g numeric(7, 2) not null check (kcal_100g >= 0),
  proteina_100g numeric(6, 2) not null check (proteina_100g >= 0),
  sinonimos text[] not null default '{}',
  embedding extensions.vector(768)
);
create index alimento_nome_trgm_idx on alimento using gin (nome extensions.gin_trgm_ops);
create index alimento_embedding_idx on alimento using hnsw (embedding extensions.vector_cosine_ops);

create table medida_caseira (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid references auth.users (id) on delete cascade,
  alimento_id text references alimento (id) on delete cascade,
  categoria text,
  nome text not null,
  gramas numeric(7, 2) not null check (gramas > 0),
  check (alimento_id is not null or categoria is not null)
);
create index medida_caseira_alimento_idx on medida_caseira (alimento_id);

create table refeicao (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  registrada_em timestamptz not null,
  texto_original text,
  foto_url text,
  confirmada boolean not null default false
);
create index refeicao_usuario_data_idx on refeicao (usuario_id, registrada_em desc);

create table refeicao_item (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  refeicao_id uuid not null references refeicao (id) on delete cascade,
  alimento_id text not null references alimento (id),
  gramas numeric(7, 2) not null check (gramas > 0),
  porcao_assumida boolean not null default false,
  confianca numeric(3, 2) check (confianca between 0 and 1)
);
create index refeicao_item_refeicao_idx on refeicao_item (refeicao_id);

-- ---------------------------------------------------------------------------
-- WhatsApp e observabilidade de IA
-- ---------------------------------------------------------------------------

create table mensagem (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users (id) on delete cascade,
  direcao text not null check (direcao in ('entrada', 'saida')),
  conteudo text not null,
  intent text,
  correlacao_id uuid,
  criada_em timestamptz not null default now()
);
create index mensagem_usuario_data_idx on mensagem (usuario_id, criada_em desc);

create table acao_pendente (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  tipo text not null,
  payload jsonb not null default '{}'::jsonb,
  expira_em timestamptz not null,
  criada_em timestamptz not null default now()
);
create index acao_pendente_usuario_idx on acao_pendente (usuario_id, expira_em desc);

create table llm_chamada (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid references auth.users (id) on delete set null,
  correlacao_id uuid,
  skill text not null,
  versao_skill text not null,
  modelo text not null,
  tokens integer,
  latencia_ms integer,
  entrada_hash text,
  saida jsonb,
  validacao_ok boolean not null,
  erro text,
  criada_em timestamptz not null default now()
);
create index llm_chamada_criada_idx on llm_chamada (criada_em desc);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

do $$
declare
  t text;
  cmd text;
begin
  -- Tabelas do usuário: acesso total apenas às próprias linhas.
  foreach t in array array[
    'perfil', 'metas', 'programa', 'sessao_modelo', 'slot', 'fila_estado', 'treino', 'serie',
    'status_progressao', 'pesagem', 'refeicao', 'refeicao_item', 'acao_pendente'
  ] loop
    execute format('alter table %I enable row level security', t);
    execute format(
      'create policy %I on %I for all to authenticated using (usuario_id = (select auth.uid())) with check (usuario_id = (select auth.uid()))',
      t || '_dono', t
    );
  end loop;

  -- Catálogos: leitura de linhas globais ou próprias; escrita só nas próprias.
  foreach t in array array['equipamento', 'exercicio', 'alimento', 'medida_caseira'] loop
    execute format('alter table %I enable row level security', t);
    execute format(
      'create policy %I on %I for select to authenticated using (usuario_id is null or usuario_id = (select auth.uid()))',
      t || '_leitura', t
    );
    execute format(
      'create policy %I on %I for insert to authenticated with check (usuario_id = (select auth.uid()))',
      t || '_insert_proprio', t
    );
    execute format(
      'create policy %I on %I for update to authenticated using (usuario_id = (select auth.uid())) with check (usuario_id = (select auth.uid()))',
      t || '_update_proprio', t
    );
    execute format(
      'create policy %I on %I for delete to authenticated using (usuario_id = (select auth.uid()))',
      t || '_delete_proprio', t
    );
  end loop;

  -- Mensagens: o app só lê; escrita é do backend (service role).
  alter table mensagem enable row level security;
  create policy mensagem_leitura on mensagem for select to authenticated
    using (usuario_id = (select auth.uid()));

  -- llm_chamada: somente backend (RLS ligado, sem policies para clientes).
  alter table llm_chamada enable row level security;
end
$$;

-- ---------------------------------------------------------------------------
-- Busca híbrida de alimentos (PRD §8.3): pg_trgm + pgvector com Reciprocal Rank Fusion
-- ---------------------------------------------------------------------------

create or replace function buscar_alimentos_hibrido(
  termo text,
  vetor_busca extensions.vector(768),
  usuario uuid,
  limite integer default 5
)
returns table (alimento_id text, nome text, fonte text, score double precision)
language sql
stable
set search_path = public, extensions
as $$
  with lexical as (
    select t.id, row_number() over (order by t.sim desc) as r
    from (
      select
        a.id,
        greatest(
          similarity(a.nome, termo),
          coalesce((select max(similarity(s, termo)) from unnest(a.sinonimos) s), 0)
        ) as sim
      from alimento a
      where a.usuario_id is null or a.usuario_id = usuario
    ) t
    where t.sim > 0.2
    order by t.sim desc
    limit 20
  ),
  semantico as (
    select t.id, row_number() over (order by t.dist) as r
    from (
      select a.id, a.embedding <=> vetor_busca as dist
      from alimento a
      where vetor_busca is not null
        and a.embedding is not null
        and (a.usuario_id is null or a.usuario_id = usuario)
      order by a.embedding <=> vetor_busca
      limit 20
    ) t
  ),
  fundido as (
    select
      coalesce(l.id, s.id) as id,
      coalesce(1.0 / (60 + l.r), 0) + coalesce(1.0 / (60 + s.r), 0) as score
    from lexical l
    full outer join semantico s on s.id = l.id
  )
  select
    a.id as alimento_id,
    a.nome,
    a.fonte,
    -- Alimentos do próprio usuário têm prioridade leve (PRD §8.3, corpus 2).
    (f.score + case when a.usuario_id = usuario then 0.005 else 0 end)::double precision as score
  from fundido f
  join alimento a on a.id = f.id
  order by 4 desc
  limit limite;
$$;

-- Só o backend (service role) consulta o retrieval.
revoke execute on function buscar_alimentos_hibrido(text, extensions.vector, uuid, integer)
  from public, anon, authenticated;
grant execute on function buscar_alimentos_hibrido(text, extensions.vector, uuid, integer)
  to service_role;

