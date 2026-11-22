-- Idempotent global seed for cardio modalities and essential strength
-- exercises so every new LIFTR account starts with a complete catalog for
-- manual plans, plan import, and the AI workout generator.

insert into public.exercises (
  id,
  user_id,
  name,
  primary_muscle_group,
  secondary_muscles,
  equipment,
  movement_pattern,
  instructions,
  is_custom
)
select
  v.id::uuid,
  null,
  v.name,
  v.primary_muscle_group,
  v.secondary_muscles,
  v.equipment,
  v.movement_pattern,
  v.instructions,
  false
from (
  values
    (
      '00000000-0000-4000-8000-000000000035',
      'Esteira / Cardio',
      'cardio',
      array[]::text[],
      'machine',
      'cardio',
      'Mantenha ritmo constante ou inclinação moderada monitorando o tempo e a frequência cardíaca.'
    ),
    (
      '00000000-0000-4000-8000-000000000036',
      'Bicicleta Ergométrica',
      'cardio',
      array[]::text[],
      'machine',
      'cardio',
      'Ajuste a altura do selim e pedale em cadência estável com resistência moderada pelo tempo alvo.'
    ),
    (
      '00000000-0000-4000-8000-000000000037',
      'Escada / Elíptico',
      'cardio',
      array[]::text[],
      'machine',
      'cardio',
      'Mantenha o tronco ereto sem se apoiar em excesso no suporte e sustente passada contínua.'
    ),
    (
      '00000000-0000-4000-8000-000000000038',
      'Caminhada Inclinada',
      'cardio',
      array[]::text[],
      'machine',
      'cardio',
      'Caminhe em ritmo firme com inclinação confortável, sem segurar nas alças laterais.'
    ),
    (
      '00000000-0000-4000-8000-000000000039',
      'Cadeira abdutora',
      'legs',
      array[]::text[],
      'machine',
      'isolation',
      'Mantenha o tronco apoiado e afaste os joelhos controlando o retorno sem bater as placas.'
    ),
    (
      '00000000-0000-4000-8000-000000000040',
      'Cadeira adutora',
      'legs',
      array[]::text[],
      'machine',
      'isolation',
      'Aproxime as pernas de forma fluida e segure 1 segundo no pico antes de abrir novamente.'
    ),
    (
      '00000000-0000-4000-8000-000000000041',
      'Glúteo no cabo (coice)',
      'legs',
      array['core'],
      'cable',
      'isolation',
      'Estabilize o tronco e estenda o quadril para trás contraindo o glúteo sem arquear a lombar.'
    ),
    (
      '00000000-0000-4000-8000-000000000042',
      'Passada / Afundo com halteres',
      'legs',
      array['core'],
      'dumbbell',
      'lunge',
      'Dê um passo firme à frente, desça controlando o joelho traseiro e empurre pelo calcanhar.'
    ),
    (
      '00000000-0000-4000-8000-000000000043',
      'Puxada triângulo no cabo',
      'back',
      array['arms'],
      'cable',
      'vertical_pull',
      'Mantenha o peito aberto e puxe o triângulo até o topo do esterno aproximando as escápulas.'
    ),
    (
      '00000000-0000-4000-8000-000000000044',
      'Crucifixo inverso na máquina',
      'shoulders',
      array['back'],
      'machine',
      'isolation',
      'Com braços semiflexionados, abra os pegadores para trás focando no deltóide posterior.'
    ),
    (
      '00000000-0000-4000-8000-000000000045',
      'Panturrilha sentado na máquina',
      'legs',
      array[]::text[],
      'machine',
      'isolation',
      'Desça os calcanhares ao máximo embaixo e suba com controle sem dar impulso.'
    ),
    (
      '00000000-0000-4000-8000-000000000046',
      'Rosca martelo com halteres',
      'arms',
      array[]::text[],
      'dumbbell',
      'isolation',
      'Com pegada neutra e cotovelos firmes ao lado do corpo, flexione até a contração total.'
    )
) as v(
  id,
  name,
  primary_muscle_group,
  secondary_muscles,
  equipment,
  movement_pattern,
  instructions
)
where not exists (
  select 1
  from public.exercises e
  where e.user_id is null
    and e.deleted_at is null
    and lower(e.name) = lower(v.name)
)
on conflict (id) do nothing;
