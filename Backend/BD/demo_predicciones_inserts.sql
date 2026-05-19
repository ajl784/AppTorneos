-- Demo data para visualizar predicciones con historial (Liga + Eliminación)
-- Requisitos:
-- - Tipos de torneo con nombres compatibles con el front: "Liga" y "Eliminación".
-- - Partidos futuros en estado 'planificado' y con participacion_partido (>=2 equipos) para que /partidos/:id/prediccion devuelva probabilidades.
-- - Torneo histórico "acabado" con resultados + varias entradas en historial_elo por equipo.

BEGIN;

-- Nota: evitamos ON CONFLICT para compatibilidad con Postgres < 9.5.

WITH
-- 1) Tipos de torneo
tipo_liga_upd AS (
  UPDATE tipo_torneo
  SET descripcion = 'Torneo tipo liga (demo predicciones)'
  WHERE nombre = 'Liga'
  RETURNING id_tipo_torneo
),
tipo_liga_ins AS (
  INSERT INTO tipo_torneo (nombre, descripcion)
  SELECT 'Liga', 'Torneo tipo liga (demo predicciones)'
  WHERE NOT EXISTS (SELECT 1 FROM tipo_torneo WHERE nombre = 'Liga')
  RETURNING id_tipo_torneo
),
tipo_liga AS (
  SELECT id_tipo_torneo
  FROM (
    SELECT id_tipo_torneo FROM tipo_liga_upd
    UNION ALL
    SELECT id_tipo_torneo FROM tipo_liga_ins
    UNION ALL
    SELECT id_tipo_torneo FROM tipo_torneo WHERE nombre = 'Liga'
  ) q
  LIMIT 1
),

tipo_elim_upd AS (
  UPDATE tipo_torneo
  SET descripcion = 'Torneo tipo eliminacion (demo predicciones)'
  WHERE nombre = 'Eliminación'
  RETURNING id_tipo_torneo
),
tipo_elim_ins AS (
  INSERT INTO tipo_torneo (nombre, descripcion)
  SELECT 'Eliminación', 'Torneo tipo eliminacion (demo predicciones)'
  WHERE NOT EXISTS (SELECT 1 FROM tipo_torneo WHERE nombre = 'Eliminación')
  RETURNING id_tipo_torneo
),
tipo_elim AS (
  SELECT id_tipo_torneo
  FROM (
    SELECT id_tipo_torneo FROM tipo_elim_upd
    UNION ALL
    SELECT id_tipo_torneo FROM tipo_elim_ins
    UNION ALL
    SELECT id_tipo_torneo FROM tipo_torneo WHERE nombre = 'Eliminación'
  ) q
  LIMIT 1
),

-- 2) Categoría
cat_demo_upd AS (
  UPDATE categoria
  SET participantes_por_partida = 4,
      descripcion = 'Categoría de prueba para ver porcentajes de predicción'
  WHERE nombre = 'Demo Predicciones'
  RETURNING id_categoria
),
cat_demo_ins AS (
  INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion, icono)
  SELECT 'Demo Predicciones', 4, NULL, 'Categoría de prueba para ver porcentajes de predicción', NULL
  WHERE NOT EXISTS (SELECT 1 FROM categoria WHERE nombre = 'Demo Predicciones')
  RETURNING id_categoria
),
cat_demo AS (
  SELECT id_categoria
  FROM (
    SELECT id_categoria FROM cat_demo_upd
    UNION ALL
    SELECT id_categoria FROM cat_demo_ins
    UNION ALL
    SELECT id_categoria FROM categoria WHERE nombre = 'Demo Predicciones'
  ) q
  LIMIT 1
),

-- 3) Enlace categoría <-> tipos
cat_tipo_liga AS (
  INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
  SELECT c.id_categoria, t.id_tipo_torneo
  FROM cat_demo c
  CROSS JOIN tipo_liga t
  WHERE NOT EXISTS (
    SELECT 1 FROM categoria_tipo_torneo ctt
    WHERE ctt.id_categoria = c.id_categoria AND ctt.id_tipo_torneo = t.id_tipo_torneo
  )
  RETURNING id_categoria_tipo_torneo
),
cat_tipo_elim AS (
  INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
  SELECT c.id_categoria, t.id_tipo_torneo
  FROM cat_demo c
  CROSS JOIN tipo_elim t
  WHERE NOT EXISTS (
    SELECT 1 FROM categoria_tipo_torneo ctt
    WHERE ctt.id_categoria = c.id_categoria AND ctt.id_tipo_torneo = t.id_tipo_torneo
  )
  RETURNING id_categoria_tipo_torneo
),

-- 4) Usuario organizador
usr_demo_upd AS (
  UPDATE usuario
  SET nombre_usuario = 'demo_predicciones', nombre = 'Demo', apellidos = 'Predicciones'
  WHERE correo = 'demo_predicciones@app.local'
  RETURNING id_usuario
),
usr_demo_ins AS (
  INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
  SELECT 'demo_predicciones@app.local', 'demo_predicciones', 'demo', 'Demo', 'Predicciones'
  WHERE NOT EXISTS (SELECT 1 FROM usuario WHERE correo = 'demo_predicciones@app.local')
  RETURNING id_usuario
),
usr_demo AS (
  SELECT id_usuario
  FROM (
    SELECT id_usuario FROM usr_demo_upd
    UNION ALL
    SELECT id_usuario FROM usr_demo_ins
    UNION ALL
    SELECT id_usuario FROM usuario WHERE correo = 'demo_predicciones@app.local'
  ) q
  LIMIT 1
),

