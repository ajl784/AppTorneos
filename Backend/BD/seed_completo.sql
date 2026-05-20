-- =====================================================
-- AppTorneos - Seed Completo (DEV)
-- Datos de ejemplo para cubrir todos los formatos de torneos
-- Un único organizador gestiona todos los torneos
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================================================
-- CATÁLOGOS: Tipos de Torneos y Categorías
-- =====================================================

INSERT INTO tipo_torneo (nombre, descripcion)
VALUES
	('Liga', 'Todos contra todos (puntos por victoria/empate)'),
	('Eliminación directa', 'Bracket: el perdedor queda eliminado'),
	('Eliminación por serie', 'Eliminación multi por bloques de series repetidas y clasificación por puntos'),
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
		AND tt.nombre IN ('Liga', 'Eliminación por serie', 'Serie + final (con tiempos)', 'Eliminatorias por rondas', 'Eliminación progresiva')
	)
	OR (
		c.nombre = 'Parchís'
		AND tt.nombre IN ('Eliminación por serie', 'Eliminatorias por rondas')
	)
)
ON CONFLICT (id_categoria, id_tipo_torneo) DO NOTHING;

-- =====================================================
-- USUARIOS
-- =====================================================

-- Usuario administrador
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos, fotoperfil, fechanacimiento, genero)
VALUES
	('admin@app.com', 'admin', crypt('password123', gen_salt('bf')), 'Admin', 'App', NULL, NULL, NULL)
ON CONFLICT (correo) DO NOTHING;

-- Usuario ORGANIZADOR PRINCIPAL (gestiona todos los torneos)
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos, fotoperfil, fechanacimiento, genero)
VALUES
	('organizador@app.com', 'organizador_principal', crypt('password123', gen_salt('bf')), 'Arturo', 'Organizador', NULL, '1985-05-20', 'Masculino')
ON CONFLICT (correo) DO NOTHING;

-- Árbitros (DEV)
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
	('arbitro1@app.com', 'arbitro_1', crypt('password123', gen_salt('bf')), 'Ref', 'Uno'),
	('arbitro2@app.com', 'arbitro_2', crypt('password123', gen_salt('bf')), 'Ref', 'Dos'),
	('arbitro3@app.com', 'arbitro_3', crypt('password123', gen_salt('bf')), 'Ref', 'Tres'),
	('arbitro4@app.com', 'arbitro_4', crypt('password123', gen_salt('bf')), 'Ref', 'Cuatro')
ON CONFLICT (correo) DO NOTHING;

-- Jugadores de fútbol
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
	('futbol1@app.com', 'futbol_1', crypt('password123', gen_salt('bf')), 'Cristiano', 'Ronaldo'),
	('futbol2@app.com', 'futbol_2', crypt('password123', gen_salt('bf')), 'Lionel', 'Messi'),
	('futbol3@app.com', 'futbol_3', crypt('password123', gen_salt('bf')), 'Neymar', 'Junior'),
	('futbol4@app.com', 'futbol_4', crypt('password123', gen_salt('bf')), 'Sergio', 'Ramos'),
	('futbol5@app.com', 'futbol_5', crypt('password123', gen_salt('bf')), 'Manuel', 'Neuer'),
	('futbol6@app.com', 'futbol_6', crypt('password123', gen_salt('bf')), 'Luis', 'Suárez'),
	('futbol7@app.com', 'futbol_7', crypt('password123', gen_salt('bf')), 'João', 'Félix'),
	('futbol8@app.com', 'futbol_8', crypt('password123', gen_salt('bf')), 'Vinícius', 'Junior'),
	('futbol9@app.com', 'futbol_9', crypt('password123', gen_salt('bf')), 'Eduardo', 'Camavinga'),
	('futbol10@app.com', 'futbol_10', crypt('password123', gen_salt('bf')), 'Florian', 'Wirtz'),
	('futbol11@app.com', 'futbol_11', crypt('password123', gen_salt('bf')), 'Jude', 'Bellingham'),
	('futbol12@app.com', 'futbol_12', crypt('password123', gen_salt('bf')), 'Pedri', 'González'),
	('futbol13@app.com', 'futbol_13', crypt('password123', gen_salt('bf')), 'Gavi', 'Páez'),
	('futbol14@app.com', 'futbol_14', crypt('password123', gen_salt('bf')), 'Ansu', 'Fati'),
	('futbol15@app.com', 'futbol_15', crypt('password123', gen_salt('bf')), 'Lamine', 'Yamal')
