-- =====================================================
-- Demo: Torneo de eliminación por serie (16 equipos) con organizador y árbitros
-- Base: esquema en Backend/BD/bdr
-- Motor: PostgreSQL
--
-- Qué crea:
-- - tipo_torneo + categoria + categoria_tipo_torneo
-- - 1 organizador + 3 árbitros (tabla usuario)
-- - 16 equipos (tabla equipo)
-- - 1 torneo (tabla torneo)
-- - árbitros asignados al torneo (arbitro_torneo)
-- - participaciones de equipos (participacion_torneo_equipo)
-- - bracket eliminación por serie (mejor de 3):
--   4 partidas de ronda 1 (4 equipos por partida, 3 juegos c/u) + 1 final (4 equipos, 3 juegos)
-- - equipos asignados a cada partido (participacion_partido)
-- - árbitro asignado a cada partido (arbitro_partido)
--
-- Nota: es re-ejecutable; si el torneo ya existe, lo reutiliza y
--       borra/recrea todos los partidos de ese torneo.
-- =====================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  v_id_tipo_torneo BIGINT;
  v_id_categoria BIGINT;
  v_id_torneo BIGINT;

  v_id_org BIGINT;
  v_id_ref1 BIGINT;
  v_id_ref2 BIGINT;
  v_id_ref3 BIGINT;

  v_id_arbt1 BIGINT;
  v_id_arbt2 BIGINT;
  v_id_arbt3 BIGINT;

  v_eq1 BIGINT; v_eq2 BIGINT; v_eq3 BIGINT; v_eq4 BIGINT;
  v_eq5 BIGINT; v_eq6 BIGINT; v_eq7 BIGINT; v_eq8 BIGINT;
  v_eq9 BIGINT; v_eq10 BIGINT; v_eq11 BIGINT; v_eq12 BIGINT;
  v_eq13 BIGINT; v_eq14 BIGINT; v_eq15 BIGINT; v_eq16 BIGINT;

  v_pt1 BIGINT; v_pt2 BIGINT; v_pt3 BIGINT; v_pt4 BIGINT;
  v_pt5 BIGINT; v_pt6 BIGINT; v_pt7 BIGINT; v_pt8 BIGINT;
  v_pt9 BIGINT; v_pt10 BIGINT; v_pt11 BIGINT; v_pt12 BIGINT;
  v_pt13 BIGINT; v_pt14 BIGINT; v_pt15 BIGINT; v_pt16 BIGINT;

  v_qf1_g1 BIGINT; v_qf1_g2 BIGINT; v_qf1_g3 BIGINT;
  v_qf2_g1 BIGINT; v_qf2_g2 BIGINT; v_qf2_g3 BIGINT;
  v_qf3_g1 BIGINT; v_qf3_g2 BIGINT; v_qf3_g3 BIGINT;
  v_qf4_g1 BIGINT; v_qf4_g2 BIGINT; v_qf4_g3 BIGINT;

  v_final_g1 BIGINT; v_final_g2 BIGINT; v_final_g3 BIGINT;

  v_now TIMESTAMPTZ := date_trunc('minute', now());
