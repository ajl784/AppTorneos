-- Script de setup para Liga Parchís
-- Ejecuta este script en tu BD antes de correr el test

-- Extensión requerida para cifrado
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Verificar/crear categoría Parchís (4 participantes por partido)
INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion)
VALUES ('Parchís', 4, '1;3;1', 'Categoría de parchís 4 participantes')
ON CONFLICT (nombre) DO NOTHING;

-- 2. Verificar/crear tipo de torneo Liga
INSERT INTO tipo_torneo (nombre, descripcion)
VALUES ('Liga', 'Torneo de liga (todos contra todos)')
ON CONFLICT (nombre) DO NOTHING;

-- 3. Verificar/crear relación categoria-tipo_torneo
INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
SELECT c.id_categoria, t.id_tipo_torneo
FROM categoria c
JOIN tipo_torneo t ON t.nombre = 'Liga'
WHERE c.nombre = 'Parchís'
ON CONFLICT (id_categoria, id_tipo_torneo) DO NOTHING;

-- 4. Crear usuarios para el torneo
-- Organizador
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES ('organizador_parchis@app.com', 'organizador_parchis',
        crypt('password123', gen_salt('bf')),
        'Organizador', 'Parchís')
ON CONFLICT (correo) DO NOTHING;

-- Árbitro
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES ('arbitro_parchis@app.com', 'arbitro_parchis',
        crypt('password123', gen_salt('bf')),
        'Árbitro', 'Parchís')
ON CONFLICT (correo) DO NOTHING;

-- 5. Crear equipos de prueba
INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT 'Equipo Parchís A', 'Equipo de prueba A', 1200, c.id_categoria
FROM categoria c WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT 'Equipo Parchís B', 'Equipo de prueba B', 1200, c.id_categoria
FROM categoria c WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT 'Equipo Parchís C', 'Equipo de prueba C', 1200, c.id_categoria
FROM categoria c WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT 'Equipo Parchís D', 'Equipo de prueba D', 1200, c.id_categoria
FROM categoria c WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT 'Equipo Parchís E', 'Equipo de prueba E', 1200, c.id_categoria
FROM categoria c WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT 'Equipo Parchís F', 'Equipo de prueba F', 1200, c.id_categoria
FROM categoria c WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT 'Equipo Parchís G', 'Equipo de prueba G', 1200, c.id_categoria
FROM categoria c WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT 'Equipo Parchís H', 'Equipo de prueba H', 1200, c.id_categoria
FROM categoria c WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT 'Equipo Parchís I', 'Equipo de prueba I', 1200, c.id_categoria
FROM categoria c WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT 'Equipo Parchís J', 'Equipo de prueba J', 1200, c.id_categoria
FROM categoria c WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT 'Equipo Parchís K', 'Equipo de prueba K', 1200, c.id_categoria
FROM categoria c WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
SELECT 'Equipo Parchís L', 'Equipo de prueba L', 1200, c.id_categoria
FROM categoria c WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre) DO NOTHING;

-- 6. Crear torneo Liga Parchís
INSERT INTO torneo (
  nombre, descripcion, fecha_inicio, fecha_fin, estado,
  limite_equipos, id_categoria, id_tipo_torneo, id_organizador,
  norma_puntuacion, tipo_generacion_enfrentamientos, preferencia_horario
)
SELECT 
  'Liga Parchís',
  'Liga de parchís para testing (4 participantes)',
  NOW() - INTERVAL '15 days',
  NOW() + INTERVAL '30 days',
  'inscripcion_cerrada',
  12,
  c.id_categoria,
  t.id_tipo_torneo,
  u.id_usuario,
  '1;3;1',
  'balanceada',
  '{"dias": ["lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo"]}'::jsonb
FROM categoria c
JOIN tipo_torneo t ON t.nombre = 'Liga'
JOIN usuario u ON u.correo = 'organizador_parchis@app.com'
WHERE c.nombre = 'Parchís'
ON CONFLICT (nombre, id_categoria, id_tipo_torneo) DO UPDATE SET
  estado = 'inscripcion_cerrada',
  fecha_inicio = NOW() - INTERVAL '15 days',
  fecha_fin = NOW() + INTERVAL '30 days',
  id_organizador = (SELECT id_usuario FROM usuario WHERE correo = 'organizador_parchis@app.com'),
  preferencia_horario = '{"dias": ["lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo"]}'::jsonb;

-- 7. Registrar equipos en el torneo con estado jugando
INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, puntuacion)
SELECT t.id_torneo, e.id_equipo, 'jugando', 0
FROM torneo t
JOIN equipo e ON e.id_categoria = t.id_categoria
WHERE t.nombre = 'Liga Parchís'
AND e.nombre IN (
  'Equipo Parchís A', 'Equipo Parchís B', 'Equipo Parchís C',
  'Equipo Parchís D', 'Equipo Parchís E', 'Equipo Parchís F',
  'Equipo Parchís G', 'Equipo Parchís H', 'Equipo Parchís I',
  'Equipo Parchís J', 'Equipo Parchís K', 'Equipo Parchís L'
)
ON CONFLICT (id_torneo, id_equipo) DO UPDATE SET
  estado = 'jugando';

-- 8. Registrar árbitro en el torneo
INSERT INTO arbitro_torneo (id_usuario, id_torneo)
SELECT u.id_usuario, t.id_torneo
FROM usuario u
JOIN torneo t ON t.nombre = 'Liga Parchís'
WHERE u.correo = 'arbitro_parchis@app.com'
ON CONFLICT (id_usuario, id_torneo) DO NOTHING;

-- Verificar setup
SELECT '=== LIGA PARCHÍS SETUP ===' as info;

SELECT t.nombre, t.estado, t.limite_equipos,
       COUNT(pte.id_participacion_equipo) as equipos,
       u.nombre as organizador
FROM torneo t
LEFT JOIN participacion_torneo_equipo pte ON pte.id_torneo = t.id_torneo
LEFT JOIN usuario u ON u.id_usuario = t.id_organizador
WHERE t.nombre = 'Liga Parchís'
GROUP BY t.id_torneo, t.nombre, t.estado, t.limite_equipos, u.nombre;

SELECT '✓ Usuarios creados:' as info;
SELECT correo, nombre, apellidos FROM usuario 
WHERE correo IN ('organizador_parchis@app.com', 'arbitro_parchis@app.com');

SELECT '✓ Equipos en torneo:' as info;
SELECT pte.estado, COUNT(*) as cantidad
FROM participacion_torneo_equipo pte
JOIN torneo t ON t.id_torneo = pte.id_torneo
WHERE t.nombre = 'Liga Parchís'
GROUP BY pte.estado;