ON CONFLICT (correo) DO NOTHING;

-- Jugadores de baloncesto
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
	('basket1@app.com', 'basket_1', crypt('password123', gen_salt('bf')), 'LeBron', 'James'),
	('basket2@app.com', 'basket_2', crypt('password123', gen_salt('bf')), 'Luka', 'Doncic'),
	('basket3@app.com', 'basket_3', crypt('password123', gen_salt('bf')), 'Jayson', 'Tatum'),
	('basket4@app.com', 'basket_4', crypt('password123', gen_salt('bf')), 'Kevin', 'Durant'),
	('basket5@app.com', 'basket_5', crypt('password123', gen_salt('bf')), 'Stephen', 'Curry'),
	('basket6@app.com', 'basket_6', crypt('password123', gen_salt('bf')), 'Giannis', 'Antetokounmpo'),
	('basket7@app.com', 'basket_7', crypt('password123', gen_salt('bf')), 'Anthony', 'Davis'),
	('basket8@app.com', 'basket_8', crypt('password123', gen_salt('bf')), 'Damian', 'Lillard'),
	('basket9@app.com', 'basket_9', crypt('password123', gen_salt('bf')), 'Joel', 'Embiid'),
	('basket10@app.com', 'basket_10', crypt('password123', gen_salt('bf')), 'Nikola', 'Jokic')
ON CONFLICT (correo) DO NOTHING;

-- Atletas
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
	('atletismo1@app.com', 'atleta_1', crypt('password123', gen_salt('bf')), 'Usain', 'Bolt'),
	('atletismo2@app.com', 'atleta_2', crypt('password123', gen_salt('bf')), 'Florence', 'Griffith-Joyner'),
	('atletismo3@app.com', 'atleta_3', crypt('password123', gen_salt('bf')), 'Carl', 'Lewis'),
	('atletismo4@app.com', 'atleta_4', crypt('password123', gen_salt('bf')), 'Jackie', 'Joyner-Kersee'),
	('atletismo5@app.com', 'atleta_5', crypt('password123', gen_salt('bf')), 'Michael', 'Johnson'),
	('atletismo6@app.com', 'atleta_6', crypt('password123', gen_salt('bf')), 'Nadia', 'Toft'),
	('atletismo7@app.com', 'atleta_7', crypt('password123', gen_salt('bf')), 'Maurice', 'Greene'),
	('atletismo8@app.com', 'atleta_8', crypt('password123', gen_salt('bf')), 'Tirunesh', 'Dibaba'),
	('atletismo9@app.com', 'atleta_9', crypt('password123', gen_salt('bf')), 'Haile', 'Gebrselassie'),
	('atletismo10@app.com', 'atleta_10', crypt('password123', gen_salt('bf')), 'Almaz', 'Ayana'),
	('atletismo11@app.com', 'atleta_11', crypt('password123', gen_salt('bf')), 'Mo', 'Farah'),
	('atletismo12@app.com', 'atleta_12', crypt('password123', gen_salt('bf')), 'Merritt', 'Beyer'),
	('atletismo13@app.com', 'atleta_13', crypt('password123', gen_salt('bf')), 'Evelyn', 'Agosi'),
	('atletismo14@app.com', 'atleta_14', crypt('password123', gen_salt('bf')), 'Justyn', 'Knight'),
	('atletismo15@app.com', 'atleta_15', crypt('password123', gen_salt('bf')), 'Sifan', 'Hassan'),
	('atletismo16@app.com', 'atleta_16', crypt('password123', gen_salt('bf')), 'Donovan', 'Brazier')
ON CONFLICT (correo) DO NOTHING;

