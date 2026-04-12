-- =====================================================
-- AppTorneos - Seed (DEV)
-- Ejecutar en una BD ya creada para tener datos de ejemplo.
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO tipo_torneo (nombre, descripcion)
VALUES
	('Liga', 'Todos contra todos (puntos por victoria/empate)'),
	('Eliminación directa', 'Bracket: el perdedor queda eliminado'),
	('Serie + final (con tiempos)', 'Series y final por mejores tiempos'),
	('Eliminatorias por rondas', 'Rondas sucesivas con clasificacion por puestos/tiempos'),
	('Eliminación progresiva', 'Cada ronda elimina un porcentaje de participantes')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion)
VALUES
	('Fútbol 11', 2, 'Reglas estándar', 'Partidos de equipos 1 vs 1'),
	('Baloncesto 5', 2, 'Reglas estándar', 'Partidos de equipos 1 vs 1'),
	('Atletismo', 8, 'Clasificacion por posicion/tiempo', 'Eventos con varias personas por serie'),
	('Parchís', 4, 'Puntuacion por posicion en partida', 'Partidas de 4 contrincantes')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
SELECT c.id_categoria, tt.id_tipo_torneo
FROM categoria c
JOIN tipo_torneo tt ON (
	(c.nombre = 'Fútbol 11' AND tt.nombre IN ('Liga', 'Eliminación directa'))
	OR (c.nombre = 'Baloncesto 5' AND tt.nombre IN ('Liga', 'Eliminación directa'))
	OR (
		c.nombre = 'Atletismo'
		AND tt.nombre IN ('Liga', 'Serie + final (con tiempos)', 'Eliminatorias por rondas', 'Eliminación progresiva')
	)
	OR (
		c.nombre = 'Parchís'
		AND tt.nombre IN ('Eliminatorias por rondas')
	)
)
ON CONFLICT (id_categoria, id_tipo_torneo) DO NOTHING;

INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos, fotoperfil, fechanacimiento, genero)
VALUES
	('admin@app.com', 'admin', crypt('password123', gen_salt('bf')), 'Admin', 'App', NULL, NULL, NULL)
ON CONFLICT (correo) DO NOTHING;

INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos, fotoperfil, fechanacimiento, genero)
VALUES
	('laura@parchis.app', 'laura_parchis', crypt('password123', gen_salt('bf')), 'Laura', 'Pérez', NULL, '1995-04-10', 'Femenino'),
	('mario@parchis.app', 'mario_parchis', crypt('password123', gen_salt('bf')), 'Mario', 'García', '3.jpg', '1993-07-22', 'Masculino'),
	('nora@parchis.app', 'nora_parchis', crypt('password123', gen_salt('bf')), 'Nora', 'López', NULL, '1996-01-15', 'Femenino'),
	('oscar@parchis.app', 'oscar_parchis', crypt('password123', gen_salt('bf')), 'Oscar', 'Martínez', NULL, '1992-11-30', 'Masculino'),
	('paula@parchis.app', 'paula_parchis', crypt('password123', gen_salt('bf')), 'Paula', 'Sánchez', NULL, '1994-09-05', 'Femenino'),
	('quique@parchis.app', 'quique_parchis', crypt('password123', gen_salt('bf')), 'Quique', 'Ruiz', NULL, '1991-12-12', 'Masculino'),
	('raquel@parchis.app', 'raquel_parchis', crypt('password123', gen_salt('bf')), 'Raquel', 'Moreno', NULL, '1997-03-18', 'Femenino'),
	('sergio@parchis.app', 'sergio_parchis', crypt('password123', gen_salt('bf')), 'Sergio', 'Jiménez', NULL, '1990-06-25', 'Masculino')
ON CONFLICT (correo) DO NOTHING;

-- Árbitros (DEV) para que se puedan generar enfrentamientos
INSERT INTO usuario (correo, nombre_usuario, password_hash)
VALUES
	('ref_01@app.com', 'ref_01', crypt('password123', gen_salt('bf'))),
	('ref_02@app.com', 'ref_02', crypt('password123', gen_salt('bf')))