-- 5) Equipos (mismos equipos para torneo histórico y demos)
team_a_upd AS (
  UPDATE equipo
  SET descripcion = 'Equipo demo A', elo = 1300, id_categoria = (SELECT id_categoria FROM cat_demo)
  WHERE nombre = 'Demo A'
  RETURNING id_equipo
),
team_a_ins AS (
  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  SELECT 'Demo A', 'Equipo demo A', 1300, (SELECT id_categoria FROM cat_demo)
  WHERE NOT EXISTS (SELECT 1 FROM equipo WHERE nombre = 'Demo A')
  RETURNING id_equipo
),
team_a AS (
  SELECT id_equipo
  FROM (
    SELECT id_equipo FROM team_a_upd
    UNION ALL
    SELECT id_equipo FROM team_a_ins
    UNION ALL
    SELECT id_equipo FROM equipo WHERE nombre = 'Demo A'
  ) q
  LIMIT 1
),

team_b_upd AS (
  UPDATE equipo
  SET descripcion = 'Equipo demo B', elo = 1200, id_categoria = (SELECT id_categoria FROM cat_demo)
  WHERE nombre = 'Demo B'
  RETURNING id_equipo
),
team_b_ins AS (
  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  SELECT 'Demo B', 'Equipo demo B', 1200, (SELECT id_categoria FROM cat_demo)
  WHERE NOT EXISTS (SELECT 1 FROM equipo WHERE nombre = 'Demo B')
  RETURNING id_equipo
),
team_b AS (
  SELECT id_equipo
  FROM (
    SELECT id_equipo FROM team_b_upd
    UNION ALL
    SELECT id_equipo FROM team_b_ins
    UNION ALL
    SELECT id_equipo FROM equipo WHERE nombre = 'Demo B'
  ) q
  LIMIT 1
),

team_c_upd AS (
  UPDATE equipo
  SET descripcion = 'Equipo demo C', elo = 1100, id_categoria = (SELECT id_categoria FROM cat_demo)
  WHERE nombre = 'Demo C'
  RETURNING id_equipo
),
team_c_ins AS (
  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  SELECT 'Demo C', 'Equipo demo C', 1100, (SELECT id_categoria FROM cat_demo)
  WHERE NOT EXISTS (SELECT 1 FROM equipo WHERE nombre = 'Demo C')
  RETURNING id_equipo
),
team_c AS (
  SELECT id_equipo
  FROM (
    SELECT id_equipo FROM team_c_upd
    UNION ALL
    SELECT id_equipo FROM team_c_ins
    UNION ALL
    SELECT id_equipo FROM equipo WHERE nombre = 'Demo C'
  ) q
  LIMIT 1
),

team_d_upd AS (
  UPDATE equipo
  SET descripcion = 'Equipo demo D', elo = 1400, id_categoria = (SELECT id_categoria FROM cat_demo)
  WHERE nombre = 'Demo D'
  RETURNING id_equipo
),
team_d_ins AS (
  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  SELECT 'Demo D', 'Equipo demo D', 1400, (SELECT id_categoria FROM cat_demo)
  WHERE NOT EXISTS (SELECT 1 FROM equipo WHERE nombre = 'Demo D')
  RETURNING id_equipo
),
team_d AS (
  SELECT id_equipo
  FROM (
    SELECT id_equipo FROM team_d_upd
    UNION ALL
    SELECT id_equipo FROM team_d_ins
    UNION ALL
    SELECT id_equipo FROM equipo WHERE nombre = 'Demo D'
  ) q
  LIMIT 1
),

teams AS (
  SELECT id_equipo, 'Demo A'::text AS nombre FROM team_a
  UNION ALL SELECT id_equipo, 'Demo B'::text AS nombre FROM team_b
  UNION ALL SELECT id_equipo, 'Demo C'::text AS nombre FROM team_c
  UNION ALL SELECT id_equipo, 'Demo D'::text AS nombre FROM team_d
),

-- 6) Torneo histórico (acabado) con resultados
torneo_hist_upd AS (
  UPDATE torneo
  SET descripcion = 'Torneo histórico para generar elo y resultados (demo)',
      estado = 'acabado',
      fecha_inicio = TIMESTAMPTZ '2025-01-01 00:00:00+00',
      fecha_fin = TIMESTAMPTZ '2025-02-01 00:00:00+00',
      norma_puntuacion = 'victoria=3;empate=1;derrota=0'
  WHERE nombre = 'Demo Historial Predicciones'
    AND id_categoria = (SELECT id_categoria FROM cat_demo)
    AND id_tipo_torneo = (SELECT id_tipo_torneo FROM tipo_liga)
  RETURNING id_torneo
),
torneo_hist_ins AS (
  INSERT INTO torneo (
    nombre, descripcion, fecha_inicio, fecha_fin, estado, limite_equipos,
    id_categoria, id_tipo_torneo, id_organizador, norma_puntuacion
  )
  SELECT
    'Demo Historial Predicciones',
    'Torneo histórico para generar elo y resultados (demo)',
    TIMESTAMPTZ '2025-01-01 00:00:00+00',
    TIMESTAMPTZ '2025-02-01 00:00:00+00',
    'acabado',
    10,
    (SELECT id_categoria FROM cat_demo),
    (SELECT id_tipo_torneo FROM tipo_liga),
    (SELECT id_usuario FROM usr_demo),
    'victoria=3;empate=1;derrota=0'
  WHERE NOT EXISTS (
    SELECT 1 FROM torneo t
    WHERE t.nombre = 'Demo Historial Predicciones'
      AND t.id_categoria = (SELECT id_categoria FROM cat_demo)
      AND t.id_tipo_torneo = (SELECT id_tipo_torneo FROM tipo_liga)
  )
  RETURNING id_torneo
),
torneo_hist AS (
  SELECT id_torneo
  FROM (
    SELECT id_torneo FROM torneo_hist_upd
    UNION ALL SELECT id_torneo FROM torneo_hist_ins
    UNION ALL
    SELECT t.id_torneo
    FROM torneo t
    WHERE t.nombre = 'Demo Historial Predicciones'
      AND t.id_categoria = (SELECT id_categoria FROM cat_demo)
      AND t.id_tipo_torneo = (SELECT id_tipo_torneo FROM tipo_liga)
  ) q
  LIMIT 1
),