-- Jugadores de parchís
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
	('parchis1@app.com', 'parchis_1', crypt('password123', gen_salt('bf')), 'Laura', 'Pérez'),
	('parchis2@app.com', 'parchis_2', crypt('password123', gen_salt('bf')), 'Mario', 'García'),
	('parchis3@app.com', 'parchis_3', crypt('password123', gen_salt('bf')), 'Nora', 'López'),
	('parchis4@app.com', 'parchis_4', crypt('password123', gen_salt('bf')), 'Oscar', 'Martínez'),
	('parchis5@app.com', 'parchis_5', crypt('password123', gen_salt('bf')), 'Paula', 'Sánchez'),
	('parchis6@app.com', 'parchis_6', crypt('password123', gen_salt('bf')), 'Quique', 'Ruiz'),
	('parchis7@app.com', 'parchis_7', crypt('password123', gen_salt('bf')), 'Raquel', 'Moreno'),
	('parchis8@app.com', 'parchis_8', crypt('password123', gen_salt('bf')), 'Sergio', 'Jiménez'),
	('parchis9@app.com', 'parchis_9', crypt('password123', gen_salt('bf')), 'Tania', 'Vázquez'),
	('parchis10@app.com', 'parchis_10', crypt('password123', gen_salt('bf')), 'Ulises', 'Cortés'),
	('parchis11@app.com', 'parchis_11', crypt('password123', gen_salt('bf')), 'Valeria', 'Navarro'),
	('parchis12@app.com', 'parchis_12', crypt('password123', gen_salt('bf')), 'Walter', 'Rojas')
ON CONFLICT (correo) DO NOTHING;

-- =====================================================
-- EQUIPOS: FÚTBOL 11
-- =====================================================

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT v.nombre, v.descripcion, v.elo, c.id_categoria
FROM (
	VALUES
		('Real Madrid CF', 'Club de fútbol histórico', 1400),
		('FC Barcelona', 'Club catalán de fútbol', 1400),
		('Atlético Madrid', 'Colchoneros de Madrid', 1350),
		('Valencia CF', 'Club de la región Valencia', 1300),
		('Sevilla FC', 'Club sevillano', 1300),
		('Athletic Bilbao', 'Club vasco', 1250),
		('Villarreal CF', 'Submarino Amarillo', 1250),
		('Real Sociedad', 'Club vasco del norte', 1250),
		('Celta Vigo', 'Club galego', 1200),
		('Sporting Gijón', 'Club asturiano', 1200),
		('Betis Sevilla', 'Club sevillano', 1200),
		('Racing Santander', 'Club cántabro', 1180),
		('Mallorca', 'Club balear', 1180),
		('Real Zaragoza', 'Club aragonés', 1180),
		('SD Eibar', 'Club vasco', 1180),
		('Leganés', 'Club madrileño', 1200),
		('Getafe CF', 'Club madrileño', 1200),
		('Rayo Vallecano', 'Club madrileño', 1200),
		('Real Oviedo', 'Club asturiano', 1180),
		('CD Tenerife', 'Club canario', 1180)
) AS v(nombre, descripcion, elo)
JOIN categoria c ON c.nombre = 'Fútbol 11'
ON CONFLICT (nombre) DO NOTHING;

-- =====================================================
-- EQUIPOS: BALONCESTO 5
-- =====================================================

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT v.nombre, v.descripcion, v.elo, c.id_categoria
FROM (
	VALUES
		('Real Madrid Baloncesto', 'Gigantes del baloncesto', 1450),
		('FC Barcelona Lassa', 'Club catalán de baloncesto', 1430),
		('Tecnyconta Zaragoza', 'Club aragonés', 1350),
		('Estudiantes Madrid', 'Club madrileño histórico', 1350),
		('Baskonia Vitoria', 'Club vasco', 1330),
		('Unicaja Málaga', 'Club malagueño', 1300),
		('Joventut Badalona', 'Club catalán', 1280),
		('UCAM Murcia', 'Club murciano', 1270),
		('Real Betis Baloncesto', 'Club sevillano', 1250),
		('Obradoiro CAB', 'Club gallego', 1250)
) AS v(nombre, descripcion, elo)
JOIN categoria c ON c.nombre = 'Baloncesto 5'
ON CONFLICT (nombre) DO NOTHING;

