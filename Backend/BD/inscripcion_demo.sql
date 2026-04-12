-- =====================================================
-- AppTorneos - Dataset Inscripción Abierta (DEV)
--
-- Crea:
-- - 1 usuario organizador (distinto)
-- - 2 torneos en estado 'inscripcion_abierta':
--     * 1 de Liga
--     * 1 de Eliminación directa
-- - Varios equipos inscritos en cada torneo (participacion_torneo_equipo)
-- - NO crea partidos
--
-- Idempotente: limpia SOLO recursos prefijados con INS- y correos ins_*
-- =====================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------
-- 0) Limpieza (solo dataset INS-)
-- ------------------------------
DELETE FROM historial_elo
WHERE id_equipo IN (SELECT id_equipo FROM equipo WHERE nombre LIKE 'INS-%');

-- Borra torneos INS- (CASCADE elimina participaciones y cualquier hijo)
DELETE FROM torneo
WHERE nombre LIKE 'INS-%';

-- Pertenencias/roles por si existieran en tu entorno
DELETE FROM entrenador_equipo
WHERE id_usuario IN (SELECT id_usuario FROM usuario WHERE correo LIKE 'ins_%@app.com')
   OR id_equipo IN (SELECT id_equipo FROM equipo WHERE nombre LIKE 'INS-%');

DELETE FROM pertenece
WHERE id_usuario IN (SELECT id_usuario FROM usuario WHERE correo LIKE 'ins_%@app.com')
   OR id_equipo IN (SELECT id_equipo FROM equipo WHERE nombre LIKE 'INS-%');

DELETE FROM arbitro_torneo
WHERE id_usuario IN (SELECT id_usuario FROM usuario WHERE correo LIKE 'ins_%@app.com');

DELETE FROM equipo
WHERE nombre LIKE 'INS-%';

DELETE FROM usuario
WHERE correo LIKE 'ins_%@app.com';

-- ------------------------------
-- 1) Catálogos mínimos
-- ------------------------------
INSERT INTO tipo_torneo (nombre, descripcion)
VALUES
	('Liga', 'Todos contra todos'),
	('Eliminación directa', 'Bracket eliminatorio')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion)
VALUES
	('Fútbol 11', 2, 'Reglas estándar', 'Partidos 1 vs 1')
ON CONFLICT (nombre) DO NOTHING;

-- Vincular categoría con ambos tipos de torneo (requisito por FK compuesta en torneo)
INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
SELECT c.id_categoria, tt.id_tipo_torneo
FROM categoria c
JOIN tipo_torneo tt
	ON c.nombre = 'Fútbol 11'
	AND tt.nombre IN ('Liga', 'Eliminación directa')
ON CONFLICT (id_categoria, id_tipo_torneo) DO NOTHING;

-- ------------------------------
-- 2) Usuario organizador (distinto)
-- ------------------------------
INSERT INTO usuario (
	correo,
	nombre_usuario,
	password_hash,
	nombre,
	apellidos,
	fotoperfil,
	fechanacimiento,
	genero
)
VALUES
	('ins_org@app.com', 'ins_org', crypt('password123', gen_salt('bf')), 'Inés', 'Organizadora', NULL, DATE '1994-05-11', 'F')
ON CONFLICT (correo) DO NOTHING;

-- ------------------------------
-- 2.1) Árbitros (usuarios) - 2 por torneo
-- ------------------------------
INSERT INTO usuario (
	correo,
	nombre_usuario,
	password_hash,
	nombre,
	apellidos,
	fotoperfil,
	fechanacimiento,
	genero
)
VALUES
	('ins_ref_liga_01@app.com', 'ins_ref_liga_01', crypt('password123', gen_salt('bf')), 'Raúl', 'Árbitro Liga 01', NULL, DATE '1988-02-03', 'M'),
	('ins_ref_liga_02@app.com', 'ins_ref_liga_02', crypt('password123', gen_salt('bf')), 'Lucía', 'Árbitro Liga 01', NULL, DATE '1991-09-22', 'F'),
	('ins_ref_elim_01@app.com', 'ins_ref_elim_01', crypt('password123', gen_salt('bf')), 'Sergio', 'Árbitro Elim 01', NULL, DATE '1986-11-15', 'M'),
	('ins_ref_elim_02@app.com', 'ins_ref_elim_02', crypt('password123', gen_salt('bf')), 'Nora', 'Árbitro Elim 01', NULL, DATE '1993-07-08', 'F')
ON CONFLICT (correo) DO NOTHING;

