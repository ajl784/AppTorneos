const { pool } = require("../db/pool");
const notificacionesService = require('./notificaciones.service');

const listParticipaciones = async ({
  limit,
  offset,
  torneoId,
  equipoId,
  estado,
}) => {
  const values = [limit, offset];
  const filters = [];

  if (torneoId) {
    values.push(torneoId);
    filters.push(`p.id_torneo = $${values.length}`);
  }

  if (equipoId) {
    values.push(equipoId);
    filters.push(`p.id_equipo = $${values.length}`);
  }

  if (estado) {
    values.push(estado);
    filters.push(`p.estado = $${values.length}`);
  }

  const where = filters.length ? `WHERE ${filters.join(" AND ")}` : "";

  const result = await pool.query(
    `SELECT
      p.id_participacion_equipo,
      p.id_torneo,
      t.nombre AS torneo_nombre,
      p.id_equipo,
      e.nombre AS equipo_nombre,
      p.fecha,
      p.respuesta,
      p.estado,
      p.puntuacion
     FROM participacion_torneo_equipo p
     JOIN torneo t ON t.id_torneo = p.id_torneo
     JOIN equipo e ON e.id_equipo = p.id_equipo
     ${where}
     ORDER BY p.id_participacion_equipo DESC
     LIMIT $1 OFFSET $2`,
    values,
  );

  return result.rows;
};

const getParticipacionById = async (idParticipacionEquipo) => {
  const result = await pool.query(
    `SELECT
      p.id_participacion_equipo,
      p.id_torneo,
      t.nombre AS torneo_nombre,
      p.id_equipo,
      e.nombre AS equipo_nombre,
      p.fecha,
      p.respuesta,
      p.estado,
      p.puntuacion
     FROM participacion_torneo_equipo p
     JOIN torneo t ON t.id_torneo = p.id_torneo
     JOIN equipo e ON e.id_equipo = p.id_equipo
     WHERE p.id_participacion_equipo = $1`,
    [idParticipacionEquipo],
  );

  return result.rows[0] || null;
};

const createParticipacion = async ({
  id_torneo,
  id_equipo,
  respuesta,
  estado,
  puntuacion,
}) => {
  const result = await pool.query(
    `INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, respuesta, estado, puntuacion)
     VALUES ($1, $2, $3::jsonb, $4, $5)
     RETURNING id_participacion_equipo`,
    [
      id_torneo,
      id_equipo,
      respuesta ? JSON.stringify(respuesta) : null,
      estado || "pendiente",
      puntuacion ?? 0,
    ],
  );

  return getParticipacionById(result.rows[0].id_participacion_equipo);
};

const updateParticipacion = async (idParticipacionEquipo, payload) => {
  const mapping = {
    id_torneo: "id_torneo",
    id_equipo: "id_equipo",
    estado: "estado",
    puntuacion: "puntuacion",
  };

  const fields = [];
  const values = [];

  Object.keys(mapping).forEach((key) => {
    if (payload[key] !== undefined) {
      values.push(payload[key]);
      fields.push(`${mapping[key]} = $${values.length}`);
    }
  });

  if (payload.respuesta !== undefined) {
    values.push(payload.respuesta ? JSON.stringify(payload.respuesta) : null);
    fields.push(`respuesta = $${values.length}::jsonb`);
  }

  if (!fields.length) {
    return getParticipacionById(idParticipacionEquipo);
  }

  values.push(idParticipacionEquipo);

  const result = await pool.query(
    `UPDATE participacion_torneo_equipo
     SET ${fields.join(", ")}
     WHERE id_participacion_equipo = $${values.length}
     RETURNING id_participacion_equipo`,
    values,
  );

  if (!result.rowCount) {
    return null;
  }

  return getParticipacionById(idParticipacionEquipo);
};

const deleteParticipacion = async (idParticipacionEquipo) => {
  const result = await pool.query(
    `DELETE FROM participacion_torneo_equipo
     WHERE id_participacion_equipo = $1
     RETURNING id_participacion_equipo`,
    [idParticipacionEquipo],
  );

  return Boolean(result.rowCount);
};

