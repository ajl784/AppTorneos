BEGIN;

TRUNCATE TABLE
	arbitro_partido,
	participacion_partido,
	partido,
	arbitro_torneo,
	participacion_torneo_equipo,
	invitacion,
	notificacion,
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
