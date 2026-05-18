-- Demo data para visualizar predicciones (Liga + Eliminación)
-- Requisitos:
-- - Tipos de torneo con nombres compatibles con el front: "Liga" y "Eliminación".
-- - Partidos futuros en estado 'planificado' y con participacion_partido (>=2 equipos) para que /partidos/:id/prediccion devuelva probabilidades.
-- - Historial Elo previo a la fecha del partido.

BEGIN;

-- Nota: evitamos ON CONFLICT para compatibilidad con Postgres < 9.5.

-- 1) Tipos de torneo (insert/update idempotente)
WITH tipo_liga_upd AS (
  UPDATE tipo_torneo
  SET descripcion = 'Torneo tipo liga (demo predicciones)'
  WHERE nombre = 'Liga'
  RETURNING id_tipo_torneo
), tipo_liga_ins AS (
  INSERT INTO tipo_torneo (nombre, descripcion)
  SELECT 'Liga', 'Torneo tipo liga (demo predicciones)'
  WHERE NOT EXISTS (SELECT 1 FROM tipo_torneo WHERE nombre = 'Liga')
  RETURNING id_tipo_torneo
), tipo_liga AS (
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
), tipo_elim_ins AS (
  INSERT INTO tipo_torneo (nombre, descripcion)
  SELECT 'Eliminación', 'Torneo tipo eliminacion (demo predicciones)'
  WHERE NOT EXISTS (SELECT 1 FROM tipo_torneo WHERE nombre = 'Eliminación')
  RETURNING id_tipo_torneo
), tipo_elim AS (
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

-- 2) Categoría (una sola categoría que permite también partidos 3+)
cat_demo_upd AS (
  UPDATE categoria
  SET participantes_por_partida = 4,
      descripcion = 'Categoría de prueba para ver porcentajes de predicción'
  WHERE nombre = 'Demo Predicciones'
  RETURNING id_categoria
),
cat_demo_ins AS (
  INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion, icono)
  SELECT
    'Demo Predicciones',
    4,
    NULL,
    'Categoría de prueba para ver porcentajes de predicción',
    NULL
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
    SELECT 1
    FROM categoria_tipo_torneo ctt
    WHERE ctt.id_categoria = c.id_categoria
      AND ctt.id_tipo_torneo = t.id_tipo_torneo
  )
  RETURNING id_categoria_tipo_torneo
),
cat_tipo_elim AS (
  INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
  SELECT c.id_categoria, t.id_tipo_torneo
  FROM cat_demo c
  CROSS JOIN tipo_elim t
  WHERE NOT EXISTS (
    SELECT 1
    FROM categoria_tipo_torneo ctt
    WHERE ctt.id_categoria = c.id_categoria
      AND ctt.id_tipo_torneo = t.id_tipo_torneo
  )
  RETURNING id_categoria_tipo_torneo
),

-- 4) Usuario organizador
usr_demo_upd AS (
  UPDATE usuario
  SET nombre_usuario = 'demo_predicciones',
      nombre = 'Demo',
      apellidos = 'Predicciones'
  WHERE correo = 'demo_predicciones@app.local'
  RETURNING id_usuario
),
usr_demo_ins AS (
  INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
  SELECT
    'demo_predicciones@app.local',
    'demo_predicciones',
    'demo',
    'Demo',
    'Predicciones'
  WHERE NOT EXISTS (
    SELECT 1 FROM usuario WHERE correo = 'demo_predicciones@app.local'
  )
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

-- 5) Equipos
team_a_upd AS (
  UPDATE equipo
  SET descripcion = 'Equipo demo A',
      elo = 1300,
      id_categoria = (SELECT id_categoria FROM cat_demo)
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
  SET descripcion = 'Equipo demo B',
      elo = 1200,
      id_categoria = (SELECT id_categoria FROM cat_demo)
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
  SET descripcion = 'Equipo demo C',
      elo = 1100,
      id_categoria = (SELECT id_categoria FROM cat_demo)
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
  SET descripcion = 'Equipo demo D',
      elo = 1400,
      id_categoria = (SELECT id_categoria FROM cat_demo)
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
  UNION ALL
  SELECT id_equipo, 'Demo B'::text AS nombre FROM team_b
  UNION ALL
  SELECT id_equipo, 'Demo C'::text AS nombre FROM team_c
  UNION ALL
  SELECT id_equipo, 'Demo D'::text AS nombre FROM team_d
),

