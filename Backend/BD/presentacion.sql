-- =====================================================
-- AppTorneos - Datos de presentación (sin partidos)
-- Fecha: 2026-04-13
--
-- Objetivo:
-- - Vaciar tablas (por si hay datos)
-- - Crear catálogos, 1 admin, jugadores, árbitros
-- - Crear 2 torneos: 1 Liga y 1 Eliminación
-- - Torneos en estado: inscripcion_abierta
-- - Inscripciones (participacion_torneo_equipo):
--   - Torneo Liga: estado 'jugando'
--   - Torneo Eliminación: estado 'jugando'
-- - NO insertar partidos
-- - Insertar historial_elo para equipos donde están los usuarios de demo
-- =====================================================

BEGIN;

-- Necesario para gen_salt/crypt usados por el login
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------
-- 1) Limpiar datos existentes
-- -----------------------------
-- Nota: en algunos entornos la BD puede no tener todas las tablas
-- (por ejemplo, si el volumen ya existía y el esquema cambió).
-- Este bloque arma un TRUNCATE con solo las tablas que EXISTEN.
DO $$
DECLARE
	tbl text;
	tables_to_try text[] := ARRAY[
		'arbitro_partido',
		'participacion_partido',
		'partido',
		'arbitro_torneo',
		'participacion_torneo_equipo',
		'torneo',
		'solicitud_equipo',
		'entrenador_equipo',
		'pertenece',
		'historial_elo',
		'equipo',
		'categoria_tipo_torneo',
		'categoria',
		'tipo_torneo',
		'usuario'
	];
	existing_tables text[] := ARRAY[]::text[];
	sql text;
BEGIN
	FOREACH tbl IN ARRAY tables_to_try LOOP
		IF to_regclass('public.' || tbl) IS NOT NULL THEN
			existing_tables := array_append(existing_tables, quote_ident(tbl));
		END IF;
	END LOOP;

	IF array_length(existing_tables, 1) IS NOT NULL THEN
		sql :=
			'TRUNCATE TABLE ' || array_to_string(existing_tables, ', ') ||
			' RESTART IDENTITY CASCADE';
		EXECUTE sql;
	END IF;
END $$;

-- -----------------------------
-- 1b) Compatibilidad (volumen antiguo)
-- -----------------------------
-- En algunos entornos, el volumen ya existía cuando el esquema aún no incluía
-- `equipo.id_categoria`. Como acabamos de TRUNCATE, podemos añadir la columna
-- y la FK de forma segura.
DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM information_schema.columns
		WHERE table_schema = 'public'
		  AND table_name = 'equipo'
		  AND column_name = 'id_categoria'
	) THEN
		ALTER TABLE equipo ADD COLUMN id_categoria BIGINT;
		ALTER TABLE equipo
			ADD CONSTRAINT equipo_id_categoria_fkey
			FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria);
		ALTER TABLE equipo ALTER COLUMN id_categoria SET NOT NULL;
	END IF;
END $$;

-- -----------------------------
-- 2) Catálogos
-- -----------------------------
INSERT INTO tipo_torneo (nombre, descripcion)
VALUES
	('Liga', 'Todos contra todos (clasificación por puntos)'),
	('Eliminación directa', 'Bracket de eliminación (directa o variantes)');

INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion)
VALUES
	('Fútbol 7', 2, NULL, 'Categoría demo para la presentación');

-- Vincular la categoría con ambos tipos
INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
SELECT c.id_categoria, tt.id_tipo_torneo
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre IN ('Liga', 'Eliminación directa')
WHERE c.nombre = 'Fútbol 7';

-- -----------------------------
-- 3) Usuarios (admin, árbitros, jugadores)
-- -----------------------------
-- Nota: el backend valida passwords con pgcrypto: password_hash = crypt($password, password_hash).
-- Por eso aquí generamos password_hash con crypt('1234', gen_salt('bf')).

-- Admin/organizador
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
	(
		'admin@app.com',
		'admin',
		crypt('1234', gen_salt('bf')),
		'Admin',
		'AppTorneos'
	);

-- Árbitros
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
	(
		'arb1@app.com',
		'arb1',
		crypt('1234', gen_salt('bf')),
		'Árbitro',
		'Uno'
	),
	(
		'arb2@app.com',
		'arb2',
		crypt('1234', gen_salt('bf')),
		'Árbitro',
		'Dos'
	);

-- Jugadores torneo Liga
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
	(
		'liga1@app.com',
		'liga1',
		crypt('1234', gen_salt('bf')),
		'Liga',
		'Jugador1'
	),
	(
		'liga2@app.com',
		'liga2',
		crypt('1234', gen_salt('bf')),
		'Liga',
		'Jugador2'
	),
	(
		'liga3@app.com',
		'liga3',
		crypt('1234', gen_salt('bf')),
		'Liga',
		'Jugador3'
	),
	(
		'liga4@app.com',
		'liga4',
		crypt('1234', gen_salt('bf')),
		'Liga',
		'Jugador4'
	);

