-- Seed de desenvolvimento. Linhas globais (usuario_id nulo).
-- TODO(US-35): substituir a amostra de alimentos pela importação completa da TACO + sinônimos regionais
-- e gerar os embeddings (text-embedding-004, 768 dims). Valores nutricionais abaixo são uma amostra
-- para desenvolvimento: conferir com a TACO antes de qualquer uso real.
-- TODO(US-10): mapear imagem_url para o free-exercise-db (Unlicense) após conferir os nomes dos arquivos.

-- Equipamentos (passos padrão editáveis pelo usuário, US-16)
insert into equipamento (id, tipo, nome, passo) values
  ('eq_barra', 'barra', 'Barra', 2.5),
  ('eq_halter', 'halter', 'Halter', 2),
  ('eq_maquina', 'maquina', 'Máquina', 5),
  ('eq_cabo', 'cabo', 'Cabo', 5),
  ('eq_peso_corporal', 'peso_corporal', 'Peso corporal', null);

-- Exercícios curados por padrão de movimento
insert into exercicio (id, nome, padrao_movimento, tipo, equipamento_id, grupos_musculares) values
  ('ex_supino_reto_barra', 'Supino reto com barra', 'empurrar_horizontal', 'composto_pesado', 'eq_barra', '{peitoral,triceps,ombro_anterior}'),
  ('ex_supino_inclinado_halteres', 'Supino inclinado com halteres', 'empurrar_horizontal', 'composto', 'eq_halter', '{peitoral,ombro_anterior,triceps}'),
  ('ex_supino_reto_halteres', 'Supino reto com halteres', 'empurrar_horizontal', 'composto', 'eq_halter', '{peitoral,triceps,ombro_anterior}'),
  ('ex_supino_maquina', 'Supino em máquina', 'empurrar_horizontal', 'composto', 'eq_maquina', '{peitoral,triceps}'),
  ('ex_flexao_braco', 'Flexão de braço', 'empurrar_horizontal', 'composto', 'eq_peso_corporal', '{peitoral,triceps,ombro_anterior}'),
  ('ex_desenvolvimento_halteres', 'Desenvolvimento com halteres', 'empurrar_vertical', 'composto', 'eq_halter', '{ombro_anterior,ombro_lateral,triceps}'),
  ('ex_desenvolvimento_maquina', 'Desenvolvimento em máquina', 'empurrar_vertical', 'composto', 'eq_maquina', '{ombro_anterior,ombro_lateral,triceps}'),
  ('ex_desenvolvimento_barra', 'Desenvolvimento militar com barra', 'empurrar_vertical', 'composto_pesado', 'eq_barra', '{ombro_anterior,ombro_lateral,triceps}'),
  ('ex_remada_curvada_barra', 'Remada curvada com barra', 'puxar_horizontal', 'composto_pesado', 'eq_barra', '{dorsal,romboides,biceps}'),
  ('ex_remada_baixa_cabo', 'Remada baixa no cabo', 'puxar_horizontal', 'composto', 'eq_cabo', '{dorsal,romboides,biceps}'),
  ('ex_remada_unilateral_halter', 'Remada unilateral com halter', 'puxar_horizontal', 'composto', 'eq_halter', '{dorsal,romboides,biceps}'),
  ('ex_remada_maquina', 'Remada em máquina', 'puxar_horizontal', 'composto', 'eq_maquina', '{dorsal,romboides,biceps}'),
  ('ex_puxada_frontal_cabo', 'Puxada frontal no cabo', 'puxar_vertical', 'composto', 'eq_cabo', '{dorsal,biceps}'),
  ('ex_barra_fixa', 'Barra fixa', 'puxar_vertical', 'composto', 'eq_peso_corporal', '{dorsal,biceps}'),
  ('ex_puxada_maquina', 'Puxada em máquina', 'puxar_vertical', 'composto', 'eq_maquina', '{dorsal,biceps}'),
  ('ex_agachamento_livre', 'Agachamento livre', 'agachar', 'composto_pesado', 'eq_barra', '{quadriceps,gluteos}'),
  ('ex_leg_press', 'Leg press', 'agachar', 'composto', 'eq_maquina', '{quadriceps,gluteos}'),
  ('ex_agachamento_bulgaro', 'Agachamento búlgaro', 'agachar', 'composto', 'eq_halter', '{quadriceps,gluteos}'),
  ('ex_hack_machine', 'Hack machine', 'agachar', 'composto', 'eq_maquina', '{quadriceps,gluteos}'),
  ('ex_levantamento_terra', 'Levantamento terra', 'dobradica_quadril', 'composto_pesado', 'eq_barra', '{posterior_coxa,gluteos,lombar}'),
  ('ex_stiff_barra', 'Stiff com barra', 'dobradica_quadril', 'composto', 'eq_barra', '{posterior_coxa,gluteos}'),
  ('ex_elevacao_pelvica', 'Elevação pélvica', 'dobradica_quadril', 'composto', 'eq_barra', '{gluteos,posterior_coxa}'),
  ('ex_cadeira_flexora', 'Cadeira flexora', 'isolado_posterior_coxa', 'isolado', 'eq_maquina', '{posterior_coxa}'),
  ('ex_mesa_flexora', 'Mesa flexora', 'isolado_posterior_coxa', 'isolado', 'eq_maquina', '{posterior_coxa}'),
  ('ex_cadeira_extensora', 'Cadeira extensora', 'isolado_quadriceps', 'isolado', 'eq_maquina', '{quadriceps}'),
  ('ex_panturrilha_em_pe', 'Panturrilha em pé', 'isolado_panturrilha', 'isolado', 'eq_maquina', '{panturrilha}'),
  ('ex_elevacao_lateral', 'Elevação lateral', 'isolado_ombro_lateral', 'isolado', 'eq_halter', '{ombro_lateral}'),
  ('ex_peck_deck', 'Peck deck', 'isolado_peitoral', 'isolado', 'eq_maquina', '{peitoral}'),
  ('ex_rosca_direta_barra', 'Rosca direta com barra', 'isolado_biceps', 'isolado', 'eq_barra', '{biceps}'),
  ('ex_rosca_alternada_halteres', 'Rosca alternada com halteres', 'isolado_biceps', 'isolado', 'eq_halter', '{biceps}'),
  ('ex_triceps_polia', 'Tríceps na polia', 'isolado_triceps', 'isolado', 'eq_cabo', '{triceps}'),
  ('ex_triceps_testa', 'Tríceps testa', 'isolado_triceps', 'isolado', 'eq_barra', '{triceps}'),
  ('ex_face_pull', 'Face pull', 'isolado_ombro_posterior', 'isolado', 'eq_cabo', '{ombro_posterior,romboides}');