-- =====================================================
-- EQUIPOS: ATLETISMO (individuos/atletas)
-- =====================================================

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT v.nombre, v.descripcion, v.elo, c.id_categoria
FROM (
	VALUES
		('Usain Bolt Sprinter', 'Velocista de clase mundial', 1500),
		('Florence Griffith Velocista', 'Leyenda del sprint', 1480),
		('Carl Lewis Jumper', 'Saltador de clase mundial', 1450),
		('Jackie Joyner Atleta', 'Polivalente olímpica', 1450),
		('Michael Johnson Rápido', 'Velocista histórico', 1450),
		('Nadia Toft Runner', 'Corredora de distancia', 1400),
		('Maurice Greene Sprinter', 'Velocista elite', 1420),
		('Tirunesh Dibaba Corredor', 'Corredora de fondo', 1440),
		('Haile Gebrselassie Maratón', 'Maratoniano legendario', 1460),
		('Almaz Ayana Distancia', 'Corredora de distancia', 1430),
		('Mo Farah Fondo', 'Corredor de media-larga', 1420),
		('Merritt Beyer Sprinter', 'Velocista velocidad', 1400),
		('Evelyn Agosi Jump', 'Saltadora en largo', 1380),
		('Justyn Knight Runner', 'Corredor de media', 1390),
		('Sifan Hassan Multipropósito', 'Atleta versátil', 1450),
		('Donovan Brazier Miler', 'Corredor de milla', 1410)
) AS v(nombre, descripcion, elo)
JOIN categoria c ON c.nombre = 'Atletismo'
ON CONFLICT (nombre) DO NOTHING;

-- =====================================================
-- EQUIPOS: PARCHÍS (individuos/jugadores)
-- =====================================================

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT v.nombre, v.descripcion, v.elo, c.id_categoria
FROM (
	VALUES
		('Laura Parchista', 'Jugadora avanzada', 1250),
		('Mario Gambler', 'Jugador estratega', 1240),
		('Nora Dados', 'Experta en dados', 1230),
		('Oscar Meta', 'Buscador de metas', 1220),
		('Paula Tablero', 'Dominadora del juego', 1250),
		('Quique Suerte', 'El suertudo', 1200),
		('Raquel Turno', 'Especialista en turnos', 1210),
		('Sergio Fichas', 'Maestro de fichas', 1240),
		('Tania Avance', 'Aceleradora', 1210),
		('Ulises Casa', 'Protector del hogar', 1200),
		('Valeria Seguridad', 'Jugadora defensiva', 1210),
		('Walter Velocidad', 'Jugador rápido', 1230)
) AS v(nombre, descripcion, elo)
JOIN categoria c ON c.nombre = 'Parchís'
ON CONFLICT (nombre) DO NOTHING;

-- =====================================================
-- RELACIONES USUARIO-EQUIPO
-- =====================================================

INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, e.id_equipo, CURRENT_DATE
FROM usuario u
JOIN equipo e ON (
	-- Fútbol
	(u.correo = 'futbol1@app.com' AND e.nombre = 'Real Madrid CF') OR
	(u.correo = 'futbol2@app.com' AND e.nombre = 'FC Barcelona') OR
	(u.correo = 'futbol3@app.com' AND e.nombre = 'Atlético Madrid') OR
	(u.correo = 'futbol4@app.com' AND e.nombre = 'Valencia CF') OR
	(u.correo = 'futbol5@app.com' AND e.nombre = 'Sevilla FC') OR
	(u.correo = 'futbol6@app.com' AND e.nombre = 'Athletic Bilbao') OR
	(u.correo = 'futbol7@app.com' AND e.nombre = 'Villarreal CF') OR
	(u.correo = 'futbol8@app.com' AND e.nombre = 'Real Sociedad') OR
	(u.correo = 'futbol9@app.com' AND e.nombre = 'Celta Vigo') OR
	(u.correo = 'futbol10@app.com' AND e.nombre = 'Sporting Gijón') OR
	(u.correo = 'futbol11@app.com' AND e.nombre = 'Betis Sevilla') OR
	(u.correo = 'futbol12@app.com' AND e.nombre = 'Racing Santander') OR
	(u.correo = 'futbol13@app.com' AND e.nombre = 'Mallorca') OR
	(u.correo = 'futbol14@app.com' AND e.nombre = 'Real Zaragoza') OR
	(u.correo = 'futbol15@app.com' AND e.nombre = 'SD Eibar') OR
	-- Baloncesto
	(u.correo = 'basket1@app.com' AND e.nombre = 'Real Madrid Baloncesto') OR
	(u.correo = 'basket2@app.com' AND e.nombre = 'FC Barcelona Lassa') OR
	(u.correo = 'basket3@app.com' AND e.nombre = 'Tecnyconta Zaragoza') OR
	(u.correo = 'basket4@app.com' AND e.nombre = 'Estudiantes Madrid') OR
	(u.correo = 'basket5@app.com' AND e.nombre = 'Baskonia Vitoria') OR
	(u.correo = 'basket6@app.com' AND e.nombre = 'Unicaja Málaga') OR
	(u.correo = 'basket7@app.com' AND e.nombre = 'Joventut Badalona') OR
	(u.correo = 'basket8@app.com' AND e.nombre = 'UCAM Murcia') OR
	(u.correo = 'basket9@app.com' AND e.nombre = 'Real Betis Baloncesto') OR
	(u.correo = 'basket10@app.com' AND e.nombre = 'Obradoiro CAB') OR
	-- Atletismo
	(u.correo = 'atletismo1@app.com' AND e.nombre = 'Usain Bolt Sprinter') OR
	(u.correo = 'atletismo2@app.com' AND e.nombre = 'Florence Griffith Velocista') OR
	(u.correo = 'atletismo3@app.com' AND e.nombre = 'Carl Lewis Jumper') OR
	(u.correo = 'atletismo4@app.com' AND e.nombre = 'Jackie Joyner Atleta') OR
	(u.correo = 'atletismo5@app.com' AND e.nombre = 'Michael Johnson Rápido') OR
	(u.correo = 'atletismo6@app.com' AND e.nombre = 'Nadia Toft Runner') OR
	(u.correo = 'atletismo7@app.com' AND e.nombre = 'Maurice Greene Sprinter') OR
	(u.correo = 'atletismo8@app.com' AND e.nombre = 'Tirunesh Dibaba Corredor') OR
	(u.correo = 'atletismo9@app.com' AND e.nombre = 'Haile Gebrselassie Maratón') OR
	(u.correo = 'atletismo10@app.com' AND e.nombre = 'Almaz Ayana Distancia') OR
	(u.correo = 'atletismo11@app.com' AND e.nombre = 'Mo Farah Fondo') OR
	(u.correo = 'atletismo12@app.com' AND e.nombre = 'Merritt Beyer Sprinter') OR
	(u.correo = 'atletismo13@app.com' AND e.nombre = 'Evelyn Agosi Jump') OR
	(u.correo = 'atletismo14@app.com' AND e.nombre = 'Justyn Knight Runner') OR
	(u.correo = 'atletismo15@app.com' AND e.nombre = 'Sifan Hassan Multipropósito') OR
	(u.correo = 'atletismo16@app.com' AND e.nombre = 'Donovan Brazier Miler') OR
	-- Parchís
	(u.correo = 'parchis1@app.com' AND e.nombre = 'Laura Parchista') OR
	(u.correo = 'parchis2@app.com' AND e.nombre = 'Mario Gambler') OR
	(u.correo = 'parchis3@app.com' AND e.nombre = 'Nora Dados') OR
	(u.correo = 'parchis4@app.com' AND e.nombre = 'Oscar Meta') OR
	(u.correo = 'parchis5@app.com' AND e.nombre = 'Paula Tablero') OR
	(u.correo = 'parchis6@app.com' AND e.nombre = 'Quique Suerte') OR
	(u.correo = 'parchis7@app.com' AND e.nombre = 'Raquel Turno') OR
	(u.correo = 'parchis8@app.com' AND e.nombre = 'Sergio Fichas') OR
	(u.correo = 'parchis9@app.com' AND e.nombre = 'Tania Avance') OR
	(u.correo = 'parchis10@app.com' AND e.nombre = 'Ulises Casa') OR
	(u.correo = 'parchis11@app.com' AND e.nombre = 'Valeria Seguridad') OR
	(u.correo = 'parchis12@app.com' AND e.nombre = 'Walter Velocidad')
)
ON CONFLICT (id_usuario, id_equipo, fecha_inicio) DO NOTHING;

-- =====================================================
-- TORNEOS: FÚTBOL 11 (2 formatos)
-- =====================================================