pte_hist_upd AS (
  UPDATE participacion_torneo_equipo p
  SET estado = 'jugando'
  FROM torneo_hist th
  JOIN teams t ON true
  WHERE p.id_torneo = th.id_torneo
    AND p.id_equipo = t.id_equipo
  RETURNING p.id_participacion_equipo
),
pte_hist_ins AS (
  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado)
  SELECT th.id_torneo, t.id_equipo, 'jugando'
  FROM torneo_hist th
  CROSS JOIN teams t
  WHERE NOT EXISTS (
    SELECT 1 FROM participacion_torneo_equipo p
    WHERE p.id_torneo = th.id_torneo AND p.id_equipo = t.id_equipo
  )
  RETURNING id_participacion_equipo
),
pte_hist_touch AS (
  SELECT 1 AS ok
  FROM (
    SELECT 1 FROM pte_hist_upd
    UNION ALL SELECT 1 FROM pte_hist_ins
    UNION ALL SELECT 1
  ) q
  LIMIT 1
),
pte_hist_ref AS (
  SELECT p.id_participacion_equipo, p.id_torneo, p.id_equipo
  FROM participacion_torneo_equipo p
  JOIN torneo_hist th ON th.id_torneo = p.id_torneo
  JOIN teams t ON t.id_equipo = p.id_equipo
  WHERE EXISTS (SELECT 1 FROM pte_hist_touch)
),

partido_hist_ab_upd AS (
  UPDATE partido p
  SET fecha_hora = TIMESTAMPTZ '2025-01-10 18:00:00+00',
      lugar = 'DEMO_HIST_AB',
      estado = 'acabado',
      jornada = 1
  WHERE p.id_torneo = (SELECT id_torneo FROM torneo_hist)
    AND p.lugar = 'DEMO_HIST_AB'
  RETURNING id_partido, id_torneo
),
partido_hist_ab_ins AS (
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada)
  SELECT (SELECT id_torneo FROM torneo_hist),
         TIMESTAMPTZ '2025-01-10 18:00:00+00',
         'DEMO_HIST_AB',
         'acabado',
         1
  WHERE NOT EXISTS (
    SELECT 1 FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_hist) AND p.lugar = 'DEMO_HIST_AB'
  )
  RETURNING id_partido, id_torneo
),
partido_hist_ab AS (
  SELECT id_partido, id_torneo
  FROM (
    SELECT id_partido, id_torneo FROM partido_hist_ab_upd
    UNION ALL SELECT id_partido, id_torneo FROM partido_hist_ab_ins
    UNION ALL
    SELECT p.id_partido, p.id_torneo
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_hist) AND p.lugar = 'DEMO_HIST_AB'
  ) q
  LIMIT 1
),

partido_hist_cd_upd AS (
  UPDATE partido p
  SET fecha_hora = TIMESTAMPTZ '2025-01-12 18:00:00+00',
      lugar = 'DEMO_HIST_CD',
      estado = 'acabado',
      jornada = 1
  WHERE p.id_torneo = (SELECT id_torneo FROM torneo_hist)
    AND p.lugar = 'DEMO_HIST_CD'
  RETURNING id_partido, id_torneo
),
partido_hist_cd_ins AS (
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada)
  SELECT (SELECT id_torneo FROM torneo_hist),
         TIMESTAMPTZ '2025-01-12 18:00:00+00',
         'DEMO_HIST_CD',
         'acabado',
         1
  WHERE NOT EXISTS (
    SELECT 1 FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_hist) AND p.lugar = 'DEMO_HIST_CD'
  )
  RETURNING id_partido, id_torneo
),
partido_hist_cd AS (
  SELECT id_partido, id_torneo
  FROM (
    SELECT id_partido, id_torneo FROM partido_hist_cd_upd
    UNION ALL SELECT id_partido, id_torneo FROM partido_hist_cd_ins
    UNION ALL
    SELECT p.id_partido, p.id_torneo
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_hist) AND p.lugar = 'DEMO_HIST_CD'
  ) q
  LIMIT 1
),

partido_hist_ad_upd AS (
  UPDATE partido p
  SET fecha_hora = TIMESTAMPTZ '2025-01-20 18:00:00+00',
      lugar = 'DEMO_HIST_AD',
      estado = 'acabado',
      jornada = 2
  WHERE p.id_torneo = (SELECT id_torneo FROM torneo_hist)
    AND p.lugar = 'DEMO_HIST_AD'
  RETURNING id_partido, id_torneo
),
partido_hist_ad_ins AS (
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada)
  SELECT (SELECT id_torneo FROM torneo_hist),
         TIMESTAMPTZ '2025-01-20 18:00:00+00',
         'DEMO_HIST_AD',
         'acabado',
         2
  WHERE NOT EXISTS (
    SELECT 1 FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_hist) AND p.lugar = 'DEMO_HIST_AD'
  )
  RETURNING id_partido, id_torneo
),
partido_hist_ad AS (
  SELECT id_partido, id_torneo
  FROM (
    SELECT id_partido, id_torneo FROM partido_hist_ad_upd
    UNION ALL SELECT id_partido, id_torneo FROM partido_hist_ad_ins
    UNION ALL
    SELECT p.id_partido, p.id_torneo
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_hist) AND p.lugar = 'DEMO_HIST_AD'
  ) q
  LIMIT 1
),

pp_hist_ab_upd AS (
  UPDATE participacion_partido pp
  SET punto = CASE WHEN e.nombre = 'Demo A' THEN 10 ELSE 7 END
  FROM partido_hist_ab p
  JOIN pte_hist_ref pte ON pte.id_torneo = p.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE pp.id_partido = p.id_partido
    AND pp.id_participacion_equipo = pte.id_participacion_equipo
    AND e.nombre IN ('Demo A', 'Demo B')
  RETURNING pp.id_participacion_partido
),
pp_hist_ab_ins AS (
  INSERT INTO participacion_partido (id_partido, id_participacion_equipo, punto)
  SELECT p.id_partido,
         pte.id_participacion_equipo,
         CASE WHEN e.nombre = 'Demo A' THEN 10 ELSE 7 END
  FROM partido_hist_ab p
  JOIN pte_hist_ref pte ON pte.id_torneo = p.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE e.nombre IN ('Demo A', 'Demo B')
    AND NOT EXISTS (
      SELECT 1 FROM participacion_partido pp
      WHERE pp.id_partido = p.id_partido AND pp.id_participacion_equipo = pte.id_participacion_equipo
    )
  RETURNING id_participacion_partido
),

