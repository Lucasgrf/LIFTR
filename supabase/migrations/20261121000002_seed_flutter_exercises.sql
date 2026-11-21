-- Curated global exercise library seed for the Flutter app (34 exercises).
-- Idempotent via deterministic UUIDs + ON CONFLICT (id) DO NOTHING.

insert into exercises (
  id,
  user_id,
  name,
  primary_muscle_group,
  secondary_muscles,
  equipment,
  movement_pattern,
  instructions,
  is_custom
) values
  -- Chest (Peitoral)
  (
    '00000000-0000-4000-8000-000000000001',
    null,
    'Supino reto com barra',
    'chest',
    array['shoulders', 'arms'],
    'barbell',
    'horizontal_push',
    'Mantenha as escápulas retraídas e desça a barra de forma controlada até tocar o meio do peito.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000002',
    null,
    'Supino inclinado com halteres',
    'chest',
    array['shoulders', 'arms'],
    'dumbbell',
    'horizontal_push',
    'Ajuste o banco entre 30° e 45° e controle a fase excêntrica mantendo os cotovelos a ~45°.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000003',
    null,
    'Supino reto com halteres',
    'chest',
    array['shoulders', 'arms'],
    'dumbbell',
    'horizontal_push',
    'Desça os halteres ao lado do peito com amplitude completa sem perder a estabilidade dos ombros.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000004',
    null,
    'Supino em máquina',
    'chest',
    array['arms'],
    'machine',
    'horizontal_push',
    'Ajuste o banco para alinhar as manoplas ao meio do peitoral e empurre sem travar os cotovelos.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000005',
    null,
    'Peck deck',
    'chest',
    array['shoulders'],
    'machine',
    'isolation',
    'Mantenha o peito aberto e aproxime os braços contraindo o peitoral por 1 segundo no pico.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000006',
    null,
    'Flexão de braço',
    'chest',
    array['arms', 'core'],
    'bodyweight',
    'horizontal_push',
    'Mantenha o tronco alinhado da cabeça aos calcanhares durante toda a repetição.',
    false
  ),

  -- Back (Costas)
  (
    '00000000-0000-4000-8000-000000000007',
    null,
    'Remada curvada com barra',
    'back',
    array['arms'],
    'barbell',
    'horizontal_pull',
    'Mantenha a coluna neutra inclinada a ~45° e puxe a barra em direção ao umbigo.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000008',
    null,
    'Remada baixa no cabo',
    'back',
    array['arms'],
    'cable',
    'horizontal_pull',
    'Inicie o movimento retraindo as escápulas e puxe o triângulo até a linha do abdômen.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000009',
    null,
    'Remada unilateral com halter',
    'back',
    array['arms'],
    'dumbbell',
    'horizontal_pull',
    'Apoie joelho e mão no banco e conduza o halter em arco na direção do quadril.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000010',
    null,
    'Remada em máquina',
    'back',
    array['arms'],
    'machine',
    'horizontal_pull',
    'Apoie o tórax no suporte e foque em aproximar as escápulas no final da puxada.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000011',
    null,
    'Puxada frontal no cabo',
    'back',
    array['arms'],
    'cable',
    'vertical_pull',
    'Segure um pouco além da largura dos ombros e puxe a barra até a parte superior do peito.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000012',
    null,
    'Barra fixa',
    'back',
    array['arms', 'core'],
    'bodyweight',
    'vertical_pull',
    'Suba conduzindo o peito em direção à barra sem balançar as pernas.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000013',
    null,
    'Puxada em máquina',
    'back',
    array['arms'],
    'machine',
    'vertical_pull',
    'Mantenha o tronco estável e controle o retorno completo dos braços no topo.',
    false
  ),

  -- Legs (Pernas)
  (
    '00000000-0000-4000-8000-000000000014',
    null,
    'Agachamento livre com barra',
    'legs',
    array['core'],
    'barbell',
    'squat',
    'Pés na largura dos ombros, desça mantendo joelhos alinhados aos pés até quebrar a paralela.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000015',
    null,
    'Leg press 45°',
    'legs',
    array[]::text[],
    'machine',
    'squat',
    'Desça a plataforma controlando a flexão sem tirar o quadril do encosto.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000016',
    null,
    'Hack squat',
    'legs',
    array['core'],
    'machine',
    'squat',
    'Mantenha lombar e ombros firmes no apoio enquanto desce com controle profundo.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000017',
    null,
    'Agachamento búlgaro com halteres',
    'legs',
    array['core'],
    'dumbbell',
    'lunge',
    'Apoie o peito do pé atrás no banco e desça verticalmente priorizando a perna da frente.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000018',
    null,
    'Levantamento terra',
    'legs',
    array['back', 'core'],
    'barbell',
    'hinge',
    'Mantenha a barra rente às canelas, coluna neutra e empurre o chão com os pés.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000019',
    null,
    'Stiff com barra',
    'legs',
    array['back'],
    'barbell',
    'hinge',
    'Empurre o quadril para trás mantendo joelhos semiflexionados até alongar posteriores.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000020',
    null,
    'Elevação pélvica com barra',
    'legs',
    array['core'],
    'barbell',
    'hinge',
    'Apoie as escápulas no banco e estenda o quadril contraindo glúteos no topo.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000021',
    null,
    'Cadeira extensora',
    'legs',
    array[]::text[],
    'machine',
    'isolation',
    'Estenda os joelhos por completo segurando 1 segundo no topo e desça sem soltar o peso.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000022',
    null,
    'Cadeira flexora',
    'legs',
    array[]::text[],
    'machine',
    'isolation',
    'Alinhe o eixo da máquina ao joelho e flexione mantendo o quadril firme no assento.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000023',
    null,
    'Mesa flexora',
    'legs',
    array[]::text[],
    'machine',
    'isolation',
    'Flexione os joelhos mantendo o quadril pressionado contra o banco durante todo o movimento.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000024',
    null,
    'Panturrilha em pé na máquina',
    'legs',
    array[]::text[],
    'machine',
    'isolation',
    'Faça pausa de 1 segundo em alongamento máximo embaixo antes de subir na ponta dos pés.',
    false
  ),

  -- Shoulders (Ombros)
  (
    '00000000-0000-4000-8000-000000000025',
    null,
    'Desenvolvimento com halteres',
    'shoulders',
    array['arms'],
    'dumbbell',
    'vertical_push',
    'Empurre os halteres acima da cabeça mantendo o abdômen firme e controle na descida.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000026',
    null,
    'Desenvolvimento militar com barra',
    'shoulders',
    array['arms', 'core'],
    'barbell',
    'vertical_push',
    'Com glúteos e core contraídos, pressione a barra da altura dos ombros até acima da cabeça.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000027',
    null,
    'Elevação lateral com halteres',
    'shoulders',
    array[]::text[],
    'dumbbell',
    'isolation',
    'Eleve os braços até a linha dos ombros liderando pelos cotovelos sem balançar o tronco.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000028',
    null,
    'Face pull no cabo',
    'shoulders',
    array['back'],
    'cable',
    'horizontal_pull',
    'Puxe a corda em direção à testa abrindo os cotovelos e rotacionando externamente os ombros.',
    false
  ),

  -- Arms (Braços)
  (
    '00000000-0000-4000-8000-000000000029',
    null,
    'Rosca direta com barra',
    'arms',
    array[]::text[],
    'barbell',
    'isolation',
    'Mantenha os cotovelos fixos ao lado do corpo e controle toda a descida sem impulso.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000030',
    null,
    'Rosca alternada com halteres',
    'arms',
    array[]::text[],
    'dumbbell',
    'isolation',
    'Supine o punho gradualmente ao subir cada halter mantendo os ombros estáveis.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000031',
    null,
    'Tríceps na polia com corda',
    'arms',
    array[]::text[],
    'cable',
    'isolation',
    'Fixe os cotovelos junto ao tronco e estenda completamente afastando as pontas da corda.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000032',
    null,
    'Tríceps testa com barra',
    'arms',
    array[]::text[],
    'barbell',
    'isolation',
    'Desça a barra em direção à testa ou topo da cabeça mantendo os braços estáveis.',
    false
  ),

  -- Core
  (
    '00000000-0000-4000-8000-000000000033',
    null,
    'Abdominal crunch no cabo',
    'core',
    array[]::text[],
    'cable',
    'isolation',
    'Flexione a coluna enrolando o tronco em direção ao quadril mantendo o quadril estático.',
    false
  ),
  (
    '00000000-0000-4000-8000-000000000034',
    null,
    'Prancha abdominal isométrica',
    'core',
    array['shoulders'],
    'bodyweight',
    'isolation',
    'Mantenha pelve neutra, glúteos e abdômen contraídos durante todo o tempo da série.',
    false
  )
on conflict (id) do nothing;