-- Torneo 1: Liga de Fútbol
INSERT INTO torneo (
	nombre, descripcion, fecha_inicio, fecha_fin, estado, limite_equipos,
	id_categoria, id_tipo_torneo, id_organizador,
	norma_puntuacion, preferencia_horario
)
SELECT
	'Liga Profesional Primavera 2026',
	'Liga de todos contra todos en temporada de primavera',
	NOW() + INTERVAL '7 days', NOW() + INTERVAL '90 days', 'inscripcion_abierta', 20,
	c.id_categoria, tt.id_tipo_torneo, u.id_usuario,
	'3-1-0', '{"dias":["sabado","domingo"],"hora_inicio":"16:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Liga'
JOIN usuario u ON u.correo = 'organizador@app.com'
WHERE c.nombre = 'Fútbol 11'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- Torneo 2: Eliminación Directa de Fútbol
INSERT INTO torneo (
	nombre, descripcion, fecha_inicio, fecha_fin, estado, limite_equipos,
	id_categoria, id_tipo_torneo, id_organizador,
	norma_puntuacion, preferencia_horario
)
SELECT
	'Copa del Rey Primavera 2026',
	'Eliminación directa (bracket) en formato copa',
	NOW() + INTERVAL '5 days', NOW() + INTERVAL '30 days', 'inscripcion_cerrada', 16,
	c.id_categoria, tt.id_tipo_torneo, u.id_usuario,
	'Gana el partido', '{"dias":["miercoles","viernes"],"hora_inicio":"20:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Eliminación directa'
JOIN usuario u ON u.correo = 'organizador@app.com'
WHERE c.nombre = 'Fútbol 11'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- =====================================================
-- TORNEOS: BALONCESTO 5 (2 formatos)
-- =====================================================

-- Torneo 3: Liga de Baloncesto
INSERT INTO torneo (
	nombre, descripcion, fecha_inicio, fecha_fin, estado, limite_equipos,
	id_categoria, id_tipo_torneo, id_organizador,
	norma_puntuacion, preferencia_horario
)
SELECT
	'Liga ACB Primavera 2026',
	'Liga profesional de baloncesto',
	NOW() + INTERVAL '10 days', NOW() + INTERVAL '120 days', 'inscripcion_abierta', 18,
	c.id_categoria, tt.id_tipo_torneo, u.id_usuario,
	'2-1-0', '{"dias":["martes","jueves"],"hora_inicio":"19:30"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Liga'
JOIN usuario u ON u.correo = 'organizador@app.com'
WHERE c.nombre = 'Baloncesto 5'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- Torneo 4: Eliminación Directa de Baloncesto
INSERT INTO torneo (
	nombre, descripcion, fecha_inicio, fecha_fin, estado, limite_equipos,
	id_categoria, id_tipo_torneo, id_organizador,
	norma_puntuacion, preferencia_horario
)
SELECT
	'Copa de la Reina Baloncesto 2026',
	'Torneo de eliminación directa para baloncesto',
	NOW() + INTERVAL '15 days', NOW() + INTERVAL '45 days', 'inscripcion_abierta', 12,
	c.id_categoria, tt.id_tipo_torneo, u.id_usuario,
	'Gana el partido', '{"dias":["miercoles"],"hora_inicio":"18:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Eliminación directa'
JOIN usuario u ON u.correo = 'organizador@app.com'
WHERE c.nombre = 'Baloncesto 5'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- =====================================================
-- TORNEOS: ATLETISMO (5 formatos - todos posibles)
-- =====================================================

-- Torneo 5: Liga de Atletismo
INSERT INTO torneo (
	nombre, descripcion, fecha_inicio, fecha_fin, estado, limite_equipos,
	id_categoria, id_tipo_torneo, id_organizador,
	norma_puntuacion, preferencia_horario
)
SELECT
	'Campeonato de Liga Atletismo 2026',
	'Liga de atletismo con múltiples series',
	NOW() + INTERVAL '8 days', NOW() + INTERVAL '100 days', 'inscripcion_abierta', 32,
	c.id_categoria, tt.id_tipo_torneo, u.id_usuario,
	'10,8,6,5,4,3,2,1', '{"dias":["martes","jueves","sabado"],"hora_inicio":"10:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Liga'