pp_hist_cd_upd AS (
  UPDATE participacion_partido pp
  SET punto = CASE WHEN e.nombre = 'Demo D' THEN 12 ELSE 6 END
  FROM partido_hist_cd p
  JOIN pte_hist_ref pte ON pte.id_torneo = p.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE pp.id_partido = p.id_partido
    AND pp.id_participacion_equipo = pte.id_participacion_equipo
    AND e.nombre IN ('Demo C', 'Demo D')
  RETURNING pp.id_participacion_partido
),
pp_hist_cd_ins AS (
  INSERT INTO participacion_partido (id_partido, id_participacion_equipo, punto)
  SELECT p.id_partido,
         pte.id_participacion_equipo,
         CASE WHEN e.nombre = 'Demo D' THEN 12 ELSE 6 END
  FROM partido_hist_cd p
  JOIN pte_hist_ref pte ON pte.id_torneo = p.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE e.nombre IN ('Demo C', 'Demo D')
    AND NOT EXISTS (
      SELECT 1 FROM participacion_partido pp
      WHERE pp.id_partido = p.id_partido AND pp.id_participacion_equipo = pte.id_participacion_equipo
    )
  RETURNING id_participacion_partido
),

pp_hist_ad_upd AS (
  UPDATE participacion_partido pp
  SET punto = CASE WHEN e.nombre = 'Demo D' THEN 9 ELSE 8 END
  FROM partido_hist_ad p
  JOIN pte_hist_ref pte ON pte.id_torneo = p.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE pp.id_partido = p.id_partido
    AND pp.id_participacion_equipo = pte.id_participacion_equipo
    AND e.nombre IN ('Demo A', 'Demo D')
  RETURNING pp.id_participacion_partido
),
pp_hist_ad_ins AS (
  INSERT INTO participacion_partido (id_partido, id_participacion_equipo, punto)
  SELECT p.id_partido,
         pte.id_participacion_equipo,
         CASE WHEN e.nombre = 'Demo D' THEN 9 ELSE 8 END
  FROM partido_hist_ad p
  JOIN pte_hist_ref pte ON pte.id_torneo = p.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE e.nombre IN ('Demo A', 'Demo D')
    AND NOT EXISTS (
      SELECT 1 FROM participacion_partido pp
      WHERE pp.id_partido = p.id_partido AND pp.id_participacion_equipo = pte.id_participacion_equipo
    )
  RETURNING id_participacion_partido
),

-- 7) Historial ELO (varias entradas por equipo; idempotente por (equipo,fecha,desc))
elo_seed AS (
  INSERT INTO historial_elo (id_equipo, elo_anterior, elo_nuevo, descripcion, creado_en)
  SELECT t.id_equipo, e.elo, e.elo, 'DEMO_ELO_SEED', TIMESTAMPTZ '2025-01-01 00:00:00+00'
  FROM teams t
  JOIN equipo e ON e.id_equipo = t.id_equipo
  WHERE NOT EXISTS (
    SELECT 1 FROM historial_elo he
    WHERE he.id_equipo = t.id_equipo
      AND he.descripcion = 'DEMO_ELO_SEED'
      AND he.creado_en = TIMESTAMPTZ '2025-01-01 00:00:00+00'
  )
  RETURNING id_historial_elo
),
elo_after_ab_a AS (
  INSERT INTO historial_elo (id_equipo, elo_anterior, elo_nuevo, descripcion, creado_en)
  SELECT (SELECT id_equipo FROM team_a), 1300, 1320, 'DEMO_ELO_AFTER_AB', TIMESTAMPTZ '2025-01-10 18:05:00+00'
  WHERE NOT EXISTS (
    SELECT 1 FROM historial_elo he
    WHERE he.id_equipo = (SELECT id_equipo FROM team_a)
      AND he.descripcion = 'DEMO_ELO_AFTER_AB'
      AND he.creado_en = TIMESTAMPTZ '2025-01-10 18:05:00+00'
  )
  RETURNING id_historial_elo
),
elo_after_ab_b AS (
  INSERT INTO historial_elo (id_equipo, elo_anterior, elo_nuevo, descripcion, creado_en)
  SELECT (SELECT id_equipo FROM team_b), 1200, 1180, 'DEMO_ELO_AFTER_AB', TIMESTAMPTZ '2025-01-10 18:05:00+00'
  WHERE NOT EXISTS (
    SELECT 1 FROM historial_elo he
    WHERE he.id_equipo = (SELECT id_equipo FROM team_b)
      AND he.descripcion = 'DEMO_ELO_AFTER_AB'
      AND he.creado_en = TIMESTAMPTZ '2025-01-10 18:05:00+00'
  )
  RETURNING id_historial_elo
),
elo_after_cd_d AS (
  INSERT INTO historial_elo (id_equipo, elo_anterior, elo_nuevo, descripcion, creado_en)
  SELECT (SELECT id_equipo FROM team_d), 1400, 1415, 'DEMO_ELO_AFTER_CD', TIMESTAMPTZ '2025-01-12 18:05:00+00'
  WHERE NOT EXISTS (
    SELECT 1 FROM historial_elo he
    WHERE he.id_equipo = (SELECT id_equipo FROM team_d)
      AND he.descripcion = 'DEMO_ELO_AFTER_CD'
      AND he.creado_en = TIMESTAMPTZ '2025-01-12 18:05:00+00'
  )
  RETURNING id_historial_elo
),
elo_after_cd_c AS (
  INSERT INTO historial_elo (id_equipo, elo_anterior, elo_nuevo, descripcion, creado_en)
  SELECT (SELECT id_equipo FROM team_c), 1100, 1085, 'DEMO_ELO_AFTER_CD', TIMESTAMPTZ '2025-01-12 18:05:00+00'
  WHERE NOT EXISTS (
    SELECT 1 FROM historial_elo he
    WHERE he.id_equipo = (SELECT id_equipo FROM team_c)
      AND he.descripcion = 'DEMO_ELO_AFTER_CD'
      AND he.creado_en = TIMESTAMPTZ '2025-01-12 18:05:00+00'
  )
  RETURNING id_historial_elo
),
elo_after_ad_d AS (
  INSERT INTO historial_elo (id_equipo, elo_anterior, elo_nuevo, descripcion, creado_en)
  SELECT (SELECT id_equipo FROM team_d), 1415, 1430, 'DEMO_ELO_AFTER_AD', TIMESTAMPTZ '2025-01-20 18:05:00+00'
  WHERE NOT EXISTS (
    SELECT 1 FROM historial_elo he
    WHERE he.id_equipo = (SELECT id_equipo FROM team_d)
      AND he.descripcion = 'DEMO_ELO_AFTER_AD'
      AND he.creado_en = TIMESTAMPTZ '2025-01-20 18:05:00+00'
  )
  RETURNING id_historial_elo
),
elo_after_ad_a AS (
  INSERT INTO historial_elo (id_equipo, elo_anterior, elo_nuevo, descripcion, creado_en)
  SELECT (SELECT id_equipo FROM team_a), 1320, 1310, 'DEMO_ELO_AFTER_AD', TIMESTAMPTZ '2025-01-20 18:05:00+00'
  WHERE NOT EXISTS (
    SELECT 1 FROM historial_elo he
    WHERE he.id_equipo = (SELECT id_equipo FROM team_a)
      AND he.descripcion = 'DEMO_ELO_AFTER_AD'
      AND he.creado_en = TIMESTAMPTZ '2025-01-20 18:05:00+00'
  )
  RETURNING id_historial_elo
),