BEGIN
  -- 1) Catálogos
  INSERT INTO tipo_torneo (nombre, descripcion)
  VALUES ('Eliminación por serie', 'Eliminación directa por rondas; cada cruce se juega como serie (mejor de 3).')
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion
  RETURNING id_tipo_torneo INTO v_id_tipo_torneo;

  INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion, icono)
  VALUES ('Parchís', 4, 'Partida a 4 equipos', 'Categoría demo para partidas de 4 contrincantes.', NULL)
  ON CONFLICT (nombre)
  DO UPDATE SET
    participantes_por_partida = EXCLUDED.participantes_por_partida,
    norma = EXCLUDED.norma,
    descripcion = EXCLUDED.descripcion,
    icono = EXCLUDED.icono
  RETURNING id_categoria INTO v_id_categoria;

  INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
  VALUES (v_id_categoria, v_id_tipo_torneo)
  ON CONFLICT (id_categoria, id_tipo_torneo)
  DO NOTHING;

  -- 2) Usuarios (organizador y árbitros)
  INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos, genero)
  VALUES (
    'organizador@app.local',
    'organizador_demo',
    crypt('Organizador123', gen_salt('bf')),
    'Alex',
    'Organizador',
    'otro'
  )
  ON CONFLICT (correo)
  DO UPDATE SET
    nombre_usuario = EXCLUDED.nombre_usuario,
    password_hash = EXCLUDED.password_hash,
    nombre = EXCLUDED.nombre,
    apellidos = EXCLUDED.apellidos,
    genero = EXCLUDED.genero
  RETURNING id_usuario INTO v_id_org;

  INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos, genero)
  VALUES (
    'arbitro1@app.local',
    'arbitro_demo_1',
    crypt('Arbitro123', gen_salt('bf')),
    'Sam',
    'Árbitro Uno',
    'otro'
  )
  ON CONFLICT (correo)
  DO UPDATE SET
    nombre_usuario = EXCLUDED.nombre_usuario,
    password_hash = EXCLUDED.password_hash,
    nombre = EXCLUDED.nombre,
    apellidos = EXCLUDED.apellidos,
    genero = EXCLUDED.genero
  RETURNING id_usuario INTO v_id_ref1;

  INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos, genero)
  VALUES (
    'arbitro2@app.local',
    'arbitro_demo_2',
    crypt('Arbitro123', gen_salt('bf')),
    'Taylor',
    'Árbitro Dos',
    'otro'
  )
  ON CONFLICT (correo)
  DO UPDATE SET
    nombre_usuario = EXCLUDED.nombre_usuario,
    password_hash = EXCLUDED.password_hash,
    nombre = EXCLUDED.nombre,
    apellidos = EXCLUDED.apellidos,
    genero = EXCLUDED.genero
  RETURNING id_usuario INTO v_id_ref2;

  INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos, genero)
  VALUES (
    'arbitro3@app.local',
    'arbitro_demo_3',
    crypt('Arbitro123', gen_salt('bf')),
    'Jordan',
    'Árbitro Tres',
    'otro'
  )
  ON CONFLICT (correo)
  DO UPDATE SET
    nombre_usuario = EXCLUDED.nombre_usuario,
    password_hash = EXCLUDED.password_hash,
    nombre = EXCLUDED.nombre,
    apellidos = EXCLUDED.apellidos,
    genero = EXCLUDED.genero
  RETURNING id_usuario INTO v_id_ref3;

  -- 3) Equipos (16)
  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Halcones FC', 'Equipo demo 1', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq1;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Tigres FC', 'Equipo demo 2', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq2;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Lobos FC', 'Equipo demo 3', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq3;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Panteras FC', 'Equipo demo 4', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq4;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Águilas FC', 'Equipo demo 5', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq5;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Búhos FC', 'Equipo demo 6', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq6;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Toros FC', 'Equipo demo 7', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq7;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Osos FC', 'Equipo demo 8', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq8;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Leones FC', 'Equipo demo 9', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq9;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Delfines FC', 'Equipo demo 10', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq10;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Zorros FC', 'Equipo demo 11', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq11;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Gacelas FC', 'Equipo demo 12', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq12;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Cóndores FC', 'Equipo demo 13', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq13;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Rinocerontes FC', 'Equipo demo 14', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq14;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Chacales FC', 'Equipo demo 15', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq15;

  INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
  VALUES ('Mapaches FC', 'Equipo demo 16', 1200, v_id_categoria)
  ON CONFLICT (nombre)
  DO UPDATE SET descripcion = EXCLUDED.descripcion, elo = EXCLUDED.elo, id_categoria = EXCLUDED.id_categoria
  RETURNING id_equipo INTO v_eq16;

  -- 4) Torneo
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
    tipo_generacion_enfrentamientos
  )
  VALUES (
    'Copa Eliminación Demo',
    'Torneo demo de eliminación por serie (partidas de 4 equipos).',
    v_now + interval '1 day',
    v_now + interval '4 days',
    'en_curso',
    16,
    v_id_categoria,
    v_id_tipo_torneo,
    v_id_org,
    'Victoria: 1, Derrota: 0 (demo)',
    NULL
  )
  ON CONFLICT (nombre, id_categoria, id_tipo_torneo)
  DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    fecha_inicio = EXCLUDED.fecha_inicio,
    fecha_fin = EXCLUDED.fecha_fin,
    estado = EXCLUDED.estado,
    limite_equipos = EXCLUDED.limite_equipos,
    id_organizador = EXCLUDED.id_organizador,
    norma_puntuacion = EXCLUDED.norma_puntuacion,
    tipo_generacion_enfrentamientos = EXCLUDED.tipo_generacion_enfrentamientos
  RETURNING id_torneo INTO v_id_torneo;

  -- 5) Árbitros asignados al torneo
  INSERT INTO arbitro_torneo (id_usuario, id_torneo)
  VALUES (v_id_ref1, v_id_torneo)
  ON CONFLICT (id_usuario, id_torneo)
  DO UPDATE SET id_usuario = EXCLUDED.id_usuario
  RETURNING id_arbitro_torneo INTO v_id_arbt1;

  INSERT INTO arbitro_torneo (id_usuario, id_torneo)
  VALUES (v_id_ref2, v_id_torneo)
  ON CONFLICT (id_usuario, id_torneo)
  DO UPDATE SET id_usuario = EXCLUDED.id_usuario
  RETURNING id_arbitro_torneo INTO v_id_arbt2;

  INSERT INTO arbitro_torneo (id_usuario, id_torneo)
  VALUES (v_id_ref3, v_id_torneo)
  ON CONFLICT (id_usuario, id_torneo)
  DO UPDATE SET id_usuario = EXCLUDED.id_usuario
  RETURNING id_arbitro_torneo INTO v_id_arbt3;

  -- 6) Participaciones de equipos en el torneo
  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq1, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt1;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq2, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt2;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq3, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt3;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq4, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt4;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq5, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt5;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq6, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt6;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq7, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt7;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq8, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt8;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq9, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt9;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq10, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt10;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq11, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt11;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq12, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt12;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq13, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt13;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq14, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt14;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq15, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt15;

  INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, estado, respuesta, puntuacion)
  VALUES (v_id_torneo, v_eq16, 'jugando', '{}'::jsonb, 0)
  ON CONFLICT (id_torneo, id_equipo)
  DO UPDATE SET estado = EXCLUDED.estado, respuesta = EXCLUDED.respuesta, puntuacion = EXCLUDED.puntuacion
  RETURNING id_participacion_equipo INTO v_pt16;

  -- 7) Bracket eliminación: se borra y se recrea (idempotente)
  DELETE FROM partido WHERE id_torneo = v_id_torneo;

  -- =====================================================
  -- Eliminación por serie (mejor de 3)
  -- Convención: cada cruce es 3 partidos (g1/g2/g3).
  -- Para mantener el bracket, todos los partidos de un cruce apuntan a
  -- la primera partida (g1) del cruce siguiente.
  -- orden_ronda codifica (cruce*10 + juego). Ej: cruce 2 juego 3 => 23.
  -- =====================================================

  -- Final (ronda 2) - 1 cruce => orden 11,12,13
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda)
  VALUES (v_id_torneo, v_now + interval '3 days' + interval '18 hours', 'Campo Central', 'planificado', 2, 2, 11)
  RETURNING id_partido INTO v_final_g1;

  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda)
  VALUES (v_id_torneo, v_now + interval '3 days' + interval '20 hours', 'Campo Central', 'planificado', 2, 2, 12)
  RETURNING id_partido INTO v_final_g2;

  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda)
  VALUES (v_id_torneo, v_now + interval '4 days' + interval '18 hours', 'Campo Central', 'planificado', 2, 2, 13)
  RETURNING id_partido INTO v_final_g3;

  -- Cuartos (ronda 1) - 4 cruces => orden 11-13,21-23,31-33,41-43
  -- QF1 -> Final
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda, id_partido_siguiente)
  VALUES (v_id_torneo, v_now + interval '1 day' + interval '18 hours', 'Campo 1', 'planificado', 1, 1, 11, v_final_g1)
  RETURNING id_partido INTO v_qf1_g1;
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda, id_partido_siguiente)
  VALUES (v_id_torneo, v_now + interval '1 day' + interval '20 hours', 'Campo 1', 'planificado', 1, 1, 12, v_final_g1)
  RETURNING id_partido INTO v_qf1_g2;
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda, id_partido_siguiente)
  VALUES (v_id_torneo, v_now + interval '2 days' + interval '10 hours', 'Campo 1', 'planificado', 1, 1, 13, v_final_g1)
  RETURNING id_partido INTO v_qf1_g3;

  -- QF2 -> Final
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda, id_partido_siguiente)
  VALUES (v_id_torneo, v_now + interval '1 day' + interval '18 hours', 'Campo 2', 'planificado', 1, 1, 21, v_final_g1)
  RETURNING id_partido INTO v_qf2_g1;
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda, id_partido_siguiente)
  VALUES (v_id_torneo, v_now + interval '1 day' + interval '20 hours', 'Campo 2', 'planificado', 1, 1, 22, v_final_g1)
  RETURNING id_partido INTO v_qf2_g2;
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda, id_partido_siguiente)
  VALUES (v_id_torneo, v_now + interval '2 days' + interval '10 hours', 'Campo 2', 'planificado', 1, 1, 23, v_final_g1)
  RETURNING id_partido INTO v_qf2_g3;

  -- QF3 -> Final
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda, id_partido_siguiente)
  VALUES (v_id_torneo, v_now + interval '1 day' + interval '22 hours', 'Campo 3', 'planificado', 1, 1, 31, v_final_g1)
  RETURNING id_partido INTO v_qf3_g1;
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda, id_partido_siguiente)
  VALUES (v_id_torneo, v_now + interval '2 days' + interval '12 hours', 'Campo 3', 'planificado', 1, 1, 32, v_final_g1)
  RETURNING id_partido INTO v_qf3_g2;
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda, id_partido_siguiente)
  VALUES (v_id_torneo, v_now + interval '2 days' + interval '22 hours', 'Campo 3', 'planificado', 1, 1, 33, v_final_g1)
  RETURNING id_partido INTO v_qf3_g3;

  -- QF4 -> Final
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda, id_partido_siguiente)
  VALUES (v_id_torneo, v_now + interval '2 days' + interval '10 hours', 'Campo 4', 'planificado', 1, 1, 41, v_final_g1)
  RETURNING id_partido INTO v_qf4_g1;
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda, id_partido_siguiente)
  VALUES (v_id_torneo, v_now + interval '2 days' + interval '12 hours', 'Campo 4', 'planificado', 1, 1, 42, v_final_g1)
  RETURNING id_partido INTO v_qf4_g2;
  INSERT INTO partido (id_torneo, fecha_hora, lugar, estado, jornada, ronda, orden_ronda, id_partido_siguiente)
  VALUES (v_id_torneo, v_now + interval '2 days' + interval '22 hours', 'Campo 4', 'planificado', 1, 1, 43, v_final_g1)
  RETURNING id_partido INTO v_qf4_g3;

  -- 8) Equipos en cada partido (se repiten por juego dentro de la serie)
  INSERT INTO participacion_partido (id_partido, id_participacion_equipo, punto)
  VALUES
    -- Ronda 1 (4 equipos por partida, mejor de 3)
    -- QF1: v_pt1, v_pt2, v_pt3, v_pt4
    (v_qf1_g1, v_pt1, 0), (v_qf1_g1, v_pt2, 0), (v_qf1_g1, v_pt3, 0), (v_qf1_g1, v_pt4, 0),
    (v_qf1_g2, v_pt1, 0), (v_qf1_g2, v_pt2, 0), (v_qf1_g2, v_pt3, 0), (v_qf1_g2, v_pt4, 0),
    (v_qf1_g3, v_pt1, 0), (v_qf1_g3, v_pt2, 0), (v_qf1_g3, v_pt3, 0), (v_qf1_g3, v_pt4, 0),

    -- QF2: v_pt5, v_pt6, v_pt7, v_pt8
    (v_qf2_g1, v_pt5, 0), (v_qf2_g1, v_pt6, 0), (v_qf2_g1, v_pt7, 0), (v_qf2_g1, v_pt8, 0),
    (v_qf2_g2, v_pt5, 0), (v_qf2_g2, v_pt6, 0), (v_qf2_g2, v_pt7, 0), (v_qf2_g2, v_pt8, 0),
    (v_qf2_g3, v_pt5, 0), (v_qf2_g3, v_pt6, 0), (v_qf2_g3, v_pt7, 0), (v_qf2_g3, v_pt8, 0),

    -- QF3: v_pt9, v_pt10, v_pt11, v_pt12
    (v_qf3_g1, v_pt9, 0), (v_qf3_g1, v_pt10, 0), (v_qf3_g1, v_pt11, 0), (v_qf3_g1, v_pt12, 0),
    (v_qf3_g2, v_pt9, 0), (v_qf3_g2, v_pt10, 0), (v_qf3_g2, v_pt11, 0), (v_qf3_g2, v_pt12, 0),
    (v_qf3_g3, v_pt9, 0), (v_qf3_g3, v_pt10, 0), (v_qf3_g3, v_pt11, 0), (v_qf3_g3, v_pt12, 0),

    -- QF4: v_pt13, v_pt14, v_pt15, v_pt16
    (v_qf4_g1, v_pt13, 0), (v_qf4_g1, v_pt14, 0), (v_qf4_g1, v_pt15, 0), (v_qf4_g1, v_pt16, 0),
    (v_qf4_g2, v_pt13, 0), (v_qf4_g2, v_pt14, 0), (v_qf4_g2, v_pt15, 0), (v_qf4_g2, v_pt16, 0),
    (v_qf4_g3, v_pt13, 0), (v_qf4_g3, v_pt14, 0), (v_qf4_g3, v_pt15, 0), (v_qf4_g3, v_pt16, 0),

    -- Final (demo placeholder): ganadores de QF1/QF2/QF3/QF4
    -- Usamos como placeholder: v_pt1, v_pt5, v_pt9, v_pt13
    (v_final_g1, v_pt1, 0), (v_final_g1, v_pt5, 0), (v_final_g1, v_pt9, 0), (v_final_g1, v_pt13, 0),
    (v_final_g2, v_pt1, 0), (v_final_g2, v_pt5, 0), (v_final_g2, v_pt9, 0), (v_final_g2, v_pt13, 0),
    (v_final_g3, v_pt1, 0), (v_final_g3, v_pt5, 0), (v_final_g3, v_pt9, 0), (v_final_g3, v_pt13, 0)
  ON CONFLICT (id_partido, id_participacion_equipo)
  DO UPDATE SET punto = EXCLUDED.punto;

  -- 9) Árbitro por partido (rotación simple)
  INSERT INTO arbitro_partido (id_partido, id_arbitro_torneo, acta)
  VALUES
    (v_qf1_g1, v_id_arbt1, '{}'::jsonb), (v_qf1_g2, v_id_arbt2, '{}'::jsonb), (v_qf1_g3, v_id_arbt3, '{}'::jsonb),
    (v_qf2_g1, v_id_arbt2, '{}'::jsonb), (v_qf2_g2, v_id_arbt3, '{}'::jsonb), (v_qf2_g3, v_id_arbt1, '{}'::jsonb),
    (v_qf3_g1, v_id_arbt3, '{}'::jsonb), (v_qf3_g2, v_id_arbt1, '{}'::jsonb), (v_qf3_g3, v_id_arbt2, '{}'::jsonb),
    (v_qf4_g1, v_id_arbt1, '{}'::jsonb), (v_qf4_g2, v_id_arbt2, '{}'::jsonb), (v_qf4_g3, v_id_arbt3, '{}'::jsonb),

    (v_final_g1, v_id_arbt1, '{}'::jsonb), (v_final_g2, v_id_arbt2, '{}'::jsonb), (v_final_g3, v_id_arbt3, '{}'::jsonb)
  ON CONFLICT (id_partido, id_arbitro_torneo)
  DO UPDATE SET acta = EXCLUDED.acta;

  RAISE NOTICE 'Demo creado/actualizado. Torneo id=%', v_id_torneo;
END $$;

COMMIT;
