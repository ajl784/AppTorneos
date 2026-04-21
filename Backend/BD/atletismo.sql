-- =====================================================
-- AppTorneos - Dataset para probar Estadísticas (DEV)
--
-- Crea un set para probar clasificación con “masa”:
-- - 1 usuario
-- - >= 30 equipos
-- - 1 torneo (1 categoría)
-- - SOLO el usuario pertenece a 1 equipo
-- - SOLO ese equipo tiene historial_elo
-- - El resto de equipos tienen ELO aleatorio
--
-- Idempotente: limpia SOLO recursos prefijados con STATS-/stats_
-- =====================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------
-- 0) Limpieza de dataset previo
-- ------------------------------
-- Ojo: borrar primero tablas hijas para evitar problemas de FK.
DELETE FROM participacion_torneo_equipo
WHERE id_torneo IN (SELECT id_torneo FROM torneo WHERE nombre LIKE 'STATS-%')
   OR id_equipo IN (SELECT id_equipo FROM equipo WHERE nombre LIKE 'STATS-%');

DELETE FROM historial_elo
WHERE id_equipo IN (
  SELECT id_equipo FROM equipo WHERE nombre LIKE 'STATS-%'
);

DELETE FROM torneo
WHERE nombre LIKE 'STATS-%';

DELETE FROM pertenece
WHERE id_usuario IN (
  SELECT id_usuario FROM usuario WHERE correo LIKE 'stats_%@app.com'
);

DELETE FROM equipo
WHERE nombre LIKE 'STATS-%';

DELETE FROM usuario
WHERE correo LIKE 'stats_%@app.com';

-- ------------------------------
-- 1) Catálogos mínimos (si faltan)
-- ------------------------------
INSERT INTO tipo_torneo (nombre, descripcion)
VALUES
  ('Liga', 'Todos contra todos'),
  ('Eliminación directa', 'Bracket')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion)
VALUES
  ('Fútbol 11', 2, 'Reglas estándar', 'Partidos 1 vs 1'),
  ('Baloncesto 5', 2, 'Reglas estándar', 'Partidos 1 vs 1'),
  ('Atletismo', 8, 'Clasificación por posicion/tiempo', 'Multi-participante')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
SELECT c.id_categoria, tt.id_tipo_torneo
FROM categoria c
JOIN tipo_torneo tt ON (
  (c.nombre IN ('Fútbol 11','Baloncesto 5','Atletismo') AND tt.nombre = 'Liga')
  OR (c.nombre IN ('Fútbol 11','Baloncesto 5') AND tt.nombre = 'Eliminación directa')
)
ON CONFLICT (id_categoria, id_tipo_torneo) DO NOTHING;

-- ------------------------------
-- 2) Usuario (1)
-- ------------------------------
INSERT INTO usuario (correo, nombre_usuario, password_hash)
VALUES ('stats_user@app.com', 'stats_user', crypt('password123', gen_salt('bf')))
ON CONFLICT (correo) DO NOTHING;

-- ------------------------------
-- 3) Equipos (>= 30)
-- ------------------------------
-- Un equipo "mío" (el único que pertenecerá al usuario)
INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
VALUES (
  'STATS-ME-Futbol',
  'Equipo del usuario (Fútbol)',
  1200,
  (SELECT id_categoria FROM categoria WHERE nombre = 'Fútbol 11')
)
ON CONFLICT (nombre) DO NOTHING;

-- Resto de equipos para clasificación (ELO aleatorio)
INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT
  'STATS-TEAM-' || LPAD(gs::text, 2, '0') AS nombre,
  'Equipo ranking #' || gs AS descripcion,
  (900 + (random() * 700))::int AS elo,
  (SELECT id_categoria FROM categoria WHERE nombre = 'Fútbol 11') AS id_categoria
FROM generate_series(1, 30) AS gs
ON CONFLICT (nombre) DO NOTHING;

-- ------------------------------
-- 4) Torneo (1) - 1 categoría
-- ------------------------------
WITH ids AS (
  SELECT
    (SELECT id_usuario FROM usuario WHERE correo = 'stats_user@app.com') AS org_id,
    (SELECT id_categoria FROM categoria WHERE nombre = 'Fútbol 11') AS cat_fut,
    (SELECT id_tipo_torneo FROM tipo_torneo WHERE nombre = 'Liga') AS tt_liga
)
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
  norma_puntuacion,
  preferencia_horario
)
VALUES (
  'STATS-FUT-Liga',
  'Torneo de prueba estadísticas (Fútbol 11 - Liga) con 30+ equipos',
  NOW() - INTERVAL '10 days',
  NOW() + INTERVAL '20 days',
  'en_curso',
  40,
  (SELECT cat_fut FROM ids),
  (SELECT tt_liga FROM ids),
  (SELECT org_id FROM ids),
  '3-1-0',
  '{"dias":["sabado"],"hora_inicio":"10:00"}'::jsonb
)
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- ------------------------------
-- 5) Participaciones (meter TODOS los equipos en el torneo)
-- ------------------------------
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT
  t.id_torneo,
  e.id_equipo,
  NOW(),
  'jugando',
  0
FROM torneo t
JOIN equipo e ON e.nombre = 'STATS-ME-Futbol'
   OR e.nombre LIKE 'STATS-TEAM-%'
WHERE t.nombre = 'STATS-FUT-Liga'
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- ------------------------------
-- 6) Pertenece (SOLO 1 usuario -> SOLO 1 equipo)
-- ------------------------------
INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio, fecha_fin)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE - 30, NULL
FROM usuario u
JOIN equipo e ON e.nombre = 'STATS-ME-Futbol'
WHERE u.correo = 'stats_user@app.com'
ON CONFLICT (id_usuario, id_equipo, fecha_inicio) DO NOTHING;

-- ------------------------------
-- 7) Historial de ELO (para gráficas)
-- ------------------------------
-- Nota: entradas "manuales" (no partido:*). Solo para el equipo del usuario.
WITH me AS (
  SELECT id_equipo
  FROM equipo
  WHERE nombre = 'STATS-ME-Futbol'
)
INSERT INTO historial_elo (id_equipo, elo_anterior, elo_nuevo, descripcion, creado_en)
SELECT
  (SELECT id_equipo FROM me),
  v.elo_anterior,
  v.elo_nuevo,
  v.descripcion,
  v.creado_en
FROM (
  VALUES
    (1200, 1188, 'stats:init', NOW() - INTERVAL '9 days'),
    (1188, 1215, 'stats:subida', NOW() - INTERVAL '6 days'),
    (1215, 1202, 'stats:ajuste', NOW() - INTERVAL '4 days'),
    (1202, 1240, 'stats:subida', NOW() - INTERVAL '2 days'),
    (1240, 1265, 'stats:subida', NOW() - INTERVAL '1 days')
) AS v(elo_anterior, elo_nuevo, descripcion, creado_en)
WHERE (SELECT id_equipo FROM me) IS NOT NULL;

COMMIT;

-- =====================================================
-- Cómo cargarlo (desde la raíz del repo):
--   docker exec -i app_postgres psql -U admin -d app_db < Backend/BD/script.sql
--
-- Usuarios para login:
--   stats_user@app.com / password123
-- =====================================================