-- 6) Historial Elo (si ya existe historial, no lo tocamos; si está vacío, insertamos 2 puntos por equipo)
hist_check AS (
  SELECT COUNT(*)::int AS n FROM historial_elo he
  JOIN teams t ON t.id_equipo = he.id_equipo
),
hist_seed AS (
  INSERT INTO historial_elo (id_equipo, elo_anterior, elo_nuevo, descripcion, creado_en)
  SELECT t.id_equipo,
         e.elo AS elo_anterior,
         e.elo AS elo_nuevo,
         'Seed demo predicciones',
         NOW() - INTERVAL '30 days'
  FROM teams t
  JOIN equipo e ON e.id_equipo = t.id_equipo
  WHERE (SELECT n FROM hist_check) = 0
  RETURNING id_historial_elo
),
hist_recent AS (
  INSERT INTO historial_elo (id_equipo, elo_anterior, elo_nuevo, descripcion, creado_en)
  SELECT t.id_equipo,
         e.elo AS elo_anterior,
         e.elo AS elo_nuevo,
         'Último elo demo predicciones',
         NOW() - INTERVAL '3 days'
  FROM teams t
  JOIN equipo e ON e.id_equipo = t.id_equipo
  WHERE (SELECT n FROM hist_check) = 0
  RETURNING id_historial_elo
),

-- 7) Torneo Liga (estado visible para el front)
torneo_liga_upd AS (
  UPDATE torneo
  SET descripcion = 'Liga demo para visualizar porcentajes junto al equipo en jornadas',
      estado = 'en_curso',
      norma_puntuacion = 'victoria=3;empate=1;derrota=0'
  WHERE nombre = 'Demo Liga Predicciones'
    AND id_categoria = (SELECT id_categoria FROM cat_demo)
    AND id_tipo_torneo = (SELECT id_tipo_torneo FROM tipo_liga)
  RETURNING id_torneo
),
torneo_liga_ins AS (
  INSERT INTO torneo (
    nombre,
    descripcion,
    fecha_inicio,
    fecha_fin,
    estado,
    limite_equipos,
    id_categoria,
    id_tipo_torneo,
    id_organizador,
    norma_puntuacion
  )
  SELECT
    'Demo Liga Predicciones',
    'Liga demo para visualizar porcentajes junto al equipo en jornadas',
    NOW() - INTERVAL '1 day',
    NULL,
    'en_curso',
    10,
    (SELECT id_categoria FROM cat_demo),
    (SELECT id_tipo_torneo FROM tipo_liga),
    (SELECT id_usuario FROM usr_demo),
    'victoria=3;empate=1;derrota=0'
  WHERE NOT EXISTS (
    SELECT 1
    FROM torneo t
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
    UNION ALL
    SELECT id_torneo FROM torneo_liga_ins
    UNION ALL
    SELECT t.id_torneo
    FROM torneo t
    WHERE t.nombre = 'Demo Liga Predicciones'
      AND t.id_categoria = (SELECT id_categoria FROM cat_demo)
      AND t.id_tipo_torneo = (SELECT id_tipo_torneo FROM tipo_liga)
  ) q
  LIMIT 1
),

-- Participaciones en Liga
pte_liga AS (
  SELECT p.id_participacion_equipo, p.id_torneo, p.id_equipo
  FROM participacion_torneo_equipo p
  JOIN torneo_liga tlg ON tlg.id_torneo = p.id_torneo
  JOIN teams t ON t.id_equipo = p.id_equipo
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
    SELECT 1
    FROM participacion_torneo_equipo p
    WHERE p.id_torneo = tlg.id_torneo
      AND p.id_equipo = t.id_equipo
  )
  RETURNING id_participacion_equipo
),

pte_liga_ref AS (
  SELECT p.id_participacion_equipo, p.id_torneo, p.id_equipo
  FROM participacion_torneo_equipo p
  JOIN torneo_liga tlg ON tlg.id_torneo = p.id_torneo
  JOIN teams t ON t.id_equipo = p.id_equipo
),