equipo_elo_apply AS (
  UPDATE equipo e
  SET elo = CASE
    WHEN e.id_equipo = (SELECT id_equipo FROM team_a) THEN 1310
    WHEN e.id_equipo = (SELECT id_equipo FROM team_b) THEN 1180
    WHEN e.id_equipo = (SELECT id_equipo FROM team_c) THEN 1085
    WHEN e.id_equipo = (SELECT id_equipo FROM team_d) THEN 1430
    ELSE e.elo
  END
  WHERE e.id_equipo IN (
    (SELECT id_equipo FROM team_a),
    (SELECT id_equipo FROM team_b),
    (SELECT id_equipo FROM team_c),
    (SELECT id_equipo FROM team_d)
  )
  RETURNING e.id_equipo
),

-- 8) Torneo Liga demo (en_curso) con partidos FUTUROS
torneo_liga_upd AS (
  UPDATE torneo
  SET descripcion = 'Liga demo para visualizar predicciones en jornadas',
      estado = 'en_curso',
      norma_puntuacion = 'victoria=3;empate=1;derrota=0'
  WHERE nombre = 'Demo Liga Predicciones'
    AND id_categoria = (SELECT id_categoria FROM cat_demo)
    AND id_tipo_torneo = (SELECT id_tipo_torneo FROM tipo_liga)
  RETURNING id_torneo
),
torneo_liga_ins AS (
  INSERT INTO torneo (
    nombre, descripcion, fecha_inicio, fecha_fin, estado, limite_equipos,
    id_categoria, id_tipo_torneo, id_organizador, norma_puntuacion
  )
  SELECT
    'Demo Liga Predicciones',
    'Liga demo para visualizar predicciones en jornadas',
    NOW() - INTERVAL '1 day',
    NULL,
    'en_curso',
    10,
    (SELECT id_categoria FROM cat_demo),
    (SELECT id_tipo_torneo FROM tipo_liga),
    (SELECT id_usuario FROM usr_demo),
    'victoria=3;empate=1;derrota=0'
  WHERE NOT EXISTS (
    SELECT 1 FROM torneo t
    WHERE t.nombre = 'Demo Liga Predicciones'
      AND t.id_categoria = (SELECT id_categoria FROM cat_demo)
      AND t.id_tipo_torneo = (SELECT id_tipo_torneo FROM tipo_liga)
  )
  RETURNING id_torneo
),
torneo_liga AS (
  SELECT id_torneo
  FROM (
    SELECT id_torneo FROM torneo_liga_upd
    UNION ALL SELECT id_torneo FROM torneo_liga_ins
    UNION ALL
    SELECT t.id_torneo
    FROM torneo t
    WHERE t.nombre = 'Demo Liga Predicciones'
      AND t.id_categoria = (SELECT id_categoria FROM cat_demo)
      AND t.id_tipo_torneo = (SELECT id_tipo_torneo FROM tipo_liga)
  ) q
  LIMIT 1
),

pte_liga_upd AS (
  UPDATE participacion_torneo_equipo p
  SET estado = 'jugando'
  FROM torneo_liga tlg
  JOIN teams t ON true
  WHERE p.id_torneo = tlg.id_torneo
    AND p.id_equipo = t.id_equipo
  RETURNING p.id_participacion_equipo
),
pte_liga_ins AS (
  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado)
  SELECT tlg.id_torneo, t.id_equipo, 'jugando'
  FROM torneo_liga tlg
  CROSS JOIN teams t
  WHERE NOT EXISTS (
    SELECT 1 FROM participacion_torneo_equipo p
    WHERE p.id_torneo = tlg.id_torneo AND p.id_equipo = t.id_equipo
  )
  RETURNING id_participacion_equipo
),
pte_liga_ref AS (
  SELECT p.id_participacion_equipo, p.id_torneo, p.id_equipo
  FROM participacion_torneo_equipo p
  JOIN torneo_liga tlg ON tlg.id_torneo = p.id_torneo
  JOIN teams t ON t.id_equipo = p.id_equipo
),