JOIN usuario u ON u.correo = 'organizador@app.com'
WHERE c.nombre = 'Atletismo'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- Torneo 6: Eliminación por Serie de Atletismo
INSERT INTO torneo (
	nombre, descripcion, fecha_inicio, fecha_fin, estado, limite_equipos,
	id_categoria, id_tipo_torneo, id_organizador,
	norma_puntuacion, preferencia_horario
)
SELECT
	'Competición Series Atletismo 2026',
	'Series con eliminación progresiva',
	NOW() + INTERVAL '12 days', NOW() + INTERVAL '60 days', 'inscripcion_abierta', 24,
	c.id_categoria, tt.id_tipo_torneo, u.id_usuario,
	'Clasificación por posición en serie', '{"dias":["lunes","miercoles"],"hora_inicio":"17:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Eliminación por serie'
JOIN usuario u ON u.correo = 'organizador@app.com'
WHERE c.nombre = 'Atletismo'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- Torneo 7: Serie + Final con Tiempos
INSERT INTO torneo (
	nombre, descripcion, fecha_inicio, fecha_fin, estado, limite_equipos,
	id_categoria, id_tipo_torneo, id_organizador,
	norma_puntuacion, preferencia_horario
)
SELECT
	'Campeonato Series y Final Atletismo 2026',
	'Series clasificatorias y final por mejores tiempos',
	NOW() + INTERVAL '20 days', NOW() + INTERVAL '50 days', 'inscripcion_abierta', 20,
	c.id_categoria, tt.id_tipo_torneo, u.id_usuario,
	'Mejor tiempo en final', '{"dias":["viernes","sabado"],"hora_inicio":"09:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Serie + final (con tiempos)'
JOIN usuario u ON u.correo = 'organizador@app.com'
WHERE c.nombre = 'Atletismo'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- Torneo 8: Eliminatorias por Rondas
INSERT INTO torneo (
	nombre, descripcion, fecha_inicio, fecha_fin, estado, limite_equipos,
	id_categoria, id_tipo_torneo, id_organizador,
	norma_puntuacion, preferencia_horario
)
SELECT
	'Eliminatorias Rondas Atletismo 2026',
	'Rondas sucesivas con clasificación por tiempos/puestos',
	NOW() + INTERVAL '6 days', NOW() + INTERVAL '75 days', 'inscripcion_abierta', 28,
	c.id_categoria, tt.id_tipo_torneo, u.id_usuario,
	'Clasificación por tiempos', '{"dias":["martes","viernes"],"hora_inicio":"15:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Eliminatorias por rondas'
JOIN usuario u ON u.correo = 'organizador@app.com'
WHERE c.nombre = 'Atletismo'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- Torneo 9: Eliminación Progresiva
INSERT INTO torneo (
	nombre, descripcion, fecha_inicio, fecha_fin, estado, limite_equipos,
	id_categoria, id_tipo_torneo, id_organizador,
	norma_puntuacion, preferencia_horario
)
SELECT
	'Torneo Eliminación Progresiva Atletismo 2026',
	'Cada ronda elimina un porcentaje de participantes',
	NOW() + INTERVAL '3 days', NOW() + INTERVAL '80 days', 'en_curso', 30,
	c.id_categoria, tt.id_tipo_torneo, u.id_usuario,
	'Mejor tiempo por ronda', '{"dias":["lunes","miercoles","viernes"],"hora_inicio":"16:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Eliminación progresiva'
JOIN usuario u ON u.correo = 'organizador@app.com'
WHERE c.nombre = 'Atletismo'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- =====================================================
-- TORNEOS: PARCHÍS (2 formatos)
-- =====================================================

-- Torneo 10: Eliminación por Serie
INSERT INTO torneo (
	nombre, descripcion, fecha_inicio, fecha_fin, estado, limite_equipos,
	id_categoria, id_tipo_torneo, id_organizador,
	norma_puntuacion, preferencia_horario
)
SELECT
	'Campeonato Series Parchís 2026',
	'Parchís con series y eliminación',
	NOW() + INTERVAL '9 days', NOW() + INTERVAL '55 days', 'inscripcion_abierta', 16,
	c.id_categoria, tt.id_tipo_torneo, u.id_usuario,
	'Puntuación por posición en partida', '{"dias":["viernes","sabado","domingo"],"hora_inicio":"18:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Eliminación por serie'