-- Partidos Liga: uno 1v1 y otro 4-equipos, ambos futuros/planificados
partido_liga_1v1_upd AS (
  UPDATE partido p
  SET fecha_hora = TIMESTAMPTZ '2030-01-02 18:00:00+00',
      lugar = 'DEMO_LIGA_1V1',
      estado = 'planificado',
      jornada = 1
  WHERE p.id_torneo = (SELECT id_torneo FROM torneo_liga)
    AND p.lugar = 'DEMO_LIGA_1V1'
  RETURNING id_partido, id_torneo
),
partido_liga_1v1_ins AS (
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada)
  SELECT (SELECT id_torneo FROM torneo_liga),
         TIMESTAMPTZ '2030-01-02 18:00:00+00',
         'DEMO_LIGA_1V1',
         'planificado',
         1
  WHERE NOT EXISTS (
    SELECT 1
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_liga)
      AND p.lugar = 'DEMO_LIGA_1V1'
  )
  RETURNING id_partido, id_torneo
),
partido_liga_1v1 AS (
  SELECT id_partido, id_torneo
  FROM (
    SELECT id_partido, id_torneo FROM partido_liga_1v1_upd
    UNION ALL
    SELECT id_partido, id_torneo FROM partido_liga_1v1_ins
    UNION ALL
    SELECT p.id_partido, p.id_torneo
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_liga)
      AND p.lugar = 'DEMO_LIGA_1V1'
  ) q
  LIMIT 1
),
partido_liga_multi AS (
partido_liga_multi_upd AS (
  UPDATE partido p
  SET fecha_hora = TIMESTAMPTZ '2030-01-04 18:00:00+00',
      lugar = 'DEMO_LIGA_MULTI',
      estado = 'planificado',
      jornada = 1
  WHERE p.id_torneo = (SELECT id_torneo FROM torneo_liga)
    AND p.lugar = 'DEMO_LIGA_MULTI'
  RETURNING id_partido, id_torneo
),
partido_liga_multi_ins AS (
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada)
  SELECT (SELECT id_torneo FROM torneo_liga),
         TIMESTAMPTZ '2030-01-04 18:00:00+00',
         'DEMO_LIGA_MULTI',
         'planificado',
         1
  WHERE NOT EXISTS (
    SELECT 1
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_liga)
      AND p.lugar = 'DEMO_LIGA_MULTI'
  )
  RETURNING id_partido, id_torneo
),
partido_liga_multi AS (
  SELECT id_partido, id_torneo
  FROM (
    SELECT id_partido, id_torneo FROM partido_liga_multi_upd
    UNION ALL
    SELECT id_partido, id_torneo FROM partido_liga_multi_ins
    UNION ALL
    SELECT p.id_partido, p.id_torneo
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_liga)
      AND p.lugar = 'DEMO_LIGA_MULTI'
  ) q
  LIMIT 1
),

-- Participación por partido (Liga 1v1: A vs B)
pp_liga_1v1 AS (
  INSERT INTO participacion_partido (id_partido, id_participacion_equipo, punto)
  SELECT p.id_partido, pte.id_participacion_equipo, 0
  FROM partido_liga_1v1 p
  JOIN pte_liga_ref pte ON pte.id_torneo = p.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE e.nombre IN ('Demo A', 'Demo B')
    AND NOT EXISTS (
      SELECT 1
      FROM participacion_partido pp
      WHERE pp.id_partido = p.id_partido
        AND pp.id_participacion_equipo = pte.id_participacion_equipo
    )
  RETURNING id_participacion_partido
),

pp_liga_1v1_upd AS (
  UPDATE participacion_partido pp
  SET punto = 0
  FROM partido_liga_1v1 p
  JOIN pte_liga_ref pte ON pte.id_torneo = p.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE pp.id_partido = p.id_partido
    AND pp.id_participacion_equipo = pte.id_participacion_equipo
    AND e.nombre IN ('Demo A', 'Demo B')
  RETURNING pp.id_participacion_partido
),

-- Participación por partido (Liga multi: A,B,C,D)
pp_liga_multi AS (
  INSERT INTO participacion_partido (id_partido, id_participacion_equipo, punto)
  SELECT p.id_partido, pte.id_participacion_equipo, 0
  FROM partido_liga_multi p
  JOIN pte_liga_ref pte ON pte.id_torneo = p.id_torneo
  WHERE NOT EXISTS (
    SELECT 1
    FROM participacion_partido pp
    WHERE pp.id_partido = p.id_partido
      AND pp.id_participacion_equipo = pte.id_participacion_equipo
  )
  RETURNING id_participacion_partido
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

-- 8) Torneo Eliminación
torneo_elim AS (
  SELECT id_torneo
  FROM (
    SELECT id_torneo FROM torneo_elim_upd
    UNION ALL
    SELECT id_torneo FROM torneo_elim_ins
    UNION ALL
    SELECT t.id_torneo
    FROM torneo t
    WHERE t.nombre = 'Demo Eliminación Predicciones'
      AND t.id_categoria = (SELECT id_categoria FROM cat_demo)
      AND t.id_tipo_torneo = (SELECT id_tipo_torneo FROM tipo_elim)
  ) q
  LIMIT 1
),

