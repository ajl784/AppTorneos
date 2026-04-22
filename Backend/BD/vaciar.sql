BEGIN;

TRUNCATE TABLE
	arbitro_partido,
	participacion_partido,
	partido,
	participacion_torneo_equipo,
	arbitro_torneo,
	solicitud_equipo,
	entrenador_equipo,
	pertenece,
	historial_elo,
	torneo,
	equipo,
	usuario,
	categoria_tipo_torneo,
	categoria,
	tipo_torneo
RESTART IDENTITY CASCADE;

COMMIT;