-- Amostra de alimentos (ids taco_3/77/409/500 são os usados nos exemplos das skills)
insert into alimento (id, nome, fonte, kcal_100g, proteina_100g, sinonimos) values
  ('taco_3', 'Arroz, tipo 1, cozido', 'taco', 128, 2.5, '{arroz branco}'),
  ('taco_77', 'Cuscuz de milho, cozido', 'taco', 113, 2.2, '{}'),
  ('taco_409', 'Frango, peito, sem pele, grelhado', 'taco', 159, 32.0, '{peito de frango}'),
  ('taco_500', 'Carne, bovina, contra-filé, grelhado', 'taco', 194, 35.9, '{contrafilé}'),
  ('taco_dev_feijao_carioca', 'Feijão, carioca, cozido', 'taco', 76, 4.8, '{feijão}'),
  ('taco_dev_ovo_cozido', 'Ovo, de galinha, inteiro, cozido', 'taco', 146, 13.3, '{ovo}'),
  ('taco_dev_pao_frances', 'Pão, trigo, francês', 'taco', 300, 8.0, '{pão de sal,cacetinho}'),
  ('taco_dev_mandioca_cozida', 'Mandioca, cozida', 'taco', 125, 0.6, '{macaxeira,aipim}'),
  ('taco_dev_leite_integral', 'Leite, de vaca, integral', 'taco', 61, 2.9, '{leite}');

-- Medidas caseiras citadas no PRD/skills (amostra)
insert into medida_caseira (alimento_id, nome, gramas) values
  ('taco_3', 'concha', 100),
  ('taco_3', 'colher_sopa', 25),
  ('taco_dev_feijao_carioca', 'concha', 86);

