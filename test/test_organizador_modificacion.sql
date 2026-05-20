-- =====================================================
-- TEST: Rol Organizador - Modificación de Datos del Torneo
-- Pruebas para:
--  - Cambiar nombre de torneo (solo en inscripción_abierta)
--  - Cambiar fecha de partidos
--  - Eliminar equipos (con comportamiento diferente por formato)
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ========== PREPARACIÓN INICIAL ==========

-- 1. Crear categorías
INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion)
VALUES 
  ('Fútbol 11', 2, 'Reglas estándar', 'Partidos de equipos 1 vs 1'),
  ('Baloncesto 5', 2, 'Reglas estándar', 'Partidos de equipos 1 vs 1'),
  ('Atletismo', 8, 'Clasificacion por posicion/tiempo', 'Eventos con varias personas'),
  ('Parchís', 4, 'Puntuacion por posicion', 'Partidas de 4 participantes')
ON CONFLICT (nombre) DO NOTHING;

-- 2. Crear tipos de torneo
INSERT INTO tipo_torneo (nombre, descripcion)
VALUES
  ('Liga', 'Todos contra todos (puntos por victoria/empate)'),
  ('Eliminación directa', 'Bracket: el perdedor queda eliminado'),
  ('Eliminación por serie', 'Eliminación multi por bloques'),
  ('Serie + final (con tiempos)', 'Series y final por tiempos'),
  ('Eliminatorias por rondas', 'Rondas sucesivas'),
  ('Eliminación progresiva', 'Cada ronda elimina un porcentaje')
ON CONFLICT (nombre) DO NOTHING;

-- 3. Crear relaciones categoria-tipo_torneo
INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
SELECT c.id_categoria, tt.id_tipo_torneo
FROM categoria c
JOIN tipo_torneo tt ON (
  (c.nombre = 'Fútbol 11' AND tt.nombre IN ('Liga', 'Eliminación directa'))
  OR (c.nombre = 'Baloncesto 5' AND tt.nombre IN ('Liga', 'Eliminación directa'))
  OR (c.nombre = 'Atletismo' AND tt.nombre IN ('Liga', 'Eliminación por serie', 'Serie + final (con tiempos)', 'Eliminatorias por rondas', 'Eliminación progresiva'))
  OR (c.nombre = 'Parchís' AND tt.nombre IN ('Eliminación por serie', 'Eliminatorias por rondas'))
)
ON CONFLICT (id_categoria, id_tipo_torneo) DO NOTHING;

-- 4. Crear usuario organizador único
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES ('organizador@test.app', 'organizador_test', crypt('password123', gen_salt('bf')), 'Organizador', 'Test')
ON CONFLICT (correo) DO NOTHING;

-- 5. Crear árbitros
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES 
  ('arbitro1@test.app', 'arbitro1_test', crypt('password123', gen_salt('bf')), 'Árbitro', 'Uno'),
  ('arbitro2@test.app', 'arbitro2_test', crypt('password123', gen_salt('bf')), 'Árbitro', 'Dos')
ON CONFLICT (correo) DO NOTHING;

-- 6. Crear equipos para Fútbol 11 (Liga y Eliminación)
INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT v.nombre, v.descripcion, v.elo, c.id_categoria
FROM (
  VALUES
    ('FC Prueba A', 'Equipo de prueba A', 1200),
    ('FC Prueba B', 'Equipo de prueba B', 1200),
    ('FC Prueba C', 'Equipo de prueba C', 1200),
    ('FC Prueba D', 'Equipo de prueba D', 1200),
    ('FC Prueba E', 'Equipo de prueba E', 1200),
    ('FC Prueba F', 'Equipo de prueba F', 1200),
    ('FC Prueba G', 'Equipo de prueba G', 1200),
    ('FC Prueba H', 'Equipo de prueba H', 1200)
) AS v(nombre, descripcion, elo)
JOIN categoria c ON c.nombre = 'Fútbol 11'
ON CONFLICT (nombre) DO NOTHING;

-- 7. Crear equipos para Baloncesto (Liga)
INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT v.nombre, v.descripcion, v.elo, c.id_categoria
FROM (
  VALUES
    ('BC Prueba I', 'Equipo baloncesto I', 1200),
    ('BC Prueba J', 'Equipo baloncesto J', 1200),
    ('BC Prueba K', 'Equipo baloncesto K', 1200),
    ('BC Prueba L', 'Equipo baloncesto L', 1200),
    ('BC Prueba M', 'Equipo baloncesto M', 1200),
    ('BC Prueba N', 'Equipo baloncesto N', 1200)
) AS v(nombre, descripcion, elo)
JOIN categoria c ON c.nombre = 'Baloncesto 5'
ON CONFLICT (nombre) DO NOTHING;

