-- =====================================================
-- AppTorneos - Dataset Atletismo (BD vacia)
--
-- Crea desde cero:
-- - Tipo de torneo: Eliminacion por serie
-- - Categoria: atletismo (8 participantes por partida)
-- - Relacion categoria_tipo_torneo
-- - 1 usuario organizador
-- - 1 arbitro
-- - 1 torneo de atletismo
-- =====================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------
-- Asegurar que el tipo de torneo exista
-- ------------------------------
INSERT INTO tipo_torneo (nombre, descripcion)
VALUES
  ('Eliminación por serie', 'Eliminacion multi por bloques de series y clasificacion por puntos')
ON CONFLICT (nombre) DO NOTHING;

-- ------------------------------
-- Nueva categoría: Atletismo
-- ------------------------------
INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion)
VALUES (
  'atletismo',
  8,
  'Carreras de atletismo con 8 participantes por serie',
  'Categoría para torneos de atletismo en formato de eliminación por serie'
)
ON CONFLICT (nombre) DO UPDATE
SET
  participantes_por_partida = EXCLUDED.participantes_por_partida,
  norma = EXCLUDED.norma,
  descripcion = EXCLUDED.descripcion;

INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
SELECT c.id_categoria, tt.id_tipo_torneo
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Eliminación por serie'
WHERE c.nombre = 'atletismo'
ON CONFLICT (id_categoria, id_tipo_torneo) DO NOTHING;

-- ------------------------------
-- Usuario organizador y árbitro
-- ------------------------------
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES (
  'atletismo_org@app.com',
  'atletismo_org',
  crypt('password123', gen_salt('bf')),
  'Organizador',
  'Atletismo'
)
ON CONFLICT (correo) DO NOTHING;

INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES (
  'atletismo_ref@app.com',
  'atletismo_ref',
  crypt('password123', gen_salt('bf')),
  'Árbitro',
  'Atletismo'
)
ON CONFLICT (correo) DO NOTHING;

-- ------------------------------
-- Equipos (32)
-- ------------------------------
INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT
  'ATLETISMO-TEAM-' || LPAD(gs::text, 2, '0') AS nombre,
  'Equipo Atletismo #' || gs AS descripcion,
  (1000 + (random() * 300))::int AS elo,
  (SELECT id_categoria FROM categoria WHERE nombre = 'atletismo')
FROM generate_series(1, 32) AS gs
ON CONFLICT (nombre) DO NOTHING;

-- ------------------------------
-- Torneo de atletismo
-- ------------------------------
WITH ids AS (
  SELECT
    (SELECT id_usuario FROM usuario WHERE correo = 'atletismo_org@app.com') AS org_id,
    (SELECT id_categoria FROM categoria WHERE nombre = 'atletismo') AS cat_atletismo,
    (SELECT id_tipo_torneo FROM tipo_torneo WHERE nombre = 'Eliminación por serie') AS tt_serie
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
  preferencia_horario,
  tipo_generacion_enfrentamientos
)
VALUES (
  'ATLETISMO-ELIM-SERIE-01',
  'Torneo de atletismo en formato eliminación por serie',
  NOW() + INTERVAL '1 day',
  NOW() + INTERVAL '30 days',
  'inscripcion_cerrada',
  32,
  (SELECT cat_atletismo FROM ids),
  (SELECT tt_serie FROM ids),
  (SELECT org_id FROM ids),
  'modo=posiciones;pos1=3;pos2=2;pos3=1;rondas_por_serie=2;clasifican_por_serie=3;criterio=desc',
  '{"dias":["sabado","domingo"],"hora_inicio":"09:00","hora_fin":"13:00"}'::jsonb,
  'balanceada'
)
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- ------------------------------
-- Árbitro del torneo
-- ------------------------------
INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT
  u.id_usuario,
  t.id_torneo
FROM usuario u
CROSS JOIN torneo t
WHERE u.correo = 'atletismo_ref@app.com'
  AND t.nombre = 'ATLETISMO-ELIM-SERIE-01'
ON CONFLICT (id_usuario, id_torneo) DO NOTHING;

-- ------------------------------
-- Inscripciones aceptadas
-- ------------------------------
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT
  t.id_torneo,
  e.id_equipo,
  NOW(),
  'jugando',
  0
FROM torneo t
JOIN equipo e ON e.nombre LIKE 'ATLETISMO-TEAM-%'
WHERE t.nombre = 'ATLETISMO-ELIM-SERIE-01'
ORDER BY e.id_equipo ASC
LIMIT 32
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

COMMIT;

-- =====================================================
-- Carga desde PowerShell (raiz del repo):
--   Get-Content Backend/BD/bdr -Raw | docker compose exec -T postgres psql -U admin -d app_db
--   Get-Content Backend/BD/atletismo.sql -Raw | docker compose exec -T postgres psql -U admin -d app_db
--
-- Usuario organizador:
--   atletismo_org@app.com / password123
-- =====================================================