const listSolicitudesByTorneo = async ({ idTorneo, estado }) => {
  const values = [idTorneo];
  let whereEstado = "";

  if (estado) {
    values.push(estado);
    whereEstado = `AND p.estado = $${values.length}`;
  }

  const result = await pool.query(
    `SELECT
      p.id_participacion_equipo,
      p.id_torneo,
      t.nombre AS torneo_nombre,
      p.id_equipo,
      e.nombre AS equipo_nombre,
      p.fecha,
      p.respuesta,
      p.estado,
      p.puntuacion
     FROM participacion_torneo_equipo p
     JOIN torneo t ON t.id_torneo = p.id_torneo
     JOIN equipo e ON e.id_equipo = p.id_equipo
     WHERE p.id_torneo = $1
       ${whereEstado}
     ORDER BY p.id_participacion_equipo DESC`,
    values,
  );

  return result.rows;
};

/*const createSolicitudByTorneo = async ({ idTorneo, idEquipo, respuesta }) => {
  const result = await pool.query(
    `INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, respuesta, estado, puntuacion)
     VALUES ($1, $2, $3::jsonb, 'pendiente', 0)
     RETURNING id_participacion_equipo`,
    [idTorneo, idEquipo, respuesta ? JSON.stringify(respuesta) : null],
  );

  return getParticipacionById(result.rows[0].id_participacion_equipo);
};*/

const createSolicitudByTorneo = async ({ idTorneo, idEquipo, respuesta }) => {
  // Iniciar transacción (opcional pero recomendado)
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Insertar la solicitud
    const insertResult = await client.query(
      `INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, respuesta, estado, puntuacion)
       VALUES ($1, $2, $3::jsonb, 'pendiente', 0)
       RETURNING id_participacion_equipo`,
      [idTorneo, idEquipo, respuesta ? JSON.stringify(respuesta) : null]
    );
    const idParticipacion = insertResult.rows[0].id_participacion_equipo;

    // 2. Obtener datos del torneo (nombre y dueño)
    const torneoResult = await client.query(
      `SELECT nombre, id_organizador FROM torneo WHERE id_torneo = $1`,
      [idTorneo]
    );
    if (torneoResult.rows.length === 0) {
      throw new Error('Torneo no encontrado');
    }
    const { nombre: nombreTorneo, id_organizador: idOwner } = torneoResult.rows[0];

    // 3. Obtener nombre del equipo
    const equipoResult = await client.query(
      `SELECT nombre FROM equipo WHERE id_equipo = $1`,
      [idEquipo]
    );
    if (equipoResult.rows.length === 0) {
      throw new Error('Equipo no encontrado');
    }
    const nombreEquipo = equipoResult.rows[0].nombre;

    // 4. Crear la notificación para el dueño del torneo
    const notificacionData = {
      id_usuario_destino: idOwner,
      tipo: 'solicitud_equipo',
      titulo: `Solicitud de unión al torneo ${nombreTorneo}`,
      mensaje: `El equipo "${nombreEquipo}" ha solicitado unirse a tu torneo "${nombreTorneo}"`,
      datos: JSON.stringify({ id_torneo: idTorneo, id_equipo: idEquipo, id_participacion: idParticipacion })
    };
    await notificacionesService.crearNotificacion(notificacionData);

    await client.query('COMMIT');

    // 5. Retornar la participación completa (usando la función auxiliar)
    return getParticipacionById(idParticipacion);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};


const decideSolicitud = async ({ idParticipacionEquipo, aceptar }) => {
  const estado = aceptar ? "jugando" : "eliminado";

  const result = await pool.query(
    `UPDATE participacion_torneo_equipo
     SET estado = $1
     WHERE id_participacion_equipo = $2
     RETURNING id_participacion_equipo`,
    [estado, idParticipacionEquipo],
  );

  if (!result.rowCount) {
    return null;
  }

  return getParticipacionById(idParticipacionEquipo);
};

module.exports = {
  listParticipaciones,
  getParticipacionById,
  createParticipacion,
  updateParticipacion,
  deleteParticipacion,
  listSolicitudesByTorneo,
  createSolicitudByTorneo,
  decideSolicitud,
};