-- Jugadores torneo Eliminación
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
	(
		'elim1@app.com',
		'elim1',
		crypt('1234', gen_salt('bf')),
		'Elim',
		'Jugador1'
	),
	(
		'elim2@app.com',
		'elim2',
		crypt('1234', gen_salt('bf')),
		'Elim',
		'Jugador2'
	),
	(
		'elim3@app.com',
		'elim3',
		crypt('1234', gen_salt('bf')),
		'Elim',
		'Jugador3'
	),
	(
		'elim4@app.com',
		'elim4',
		crypt('1234', gen_salt('bf')),
		'Elim',
		'Jugador4'
	);

-- Entrenador demo (credenciales dedicadas)
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
	(
		'coach1@app.com',
		'coach1',
		crypt('1234', gen_salt('bf')),
		'Coach',
		'Uno'
	);

-- -----------------------------
-- 4) Equipos
-- -----------------------------
-- Equipos para Liga
INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT v.nombre, v.descripcion, v.elo, c.id_categoria
FROM (VALUES
	('Liga FC A', 'Equipo demo Liga A', 1210),
	('Liga FC B', 'Equipo demo Liga B', 1185),
	('Liga FC C', 'Equipo demo Liga C', 1245),
	('Liga FC D', 'Equipo demo Liga D', 1175),
	('Liga FC E', 'Equipo demo Liga E', 1195),
	('Liga FC F', 'Equipo demo Liga F', 1220),
	('Liga FC G', 'Equipo demo Liga G (pendiente)', 1200),
	('Liga FC H', 'Equipo demo Liga H (pendiente)', 1165)
) AS v(nombre, descripcion, elo)
JOIN categoria c ON c.nombre = 'Fútbol 7';

-- Equipos para Eliminación
INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT v.nombre, v.descripcion, v.elo, c.id_categoria
FROM (VALUES
	('Elim FC C', 'Equipo demo Eliminación C', 1230),
	('Elim FC D', 'Equipo demo Eliminación D', 1160),
	('Elim FC E', 'Equipo demo Eliminación E', 1205),
	('Elim FC F', 'Equipo demo Eliminación F', 1260),
	('Elim FC G', 'Equipo demo Eliminación G', 1140),
	('Elim FC H', 'Equipo demo Eliminación H', 1190),
	('Elim FC I', 'Equipo demo Eliminación I', 1275),
	('Elim FC J', 'Equipo demo Eliminación J', 1170)
) AS v(nombre, descripcion, elo)
JOIN categoria c ON c.nombre = 'Fútbol 7';

-- -----------------------------
-- 5) Pertenencia de usuarios a equipos
-- -----------------------------
-- Liga
INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE
FROM usuario u
JOIN equipo e ON e.nombre = 'Liga FC A'
WHERE u.correo IN ('liga1@app.com', 'liga2@app.com');

INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE
FROM usuario u
JOIN equipo e ON e.nombre = 'Liga FC B'
WHERE u.correo IN ('liga3@app.com', 'liga4@app.com');

-- Eliminación
INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE
FROM usuario u
JOIN equipo e ON e.nombre = 'Elim FC C'
WHERE u.correo IN ('elim1@app.com', 'elim2@app.com');

INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE
FROM usuario u
JOIN equipo e ON e.nombre = 'Elim FC D'
WHERE u.correo IN ('elim3@app.com', 'elim4@app.com');

-- Entrenador demo pertenece a un equipo de Liga
INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE
FROM usuario u
JOIN equipo e ON e.nombre = 'Liga FC C'
WHERE u.correo = 'coach1@app.com';