JOIN usuario u ON u.correo = 'organizador@app.com'
WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- Torneo 11: Eliminatorias por Rondas
INSERT INTO torneo (
	nombre, descripcion, fecha_inicio, fecha_fin, estado, limite_equipos,
	id_categoria, id_tipo_torneo, id_organizador,
	norma_puntuacion, preferencia_horario
)
SELECT
	'Copa Rondas Parchís 2026',
	'Rondas sucesivas de parchís',
	NOW() + INTERVAL '14 days', NOW() + INTERVAL '70 days', 'inscripcion_abierta', 20,
	c.id_categoria, tt.id_tipo_torneo, u.id_usuario,
	'Clasificación acumulada', '{"dias":["miercoles","domingo"],"hora_inicio":"19:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Eliminatorias por rondas'
JOIN usuario u ON u.correo = 'organizador@app.com'
WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO NOTHING;

-- =====================================================
-- ASIGNACIÓN DE ÁRBITROS A TORNEOS
-- =====================================================

INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT u.id_usuario, t.id_torneo
FROM usuario u
JOIN torneo t ON t.nombre LIKE '%Liga%' OR t.nombre LIKE '%Copa%' OR t.nombre LIKE '%Campeonato%' OR t.nombre LIKE '%Eliminación%' OR t.nombre LIKE '%Rondas%' OR t.nombre LIKE '%Series%'
WHERE u.correo IN ('arbitro1@app.com', 'arbitro2@app.com', 'arbitro3@app.com', 'arbitro4@app.com')
LIMIT 100  -- Para evitar demasiadas combinaciones
ON CONFLICT (id_usuario, id_torneo) DO NOTHING;

-- =====================================================
-- PARTICIPACIONES: INSCRIPCIÓN DE EQUIPOS EN TORNEOS
-- =====================================================

-- Fútbol 11 - Liga Profesional Primavera
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'pendiente', 0
FROM torneo t, equipo e
WHERE t.nombre = 'Liga Profesional Primavera 2026'
  AND e.id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'Fútbol 11')
  LIMIT 16
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Fútbol 11 - Copa del Rey Primavera
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'pendiente', 0
FROM torneo t, equipo e
WHERE t.nombre = 'Copa del Rey Primavera 2026'
  AND e.id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'Fútbol 11')
  LIMIT 8
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Baloncesto 5 - Liga ACB
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'pendiente', 0
FROM torneo t, equipo e
WHERE t.nombre = 'Liga ACB Primavera 2026'
  AND e.id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'Baloncesto 5')
  LIMIT 10
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Baloncesto 5 - Copa de la Reina
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'pendiente', 0
FROM torneo t, equipo e
WHERE t.nombre = 'Copa de la Reina Baloncesto 2026'
  AND e.id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'Baloncesto 5')
  LIMIT 8
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Atletismo - Liga
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'pendiente', 0
FROM torneo t, equipo e
WHERE t.nombre = 'Campeonato de Liga Atletismo 2026'
  AND e.id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'Atletismo')
  LIMIT 16
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Atletismo - Eliminación por Serie
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'pendiente', 0
FROM torneo t, equipo e
WHERE t.nombre = 'Competición Series Atletismo 2026'
  AND e.id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'Atletismo')
  LIMIT 12
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Atletismo - Serie + Final
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'pendiente', 0
FROM torneo t, equipo e
WHERE t.nombre = 'Campeonato Series y Final Atletismo 2026'
  AND e.id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'Atletismo')
  LIMIT 12
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Atletismo - Eliminatorias por Rondas
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'pendiente', 0
FROM torneo t, equipo e
WHERE t.nombre = 'Eliminatorias Rondas Atletismo 2026'
  AND e.id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'Atletismo')
  LIMIT 14
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Atletismo - Eliminación Progresiva
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'pendiente', 0
FROM torneo t, equipo e
WHERE t.nombre = 'Torneo Eliminación Progresiva Atletismo 2026'
  AND e.id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'Atletismo')
  LIMIT 16
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Parchís - Eliminación por Serie
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'pendiente', 0
FROM torneo t, equipo e
WHERE t.nombre = 'Campeonato Series Parchís 2026'
  AND e.id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'Parchís')
  LIMIT 12
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Parchís - Eliminatorias por Rondas
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, fecha, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, NOW(), 'pendiente', 0
FROM torneo t, equipo e
WHERE t.nombre = 'Copa Rondas Parchís 2026'
  AND e.id_categoria = (SELECT id_categoria FROM categoria WHERE nombre = 'Parchís')
  LIMIT 12
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

