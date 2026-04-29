-- =====================================================
-- AppTorneos - Dataset Atletismo y Basket (BD vacía)
--
-- Crea desde cero:
-- - Categorías: Atletismo (8 participantes por partida) y Basket (2 participantes por partida)
-- - Relación categoria_tipo_torneo
-- - Usuarios organizadores y árbitros
-- - Equipos para cada categoría
-- =====================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------
-- 1) Catálogos
-- ------------------------------
INSERT INTO tipo_torneo (nombre, descripcion)
VALUES
  ('Eliminación por serie', 'Eliminación multi por bloques de series y clasificación por puntos')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion)
VALUES
  ('atletismo', 8, 'Competencias de atletismo con 8 participantes por partida', 'Categoría para torneos de atletismo'),
  ('basket', 2, 'Partidos de 1 contra 1', 'Categoría para torneos de basket')
ON CONFLICT (nombre) DO UPDATE
SET
  participantes_por_partida = EXCLUDED.participantes_por_partida,
  norma = EXCLUDED.norma,
  descripcion = EXCLUDED.descripcion;

INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
SELECT c.id_categoria, tt.id_tipo_torneo
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Eliminación por serie'
WHERE c.nombre IN ('atletismo', 'basket')
ON CONFLICT (id_categoria, id_tipo_torneo) DO NOTHING;

-- ------------------------------
-- 2) Usuarios
-- ------------------------------
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
  ('atletismo_org@app.com', 'atletismo_org', crypt('password123', gen_salt('bf')), 'Organizador', 'Atletismo'),
  ('basket_org@app.com', 'basket_org', crypt('password123', gen_salt('bf')), 'Organizador', 'Basket'),
  ('atletismo_ref@app.com', 'atletismo_ref', crypt('password123', gen_salt('bf')), 'Árbitro', 'Atletismo'),
  ('basket_ref@app.com', 'basket_ref', crypt('password123', gen_salt('bf')), 'Árbitro', 'Basket')
ON CONFLICT (correo) DO NOTHING;

-- ------------------------------
-- 3) Equipos
-- ------------------------------
INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT
  'ATLETISMO-TEAM-' || LPAD(gs::text, 2, '0') AS nombre,
  'Equipo Atletismo #' || gs AS descripcion,
  (1000 + (random() * 300))::int AS elo,
  (SELECT id_categoria FROM categoria WHERE nombre = 'atletismo')
FROM generate_series(1, 16) AS gs
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT
  'BASKET-TEAM-' || LPAD(gs::text, 2, '0') AS nombre,
  'Equipo Basket #' || gs AS descripcion,
  (1000 + (random() * 300))::int AS elo,
  (SELECT id_categoria FROM categoria WHERE nombre = 'basket')
FROM generate_series(1, 8) AS gs
ON CONFLICT (nombre) DO NOTHING;

-- ------------------------------
-- 4) Torneos
-- ------------------------------
WITH ids AS (
  SELECT
    (SELECT id_usuario FROM usuario WHERE correo = 'atletismo_org@app.com') AS org_atletismo,
    (SELECT id_usuario FROM usuario WHERE correo = 'basket_org@app.com') AS org_basket,
    (SELECT id_categoria FROM categoria WHERE nombre = 'atletismo') AS cat_atletismo,
    (SELECT id_categoria FROM categoria WHERE nombre = 'basket') AS cat_basket,
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
VALUES
  ('ATLETISMO-ELIM-SERIE-01', 'Torneo de atletismo en formato eliminación por serie', NOW() + INTERVAL '2 days', NOW() + INTERVAL '35 days', 'inscripcion_cerrada', 16, (SELECT cat_atletismo FROM ids), (SELECT tt_serie FROM ids), (SELECT org_atletismo FROM ids), 'modo=posiciones;pos1=8;pos2=4;criterio=desc', '{"dias":["sabado","domingo"],"hora_inicio":"09:00","hora_fin":"13:00"}'::jsonb, 'balanceada'),
  ('BASKET-ELIM-SERIE-01', 'Torneo de basket en formato eliminación por serie', NOW() + INTERVAL '3 days', NOW() + INTERVAL '30 days', 'inscripcion_cerrada', 8, (SELECT cat_basket FROM ids), (SELECT tt_serie FROM ids), (SELECT org_basket FROM ids), 'modo=posiciones;pos1=2;criterio=desc', '{"dias":["sabado","domingo"],"hora_inicio":"10:00","hora_fin":"14:00"}'::jsonb, 'rotacion')
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
JOIN equipo e ON e.nombre LIKE 'ATLETISMO-TEAM-%'
WHERE t.nombre = 'ATLETISMO-ELIM-SERIE-01'
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT
  t.id_torneo,
  e.id_equipo,
  NOW(),
  'jugando',
  0
FROM torneo t
JOIN equipo e ON e.nombre LIKE 'BASKET-TEAM-%'
WHERE t.nombre = 'BASKET-ELIM-SERIE-01'
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- ------------------------------
-- 6) Árbitros del torneo
-- ------------------------------
INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT
  u.id_usuario,
  t.id_torneo
FROM usuario u
CROSS JOIN torneo t
WHERE (u.correo = 'atletismo_ref@app.com' AND t.nombre = 'ATLETISMO-ELIM-SERIE-01')
   OR (u.correo = 'basket_ref@app.com' AND t.nombre = 'BASKET-ELIM-SERIE-01')
ON CONFLICT (id_usuario, id_torneo) DO NOTHING;

COMMIT;