torneo_elim_upd AS (
  UPDATE torneo
  SET descripcion = 'Eliminación demo para visualizar porcentajes en bracket',
      estado = 'en_curso'
  WHERE nombre = 'Demo Eliminación Predicciones'
    AND id_categoria = (SELECT id_categoria FROM cat_demo)
    AND id_tipo_torneo = (SELECT id_tipo_torneo FROM tipo_elim)
  RETURNING id_torneo
),
torneo_elim_ins AS (
  INSERT INTO torneo (
    nombre,
    descripcion,
    fecha_inicio,
    fecha_fin,
    estado,
    limite_equipos,
    id_categoria,
    id_tipo_torneo,
    id_organizador
  )
  SELECT
    'Demo Eliminación Predicciones',
    'Eliminación demo para visualizar porcentajes en bracket',
    NOW() - INTERVAL '1 day',
    NULL,
    'en_curso',
    4,
    (SELECT id_categoria FROM cat_demo),
    (SELECT id_tipo_torneo FROM tipo_elim),
    (SELECT id_usuario FROM usr_demo)
  WHERE NOT EXISTS (
    SELECT 1
    FROM torneo t
    WHERE t.nombre = 'Demo Eliminación Predicciones'
      AND t.id_categoria = (SELECT id_categoria FROM cat_demo)
      AND t.id_tipo_torneo = (SELECT id_tipo_torneo FROM tipo_elim)
  )
  RETURNING id_torneo
),

-- Participaciones en Eliminación
pte_elim AS (
  SELECT p.id_participacion_equipo, p.id_torneo, p.id_equipo
  FROM participacion_torneo_equipo p
  JOIN torneo_elim te ON te.id_torneo = p.id_torneo
  JOIN teams t ON t.id_equipo = p.id_equipo
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
    SELECT 1
    FROM participacion_torneo_equipo p
    WHERE p.id_torneo = te.id_torneo
      AND p.id_equipo = t.id_equipo
  )
  RETURNING id_participacion_equipo
),

pte_elim_ref AS (
  SELECT p.id_participacion_equipo, p.id_torneo, p.id_equipo
  FROM participacion_torneo_equipo p
  JOIN torneo_elim te ON te.id_torneo = p.id_torneo
  JOIN teams t ON t.id_equipo = p.id_equipo
),

-- Partidos Eliminación: dos semifinales + final (final sin equipos = TBD)
final_elim_upd AS (
  UPDATE partido p
  SET fecha_hora = TIMESTAMPTZ '2030-01-10 18:00:00+00',
      lugar = 'DEMO_ELIM_FINAL',
      estado = 'planificado',
      ronda = 2,
      orden_ronda = 1
  WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim)
    AND p.ronda = 2
    AND p.orden_ronda = 1
  RETURNING id_partido, id_torneo
),
final_elim_ins AS (
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, ronda, orden_ronda)
  SELECT (SELECT id_torneo FROM torneo_elim),
         TIMESTAMPTZ '2030-01-10 18:00:00+00',
         'DEMO_ELIM_FINAL',
         'planificado',
         2,
         1
  WHERE NOT EXISTS (
    SELECT 1
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim)
      AND p.ronda = 2
      AND p.orden_ronda = 1
  )
  RETURNING id_partido, id_torneo
),
final_elim AS (
  SELECT id_partido, id_torneo
  FROM (
    SELECT id_partido, id_torneo FROM final_elim_upd
    UNION ALL
    SELECT id_partido, id_torneo FROM final_elim_ins
    UNION ALL
    SELECT p.id_partido, p.id_torneo
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim)
      AND p.ronda = 2
      AND p.orden_ronda = 1
  ) q
  LIMIT 1
),
semi1_elim_ins AS (
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, ronda, orden_ronda, id_partido_siguiente)
  SELECT (SELECT id_torneo FROM torneo_elim),
         TIMESTAMPTZ '2030-01-07 18:00:00+00',
         'DEMO_ELIM_SEMI_1',
         'planificado',
         1,
         1,
         (SELECT id_partido FROM final_elim)
  WHERE NOT EXISTS (
    SELECT 1
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim)
      AND p.ronda = 1
      AND p.orden_ronda = 1
  )
  RETURNING id_partido, id_torneo
),
semi1_elim_upd AS (
  UPDATE partido p
  SET fecha_hora = TIMESTAMPTZ '2030-01-07 18:00:00+00',
      lugar = 'DEMO_ELIM_SEMI_1',
      estado = 'planificado',
      ronda = 1,
      orden_ronda = 1,
      id_partido_siguiente = (SELECT id_partido FROM final_elim)
  WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim)
    AND p.ronda = 1
    AND p.orden_ronda = 1
  RETURNING id_partido, id_torneo
),
semi1_elim AS (
  SELECT id_partido, id_torneo
  FROM (
    SELECT id_partido, id_torneo FROM semi1_elim_upd
    UNION ALL
    SELECT id_partido, id_torneo FROM semi1_elim_ins
    UNION ALL
    SELECT p.id_partido, p.id_torneo
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim)
      AND p.ronda = 1
      AND p.orden_ronda = 1
  ) q
  LIMIT 1
),
semi2_elim_ins AS (
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, ronda, orden_ronda, id_partido_siguiente)
  SELECT (SELECT id_torneo FROM torneo_elim),
         TIMESTAMPTZ '2030-01-07 18:30:00+00',
         'DEMO_ELIM_SEMI_2',
         'planificado',
         1,
         2,
         (SELECT id_partido FROM final_elim)
  WHERE NOT EXISTS (
    SELECT 1
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim)
      AND p.ronda = 1
      AND p.orden_ronda = 2
  )
  RETURNING id_partido, id_torneo
),
semi2_elim_upd AS (
  UPDATE partido p
  SET fecha_hora = TIMESTAMPTZ '2030-01-07 18:30:00+00',
      lugar = 'DEMO_ELIM_SEMI_2',
      estado = 'planificado',
      ronda = 1,
      orden_ronda = 2,
      id_partido_siguiente = (SELECT id_partido FROM final_elim)
  WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim)
    AND p.ronda = 1
    AND p.orden_ronda = 2
  RETURNING id_partido, id_torneo
),
semi2_elim AS (
  SELECT id_partido, id_torneo
  FROM (
    SELECT id_partido, id_torneo FROM semi2_elim_upd
    UNION ALL
    SELECT id_partido, id_torneo FROM semi2_elim_ins
    UNION ALL
    SELECT p.id_partido, p.id_torneo
    FROM partido p
    WHERE p.id_torneo = (SELECT id_torneo FROM torneo_elim)
      AND p.ronda = 1
      AND p.orden_ronda = 2
  ) q
  LIMIT 1
),

