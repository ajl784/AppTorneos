-- =====================================================
-- AppTorneos - Dataset Atletismo (DEV)
--
-- Crea un escenario de liga multi:
-- - Categoria Atletismo (8 participantes por partido)
-- - 1 torneo de atletismo (Liga)
-- - 35 equipos inscritos/aceptados (estado = jugando)
-- - 1 usuario organizador
-- - arbitros asociados al torneo
--
-- Idempotente: limpia solo recursos ATL-
-- =====================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------
-- 0) Limpieza del dataset ATL
-- ------------------------------
DELETE FROM participacion_torneo_equipo
WHERE id_torneo IN (SELECT id_torneo FROM torneo WHERE nombre LIKE 'ATL-%')
   OR id_equipo IN (SELECT id_equipo FROM equipo WHERE nombre LIKE 'ATL-%');

DELETE FROM arbitro_torneo
WHERE id_torneo IN (SELECT id_torneo FROM torneo WHERE nombre LIKE 'ATL-%')
   OR id_usuario IN (
     SELECT id_usuario FROM usuario WHERE correo LIKE 'atl_%@app.com'
   );

DELETE FROM historial_elo
WHERE id_equipo IN (
  SELECT id_equipo FROM equipo WHERE nombre LIKE 'ATL-%'
);

DELETE FROM torneo
WHERE nombre LIKE 'ATL-%';

DELETE FROM pertenece
WHERE id_usuario IN (
  SELECT id_usuario FROM usuario WHERE correo LIKE 'atl_%@app.com'
)
   OR id_equipo IN (
     SELECT id_equipo FROM equipo WHERE nombre LIKE 'ATL-%'
   );

DELETE FROM solicitud_equipo
WHERE id_usuario IN (
  SELECT id_usuario FROM usuario WHERE correo LIKE 'atl_%@app.com'
)
   OR id_equipo IN (
     SELECT id_equipo FROM equipo WHERE nombre LIKE 'ATL-%'
   );

DELETE FROM equipo
WHERE nombre LIKE 'ATL-%';

DELETE FROM usuario
WHERE correo LIKE 'atl_%@app.com';

-- ------------------------------
-- 1) Catalogos necesarios
-- ------------------------------
INSERT INTO tipo_torneo (nombre, descripcion)
VALUES ('Liga', 'Todos contra todos')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion)
VALUES (
  'Atletismo',
  8,
  'Series de 8 y puntuacion por posicion',
  'Competicion multi-participante por posiciones'
)
ON CONFLICT (nombre) DO UPDATE
SET
  participantes_por_partida = EXCLUDED.participantes_por_partida,
  norma = EXCLUDED.norma,
  descripcion = EXCLUDED.descripcion;

INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
SELECT c.id_categoria, tt.id_tipo_torneo
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Liga'
WHERE c.nombre = 'Atletismo'
ON CONFLICT (id_categoria, id_tipo_torneo) DO NOTHING;

-- ------------------------------
-- 2) Usuario organizador
-- ------------------------------
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES (
  'atl_org@app.com',
  'atl_org',
  crypt('password123', gen_salt('bf')),
  'Organizador',
  'Atletismo'
)
ON CONFLICT (correo) DO NOTHING;

-- ------------------------------
-- 3) Usuarios arbitros
-- ------------------------------
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
  (
    'atl_ref_01@app.com',
    'atl_ref_01',
    crypt('password123', gen_salt('bf')),
    'Arbitro 1',
    'Atletismo'
  ),
  (
    'atl_ref_02@app.com',
    'atl_ref_02',
    crypt('password123', gen_salt('bf')),
    'Arbitro 2',
    'Atletismo'
  ),
  (
    'atl_ref_03@app.com',
    'atl_ref_03',
    crypt('password123', gen_salt('bf')),
    'Arbitro 3',
    'Atletismo'
  ),
  (
    'atl_ref_04@app.com',
    'atl_ref_04',
    crypt('password123', gen_salt('bf')),
    'Arbitro 4',
    'Atletismo'
  )
ON CONFLICT (correo) DO NOTHING;

-- ------------------------------
-- 4) Equipos (35)
-- ------------------------------
INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT
  'ATL-TEAM-' || LPAD(gs::text, 2, '0') AS nombre,
  'Equipo Atletismo #' || gs AS descripcion,
  (950 + (random() * 450))::int AS elo,
  (SELECT id_categoria FROM categoria WHERE nombre = 'Atletismo')
FROM generate_series(1, 35) AS gs
ON CONFLICT (nombre) DO NOTHING;

-- ------------------------------
-- 5) Torneo Atletismo (Liga, 8 por serie)
-- ------------------------------
WITH ids AS (
  SELECT
    (SELECT id_usuario FROM usuario WHERE correo = 'atl_org@app.com') AS org_id,
    (SELECT id_categoria FROM categoria WHERE nombre = 'Atletismo') AS cat_atl,
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
  preferencia_horario,
  tipo_generacion_enfrentamientos
)
VALUES (
  'ATL-LIGA-8P',
  'Liga de Atletismo con series de 8 participantes',
  NOW() - INTERVAL '5 days',
  NOW() + INTERVAL '45 days',
  'en_curso',
  40,
  (SELECT cat_atl FROM ids),
  (SELECT tt_liga FROM ids),
  (SELECT org_id FROM ids),
  'modo=posiciones;pos1=12;pos2=9;pos3=7;pos4=5;pos5=4;pos6=3;pos7=2;pos8=1;estrategia_multi=balanceada;jornadas_multi=12',
  '{"dias":["sabado","domingo"],"hora_inicio":"09:00","hora_fin":"14:00"}'::jsonb,
  'balanceada'
)
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- ------------------------------
-- 6) Inscripciones aceptadas (estado = jugando)
-- ------------------------------
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT
  t.id_torneo,
  e.id_equipo,
  NOW(),
  'jugando',
  0
FROM torneo t
JOIN equipo e ON e.nombre LIKE 'ATL-TEAM-%'
WHERE t.nombre = 'ATL-LIGA-8P'
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- ------------------------------
-- 7) Asignacion de arbitros al torneo
-- ------------------------------
INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT
  u.id_usuario,
  t.id_torneo
FROM usuario u
CROSS JOIN torneo t
WHERE u.correo IN (
  'atl_ref_01@app.com',
  'atl_ref_02@app.com',
  'atl_ref_03@app.com',
  'atl_ref_04@app.com'
)
  AND t.nombre = 'ATL-LIGA-8P'
ON CONFLICT (id_usuario, id_torneo) DO NOTHING;

COMMIT;

-- =====================================================
-- Carga desde PowerShell (raiz del repo):
--   Get-Content Backend/BD/bdr -Raw | docker compose exec -T postgres psql -U admin -d app_db
--   Get-Content Backend/BD/atletismo.sql -Raw | docker compose exec -T postgres psql -U admin -d app_db
--
-- Usuario organizador:
--   atl_org@app.com / password123
-- =====================================================