-- Limpieza: mantener el demo de liga con 1 único partido (DEMO_LIGA_MULTI)
-- Esto evita que salgan partidos "TBD" creados por generación automática u otras ejecuciones.
liga_partidos_to_delete AS (
  SELECT p.id_partido
  FROM partido p
  WHERE p.id_torneo = (SELECT id_torneo FROM torneo_liga)
    AND p.lugar IS DISTINCT FROM 'DEMO_LIGA_MULTI'
),
liga_cleanup_pp AS (
  DELETE FROM participacion_partido pp
  USING liga_partidos_to_delete d
  WHERE pp.id_partido = d.id_partido
  RETURNING pp.id_participacion_partido
),
liga_cleanup_partidos AS (
  DELETE FROM partido p
  USING liga_partidos_to_delete d
  WHERE p.id_partido = d.id_partido
  RETURNING p.id_partido
),

partido_liga_multi_upd AS (
  UPDATE partido p
  SET fecha_hora = TIMESTAMPTZ '2030-01-04 18:00:00+00', lugar = 'DEMO_LIGA_MULTI', estado = 'planificado', jornada = 1
  WHERE p.id_torneo = (SELECT id_torneo FROM torneo_liga) AND p.lugar = 'DEMO_LIGA_MULTI'
  RETURNING id_partido, id_torneo
),
partido_liga_multi_ins AS (
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada)
  SELECT (SELECT id_torneo FROM torneo_liga), TIMESTAMPTZ '2030-01-04 18:00:00+00', 'DEMO_LIGA_MULTI', 'planificado', 1
  WHERE NOT EXISTS (
    SELECT 1 FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_liga) AND p.lugar = 'DEMO_LIGA_MULTI'
  )
  RETURNING id_partido, id_torneo
),
partido_liga_multi AS (
  SELECT id_partido, id_torneo
  FROM (
    SELECT id_partido, id_torneo FROM partido_liga_multi_upd
    UNION ALL SELECT id_partido, id_torneo FROM partido_liga_multi_ins
    UNION ALL
    SELECT p.id_partido, p.id_torneo
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_liga) AND p.lugar = 'DEMO_LIGA_MULTI'
  ) q
  LIMIT 1
),

pp_liga_multi_upd AS (
  UPDATE participacion_partido pp
  SET punto = 0
  FROM partido_liga_multi p
  JOIN pte_liga_ref pte ON pte.id_torneo = p.id_torneo
  WHERE pp.id_partido = p.id_partido
    AND pp.id_participacion_equipo = pte.id_participacion_equipo
  RETURNING pp.id_participacion_partido
),
pp_liga_multi_ins AS (
  INSERT INTO participacion_partido (id_partido, id_participacion_equipo, punto)
  SELECT p.id_partido, pte.id_participacion_equipo, 0
  FROM partido_liga_multi p
  JOIN pte_liga_ref pte ON pte.id_torneo = p.id_torneo
  WHERE NOT EXISTS (
    SELECT 1 FROM participacion_partido pp
    WHERE pp.id_partido = p.id_partido AND pp.id_participacion_equipo = pte.id_participacion_equipo
  )
  RETURNING id_participacion_partido
),

-- 9) Torneo Eliminación demo (en_curso) con bracket FUTURO
torneo_elim_upd AS (
  UPDATE torneo
  SET descripcion = 'Eliminación demo para visualizar predicciones en bracket',
      estado = 'en_curso'
  WHERE nombre = 'Demo Eliminación Predicciones'
    AND id_categoria = (SELECT id_categoria FROM cat_demo)
    AND id_tipo_torneo = (SELECT id_tipo_torneo FROM tipo_elim)
  RETURNING id_torneo
),
torneo_elim_ins AS (
  INSERT INTO torneo (
    nombre, descripcion, fecha_inicio, fecha_fin, estado, limite_equipos,
    id_categoria, id_tipo_torneo, id_organizador
  )
  SELECT
    'Demo Eliminación Predicciones',
    'Eliminación demo para visualizar predicciones en bracket',
    NOW() - INTERVAL '1 day',
    NULL,
    'en_curso',
    4,
    (SELECT id_categoria FROM cat_demo),
    (SELECT id_tipo_torneo FROM tipo_elim),
    (SELECT id_usuario FROM usr_demo)
  WHERE NOT EXISTS (
    SELECT 1 FROM torneo t
    WHERE t.nombre = 'Demo Eliminación Predicciones'
      AND t.id_categoria = (SELECT id_categoria FROM cat_demo)
      AND t.id_tipo_torneo = (SELECT id_tipo_torneo FROM tipo_elim)
  )
  RETURNING id_torneo
),
torneo_elim AS (
  SELECT id_torneo
  FROM (
    SELECT id_torneo FROM torneo_elim_upd
    UNION ALL SELECT id_torneo FROM torneo_elim_ins
    UNION ALL
    SELECT t.id_torneo
    FROM torneo t
    WHERE t.nombre = 'Demo Eliminación Predicciones'
      AND t.id_categoria = (SELECT id_categoria FROM cat_demo)
      AND t.id_tipo_torneo = (SELECT id_tipo_torneo FROM tipo_elim)
  ) q
  LIMIT 1
),

pte_elim_upd AS (
  UPDATE participacion_torneo_equipo p
  SET estado = 'jugando'
  FROM torneo_elim te
  JOIN teams t ON true
  WHERE p.id_torneo = te.id_torneo
    AND p.id_equipo = t.id_equipo
  RETURNING p.id_participacion_equipo
),
pte_elim_ins AS (
  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado)
  SELECT te.id_torneo, t.id_equipo, 'jugando'
  FROM torneo_elim te
  CROSS JOIN teams t
  WHERE NOT EXISTS (
    SELECT 1 FROM participacion_torneo_equipo p
    WHERE p.id_torneo = te.id_torneo AND p.id_equipo = t.id_equipo
  )
  RETURNING id_participacion_equipo
),
pte_elim_ref AS (
  SELECT p.id_participacion_equipo, p.id_torneo, p.id_equipo
  FROM participacion_torneo_equipo p
  JOIN torneo_elim te ON te.id_torneo = p.id_torneo
  JOIN teams t ON t.id_equipo = p.id_equipo
),

