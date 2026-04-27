BEGIN;

-- =====================================================
-- Datos de ejemplo para probar la pantalla de destacados
-- =====================================================

INSERT INTO tipo_torneo (id_tipo_torneo, nombre, descripcion) VALUES
	(1, 'Liga', 'Formato de liga a puntos'),
	(2, 'Eliminación directa', 'Bracket de eliminación directa')
ON CONFLICT (id_tipo_torneo) DO NOTHING;

INSERT INTO categoria (id_categoria, nombre, participantes_por_partida, norma, descripcion) VALUES
	(1, 'Atletismo', 2, 'Puntuación por prueba', 'Categoría de pruebas atléticas'),
	(2, 'Baloncesto', 5, 'Puntos por partido', 'Categoría de baloncesto'),
	(3, 'Fútbol', 11, 'Victoria, empate y derrota', 'Categoría de fútbol')
ON CONFLICT (id_categoria) DO NOTHING;

INSERT INTO categoria_tipo_torneo (id_categoria_tipo_torneo, id_categoria, id_tipo_torneo) VALUES
	(1, 1, 1),
	(2, 1, 2),
	(3, 2, 1),
	(4, 2, 2),
	(5, 3, 1),
	(6, 3, 2)
ON CONFLICT (id_categoria, id_tipo_torneo) DO NOTHING;

INSERT INTO usuario (id_usuario, correo, nombre_usuario, password_hash, nombre, apellidos, genero) VALUES
	(1, 'entrenador.atletismo@example.com', 'coach_atletismo', 'seed', 'Mario', 'Luna', 'masculino'),
	(2, 'entrenador.baloncesto@example.com', 'coach_baloncesto', 'seed', 'Ana', 'Rojas', 'femenino'),
	(3, 'entrenador.futbol@example.com', 'coach_futbol', 'seed', 'Pablo', 'Costa', 'masculino')
ON CONFLICT (id_usuario) DO NOTHING;

-- Cada equipo pertenece a una sola categoría.
INSERT INTO equipo (id_equipo, nombre, descripcion, elo, id_categoria) VALUES
	(1, 'Veloces del Sur', 'Equipo referente de atletismo', 1860, 1),
	(2, 'Ritmo de Pista', 'Especialistas en pruebas cortas', 1775, 1),
	(3, 'Saltadores del Norte', 'Equipo polivalente de atletismo', 1690, 1),
	(4, 'Canastas Doradas', 'Equipo sólido de baloncesto', 1915, 2),
	(5, 'Triple Clan', 'Equipo muy ofensivo', 1820, 2),
	(6, 'Zona Pintada', 'Defensa y rebote', 1740, 2),
	(7, 'Balón Férreo', 'Equipo fuerte en fútbol', 1980, 3),
	(8, 'Contraataque FC', 'Transiciones rápidas', 1885, 3),
	(9, 'Tiki Taka Club', 'Posesión y control', 1810, 3)
ON CONFLICT (id_equipo) DO NOTHING;

INSERT INTO pertenece (id_pertenece, id_usuario, id_equipo, fecha_inicio, fecha_fin) VALUES
	(1, 1, 1, '2025-01-01', NULL),
	(2, 1, 2, '2025-01-01', NULL),
	(3, 1, 3, '2025-01-01', NULL),
	(4, 2, 4, '2025-01-01', NULL),
	(5, 2, 5, '2025-01-01', NULL),
	(6, 2, 6, '2025-01-01', NULL),
	(7, 3, 7, '2025-01-01', NULL),
	(8, 3, 8, '2025-01-01', NULL),
	(9, 3, 9, '2025-01-01', NULL)
ON CONFLICT (id_usuario, id_equipo, fecha_inicio) DO NOTHING;

INSERT INTO entrenador_equipo (id_entrenador, id_usuario, id_equipo, fecha_inicio, fecha_fin) VALUES
	(1, 1, 1, '2025-01-01', NULL),
	(2, 1, 2, '2025-01-01', NULL),
	(3, 1, 3, '2025-01-01', NULL),
	(4, 2, 4, '2025-01-01', NULL),
	(5, 2, 5, '2025-01-01', NULL),
	(6, 2, 6, '2025-01-01', NULL),
	(7, 3, 7, '2025-01-01', NULL),
	(8, 3, 8, '2025-01-01', NULL),
	(9, 3, 9, '2025-01-01', NULL)
ON CONFLICT (id_usuario, id_equipo, fecha_inicio) DO NOTHING;

