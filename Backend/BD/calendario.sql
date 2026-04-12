-- =====================================================
-- AppTorneos - Dataset Calendario (DEV)
--
-- Inserta un set para probar la pestaña Calendario:
-- - 2 torneos: ambos de Liga
-- - Equipos para cada torneo
-- - 2 usuarios:
--   - Usuario A arbitra partidos del Torneo 01
--   - Usuario A juega como jugador (pertenece a un equipo) en el Torneo 02
--   - Usuario B pertenece a un equipo en el Torneo 01 (para poblar rivales)
--
-- Nota: NO crea partidos (se generarán automáticamente después).
-- Idempotente: limpia SOLO recursos prefijados con CAL- y correos cal_*
-- =====================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------
-- 0.5) Compatibilidad: árbitros por torneo
--
-- En algunos esquemas antiguos, arbitro_torneo era “global” (sin id_torneo)
-- y con UNIQUE(id_usuario). Para poder tener árbitros distintos por torneo,
-- añadimos id_torneo y cambiamos la unicidad a (id_usuario, id_torneo).
-- -----------------------------------------------------
DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM information_schema.columns
		WHERE table_schema = current_schema()
			AND table_name = 'arbitro_torneo'
			AND column_name = 'id_torneo'
	) THEN
		ALTER TABLE arbitro_torneo ADD COLUMN id_torneo BIGINT;
	END IF;

	-- Drop UNIQUE(id_usuario) si existe (nombre puede variar)
	IF EXISTS (
		SELECT 1
		FROM pg_constraint c
		JOIN pg_class t ON t.oid = c.conrelid
		WHERE t.relname = 'arbitro_torneo'
			AND c.contype = 'u'
			AND pg_get_constraintdef(c.oid) LIKE '%(id_usuario)%'
			AND pg_get_constraintdef(c.oid) NOT LIKE '%id_torneo%'
	) THEN
		EXECUTE (
			SELECT format('ALTER TABLE arbitro_torneo DROP CONSTRAINT %I', c.conname)
			FROM pg_constraint c
			JOIN pg_class t ON t.oid = c.conrelid
			WHERE t.relname = 'arbitro_torneo'
				AND c.contype = 'u'
				AND pg_get_constraintdef(c.oid) LIKE '%(id_usuario)%'
				AND pg_get_constraintdef(c.oid) NOT LIKE '%id_torneo%'
			LIMIT 1
		);
	END IF;

	-- FK a torneo si falta
	IF NOT EXISTS (
		SELECT 1
		FROM pg_constraint c
		JOIN pg_class t ON t.oid = c.conrelid
		WHERE t.relname = 'arbitro_torneo'
			AND c.contype = 'f'
			AND pg_get_constraintdef(c.oid) LIKE '%(id_torneo)%'
	) THEN
		ALTER TABLE arbitro_torneo
			ADD CONSTRAINT arbitro_torneo_id_torneo_fkey
			FOREIGN KEY (id_torneo) REFERENCES torneo(id_torneo) ON DELETE CASCADE;
	END IF;

	-- UNIQUE (id_usuario, id_torneo) si falta
	IF NOT EXISTS (
		SELECT 1
		FROM pg_constraint c
		JOIN pg_class t ON t.oid = c.conrelid
		WHERE t.relname = 'arbitro_torneo'
			AND c.contype = 'u'
			AND pg_get_constraintdef(c.oid) LIKE '%(id_usuario, id_torneo)%'
	) THEN
		ALTER TABLE arbitro_torneo
			ADD CONSTRAINT arbitro_torneo_usuario_torneo_key
			UNIQUE (id_usuario, id_torneo);
	END IF;
END $$;

-- ------------------------------
-- 0) Limpieza de dataset previo
-- ------------------------------
-- Borrar primero referencias hijas, aunque muchos FKs ya tienen CASCADE.
DELETE FROM historial_elo
WHERE id_equipo IN (SELECT id_equipo FROM equipo WHERE nombre LIKE 'CAL-%');