-- 8. Crear equipos para Atletismo (Serie + final)
INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT v.nombre, v.descripcion, v.elo, c.id_categoria
FROM (
  VALUES
    ('Atletismo A', 'Equipo atletismo A', 1200),
    ('Atletismo B', 'Equipo atletismo B', 1200),
    ('Atletismo C', 'Equipo atletismo C', 1200),
    ('Atletismo D', 'Equipo atletismo D', 1200),
    ('Atletismo E', 'Equipo atletismo E', 1200),
    ('Atletismo F', 'Equipo atletismo F', 1200),
    ('Atletismo G', 'Equipo atletismo G', 1200),
    ('Atletismo H', 'Equipo atletismo H', 1200)
) AS v(nombre, descripcion, elo)
JOIN categoria c ON c.nombre = 'Atletismo'
ON CONFLICT (nombre) DO NOTHING;

-- 9. Crear equipos para Parchís (Eliminación por serie)
INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT v.nombre, v.descripcion, v.elo, c.id_categoria
FROM (
  VALUES
    ('Parchís A', 'Equipo parchís A', 1200),
    ('Parchís B', 'Equipo parchís B', 1200),
    ('Parchís C', 'Equipo parchís C', 1200),
    ('Parchís D', 'Equipo parchís D', 1200),
    ('Parchís E', 'Equipo parchís E', 1200),
    ('Parchís F', 'Equipo parchís F', 1200),
    ('Parchís G', 'Equipo parchís G', 1200),
    ('Parchís H', 'Equipo parchís H', 1200)
) AS v(nombre, descripcion, elo)
JOIN categoria c ON c.nombre = 'Parchís'
ON CONFLICT (nombre) DO NOTHING;

-- ========== CREAR TORNEOS ==========

-- TORNEO 1: Liga de Fútbol 11
INSERT INTO torneo (
  nombre, descripcion, fecha_inicio, fecha_fin, estado,
  limite_equipos, id_categoria, id_tipo_torneo, id_organizador,
  norma_puntuacion, preferencia_horario
)
SELECT
  'Liga Fútbol Modificación Test',
  'Liga para probar cambios de nombre y fecha',
  NOW() + INTERVAL '7 days',
  NOW() + INTERVAL '37 days',
  'inscripcion_abierta',
  8,
  c.id_categoria,
  tt.id_tipo_torneo,
  u.id_usuario,
  '3-1-0',
  '{"dias":["sabado"],"hora_inicio":"10:00","hora_fin":"14:00"}'::jsonb
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Liga'
JOIN usuario u ON u.correo = 'organizador@test.app'
WHERE c.nombre = 'Fútbol 11'
ON CONFLICT DO NOTHING;

-- TORNEO 2: Eliminación Directa de Fútbol 11
INSERT INTO torneo (
  nombre, descripcion, fecha_inicio, fecha_fin, estado,
  limite_equipos, id_categoria, id_tipo_torneo, id_organizador
)
SELECT
  'Eliminación Directa Fútbol Test',
  'Torneo eliminación para probar eliminación de equipos',
  NOW() + INTERVAL '2 days',
  NOW() + INTERVAL '14 days',
  'inscripcion_abierta',
  8,
  c.id_categoria,
  tt.id_tipo_torneo,
  u.id_usuario
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Eliminación directa'
JOIN usuario u ON u.correo = 'organizador@test.app'
WHERE c.nombre = 'Fútbol 11'
ON CONFLICT DO NOTHING;

-- TORNEO 3: Liga de Baloncesto
INSERT INTO torneo (
  nombre, descripcion, fecha_inicio, fecha_fin, estado,
  limite_equipos, id_categoria, id_tipo_torneo, id_organizador,
  norma_puntuacion
)
SELECT
  'Liga Baloncesto Modificación Test',
  'Liga de baloncesto para probar cambios',
  NOW() + INTERVAL '5 days',
  NOW() + INTERVAL '30 days',
  'inscripcion_abierta',
  6,
  c.id_categoria,
  tt.id_tipo_torneo,
  u.id_usuario,
  '2-1-0'
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Liga'
JOIN usuario u ON u.correo = 'organizador@test.app'
WHERE c.nombre = 'Baloncesto 5'
ON CONFLICT DO NOTHING;

-- TORNEO 4: Serie + Final de Atletismo
INSERT INTO torneo (
  nombre, descripcion, fecha_inicio, fecha_fin, estado,
  limite_equipos, id_categoria, id_tipo_torneo, id_organizador
)
SELECT
  'Atletismo Serie Final Test',
  'Atletismo con series y final',
  NOW() + INTERVAL '10 days',
  NOW() + INTERVAL '25 days',
  'inscripcion_abierta',
  8,
  c.id_categoria,
  tt.id_tipo_torneo,
  u.id_usuario
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Serie + final (con tiempos)'
JOIN usuario u ON u.correo = 'organizador@test.app'
WHERE c.nombre = 'Atletismo'
ON CONFLICT DO NOTHING;