-- Entrenadores (uno por equipo, usando el primer usuario de cada equipo)
INSERT INTO entrenador_equipo (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE
FROM usuario u
JOIN equipo e ON e.nombre = 'Liga FC A'
WHERE u.correo = 'liga1@app.com';

INSERT INTO entrenador_equipo (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE
FROM usuario u
JOIN equipo e ON e.nombre = 'Liga FC B'
WHERE u.correo = 'liga3@app.com';

INSERT INTO entrenador_equipo (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE
FROM usuario u
JOIN equipo e ON e.nombre = 'Elim FC C'
WHERE u.correo = 'elim1@app.com';

INSERT INTO entrenador_equipo (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE
FROM usuario u
JOIN equipo e ON e.nombre = 'Elim FC D'
WHERE u.correo = 'elim3@app.com';

-- Entrenador dedicado (coach1) para un equipo de Liga
INSERT INTO entrenador_equipo (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE
FROM usuario u
JOIN equipo e ON e.nombre = 'Liga FC C'
WHERE u.correo = 'coach1@app.com';

-- -----------------------------
-- 6) Crear 2 torneos (inscripcion_abierta)
-- -----------------------------
-- Torneo 1: Liga
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
SELECT
	'Torneo Demo Liga',
	'Torneo de presentación tipo Liga',
	NOW() + INTERVAL '2 days',
	NOW() + INTERVAL '30 days',
	'inscripcion_abierta',
	10,
	c.id_categoria,
	tt.id_tipo_torneo,
	u.id_usuario,
	'{"preguntas":[{"tipo":"texto","label":"¿Alguna alergia?"}]}'::jsonb,
	'victoria=3;empate=1;derrota=0',
	'{"dias":["martes","jueves"],"hora_inicio":"18:00","hora_fin":"21:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Liga'
JOIN usuario u ON u.correo = 'admin@app.com'
WHERE c.nombre = 'Fútbol 7';

-- Torneo 2: Eliminación
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
SELECT
	'Torneo Demo Eliminación',
	'Torneo de presentación tipo Eliminación',
	NOW() + INTERVAL '3 days',
	NOW() + INTERVAL '20 days',
	'inscripcion_abierta',
	8,
	c.id_categoria,
	tt.id_tipo_torneo,
	u.id_usuario,
	'{"preguntas":[{"tipo":"seleccion","label":"Talla camiseta","opciones":["S","M","L","XL"]}]}'::jsonb,
	'victoria=3;empate=0;derrota=0',
	'{"dias":["sabado"],"hora_inicio":"10:00","hora_fin":"14:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Eliminación directa'
JOIN usuario u ON u.correo = 'admin@app.com'
WHERE c.nombre = 'Fútbol 7';

-- -----------------------------
-- 7) Árbitros asignados a cada torneo
-- -----------------------------
-- arb1 -> Liga, arb2 -> Eliminación
INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT a.id_usuario, t.id_torneo
FROM usuario a
JOIN torneo t ON t.nombre = 'Torneo Demo Liga'
WHERE a.correo = 'arb1@app.com';

INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT a.id_usuario, t.id_torneo
FROM usuario a
JOIN torneo t ON t.nombre = 'Torneo Demo Eliminación'
WHERE a.correo = 'arb2@app.com';

-- -----------------------------
-- 8) Inscripción de equipos a torneos
-- -----------------------------
-- Torneo Liga: estado = jugando
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, 'jugando', 0
FROM torneo t
JOIN (VALUES
	('Liga FC A'),
	('Liga FC B'),
	('Liga FC C'),
	('Liga FC D'),
	('Liga FC E'),
	('Liga FC F')
) AS v(nombre_equipo) ON TRUE
JOIN equipo e ON e.nombre = v.nombre_equipo
WHERE t.nombre = 'Torneo Demo Liga';

-- Torneo Liga: inscripciones pendientes (aceptables)
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, 'pendiente', 0
FROM torneo t
JOIN equipo e ON e.nombre IN ('Liga FC G', 'Liga FC H')
WHERE t.nombre = 'Torneo Demo Liga';

-- Torneo Eliminación: estado = jugando
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, 'jugando', 0
FROM torneo t
JOIN equipo e ON e.nombre IN ('Elim FC C', 'Elim FC D', 'Elim FC E', 'Elim FC F')
WHERE t.nombre = 'Torneo Demo Eliminación';

-- Torneo Eliminación: inscripciones pendientes (aceptables)
-- Nota: total inscritos = 8 (2^3). Jugando=4 (2^2) y pendientes=4.
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, 'pendiente', 0
FROM torneo t
JOIN equipo e ON e.nombre IN ('Elim FC G', 'Elim FC H', 'Elim FC I', 'Elim FC J')
WHERE t.nombre = 'Torneo Demo Eliminación';

-- -----------------------------
-- 9) Historial de ELO (solo para equipos demo)
-- -----------------------------
INSERT INTO historial_elo (id_equipo, elo_anterior, elo_nuevo, descripcion)
SELECT e.id_equipo, 1200, e.elo, 'Seed presentación: ajuste inicial'
FROM equipo e
WHERE e.nombre IN (
	'Liga FC A',
	'Liga FC B',
	'Liga FC C',
	'Liga FC D',
	'Liga FC E',
	'Liga FC F',
	'Liga FC G',
	'Liga FC H',
	'Elim FC C',
	'Elim FC D',
	'Elim FC E',
	'Elim FC F',
	'Elim FC G',
	'Elim FC H',
	'Elim FC I',
	'Elim FC J'
);

COMMIT;

-- =====================================================
-- Usuarios para pruebas rápidas (correo / username)
--
-- Admin (organizador):
-- - admin@app.com / admin
--   Password: 1234
--
-- Entrenador (también usuario normal):
-- - coach1@app.com / coach1 -> entrenador de Liga FC C
--   Password: 1234
--
-- Torneo Demo Liga (equipos inscritos en jugando):
-- - liga1@app.com / liga1  -> Liga FC A
-- - liga2@app.com / liga2  -> Liga FC A
-- - liga3@app.com / liga3  -> Liga FC B
-- - liga4@app.com / liga4  -> Liga FC B
-- Árbitro: arb1@app.com / arb1
--   Password: 1234
--
-- Torneo Demo Eliminación (equipos inscritos en jugando):
-- - elim1@app.com / elim1  -> Elim FC C
-- - elim2@app.com / elim2  -> Elim FC C
-- - elim3@app.com / elim3  -> Elim FC D
-- - elim4@app.com / elim4  -> Elim FC D
-- Otros equipos sin usuarios demo: Elim FC E/F/G/H/I/J
-- Árbitro: arb2@app.com / arb2
--   Password: 1234
-- =====================================================

