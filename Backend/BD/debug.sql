-- =====================================================
-- Debug: Torneo "xd" con equipos y árbitros
-- =====================================================

BEGIN;

-- ------------------------------
-- 1) Equipos para el torneo "xd"
-- ------------------------------
INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT
  'XD-TEAM-' || LPAD(gs::text, 2, '0') AS nombre,
  'Equipo XD #' || gs AS descripcion,
  (1000 + (random() * 300))::int AS elo,
  (SELECT id_categoria FROM categoria WHERE nombre = 'atletismo')
FROM generate_series(1, 32) AS gs
ON CONFLICT (nombre) DO NOTHING;

-- ------------------------------
-- 2) Inscripciones aceptadas para el torneo "xd"
-- ------------------------------
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT
  t.id_torneo,
  e.id_equipo,
  NOW(),
  'jugando',
  0
FROM torneo t
JOIN equipo e ON e.nombre LIKE 'XD-TEAM-%'
WHERE t.nombre = 'xd'
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- ------------------------------
-- 3) Árbitros para el torneo "xd" (corrección)
-- ------------------------------
-- Crear usuarios árbitros si no existen
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
  ('arbitro1@xd.com', 'arbitro1', crypt('password123', gen_salt('bf')), 'Árbitro', 'Uno'),
  ('arbitro2@xd.com', 'arbitro2', crypt('password123', gen_salt('bf')), 'Árbitro', 'Dos'),
  ('arbitro3@xd.com', 'arbitro3', crypt('password123', gen_salt('bf')), 'Árbitro', 'Tres')
ON CONFLICT (correo) DO NOTHING;

-- Asociar árbitros al torneo "xd"
INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT
  u.id_usuario,
  t.id_torneo
FROM usuario u
CROSS JOIN torneo t
WHERE t.nombre = 'xd'
  AND u.correo IN ('arbitro1@xd.com', 'arbitro2@xd.com', 'arbitro3@xd.com')
ON CONFLICT (id_usuario, id_torneo) DO NOTHING;

COMMIT;