-- TORNEO 5: Eliminación por Serie de Parchís
INSERT INTO torneo (
  nombre, descripcion, fecha_inicio, fecha_fin, estado,
  limite_equipos, id_categoria, id_tipo_torneo, id_organizador
)
SELECT
  'Parchís Eliminación Serie Test',
  'Parchís con eliminación por serie',
  NOW() + INTERVAL '3 days',
  NOW() + INTERVAL '20 days',
  'inscripcion_abierta',
  8,
  c.id_categoria,
  tt.id_tipo_torneo,
  u.id_usuario
FROM categoria c
JOIN tipo_torneo tt ON tt.nombre = 'Eliminación por serie'
JOIN usuario u ON u.correo = 'organizador@test.app'
WHERE c.nombre = 'Parchís'
ON CONFLICT DO NOTHING;

-- ========== REGISTRAR EQUIPOS EN TORNEOS ==========

-- Equipos en Liga Fútbol
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, 'jugando', 0
FROM torneo t
JOIN equipo e ON e.id_categoria = t.id_categoria
WHERE t.nombre = 'Liga Fútbol Modificación Test'
  AND e.nombre IN ('FC Prueba A', 'FC Prueba B', 'FC Prueba C', 'FC Prueba D',
                    'FC Prueba E', 'FC Prueba F', 'FC Prueba G', 'FC Prueba H')
ON CONFLICT DO NOTHING;

-- Equipos en Eliminación Directa
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, 'jugando', 0
FROM torneo t
JOIN equipo e ON e.id_categoria = t.id_categoria
WHERE t.nombre = 'Eliminación Directa Fútbol Test'
  AND e.nombre IN ('FC Prueba A', 'FC Prueba B', 'FC Prueba C', 'FC Prueba D',
                    'FC Prueba E', 'FC Prueba F', 'FC Prueba G', 'FC Prueba H')
ON CONFLICT DO NOTHING;

-- Equipos en Liga Baloncesto
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, 'jugando', 0
FROM torneo t
JOIN equipo e ON e.id_categoria = t.id_categoria
WHERE t.nombre = 'Liga Baloncesto Modificación Test'
  AND e.nombre IN ('BC Prueba I', 'BC Prueba J', 'BC Prueba K', 'BC Prueba L', 'BC Prueba M', 'BC Prueba N')
ON CONFLICT DO NOTHING;

-- Equipos en Atletismo
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, 'jugando', 0
FROM torneo t
JOIN equipo e ON e.id_categoria = t.id_categoria
WHERE t.nombre = 'Atletismo Serie Final Test'
  AND e.nombre IN ('Atletismo A', 'Atletismo B', 'Atletismo C', 'Atletismo D',
                    'Atletismo E', 'Atletismo F', 'Atletismo G', 'Atletismo H')
ON CONFLICT DO NOTHING;

-- Equipos en Parchís
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, 'jugando', 0
FROM torneo t
JOIN equipo e ON e.id_categoria = t.id_categoria
WHERE t.nombre = 'Parchís Eliminación Serie Test'
  AND e.nombre IN ('Parchís A', 'Parchís B', 'Parchís C', 'Parchís D',
                    'Parchís E', 'Parchís F', 'Parchís G', 'Parchís H')
ON CONFLICT DO NOTHING;

-- ========== REGISTRAR ÁRBITROS ==========

INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT u.id_usuario, t.id_torneo
FROM usuario u
JOIN torneo t ON TRUE
WHERE u.correo IN ('arbitro1@test.app', 'arbitro2@test.app')
  AND t.nombre IN (
    'Liga Fútbol Modificación Test',
    'Eliminación Directa Fútbol Test',
    'Liga Baloncesto Modificación Test',
    'Atletismo Serie Final Test',
    'Parchís Eliminación Serie Test'
  )
ON CONFLICT DO NOTHING;

-- ========== PRUEBAS: CAMBIAR NOMBRE DE TORNEO ==========

SELECT '=== PRUEBA 1: CAMBIAR NOMBRE DE TORNEO ===' as test;

-- Estado inicial: inscripcion_abierta (DEBE PERMITIR)
SELECT t.id_torneo, t.nombre, t.estado FROM torneo t
WHERE t.nombre = 'Liga Fútbol Modificación Test';

-- Simular cambio de nombre (SQL directo)
UPDATE torneo SET nombre = 'Liga Fútbol Modificación Test - RENOMBRADO'
WHERE nombre = 'Liga Fútbol Modificación Test';

SELECT '✓ Nombre actualizado' as result;
SELECT t.id_torneo, t.nombre, t.estado FROM torneo t
WHERE nombre LIKE 'Liga Fútbol%RENOMBRADO%';