final_elim_upd AS (
  UPDATE partido p
  SET fecha_hora = TIMESTAMPTZ '2030-01-10 18:00:00+00', lugar = 'DEMO_ELIM_FINAL', estado = 'planificado', ronda = 2, orden_ronda = 1
  WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim) AND p.ronda = 2 AND p.orden_ronda = 1
  RETURNING id_partido, id_torneo
),
final_elim_ins AS (
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, ronda, orden_ronda)
  SELECT (SELECT id_torneo FROM torneo_elim), TIMESTAMPTZ '2030-01-10 18:00:00+00', 'DEMO_ELIM_FINAL', 'planificado', 2, 1
  WHERE NOT EXISTS (
    SELECT 1 FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim) AND p.ronda = 2 AND p.orden_ronda = 1
  )
  RETURNING id_partido, id_torneo
),
final_elim AS (
  SELECT id_partido, id_torneo
  FROM (
    SELECT id_partido, id_torneo FROM final_elim_upd
    UNION ALL SELECT id_partido, id_torneo FROM final_elim_ins
    UNION ALL
    SELECT p.id_partido, p.id_torneo
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim) AND p.ronda = 2 AND p.orden_ronda = 1
  ) q
  LIMIT 1
),

semi1_elim_upd AS (
  UPDATE partido p
  SET fecha_hora = TIMESTAMPTZ '2030-01-07 18:00:00+00', lugar = 'DEMO_ELIM_SEMI_1', estado = 'acabado', ronda = 1, orden_ronda = 1,
      id_partido_siguiente = (SELECT id_partido FROM final_elim)
  WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim) AND p.ronda = 1 AND p.orden_ronda = 1
  RETURNING id_partido, id_torneo
),
semi1_elim_ins AS (
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, ronda, orden_ronda, id_partido_siguiente)
  SELECT (SELECT id_torneo FROM torneo_elim), TIMESTAMPTZ '2030-01-07 18:00:00+00', 'DEMO_ELIM_SEMI_1', 'acabado', 1, 1, (SELECT id_partido FROM final_elim)
  WHERE NOT EXISTS (
    SELECT 1 FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim) AND p.ronda = 1 AND p.orden_ronda = 1
  )
  RETURNING id_partido, id_torneo
),
semi1_elim AS (
  SELECT id_partido, id_torneo
  FROM (
    SELECT id_partido, id_torneo FROM semi1_elim_upd
    UNION ALL SELECT id_partido, id_torneo FROM semi1_elim_ins
    UNION ALL
    SELECT p.id_partido, p.id_torneo
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim) AND p.ronda = 1 AND p.orden_ronda = 1
  ) q
  LIMIT 1
),

semi2_elim_upd AS (
  UPDATE partido p
  SET fecha_hora = TIMESTAMPTZ '2030-01-07 18:30:00+00', lugar = 'DEMO_ELIM_SEMI_2', estado = 'acabado', ronda = 1, orden_ronda = 2,
      id_partido_siguiente = (SELECT id_partido FROM final_elim)
  WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim) AND p.ronda = 1 AND p.orden_ronda = 2
  RETURNING id_partido, id_torneo
),
semi2_elim_ins AS (
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, ronda, orden_ronda, id_partido_siguiente)
  SELECT (SELECT id_torneo FROM torneo_elim), TIMESTAMPTZ '2030-01-07 18:30:00+00', 'DEMO_ELIM_SEMI_2', 'acabado', 1, 2, (SELECT id_partido FROM final_elim)
  WHERE NOT EXISTS (
    SELECT 1 FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim) AND p.ronda = 1 AND p.orden_ronda = 2
  )
  RETURNING id_partido, id_torneo
),
semi2_elim AS (
  SELECT id_partido, id_torneo
  FROM (
    SELECT id_partido, id_torneo FROM semi2_elim_upd
    UNION ALL SELECT id_partido, id_torneo FROM semi2_elim_ins
    UNION ALL
    SELECT p.id_partido, p.id_torneo
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim) AND p.ronda = 1 AND p.orden_ronda = 2
  ) q
  LIMIT 1
),

pp_semi1_upd AS (
  UPDATE participacion_partido pp
  SET punto = CASE WHEN e.nombre = 'Demo A' THEN 11 ELSE 7 END
  FROM semi1_elim s
  JOIN pte_elim_ref pte ON pte.id_torneo = s.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE pp.id_partido = s.id_partido
    AND pp.id_participacion_equipo = pte.id_participacion_equipo
    AND e.nombre IN ('Demo A', 'Demo B')
  RETURNING pp.id_participacion_partido
),
pp_semi1_ins AS (
  INSERT INTO participacion_partido (id_partido, id_participacion_equipo, punto)
  SELECT s.id_partido,
         pte.id_participacion_equipo,
         CASE WHEN e.nombre = 'Demo A' THEN 11 ELSE 7 END
  FROM semi1_elim s
  JOIN pte_elim_ref pte ON pte.id_torneo = s.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE e.nombre IN ('Demo A', 'Demo B')
    AND NOT EXISTS (
      SELECT 1 FROM participacion_partido pp
      WHERE pp.id_partido = s.id_partido AND pp.id_participacion_equipo = pte.id_participacion_equipo
    )
  RETURNING id_participacion_partido
),

pp_semi2_upd AS (
  UPDATE participacion_partido pp
  SET punto = CASE WHEN e.nombre = 'Demo D' THEN 12 ELSE 6 END
  FROM semi2_elim s
  JOIN pte_elim_ref pte ON pte.id_torneo = s.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE pp.id_partido = s.id_partido
    AND pp.id_participacion_equipo = pte.id_participacion_equipo
    AND e.nombre IN ('Demo C', 'Demo D')
  RETURNING pp.id_participacion_partido
),
pp_semi2_ins AS (
  INSERT INTO participacion_partido (id_partido, id_participacion_equipo, punto)
  SELECT s.id_partido,
         pte.id_participacion_equipo,
         CASE WHEN e.nombre = 'Demo D' THEN 12 ELSE 6 END
  FROM semi2_elim s
  JOIN pte_elim_ref pte ON pte.id_torneo = s.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE e.nombre IN ('Demo C', 'Demo D')
    AND NOT EXISTS (
      SELECT 1 FROM participacion_partido pp
      WHERE pp.id_partido = s.id_partido AND pp.id_participacion_equipo = pte.id_participacion_equipo
    )
  RETURNING id_participacion_partido
),