ON CONFLICT (correo) DO NOTHING;

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
	'Liga Primavera',
	'Torneo de prueba para ver datos en la UI',
	NOW() + INTERVAL '7 days',
	NOW() + INTERVAL '37 days',
	'inscripcion_abierta',
	16,
	c.id_categoria,
	tt.id_tipo_torneo,
	u.id_usuario,
	'{"preguntas":[{"tipo":"texto","label":"¿Algún comentario?"}]}'::jsonb,
	'3-1-0',
	'{"dias":["sabado"],"hora_inicio":"10:00","hora_fin":"14:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Liga'
JOIN usuario u ON u.correo = 'admin@app.com'
WHERE c.nombre = 'Fútbol 11'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- Asignación de árbitros a torneos de seed
-- Nota: arbitro_torneo es por torneo (id_torneo NOT NULL)
INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT u.id_usuario, t.id_torneo
FROM usuario u
JOIN torneo t ON t.nombre IN ('Liga Primavera', 'Copa Relámpago')
WHERE u.correo IN ('ref_01@app.com', 'ref_02@app.com')
ON CONFLICT (id_usuario, id_torneo) DO NOTHING;

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
	'Copa Relámpago',
	'Eliminación directa (demo)',
	NOW() + INTERVAL '2 days',
	NOW() + INTERVAL '9 days',
	'en_curso',
	8,
	c.id_categoria,
	tt.id_tipo_torneo,
	u.id_usuario,
	NULL,
	'Gana el partido',
	'{"dias":["miercoles","viernes"],"hora_inicio":"18:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Eliminación directa'
JOIN usuario u ON u.correo = 'admin@app.com'
WHERE c.nombre = 'Fútbol 11'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

INSERT INTO torneo (
	nombre,
	descripcion,
	fecha_inicio,
	fecha_fin,
	estado,
	limite_equipos,
	id_categoria,
	id_tipo_torneo,
	id_organizador
)
SELECT
	'Liga Basket',
	'Liga de baloncesto (demo)',
	NOW() - INTERVAL '15 days',
	NOW() - INTERVAL '1 days',
	'acabado',
	12,
	c.id_categoria,
	tt.id_tipo_torneo,
	u.id_usuario
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Liga'
JOIN usuario u ON u.correo = 'admin@app.com'
WHERE c.nombre = 'Baloncesto 5'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- Equipos de fútbol para Liga Primavera
INSERT INTO equipo (nombre, descripcion, elo)
VALUES
    ('Atlético Aurora', 'Equipo ficticio de barrio', 1200),
    ('Deportivo Central', 'Plantel de prueba', 1200),
    ('Unión del Parque', 'Equipo amateur', 1200),
    ('Sporting del Norte', 'Club inventado', 1200),
    ('Rápidos FC', 'Equipo de fútbol 11', 1200),
    ('Estrella Roja', 'Equipo de competición', 1200),
    ('Titanes FC', 'Equipo ficticio', 1200),
    ('Club Horizonte', 'Plantel de ejemplo', 1200),
    ('Los Leones', 'Equipo de barrio', 1200),
    ('Nueva Generación', 'Equipo juvenil ficticio', 1200)
ON CONFLICT (nombre) DO NOTHING;

-- Inscripción de equipos al torneo Liga Primavera
INSERT INTO participacion_torneo_equipo (
    id_torneo,
    id_equipo,
    fecha,
    respuesta,
    estado,
    puntuacion
)
SELECT
    t.id_torneo,
    e.id_equipo,
    NOW(),
    NULL,
    'jugando',
    0