-- Cambiar estado a inscripcion_cerrada
UPDATE torneo SET estado = 'inscripcion_cerrada'
WHERE nombre LIKE 'Liga Fútbol%RENOMBRADO%';

-- Intentar cambiar nombre en estado inscripcion_cerrada (DEBE FALLAR en API)
SELECT 'NOTA: En API, cambio de nombre en inscripcion_cerrada debería rechazarse' as note;

-- ========== PRUEBAS: GENERAR PARTIDOS Y CAMBIAR FECHAS ==========

SELECT '=== PRUEBA 2: CAMBIAR FECHA DE PARTIDOS ===' as test;

-- Crear algunos partidos de prueba en Liga Fútbol
INSERT INTO partido (id_torneo, fecha_hora, estado)
SELECT t.id_torneo, NOW() + INTERVAL '7 days', 'planificado'
FROM torneo t
WHERE t.nombre LIKE 'Liga Fútbol%RENOMBRADO%'
LIMIT 3;

-- Ver partidos creados
SELECT p.id_partido, t.nombre, p.fecha_hora, p.estado
FROM partido p
JOIN torneo t ON t.id_torneo = p.id_torneo
WHERE t.nombre LIKE 'Liga Fútbol%RENOMBRADO%'
ORDER BY p.id_partido;

-- Simular cambio de fecha en un partido
UPDATE partido
SET fecha_hora = NOW() + INTERVAL '10 days'
WHERE id_torneo IN (SELECT id_torneo FROM torneo WHERE nombre LIKE 'Liga Fútbol%RENOMBRADO%')
LIMIT 1;

SELECT '✓ Fechas de partidos actualizadas' as result;

-- ========== PRUEBAS: ELIMINAR EQUIPOS EN LIGA ==========

SELECT '=== PRUEBA 3: ELIMINAR EQUIPO EN LIGA ===' as test;

-- Obtener ID del torneo Liga Baloncesto y un equipo
WITH torneo_data AS (
  SELECT t.id_torneo, t.nombre FROM torneo t
  WHERE t.nombre = 'Liga Baloncesto Modificación Test'
),
equipo_participando AS (
  SELECT pte.id_participacion_equipo, pte.id_equipo, e.nombre as equipo_nombre
  FROM participacion_torneo_equipo pte
  JOIN equipo e ON e.id_equipo = pte.id_equipo
  JOIN torneo_data td ON td.id_torneo = pte.id_torneo
  LIMIT 1
)
SELECT 'Equipo a eliminar:' as info,
       ep.id_participacion_equipo, ep.id_equipo, ep.equipo_nombre
FROM equipo_participando ep;

-- Contar equipos antes
SELECT COUNT(*) as equipos_antes
FROM participacion_torneo_equipo pte
JOIN torneo t ON t.id_torneo = pte.id_torneo
WHERE t.nombre = 'Liga Baloncesto Modificación Test'
  AND pte.estado = 'jugando';

-- Eliminar un equipo (simular acción)
UPDATE participacion_torneo_equipo
SET estado = 'eliminado'
WHERE id_participacion_equipo IN (
  SELECT pte.id_participacion_equipo
  FROM participacion_torneo_equipo pte
  JOIN torneo t ON t.id_torneo = pte.id_torneo
  WHERE t.nombre = 'Liga Baloncesto Modificación Test'
  LIMIT 1
);

SELECT '✓ Equipo eliminado y estado actualizado a eliminado' as result;

-- Contar equipos después
SELECT COUNT(*) as equipos_despues
FROM participacion_torneo_equipo pte
JOIN torneo t ON t.id_torneo = pte.id_torneo
WHERE t.nombre = 'Liga Baloncesto Modificación Test'
  AND pte.estado = 'jugando';

-- ========== VERIFICACIÓN FINAL ==========

SELECT '=== RESUMEN DE PRUEBAS ===' as summary;

SELECT '1. Torneos creados:' as test_group;
SELECT COUNT(*) as total FROM torneo
WHERE id_organizador = (SELECT id_usuario FROM usuario WHERE correo = 'organizador@test.app');

SELECT '2. Equipos totales registrados:' as test_group;
SELECT COUNT(*) as total FROM participacion_torneo_equipo pte
WHERE pte.id_torneo IN (
  SELECT id_torneo FROM torneo
  WHERE id_organizador = (SELECT id_usuario FROM usuario WHERE correo = 'organizador@test.app')
);

SELECT '3. Partidos creados:' as test_group;
SELECT COUNT(*) as total FROM partido p
WHERE p.id_torneo IN (
  SELECT id_torneo FROM torneo
  WHERE id_organizador = (SELECT id_usuario FROM usuario WHERE correo = 'organizador@test.app')
);

SELECT '✓ SETUP COMPLETO - LISTO PARA PRUEBAS API' as final_message;
