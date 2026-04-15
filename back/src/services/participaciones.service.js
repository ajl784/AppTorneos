const { pool } = require("../db/pool");
const { AppError } = require("../utils/errors");

const assertNoUsuariosEnEquiposDelTorneo = async ({ idTorneo, idEquipo }) => {
  const conflicto = await pool.query(
    `SELECT DISTINCT
        u.id_usuario,
        u.nombre_usuario,
        p_conf.id_equipo AS id_equipo_conflicto,
        e_conf.nombre AS equipo_conflicto_nombre,
        pte.estado AS estado_conflicto
     FROM pertenece p_new
     JOIN pertenece p_conf
       ON p_conf.id_usuario = p_new.id_usuario
      AND p_conf.fecha_fin IS NULL
      AND p_conf.id_equipo <> p_new.id_equipo
     JOIN participacion_torneo_equipo pte
       ON pte.id_equipo = p_conf.id_equipo
      AND pte.id_torneo = $1
      AND pte.estado IN ('pendiente', 'jugando')
     JOIN usuario u
       ON u.id_usuario = p_new.id_usuario
     JOIN equipo e_conf
       ON e_conf.id_equipo = p_conf.id_equipo
     WHERE p_new.id_equipo = $2
       AND p_new.fecha_fin IS NULL
     ORDER BY u.id_usuario ASC
     LIMIT 10`,
    [idTorneo, idEquipo],
  );

  if (conflicto.rowCount) {
    throw new AppError(
      409,
      "No se puede inscribir el equipo: hay usuarios que ya participan o tienen solicitud pendiente en este torneo con otro equipo",
      {
        id_torneo: idTorneo,
        id_equipo: idEquipo,
        conflictos: conflicto.rows,
      },
    );
  }
};

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
  await assertNoUsuariosEnEquiposDelTorneo({
    idTorneo: id_torneo,
    idEquipo: id_equipo,
  });

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

const createSolicitudByTorneo = async ({ idTorneo, idEquipo, respuesta }) => {
  await assertNoUsuariosEnEquiposDelTorneo({
    idTorneo,
    idEquipo,
  });

  const result = await pool.query(
    `INSERT INTO participacion_torneo_equipo (id_torneo, id_equipo, respuesta, estado, puntuacion)
     VALUES ($1, $2, $3::jsonb, 'pendiente', 0)
     RETURNING id_participacion_equipo`,
    [idTorneo, idEquipo, respuesta ? JSON.stringify(respuesta) : null],
  );

  return getParticipacionById(result.rows[0].id_participacion_equipo);
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
