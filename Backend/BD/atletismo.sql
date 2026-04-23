-- =====================================================
-- AppTorneos - Dataset Parchis (BD vacia)
--
-- Crea desde cero:
-- - Tipo de torneo: Eliminacion por serie
-- - Categoria: parchis (4 participantes por partida)
-- - Relacion categoria_tipo_torneo
-- - 1 usuario organizador
-- - 1 arbitro
-- - 16 equipos
-- - 1 torneo de parchis
-- - equipos inscritos en estado jugando
-- - arbitros asociados al torneo
-- =====================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------
-- 1) Catalogos
-- ------------------------------
INSERT INTO tipo_torneo (nombre, descripcion)
VALUES
  ('Eliminación por serie', 'Eliminacion multi por bloques de series y clasificacion por puntos')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion)
VALUES (
  'parchis',
  4,
  'Partidas de 4 con puntuacion por posicion',
  'Categoria multijugador para eliminacion por serie'
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
WHERE c.nombre = 'parchis'
ON CONFLICT (id_categoria, id_tipo_torneo) DO NOTHING;

-- ------------------------------
-- 2) Usuarios
-- ------------------------------
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES (
  'parchis_org@app.com',
  'parchis_org',
  crypt('password123', gen_salt('bf')),
  'Organizador',
  'Parchis'
)
ON CONFLICT (correo) DO NOTHING;

INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
  (
    'parchis_ref_01@app.com',
    'parchis_ref_01',
    crypt('password123', gen_salt('bf')),
    'Arbitro 1',
    'Parchis'
  )
ON CONFLICT (correo) DO NOTHING;

-- ------------------------------
-- 3) Equipos (16)
-- ------------------------------
INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT
  'PARCHIS-TEAM-' || LPAD(gs::text, 2, '0') AS nombre,
  'Equipo Parchis #' || gs AS descripcion,
  (1000 + (random() * 300))::int AS elo,
  (SELECT id_categoria FROM categoria WHERE nombre = 'parchis')
FROM generate_series(1, 16) AS gs
ON CONFLICT (nombre) DO NOTHING;

-- ------------------------------
-- 4) Torneo
-- ------------------------------
WITH ids AS (
  SELECT
    (SELECT id_usuario FROM usuario WHERE correo = 'parchis_org@app.com') AS org_id,
    (SELECT id_categoria FROM categoria WHERE nombre = 'parchis') AS cat_parchis,
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
  'PARCHIS-ELIM-SERIE-01',
  'Torneo de parchis en formato eliminacion por serie',
  NOW() + INTERVAL '2 days',
  NOW() + INTERVAL '35 days',
  'inscripcion_cerrada',
  16,
  (SELECT cat_parchis FROM ids),
  (SELECT tt_serie FROM ids),
  (SELECT org_id FROM ids),
  'modo=posiciones;pos1=4;pos2=2;pos3=1;pos4=0;rondas_por_serie=3;clasifican_por_serie=2;criterio=desc',
  '{"dias":["sabado","domingo"],"hora_inicio":"10:00","hora_fin":"14:00"}'::jsonb,
  'balanceada'
)
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- ------------------------------
-- 5) Inscripciones aceptadas
-- ------------------------------
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT
  t.id_torneo,
  e.id_equipo,
  NOW(),
  'jugando',
  0
FROM torneo t
JOIN equipo e ON e.nombre LIKE 'PARCHIS-TEAM-%'
WHERE t.nombre = 'PARCHIS-ELIM-SERIE-01'
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- ------------------------------
-- 6) Arbitros del torneo
-- ------------------------------
INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT
  u.id_usuario,
  t.id_torneo
FROM usuario u
CROSS JOIN torneo t
WHERE u.correo = 'parchis_ref_01@app.com'
  AND t.nombre = 'PARCHIS-ELIM-SERIE-01'
ON CONFLICT (id_usuario, id_torneo) DO NOTHING;

COMMIT;

-- =====================================================
-- Carga desde PowerShell (raiz del repo):
--   Get-Content Backend/BD/bdr -Raw | docker compose exec -T postgres psql -U admin -d app_db
--   Get-Content Backend/BD/atletismo.sql -Raw | docker compose exec -T postgres psql -U admin -d app_db
--
-- Usuario organizador:
--   parchis_org@app.com / password123
-- =====================================================