-- ------------------------------
-- 3) Torneos (2) - inscripción abierta
-- ------------------------------
WITH ids AS (
	SELECT
		(SELECT id_usuario FROM usuario WHERE correo = 'ins_org@app.com') AS org_id,
		(SELECT id_categoria FROM categoria WHERE nombre = 'Fútbol 11') AS cat_id,
		(SELECT id_tipo_torneo FROM tipo_torneo WHERE nombre = 'Liga') AS tt_liga,
		(SELECT id_tipo_torneo FROM tipo_torneo WHERE nombre = 'Eliminación directa') AS tt_elim
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
VALUES
	(
		'INS-LIGA-01',
		'DEV - Liga en inscripción abierta',
		NOW() + INTERVAL '7 days',
		NOW() + INTERVAL '40 days',
		'inscripcion_abierta',
		12,
		(SELECT cat_id FROM ids),
		(SELECT tt_liga FROM ids),
		(SELECT org_id FROM ids),
		'3-1-0',
		'{"dias":["sabado"],"hora_inicio":"10:00"}'::jsonb
	),
	(
		'INS-ELIM-01',
		'DEV - Eliminación directa en inscripción abierta',
		NOW() + INTERVAL '10 days',
		NOW() + INTERVAL '25 days',
		'inscripcion_abierta',
		16,
		(SELECT cat_id FROM ids),
		(SELECT tt_elim FROM ids),
		(SELECT org_id FROM ids),
		'1-0',
		'{"dias":["miercoles","viernes"],"hora_inicio":"18:30"}'::jsonb
	)
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- ------------------------------
-- 4) Equipos (varios)
-- ------------------------------
INSERT INTO equipo (nombre, descripcion, elo)
VALUES
	('INS-L1-ALFA', 'Liga 01 - Equipo ALFA', 1200),
	('INS-L1-BETA', 'Liga 01 - Equipo BETA', 1200),
	('INS-L1-GAMMA', 'Liga 01 - Equipo GAMMA', 1200),
	('INS-L1-DELTA', 'Liga 01 - Equipo DELTA', 1200),
	('INS-L1-EPSILON', 'Liga 01 - Equipo EPSILON', 1200),
	('INS-L1-ZETA', 'Liga 01 - Equipo ZETA', 1200)
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO equipo (nombre, descripcion, elo)
VALUES
	('INS-E1-ALFA', 'Elim 01 - Equipo ALFA', 1200),
	('INS-E1-BETA', 'Elim 01 - Equipo BETA', 1200),
	('INS-E1-GAMMA', 'Elim 01 - Equipo GAMMA', 1200),
	('INS-E1-DELTA', 'Elim 01 - Equipo DELTA', 1200),
	('INS-E1-EPSILON', 'Elim 01 - Equipo EPSILON', 1200),
	('INS-E1-ZETA', 'Elim 01 - Equipo ZETA', 1200),
	('INS-E1-ETA', 'Elim 01 - Equipo ETA', 1200),
	('INS-E1-THETA', 'Elim 01 - Equipo THETA', 1200)
ON CONFLICT (nombre) DO NOTHING;

-- ------------------------------
-- 5) Participaciones (inscripción) - sin partidos
-- ------------------------------
-- Liga: inscribir INS-L1-*
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'pendiente', 0
FROM torneo t
JOIN equipo e ON e.nombre LIKE 'INS-L1-%'
WHERE t.nombre = 'INS-LIGA-01'
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Eliminación directa: inscribir INS-E1-*
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'pendiente', 0
FROM torneo t
JOIN equipo e ON e.nombre LIKE 'INS-E1-%'
WHERE t.nombre = 'INS-ELIM-01'
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- ------------------------------
-- 6) Árbitros por torneo
-- ------------------------------
INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT u.id_usuario, t.id_torneo
FROM usuario u
JOIN torneo t ON t.nombre = 'INS-LIGA-01'
WHERE u.correo IN ('ins_ref_liga_01@app.com', 'ins_ref_liga_02@app.com')
ON CONFLICT (id_usuario, id_torneo) DO NOTHING;

INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT u.id_usuario, t.id_torneo
FROM usuario u
JOIN torneo t ON t.nombre = 'INS-ELIM-01'
WHERE u.correo IN ('ins_ref_elim_01@app.com', 'ins_ref_elim_02@app.com')
ON CONFLICT (id_usuario, id_torneo) DO NOTHING;

COMMIT;

-- =====================================================
-- Login organizador:
--   ins_org@app.com / password123
--
-- Cómo cargarlo (desde la raíz del repo):
--   docker exec -i app_postgres psql -U admin -d app_db < Backend/BD/inscripcion_demo.sql
-- =====================================================