-- Eliminar torneos CAL- (cascada elimina partidos/participaciones/participacion_partido)
DELETE FROM torneo
WHERE nombre LIKE 'CAL-%';

-- Eliminar pertenencias (por si quedan equipos sin torneo)
DELETE FROM pertenece
WHERE id_usuario IN (SELECT id_usuario FROM usuario WHERE correo LIKE 'cal_%@app.com')
	 OR id_equipo IN (SELECT id_equipo FROM equipo WHERE nombre LIKE 'CAL-%');

-- Eliminar equipos y usuarios del dataset
DELETE FROM equipo
WHERE nombre LIKE 'CAL-%';

-- Eliminar árbitros del dataset (si quedan huérfanos por cambios de esquema)
DELETE FROM arbitro_torneo
WHERE id_usuario IN (SELECT id_usuario FROM usuario WHERE correo LIKE 'cal_%@app.com');

DELETE FROM usuario
WHERE correo LIKE 'cal_%@app.com';

-- ------------------------------
-- 1) Catálogos mínimos (si faltan)
-- ------------------------------
INSERT INTO tipo_torneo (nombre, descripcion)
VALUES
	('Liga', 'Todos contra todos')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion)
VALUES
	('Fútbol 11', 2, 'Reglas estándar', 'Partidos 1 vs 1')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
SELECT c.id_categoria, tt.id_tipo_torneo
FROM categoria c
JOIN tipo_torneo tt
	ON c.nombre = 'Fútbol 11'
 AND tt.nombre IN ('Liga')
ON CONFLICT (id_categoria, id_tipo_torneo) DO NOTHING;

-- ------------------------------
-- 2) Usuarios (2)
-- ------------------------------
INSERT INTO usuario (correo, nombre_usuario, password_hash)
VALUES
	('cal_user_a@app.com', 'cal_user_a', crypt('password123', gen_salt('bf'))),
	('cal_user_b@app.com', 'cal_user_b', crypt('password123', gen_salt('bf'))),
	('cal_ref_01@app.com', 'cal_ref_01', crypt('password123', gen_salt('bf'))),
	('cal_ref_02@app.com', 'cal_ref_02', crypt('password123', gen_salt('bf'))),
	('cal_ref_03@app.com', 'cal_ref_03', crypt('password123', gen_salt('bf'))),
	('cal_ref_04@app.com', 'cal_ref_04', crypt('password123', gen_salt('bf')))
ON CONFLICT (correo) DO NOTHING;

-- ------------------------------
-- 3) Torneos (2)
-- ------------------------------
WITH ids AS (
	SELECT
		(SELECT id_usuario FROM usuario WHERE correo = 'cal_user_a@app.com') AS org_a,
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
VALUES
	(
		'CAL-LIGA-01',
		'Calendario DEV - Liga 01 (usuario A arbitra)',
		NOW() - INTERVAL '3 days',
		NOW() + INTERVAL '40 days',
		'en_curso',
		16,
		(SELECT cat_fut FROM ids),
		(SELECT tt_liga FROM ids),
		(SELECT org_a FROM ids),
		'3-1-0',
		'{"dias":["sabado"],"hora_inicio":"10:00"}'::jsonb
	),
	(
		'CAL-LIGA-02',
		'Calendario DEV - Liga 02 (usuario A juega)',
		NOW() + INTERVAL '5 days',
		NOW() + INTERVAL '55 days',
		'en_curso',
		20,
		(SELECT cat_fut FROM ids),
		(SELECT tt_liga FROM ids),
		(SELECT org_a FROM ids),
		'3-1-0',
		'{"dias":["miercoles","viernes"],"hora_inicio":"18:00"}'::jsonb
	)
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- ------------------------------
-- 4) Equipos por torneo
-- ------------------------------
-- Liga 01 (6 equipos)
INSERT INTO equipo (nombre, descripcion, elo)
VALUES
	('CAL-L1-ALFA', 'Liga 01 - Equipo ALFA', 1200),
	('CAL-L1-BETA', 'Liga 01 - Equipo BETA', 1200),
	('CAL-L1-GAMMA', 'Liga 01 - Equipo GAMMA', 1200),
	('CAL-L1-DELTA', 'Liga 01 - Equipo DELTA', 1200),
	('CAL-L1-EPSILON', 'Liga 01 - Equipo EPSILON', 1200),
	('CAL-L1-ZETA', 'Liga 01 - Equipo ZETA', 1200)
