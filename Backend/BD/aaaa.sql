-- Añade dos usuarios de prueba y los vincula a equipos existentes
-- Usuario 1: pertenece a 'Equipo Atletismo A'
-- Usuario 2: pertenece a 'Equipo Parchís A'

-- Crear usuarios (contraseña: password123)
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES ('usuario_atletismo_test@app.com', 'usuario_atletismo', crypt('password123', gen_salt('bf')), 'Jugador', 'Atletismo')
ON CONFLICT (correo) DO NOTHING;

INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES ('usuario_parchis_test@app.com', 'usuario_parchis', crypt('password123', gen_salt('bf')), 'Jugador', 'Parchís')
ON CONFLICT (correo) DO NOTHING;

-- Vincular usuarios a equipos existentes
-- Insertar pertenencia de usuario Atletismo a Equipo Atletismo A si no existe
-- Nota: la tabla `pertenece` requiere `fecha_inicio` NOT NULL; usamos CURRENT_DATE
-- Vincula al primer equipo disponible de la categoría 'atletismo' (si existe)
INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, sub.id_equipo, CURRENT_DATE
FROM usuario u
JOIN (
	SELECT id_equipo FROM equipo
	WHERE id_categoria = (
		SELECT id_categoria FROM categoria WHERE nombre = 'atletismo' LIMIT 1
	)
	ORDER BY id_equipo
	LIMIT 1
) sub ON true
WHERE u.correo = 'usuario_atletismo_test@app.com'
AND NOT EXISTS (
	SELECT 1 FROM pertenece p
	WHERE p.id_usuario = u.id_usuario AND p.id_equipo = sub.id_equipo AND p.fecha_fin IS NULL
);

-- Insertar pertenencia de usuario Parchís a Equipo Parchís A si no existe
-- Vincula al primer equipo disponible de la categoría 'Parchís' (si existe)
INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, sub.id_equipo, CURRENT_DATE
FROM usuario u
JOIN (
	SELECT id_equipo FROM equipo
	WHERE id_categoria = (
		SELECT id_categoria FROM categoria WHERE nombre = 'Parchís' LIMIT 1
	)
	ORDER BY id_equipo
	LIMIT 1
) sub ON true
WHERE u.correo = 'usuario_parchis_test@app.com'
AND NOT EXISTS (
	SELECT 1 FROM pertenece p
	WHERE p.id_usuario = u.id_usuario AND p.id_equipo = sub.id_equipo AND p.fecha_fin IS NULL
);

-- Salida rápida para verificar
SELECT 'usuarios_insertados' AS info, correo, nombre_usuario FROM usuario
WHERE correo IN ('usuario_atletismo_test@app.com','usuario_parchis_test@app.com');

-- ---------------------------------------------
-- Mover usuario_atletismo_test@app.com a Equipo Atletismo 03
-- 1) Cerrar pertenencias activas (fecha_fin = CURRENT_DATE)
-- 2) Insertar nueva pertenencia hacia 'Equipo Atletismo 03' o 'ATLETISMO-TEAM-03' si existe
-- ---------------------------------------------

-- Cerrar pertenencias activas
UPDATE pertenece
SET fecha_fin = CURRENT_DATE
WHERE id_usuario = (
	SELECT id_usuario FROM usuario WHERE correo = 'usuario_atletismo_test@app.com' LIMIT 1
) AND fecha_fin IS NULL;

-- Insertar nueva pertenencia al equipo objetivo si existe y no hay ya una activa

WITH target AS (
	SELECT id_equipo FROM equipo
	WHERE nombre IN ('Equipo Atletismo 08', 'Equipo Atletismo 08', 'ATLETISMO-TEAM-08')
	LIMIT 1
)
INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio)
SELECT u.id_usuario, t.id_equipo, CURRENT_DATE
FROM usuario u CROSS JOIN target t
WHERE u.correo = 'usuario_atletismo_test@app.com'
AND NOT EXISTS (
	SELECT 1 FROM pertenece p
	WHERE p.id_usuario = u.id_usuario AND p.id_equipo = t.id_equipo AND p.fecha_fin IS NULL
);

-- Resultado para verificar movimiento
SELECT 'mover_result' AS info,
	(SELECT id_equipo FROM pertenece p JOIN usuario u ON u.id_usuario = p.id_usuario WHERE u.correo = 'usuario_atletismo_test@app.com' AND p.fecha_fin IS NULL LIMIT 1) AS equipo_actual_id;