INSERT INTO torneo (
	id_torneo, nombre, descripcion, fecha_inicio, fecha_fin, estado,
	limite_equipos, id_categoria, id_tipo_torneo, id_organizador,
	norma_puntuacion, tipo_generacion_enfrentamientos
) VALUES
	(1, 'Copa Atletismo Primavera', 'Primer torneo de atletismo', '2025-03-01 10:00:00+00', '2025-03-15 10:00:00+00', 'acabado', 8, 1, 1, 1, '3 puntos victoria / 1 empate', 'rotacion'),
	(2, 'Trofeo Atletismo Otoño', 'Segundo torneo de atletismo', '2025-09-01 10:00:00+00', '2025-09-15 10:00:00+00', 'acabado', 8, 1, 2, 1, '3 puntos victoria / 1 empate', 'balanceada'),
	(3, 'Liga Baloncesto Costa', 'Liga de baloncesto de temporada', '2025-04-01 10:00:00+00', '2025-05-15 10:00:00+00', 'acabado', 6, 2, 1, 2, '2 puntos victoria / 0 derrota', 'rotacion'),
	(4, 'Copa Baloncesto Verano', 'Copa corta de baloncesto', '2025-08-01 10:00:00+00', '2025-08-20 10:00:00+00', 'acabado', 6, 2, 2, 2, '2 puntos victoria / 0 derrota', 'balanceada'),
	(5, 'Liga Futbol Norte', 'Liga principal de fútbol', '2025-02-01 10:00:00+00', '2025-04-30 10:00:00+00', 'acabado', 10, 3, 1, 3, '3 puntos victoria / 1 empate', 'rotacion'),
	(6, 'Copa Futbol Verano', 'Copa de fútbol de eliminación', '2025-07-01 10:00:00+00', '2025-07-18 10:00:00+00', 'acabado', 10, 3, 2, 3, '3 puntos victoria / 1 empate', 'balanceada')
ON CONFLICT (id_torneo) DO NOTHING;

-- Participaciones por categoría en varios torneos de la misma categoría.
INSERT INTO participacion_torneo_equipo (
	id_participacion_equipo, id_torneo, id_equipo, fecha, respuesta, estado, puntuacion
) VALUES
	(1, 1, 1, '2025-03-01 12:00:00+00', NULL, 'jugando', 12),
	(2, 1, 2, '2025-03-01 12:00:00+00', NULL, 'jugando', 9),
	(3, 1, 3, '2025-03-01 12:00:00+00', NULL, 'eliminado', 6),
	(4, 2, 1, '2025-09-01 12:00:00+00', NULL, 'jugando', 15),
	(5, 2, 2, '2025-09-01 12:00:00+00', NULL, 'jugando', 11),
	(6, 2, 3, '2025-09-01 12:00:00+00', NULL, 'suspendido', 4),
	(7, 3, 4, '2025-04-01 12:00:00+00', NULL, 'jugando', 18),
	(8, 3, 5, '2025-04-01 12:00:00+00', NULL, 'jugando', 16),
	(9, 3, 6, '2025-04-01 12:00:00+00', NULL, 'eliminado', 10),
	(10, 4, 4, '2025-08-01 12:00:00+00', NULL, 'jugando', 21),
	(11, 4, 5, '2025-08-01 12:00:00+00', NULL, 'jugando', 19),
	(12, 4, 6, '2025-08-01 12:00:00+00', NULL, 'suspendido', 8),
	(13, 5, 7, '2025-02-01 12:00:00+00', NULL, 'jugando', 24),
	(14, 5, 8, '2025-02-01 12:00:00+00', NULL, 'jugando', 20),
	(15, 5, 9, '2025-02-01 12:00:00+00', NULL, 'eliminado', 14),
	(16, 6, 7, '2025-07-01 12:00:00+00', NULL, 'jugando', 27),
	(17, 6, 8, '2025-07-01 12:00:00+00', NULL, 'jugando', 22),
	(18, 6, 9, '2025-07-01 12:00:00+00', NULL, 'suspendido', 12)
ON CONFLICT (id_torneo, id_equipo) DO NOTHING;

