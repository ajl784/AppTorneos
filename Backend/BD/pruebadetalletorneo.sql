
-- =====================================================
-- Script de prueba: Detalle Torneo (Liga + Eliminación directa)
-- Asume BD "vacía" (o lo crea idempotente por ON CONFLICT).
-- NO inserta partidos: los generarás tú por endpoints.
-- =====================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------
-- Catálogos mínimos
-- -----------------------------

INSERT INTO tipo_torneo (nombre, descripcion)
VALUES
	('Liga', 'Todos contra todos. Clasificación por puntos.'),
	('Eliminación directa', 'Bracket: el perdedor queda eliminado')
ON CONFLICT (nombre)
DO UPDATE SET descripcion = EXCLUDED.descripcion;

INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion)
VALUES (
	'DT - Fútbol (2 equipos)',
	2,
	'Partidos entre 2 equipos. El árbitro registra el marcador.',
	'Categoría de prueba para detalle de torneo.'
)
ON CONFLICT (nombre)
DO UPDATE SET
	participantes_por_partida = EXCLUDED.participantes_por_partida,
	norma = EXCLUDED.norma,
	descripcion = EXCLUDED.descripcion;

INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
VALUES
	(
		(SELECT id_categoria FROM categoria WHERE nombre = 'DT - Fútbol (2 equipos)'),
		(SELECT id_tipo_torneo FROM tipo_torneo WHERE nombre = 'Liga')
	),
	(
		(SELECT id_categoria FROM categoria WHERE nombre = 'DT - Fútbol (2 equipos)'),
		(SELECT id_tipo_torneo FROM tipo_torneo WHERE nombre = 'Eliminación directa')
	)
ON CONFLICT (id_categoria, id_tipo_torneo)
DO NOTHING;

-- -----------------------------
-- Usuarios
-- -----------------------------

-- Organizador (mismo para ambos)
INSERT INTO usuario (correo, nombre_usuario, password_hash)
VALUES (
	'dt_org@demo.com',
	'DT Organizador',
	crypt('dt_org', gen_salt('bf'))
)
ON CONFLICT (correo)
DO UPDATE SET
	nombre_usuario = EXCLUDED.nombre_usuario,
	password_hash = EXCLUDED.password_hash;

-- Un usuario "para entrar" al torneo de Liga
INSERT INTO usuario (correo, nombre_usuario, password_hash)
VALUES (
	'dt_liga_user@demo.com',
	'DT Liga User',
	crypt('dt_liga_user', gen_salt('bf'))
)
ON CONFLICT (correo)
DO UPDATE SET
	nombre_usuario = EXCLUDED.nombre_usuario,
	password_hash = EXCLUDED.password_hash;

-- Un usuario "para entrar" al torneo de Eliminación directa
INSERT INTO usuario (correo, nombre_usuario, password_hash)
VALUES (
	'dt_elim_user@demo.com',
	'DT Eliminación User',
	crypt('dt_elim_user', gen_salt('bf'))
)
ON CONFLICT (correo)
DO UPDATE SET
	nombre_usuario = EXCLUDED.nombre_usuario,
	password_hash = EXCLUDED.password_hash;

-- Árbitros
INSERT INTO usuario (correo, nombre_usuario, password_hash)
VALUES
	(
		'dt_ref_liga@demo.com',
		'DT Árbitro Liga',
		crypt('dt_ref_liga', gen_salt('bf'))
	),
	(
		'dt_ref_elim@demo.com',
		'DT Árbitro Eliminación',
		crypt('dt_ref_elim', gen_salt('bf'))
	)
ON CONFLICT (correo)
DO UPDATE SET
	nombre_usuario = EXCLUDED.nombre_usuario,
	password_hash = EXCLUDED.password_hash;

-- -----------------------------
-- Equipos (Liga: 6, Eliminación: 8)
-- -----------------------------

INSERT INTO equipo (nombre, descripcion, elo)
VALUES
	('DT Liga - Equipo 01', 'Equipo de prueba (Liga)', 1200),
	('DT Liga - Equipo 02', 'Equipo de prueba (Liga)', 1200),
	('DT Liga - Equipo 03', 'Equipo de prueba (Liga)', 1200),
	('DT Liga - Equipo 04', 'Equipo de prueba (Liga)', 1200),
	('DT Liga - Equipo 05', 'Equipo de prueba (Liga)', 1200),
	('DT Liga - Equipo 06', 'Equipo de prueba (Liga)', 1200),

	('DT Elim - Equipo 01', 'Equipo de prueba (Eliminación directa)', 1200),
	('DT Elim - Equipo 02', 'Equipo de prueba (Eliminación directa)', 1200),
	('DT Elim - Equipo 03', 'Equipo de prueba (Eliminación directa)', 1200),
	('DT Elim - Equipo 04', 'Equipo de prueba (Eliminación directa)', 1200),
	('DT Elim - Equipo 05', 'Equipo de prueba (Eliminación directa)', 1200),
	('DT Elim - Equipo 06', 'Equipo de prueba (Eliminación directa)', 1200),
	('DT Elim - Equipo 07', 'Equipo de prueba (Eliminación directa)', 1200),
	('DT Elim - Equipo 08', 'Equipo de prueba (Eliminación directa)', 1200)
ON CONFLICT (nombre)
DO UPDATE SET
	descripcion = EXCLUDED.descripcion,
	elo = EXCLUDED.elo;

