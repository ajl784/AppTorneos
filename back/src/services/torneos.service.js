const { pool } = require("../db/pool");

const listTorneos = async ({
  limit,
  offset,
  estado,
  organizadorId,
  categoriaId,
  tipoTorneoId,
}) => {
  const values = [limit, offset];
  const filters = [];

  if (estado) {
    values.push(estado);
    filters.push(`t.estado = $${values.length}`);
  }

  if (organizadorId) {
    values.push(organizadorId);
    filters.push(`t.id_organizador = $${values.length}`);
  }

  if (categoriaId) {
    values.push(categoriaId);
    filters.push(`t.id_categoria = $${values.length}`);
  }

  if (tipoTorneoId) {
    values.push(tipoTorneoId);
    filters.push(`t.id_tipo_torneo = $${values.length}`);
  }

  const where = filters.length ? `WHERE ${filters.join(" AND ")}` : "";

  const result = await pool.query(
    `SELECT
      t.id_torneo,
      t.nombre,
      t.descripcion,
      t.fecha_inicio,
      t.fecha_fin,
      t.estado,
      t.id_categoria,
      c.nombre AS categoria_nombre,
      t.id_tipo_torneo,
      tt.nombre AS tipo_torneo_nombre,
      t.id_organizador
     FROM torneo t
     JOIN categoria c ON c.id_categoria = t.id_categoria
     JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
     ${where}
     ORDER BY t.id_torneo DESC
     LIMIT $1 OFFSET $2`,
    values,
  );

  return result.rows;
};

const getTorneoById = async (idTorneo) => {
  const result = await pool.query(
    `SELECT
      t.id_torneo,
      t.nombre,
      t.descripcion,
      t.fecha_inicio,
      t.fecha_fin,
      t.estado,
      t.id_categoria,
      c.nombre AS categoria_nombre,
      t.id_tipo_torneo,
      tt.nombre AS tipo_torneo_nombre,
      t.id_organizador,
      t.encuesta,
      t.norma_puntuacion,
      t.preferencia_horario
     FROM torneo t
     JOIN categoria c ON c.id_categoria = t.id_categoria
     JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
     WHERE t.id_torneo = $1`,
    [idTorneo],
  );

  return result.rows[0] || null;
};

const createTorneo = async (payload) => {
  const result = await pool.query(
    `INSERT INTO torneo (
      nombre, descripcion, fecha_inicio, fecha_fin, estado,
      id_categoria, id_tipo_torneo, id_organizador,
      encuesta, norma_puntuacion, preferencia_horario
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb, $10, $11::jsonb)
     RETURNING id_torneo`,
    [
      payload.nombre,
      payload.descripcion || null,
      payload.fecha_inicio || null,
      payload.fecha_fin || null,
      payload.estado || "planificado",
      payload.id_categoria,
      payload.id_tipo_torneo,
      payload.id_organizador || null,
      payload.encuesta ? JSON.stringify(payload.encuesta) : null,
      payload.norma_puntuacion || null,
      payload.preferencia_horario
        ? JSON.stringify(payload.preferencia_horario)
        : null,
    ],
  );

  return getTorneoById(result.rows[0].id_torneo);
};

const updateTorneo = async (idTorneo, payload) => {
  const mapping = {
    nombre: "nombre",
    descripcion: "descripcion",
    fecha_inicio: "fecha_inicio",
    fecha_fin: "fecha_fin",
    estado: "estado",
    id_categoria: "id_categoria",
    id_tipo_torneo: "id_tipo_torneo",
    id_organizador: "id_organizador",
    norma_puntuacion: "norma_puntuacion",
  };

  const fields = [];
  const values = [];

  Object.keys(mapping).forEach((key) => {
    if (payload[key] !== undefined) {
      values.push(payload[key]);
      fields.push(`${mapping[key]} = $${values.length}`);
    }
  });

  if (payload.encuesta !== undefined) {
    values.push(payload.encuesta ? JSON.stringify(payload.encuesta) : null);
    fields.push(`encuesta = $${values.length}::jsonb`);
  }

  if (payload.preferencia_horario !== undefined) {
    values.push(
      payload.preferencia_horario
        ? JSON.stringify(payload.preferencia_horario)
        : null,
    );
    fields.push(`preferencia_horario = $${values.length}::jsonb`);
  }

  if (!fields.length) {
    return getTorneoById(idTorneo);
  }

  values.push(idTorneo);

  const result = await pool.query(
    `UPDATE torneo
     SET ${fields.join(", ")}
     WHERE id_torneo = $${values.length}
     RETURNING id_torneo`,
    values,
  );

  if (!result.rowCount) {
    return null;
  }

  return getTorneoById(idTorneo);
};

const deleteTorneo = async (idTorneo) => {
  const result = await pool.query(
    `DELETE FROM torneo
     WHERE id_torneo = $1
     RETURNING id_torneo`,
    [idTorneo],
  );

  return Boolean(result.rowCount);
};

const getFormularioByTorneoId = async (idTorneo) => {
  const result = await pool.query(
    `SELECT id_torneo, nombre, encuesta
     FROM torneo
     WHERE id_torneo = $1`,
    [idTorneo],
  );

  return result.rows[0] || null;
};

const updateFormularioByTorneoId = async (idTorneo, formulario) => {
  const result = await pool.query(
    `UPDATE torneo
     SET encuesta = $1::jsonb
     WHERE id_torneo = $2
     RETURNING id_torneo`,
    [formulario ? JSON.stringify(formulario) : null, idTorneo],
  );

  if (!result.rowCount) {
    return null;
  }

  return getFormularioByTorneoId(idTorneo);
};

module.exports = {
  listTorneos,
  getTorneoById,
  createTorneo,
  updateTorneo,
  deleteTorneo,
  getFormularioByTorneoId,
  updateFormularioByTorneoId,
};
