-- =====================================================
-- AppTorneos - Seed (DEV)
-- Ejecutar en una BD ya creada para tener datos de ejemplo.
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO tipo_torneo (nombre, descripcion)
VALUES
	('Liga', 'Todos contra todos (puntos por victoria/empate)'),
	('Eliminación directa', 'Bracket: el perdedor queda eliminado')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion)
VALUES
	('Fútbol 11', 22, 'Reglas estándar', 'Partidos 11 vs 11'),
	('Baloncesto 5', 10, 'Reglas estándar', 'Partidos 5 vs 5')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
SELECT c.id_categoria, tt.id_tipo_torneo
FROM categoria c
JOIN tipo_torneo tt ON (
	(c.nombre = 'Fútbol 11' AND tt.nombre IN ('Liga', 'Eliminación directa'))
	OR (c.nombre = 'Baloncesto 5' AND tt.nombre = 'Liga')
)
ON CONFLICT (id_categoria, id_tipo_torneo) DO NOTHING;

INSERT INTO usuario (correo, nombre_usuario, password_hash)
VALUES
	('admin@app.com', 'admin', crypt('password123', gen_salt('bf')))
ON CONFLICT (correo) DO NOTHING;

INSERT INTO torneo (
	nombre,
	descripcion,
	fecha_inicio,
	fecha_fin,
	estado,
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

INSERT INTO torneo (
	nombre,
	descripcion,
	fecha_inicio,
	fecha_fin,
	estado,
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