pp_final_upd AS (
  UPDATE participacion_partido pp
  SET punto = 0
  FROM final_elim f
  JOIN pte_elim_ref pte ON pte.id_torneo = f.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE pp.id_partido = f.id_partido
    AND pp.id_participacion_equipo = pte.id_participacion_equipo
    AND e.nombre IN ('Demo A', 'Demo D')
  RETURNING pp.id_participacion_partido
),
pp_final_ins AS (
  INSERT INTO participacion_partido (id_partido, id_participacion_equipo, punto)
  SELECT f.id_partido, pte.id_participacion_equipo, 0
  FROM final_elim f
  JOIN pte_elim_ref pte ON pte.id_torneo = f.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE e.nombre IN ('Demo A', 'Demo D')
    AND NOT EXISTS (
      SELECT 1 FROM participacion_partido pp
      WHERE pp.id_partido = f.id_partido AND pp.id_participacion_equipo = pte.id_participacion_equipo
    )
  RETURNING id_participacion_partido
),

-- Importante: muchos CTE con INSERT/UPDATE pueden ser optimizados/inlined si no se referencian.
-- Esta CTE fuerza la ejecución de todos los side-effects que queremos que ocurran.
_force AS (
  SELECT 1 AS x FROM pp_hist_ab_upd
  UNION ALL SELECT 1 FROM pp_hist_ab_ins
  UNION ALL SELECT 1 FROM pp_hist_cd_upd
  UNION ALL SELECT 1 FROM pp_hist_cd_ins
  UNION ALL SELECT 1 FROM pp_hist_ad_upd
  UNION ALL SELECT 1 FROM pp_hist_ad_ins
  UNION ALL SELECT 1 FROM elo_seed
  UNION ALL SELECT 1 FROM elo_after_ab_a
  UNION ALL SELECT 1 FROM elo_after_ab_b
  UNION ALL SELECT 1 FROM elo_after_cd_d
  UNION ALL SELECT 1 FROM elo_after_cd_c
  UNION ALL SELECT 1 FROM elo_after_ad_d
  UNION ALL SELECT 1 FROM elo_after_ad_a
  UNION ALL SELECT 1 FROM equipo_elo_apply
  UNION ALL SELECT 1 FROM liga_cleanup_pp
  UNION ALL SELECT 1 FROM liga_cleanup_partidos
  UNION ALL SELECT 1 FROM pp_liga_multi_upd
  UNION ALL SELECT 1 FROM pp_liga_multi_ins
  UNION ALL SELECT 1 FROM pp_semi1_upd
  UNION ALL SELECT 1 FROM pp_semi1_ins
  UNION ALL SELECT 1 FROM pp_semi2_upd
  UNION ALL SELECT 1 FROM pp_semi2_ins
  UNION ALL SELECT 1 FROM pp_final_upd
  UNION ALL SELECT 1 FROM pp_final_ins
)

SELECT
  (SELECT id_torneo FROM torneo_hist) AS id_torneo_historial,
  (SELECT id_partido FROM partido_hist_ab) AS id_partido_hist_ab,
  (SELECT id_partido FROM partido_hist_cd) AS id_partido_hist_cd,
  (SELECT id_partido FROM partido_hist_ad) AS id_partido_hist_ad,
  (SELECT id_torneo FROM torneo_liga) AS id_torneo_liga,
  (SELECT id_partido FROM partido_liga_multi) AS id_partido_liga_multi,
  (SELECT id_torneo FROM torneo_elim) AS id_torneo_eliminacion,
  (SELECT id_partido FROM semi1_elim) AS id_partido_elim_semi1,
  (SELECT id_partido FROM semi2_elim) AS id_partido_elim_semi2,
  (SELECT id_partido FROM final_elim) AS id_partido_elim_final,
  (SELECT COUNT(*) FROM _force) AS _force_rows;

-- Seteo determinista de ganadores del torneo histórico (partidos acabados)
UPDATE partido p
SET ganador_id_participacion_equipo = (
  SELECT pte.id_participacion_equipo
  FROM participacion_torneo_equipo pte
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE pte.id_torneo = p.id_torneo AND e.nombre = 'Demo A'
  LIMIT 1
)
WHERE p.id_torneo = (
  SELECT id_torneo
  FROM torneo
  WHERE nombre = 'Demo Historial Predicciones'
  ORDER BY id_torneo DESC
  LIMIT 1
)
  AND p.lugar = 'DEMO_HIST_AB';

UPDATE partido p
SET ganador_id_participacion_equipo = (
  SELECT pte.id_participacion_equipo
  FROM participacion_torneo_equipo pte
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE pte.id_torneo = p.id_torneo AND e.nombre = 'Demo D'
  LIMIT 1
)
WHERE p.id_torneo = (
  SELECT id_torneo
  FROM torneo
  WHERE nombre = 'Demo Historial Predicciones'
  ORDER BY id_torneo DESC
  LIMIT 1
)
  AND p.lugar = 'DEMO_HIST_CD';

UPDATE partido p
SET ganador_id_participacion_equipo = (
  SELECT pte.id_participacion_equipo
  FROM participacion_torneo_equipo pte
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE pte.id_torneo = p.id_torneo AND e.nombre = 'Demo D'
  LIMIT 1
)
WHERE p.id_torneo = (
  SELECT id_torneo
  FROM torneo
  WHERE nombre = 'Demo Historial Predicciones'
  ORDER BY id_torneo DESC
  LIMIT 1
)
  AND p.lugar = 'DEMO_HIST_AD';

COMMIT;