-- Vincula los usuarios de login a un equipo (uno por torneo)
INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio, fecha_fin)
VALUES
	(
		(SELECT id_usuario FROM usuario WHERE correo = 'dt_liga_user@demo.com'),
		(SELECT id_equipo FROM equipo WHERE nombre = 'DT Liga - Equipo 01'),
		DATE '2026-01-01',
		NULL
	),
	(
		(SELECT id_usuario FROM usuario WHERE correo = 'dt_elim_user@demo.com'),
		(SELECT id_equipo FROM equipo WHERE nombre = 'DT Elim - Equipo 01'),
		DATE '2026-01-01',
		NULL
	)
ON CONFLICT (id_usuario, id_equipo, fecha_inicio)
DO NOTHING;

-- -----------------------------
-- Torneos (ambos en curso)
-- -----------------------------

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
	encuesta,
	norma_puntuacion,
	preferencia_horario
)
VALUES (
	'DT - Liga (en_curso)',
	'Torneo liga de prueba. La clasificación debe empezar en 0 puntos.',
	NOW(),
	NULL,
	'en_curso',
	6,
	(SELECT id_categoria FROM categoria WHERE nombre = 'DT - Fútbol (2 equipos)'),
	(SELECT id_tipo_torneo FROM tipo_torneo WHERE nombre = 'Liga'),
	(SELECT id_usuario FROM usuario WHERE correo = 'dt_org@demo.com'),
	NULL,
	'3-1-0',
	'{"dias": ["lunes", "miercoles", "viernes"]}'::jsonb
)
ON CONFLICT (nombre, id_categoria, id_tipo_torneo)
DO UPDATE SET
	descripcion = EXCLUDED.descripcion,
	estado = EXCLUDED.estado,
	limite_equipos = EXCLUDED.limite_equipos,
	id_organizador = EXCLUDED.id_organizador,
	norma_puntuacion = EXCLUDED.norma_puntuacion,
	preferencia_horario = EXCLUDED.preferencia_horario;

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
	encuesta,
	norma_puntuacion,
	preferencia_horario
)
VALUES (
	'DT - Eliminación directa (en_curso)',
	'Torneo de eliminación directa de prueba. Sin partidos insertados.',
	NOW(),
	NULL,
	'en_curso',
	8,
	(SELECT id_categoria FROM categoria WHERE nombre = 'DT - Fútbol (2 equipos)'),
	(SELECT id_tipo_torneo FROM tipo_torneo WHERE nombre = 'Eliminación directa'),
	(SELECT id_usuario FROM usuario WHERE correo = 'dt_org@demo.com'),
	NULL,
	NULL,
	'{"dias": ["martes", "jueves"]}'::jsonb
)
ON CONFLICT (nombre, id_categoria, id_tipo_torneo)
DO UPDATE SET
	descripcion = EXCLUDED.descripcion,
	estado = EXCLUDED.estado,
	limite_equipos = EXCLUDED.limite_equipos,
	id_organizador = EXCLUDED.id_organizador,
	preferencia_horario = EXCLUDED.preferencia_horario;

-- -----------------------------
-- Árbitros asignados por torneo
-- -----------------------------

INSERT INTO arbitro_torneo (id_usuario, id_torneo)
VALUES
	(
		(SELECT id_usuario FROM usuario WHERE correo = 'dt_ref_liga@demo.com'),
		(SELECT id_torneo FROM torneo WHERE nombre = 'DT - Liga (en_curso)')
	),
	(
		(SELECT id_usuario FROM usuario WHERE correo = 'dt_ref_elim@demo.com'),
		(SELECT id_torneo FROM torneo WHERE nombre = 'DT - Eliminación directa (en_curso)')
	)
ON CONFLICT (id_usuario, id_torneo)
DO NOTHING;

-- -----------------------------
-- Inscripciones (sin puntos en clasificación)
-- -----------------------------

-- Liga: 6 equipos (puntuacion queda a 0)
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, puntuacion)
SELECT
	(SELECT id_torneo FROM torneo WHERE nombre = 'DT - Liga (en_curso)') AS id_torneo,
	e.id_equipo,
	'jugando' AS estado,
	0 AS puntuacion
FROM equipo e
WHERE e.nombre IN (
	'DT Liga - Equipo 01',
	'DT Liga - Equipo 02',
	'DT Liga - Equipo 03',
	'DT Liga - Equipo 04',
	'DT Liga - Equipo 05',
	'DT Liga - Equipo 06'
)
ON CONFLICT (id_torneo, id_equipo)
DO UPDATE SET
	estado = EXCLUDED.estado,
	puntuacion = EXCLUDED.puntuacion;

-- Eliminación directa: 8 equipos
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, puntuacion)
SELECT
	(SELECT id_torneo FROM torneo WHERE nombre = 'DT - Eliminación directa (en_curso)') AS id_torneo,
	e.id_equipo,
	'jugando' AS estado,
	0 AS puntuacion
FROM equipo e
WHERE e.nombre IN (
	'DT Elim - Equipo 01',
	'DT Elim - Equipo 02',
	'DT Elim - Equipo 03',
	'DT Elim - Equipo 04',
	'DT Elim - Equipo 05',
	'DT Elim - Equipo 06',
	'DT Elim - Equipo 07',
	'DT Elim - Equipo 08'
)
ON CONFLICT (id_torneo, id_equipo)
DO UPDATE SET
	estado = EXCLUDED.estado,
	puntuacion = EXCLUDED.puntuacion;

-- NOTA: no se crean registros en partido/participacion_partido/arbitro_partido.

COMMIT;