ON CONFLICT (nombre) DO NOTHING;

-- Liga 02 (6 equipos)
INSERT INTO equipo (nombre, descripcion, elo)
VALUES
	('CAL-L2-ALFA', 'Liga 02 - Equipo ALFA', 1200),
	('CAL-L2-BETA', 'Liga 02 - Equipo BETA', 1200),
	('CAL-L2-GAMMA', 'Liga 02 - Equipo GAMMA', 1200),
	('CAL-L2-DELTA', 'Liga 02 - Equipo DELTA', 1200),
	('CAL-L2-EPSILON', 'Liga 02 - Equipo EPSILON', 1200),
	('CAL-L2-ZETA', 'Liga 02 - Equipo ZETA', 1200)
ON CONFLICT (nombre) DO NOTHING;

-- ------------------------------
-- 5) Inscripción/participación por torneo
-- ------------------------------
-- Liga 01: todos los equipos CAL-L1-*
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'jugando', 0
FROM torneo t
JOIN equipo e ON e.nombre LIKE 'CAL-L1-%'
WHERE t.nombre = 'CAL-LIGA-01'
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Liga 02: todos los equipos CAL-L2-*
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'jugando', 0
FROM torneo t
JOIN equipo e ON e.nombre LIKE 'CAL-L2-%'
WHERE t.nombre = 'CAL-LIGA-02'
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- ------------------------------
-- 6) Pertenece: 2 usuarios con distribución pedida
-- ------------------------------
-- Usuario A -> juega en Liga 02 (1 equipo)
INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio, fecha_fin)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE - 7, NULL
FROM usuario u
JOIN equipo e ON e.nombre = 'CAL-L2-ALFA'
WHERE u.correo = 'cal_user_a@app.com'
ON CONFLICT (id_usuario, id_equipo, fecha_inicio) DO NOTHING;

-- Usuario B -> juega en Liga 01 (1 equipo)
INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio, fecha_fin)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE - 12, NULL
FROM usuario u
JOIN equipo e ON e.nombre = 'CAL-L1-ALFA'
WHERE u.correo = 'cal_user_b@app.com'
ON CONFLICT (id_usuario, id_equipo, fecha_inicio) DO NOTHING;

-- ------------------------------
-- 7) Árbitro: usuario A (global) + asignación a partidos
-- ------------------------------
-- Liga 01: varios árbitros (incluye usuario A)
INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT u.id_usuario, t.id_torneo
FROM usuario u
JOIN torneo t ON t.nombre = 'CAL-LIGA-01'
WHERE u.correo IN (
	'cal_user_a@app.com',
	'cal_ref_01@app.com',
	'cal_ref_02@app.com'
)
ON CONFLICT (id_usuario, id_torneo) DO NOTHING;

-- Liga 02: árbitros distintos (no incluye usuario A)
INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT u.id_usuario, t.id_torneo
FROM usuario u
JOIN torneo t ON t.nombre = 'CAL-LIGA-02'
WHERE u.correo IN (
	'cal_ref_03@app.com',
	'cal_ref_04@app.com'
)
ON CONFLICT (id_usuario, id_torneo) DO NOTHING;

COMMIT;

-- =====================================================
-- Usuarios para login:
--   cal_user_a@app.com / password123
--   cal_user_b@app.com / password123
--
-- Cómo cargarlo (desde la raíz del repo):
--   docker exec -i app_postgres psql -U admin -d app_db < Backend/BD/calendario.sql
-- =====================================================