-- Participación por partido (Semis): (A vs B) y (C vs D)
pp_semi1 AS (
  INSERT INTO participacion_partido (id_partido, id_participacion_equipo, punto)
  SELECT s.id_partido, pte.id_participacion_equipo, 0
  FROM semi1_elim s
  JOIN pte_elim_ref pte ON pte.id_torneo = s.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE e.nombre IN ('Demo A', 'Demo B')
    AND NOT EXISTS (
      SELECT 1
      FROM participacion_partido pp
      WHERE pp.id_partido = s.id_partido
        AND pp.id_participacion_equipo = pte.id_participacion_equipo
    )
  RETURNING id_participacion_partido
),
pp_semi2 AS (
  INSERT INTO participacion_partido (id_partido, id_participacion_equipo, punto)
  SELECT s.id_partido, pte.id_participacion_equipo, 0
  FROM semi2_elim s
  JOIN pte_elim_ref pte ON pte.id_torneo = s.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE e.nombre IN ('Demo C', 'Demo D')
    AND NOT EXISTS (
      SELECT 1
      FROM participacion_partido pp
      WHERE pp.id_partido = s.id_partido
        AND pp.id_participacion_equipo = pte.id_participacion_equipo
    )
  RETURNING id_participacion_partido
),

-- Final (demo): le asignamos 2 equipos para que el partido también tenga predicción.
pp_final AS (
  INSERT INTO participacion_partido (id_partido, id_participacion_equipo, punto)
  SELECT f.id_partido, pte.id_participacion_equipo, 0
  FROM final_elim f
  JOIN pte_elim_ref pte ON pte.id_torneo = f.id_torneo
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  WHERE e.nombre IN ('Demo A', 'Demo D')
    AND NOT EXISTS (
      SELECT 1
      FROM participacion_partido pp
      WHERE pp.id_partido = f.id_partido
        AND pp.id_participacion_equipo = pte.id_participacion_equipo
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
)

SELECT
  (SELECT id_torneo FROM torneo_liga) AS id_torneo_liga,
  (SELECT id_partido FROM partido_liga_1v1) AS id_partido_liga_1v1,
  (SELECT id_partido FROM partido_liga_multi) AS id_partido_liga_multi,
  (SELECT id_torneo FROM torneo_elim) AS id_torneo_eliminacion,
  (SELECT id_partido FROM semi1_elim) AS id_partido_elim_semi1,
  (SELECT id_partido FROM semi2_elim) AS id_partido_elim_semi2;

COMMIT;