FROM torneo t
JOIN categoria c ON c.id_categoria = t.id_categoria
JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
JOIN equipo e ON e.nombre IN (
    'Atlético Aurora',
    'Deportivo Central',
    'Unión del Parque',
    'Sporting del Norte',
    'Rápidos FC',
    'Estrella Roja',
    'Titanes FC',
    'Club Horizonte',
    'Los Leones',
    'Nueva Generación'
)
WHERE t.nombre = 'Liga Primavera'
  AND c.nombre = 'Fútbol 11'
  AND tt.nombre = 'Liga'
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Inscripción de equipos al torneo Copa Relámpago (8 equipos para bracket)
INSERT INTO participacion_torneo_equipo (
	id_torneo,
	id_equipo,
	fecha,
	respuesta,
	estado,
	puntuacion
)
SELECT
	t.id_torneo,
	e.id_equipo,
	NOW(),
	NULL,
	'jugando',
	0
FROM torneo t
JOIN categoria c ON c.id_categoria = t.id_categoria
JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
JOIN equipo e ON e.nombre IN (
	'Atlético Aurora',
	'Deportivo Central',
	'Unión del Parque',
	'Sporting del Norte',
	'Rápidos FC',
	'Estrella Roja',
	'Titanes FC',
	'Club Horizonte'
)
WHERE t.nombre = 'Copa Relámpago'
  AND c.nombre = 'Fútbol 11'
  AND tt.nombre = 'Eliminación directa'
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Personas/equipos de atletismo para pruebas de liga multi-participante
INSERT INTO equipo (nombre, descripcion, elo)
VALUES
	('Ana Sprint', 'Atleta de velocidad', 1200),
	('Bruno Rayo', 'Atleta de velocidad', 1200),
	('Carla Pista', 'Atleta de pista', 1200),
	('Diego Zancada', 'Atleta de fondo', 1200),
	('Elena Turbo', 'Atleta de velocidad', 1200),
	('Fabio Meta', 'Atleta de pista', 1200),
	('Gina Crono', 'Atleta de tiempos', 1200),
	('Hugo Carril', 'Atleta de sprint', 1200),
	('Irene Veloz', 'Atleta de velocidad', 1200),
	('Jorge Relay', 'Atleta de relevos', 1200),
	('Karla Pulse', 'Atleta de pista', 1200),
	('Leo Finish', 'Atleta de cierre', 1200),
	('Marta Podio', 'Atleta de resistencia', 1200),
	('Nico Track', 'Atleta de pista', 1200),
	('Olga Tempo', 'Atleta de ritmo', 1200),
	('Pablo Lane', 'Atleta de carril', 1200)
ON CONFLICT (nombre) DO NOTHING;

-- Equipos/jugadores de parchis para eliminatorias por rondas
INSERT INTO equipo (nombre, descripcion, elo)
VALUES
	('Laura Dados', 'Jugadora de parchis', 1200),
	('Mario Ficha', 'Jugador de parchis', 1200),
	('Nora Meta', 'Jugadora de parchis', 1200),
	('Oscar Casilla', 'Jugador de parchis', 1200),
	('Paula Tablero', 'Jugadora de parchis', 1200),
	('Quique Color', 'Jugador de parchis', 1200),
	('Raquel Turno', 'Jugadora de parchis', 1200),
	('Sergio Doble', 'Jugador de parchis', 1200),
	('Tania Avance', 'Jugadora de parchis', 1200),
	('Ulises Casa', 'Jugador de parchis', 1200),
	('Valeria Dado', 'Jugadora de parchis', 1200),
	('Walter Salida', 'Jugador de parchis', 1200)
ON CONFLICT (nombre) DO NOTHING;

-- Torneo de atletismo para probar liga con mas de 2 participantes por partido
INSERT INTO torneo (
	nombre,
	descripcion,
	fecha_inicio,
	fecha_fin,
	estado,
	id_categoria,
	id_tipo_torneo,
	id_organizador,
	norma_puntuacion,
	preferencia_horario
)
SELECT
	'Liga Atletismo Primavera',
	'Prueba de liga en categoria multi-participante',
	NOW() + INTERVAL '3 days',
	NOW() + INTERVAL '45 days',
	'inscripcion_abierta',
	c.id_categoria,
	tt.id_tipo_torneo,
	u.id_usuario,
	'rank:10,8,6,5,4,3,2,1',
	'{"dias":["martes","jueves"],"hora_inicio":"17:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Liga'