-- Historial de ELO para que la gráfica del modal tenga evolución.
INSERT INTO historial_elo (id_historial_elo, id_equipo, elo_anterior, elo_nuevo, descripcion, creado_en) VALUES
	(1, 1, 1700, 1730, 'Sube tras la Copa Atletismo Primavera', '2025-03-15 10:00:00+00'),
	(2, 1, 1730, 1785, 'Gran actuación en el Trofeo Atletismo Otoño', '2025-09-15 10:00:00+00'),
	(3, 2, 1650, 1690, 'Mejora en la Copa Atletismo Primavera', '2025-03-15 10:00:00+00'),
	(4, 2, 1690, 1740, 'Regularidad en el Trofeo Atletismo Otoño', '2025-09-15 10:00:00+00'),
	(13, 4, 1620, 1660, 'Inicio de temporada regular', '2024-10-05 10:00:00+00'),
	(14, 4, 1660, 1705, 'Mejora en bloque ofensivo', '2024-11-18 10:00:00+00'),
	(15, 4, 1705, 1740, 'Victoria contra rival directo', '2024-12-10 10:00:00+00'),
	(16, 4, 1740, 1775, 'Consistencia en fase de grupos', '2025-01-20 10:00:00+00'),
	(17, 4, 1775, 1800, 'Buen cierre de primera vuelta', '2025-03-01 10:00:00+00'),
	(5, 4, 1800, 1855, 'Dominio en la Liga Baloncesto Costa', '2025-05-15 10:00:00+00'),
	(6, 4, 1855, 1915, 'Cierra fuerte la Copa Baloncesto Verano', '2025-08-20 10:00:00+00'),
	(7, 5, 1760, 1795, 'Ascenso en la Liga Baloncesto Costa', '2025-05-15 10:00:00+00'),
	(8, 5, 1795, 1820, 'Mantiene nivel en Copa Baloncesto Verano', '2025-08-20 10:00:00+00'),
	(18, 7, 1710, 1755, 'Ajustes tácticos de inicio', '2024-09-20 10:00:00+00'),
	(19, 7, 1755, 1790, 'Mejora defensiva notable', '2024-10-25 10:00:00+00'),
	(20, 7, 1790, 1835, 'Racha de victorias consecutivas', '2024-12-01 10:00:00+00'),
	(21, 7, 1835, 1870, 'Clasificación asegurada', '2025-01-15 10:00:00+00'),
	(22, 7, 1870, 1900, 'Dominio en tramos decisivos', '2025-03-10 10:00:00+00'),
	(9, 7, 1900, 1945, 'Arranque sólido en Liga Futbol Norte', '2025-04-30 10:00:00+00'),
	(10, 7, 1945, 1980, 'Se corona en la Copa Futbol Verano', '2025-07-18 10:00:00+00'),
	(23, 8, 1640, 1680, 'Adaptación al nuevo sistema', '2024-09-28 10:00:00+00'),
	(24, 8, 1680, 1720, 'Bloque medio muy sólido', '2024-11-02 10:00:00+00'),
	(25, 8, 1720, 1755, 'Mejoras en ataque posicional', '2024-12-12 10:00:00+00'),
	(26, 8, 1755, 1785, 'Buena fase regular', '2025-01-26 10:00:00+00'),
	(27, 8, 1785, 1825, 'Impulso antes del torneo principal', '2025-03-18 10:00:00+00'),
	(11, 8, 1825, 1850, 'Buen inicio en Liga Futbol Norte', '2025-04-30 10:00:00+00'),
	(12, 8, 1850, 1885, 'Suma puntos en Copa Futbol Verano', '2025-07-18 10:00:00+00')
ON CONFLICT (id_historial_elo) DO NOTHING;

SELECT setval(pg_get_serial_sequence('tipo_torneo', 'id_tipo_torneo'), (SELECT COALESCE(MAX(id_tipo_torneo), 1) FROM tipo_torneo), true);
SELECT setval(pg_get_serial_sequence('categoria', 'id_categoria'), (SELECT COALESCE(MAX(id_categoria), 1) FROM categoria), true);
SELECT setval(pg_get_serial_sequence('categoria_tipo_torneo', 'id_categoria_tipo_torneo'), (SELECT COALESCE(MAX(id_categoria_tipo_torneo), 1) FROM categoria_tipo_torneo), true);
SELECT setval(pg_get_serial_sequence('usuario', 'id_usuario'), (SELECT COALESCE(MAX(id_usuario), 1) FROM usuario), true);
SELECT setval(pg_get_serial_sequence('equipo', 'id_equipo'), (SELECT COALESCE(MAX(id_equipo), 1) FROM equipo), true);
SELECT setval(pg_get_serial_sequence('pertenece', 'id_pertenece'), (SELECT COALESCE(MAX(id_pertenece), 1) FROM pertenece), true);
SELECT setval(pg_get_serial_sequence('entrenador_equipo', 'id_entrenador'), (SELECT COALESCE(MAX(id_entrenador), 1) FROM entrenador_equipo), true);
SELECT setval(pg_get_serial_sequence('torneo', 'id_torneo'), (SELECT COALESCE(MAX(id_torneo), 1) FROM torneo), true);
SELECT setval(pg_get_serial_sequence('participacion_torneo_equipo', 'id_participacion_equipo'), (SELECT COALESCE(MAX(id_participacion_equipo), 1) FROM participacion_torneo_equipo), true);
SELECT setval(pg_get_serial_sequence('historial_elo', 'id_historial_elo'), (SELECT COALESCE(MAX(id_historial_elo), 1) FROM historial_elo), true);

COMMIT;