JOIN usuario u ON u.correo = 'admin@app.com'
WHERE c.nombre = 'Atletismo'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- Inscripcion de atletas al torneo de atletismo
INSERT INTO participacion_torneo_equipo (
	id_torneo,
	id_equipo,
	fecha,
	respuesta,
	estado,
	puntuacion
)
SELECT
	t.id_torneo,
	e.id_equipo,
	NOW(),
	NULL,
	'jugando',
	0
FROM torneo t
JOIN categoria c ON c.id_categoria = t.id_categoria
JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
JOIN equipo e ON e.nombre IN (
	'Ana Sprint',
	'Bruno Rayo',
	'Carla Pista',
	'Diego Zancada',
	'Elena Turbo',
	'Fabio Meta',
	'Gina Crono',
	'Hugo Carril',
	'Irene Veloz',
	'Jorge Relay',
	'Karla Pulse',
	'Leo Finish',
	'Marta Podio',
	'Nico Track',
	'Olga Tempo',
	'Pablo Lane'
)
WHERE t.nombre = 'Liga Atletismo Primavera'
  AND c.nombre = 'Atletismo'
  AND tt.nombre = 'Liga'
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Torneo de parchis para probar eliminatorias por rondas
INSERT INTO torneo (
	nombre,
	descripcion,
	fecha_inicio,
	fecha_fin,
	estado,
	id_categoria,
	id_tipo_torneo,
	id_organizador,
	norma_puntuacion,
	preferencia_horario
)
SELECT
	'Copa Parchís Clasificatoria',
	'Eliminatorias por rondas en partidas de 4 participantes',
	NOW() + INTERVAL '4 days',
	NOW() + INTERVAL '30 days',
	'inscripcion_abierta',
	c.id_categoria,
	tt.id_tipo_torneo,
	u.id_usuario,
	'criterio=desc;clasifican_por_serie=2;mejores_tiempos=0',
	'{"dias":["lunes","miercoles"],"hora_inicio":"19:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Eliminatorias por rondas'
JOIN usuario u ON u.correo = 'admin@app.com'
WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- Inscripcion de jugadores/equipos al torneo de parchis
INSERT INTO participacion_torneo_equipo (
	id_torneo,
	id_equipo,
	fecha,
	respuesta,
	estado,
	puntuacion
)
SELECT
	t.id_torneo,
	e.id_equipo,
	NOW(),
	NULL,
	'jugando',
	0
FROM torneo t
JOIN categoria c ON c.id_categoria = t.id_categoria
JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
JOIN equipo e ON e.nombre IN (
	'Laura Dados',
	'Mario Ficha',
	'Nora Meta',
	'Oscar Casilla',
	'Paula Tablero',
	'Quique Color',
	'Raquel Turno',
	'Sergio Doble',
	'Tania Avance',
	'Ulises Casa',
	'Valeria Dado',
	'Walter Salida'
)
WHERE t.nombre = 'Copa Parchís Clasificatoria'
  AND c.nombre = 'Parchís'
  AND tt.nombre = 'Eliminatorias por rondas'
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Relacion jugador-equipo para usuarios de parchis (muestra de usuarios diferentes)
INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE
FROM usuario u
JOIN equipo e ON (
	(u.correo = 'laura@parchis.app' AND e.nombre = 'Laura Dados') OR
	(u.correo = 'mario@parchis.app' AND e.nombre = 'Mario Ficha') OR
	(u.correo = 'nora@parchis.app' AND e.nombre = 'Nora Meta') OR
	(u.correo = 'oscar@parchis.app' AND e.nombre = 'Oscar Casilla') OR
	(u.correo = 'paula@parchis.app' AND e.nombre = 'Paula Tablero') OR
	(u.correo = 'quique@parchis.app' AND e.nombre = 'Quique Color') OR
	(u.correo = 'raquel@parchis.app' AND e.nombre = 'Raquel Turno') OR
	(u.correo = 'sergio@parchis.app' AND e.nombre = 'Sergio Doble')
)
ON CONFLICT (id_usuario, id_equipo, fecha_inicio) DO NOTHING;