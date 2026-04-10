const { pool } = require("../db/pool");

const listEquipos = async ({ limit, offset, nombre }) => {
  const values = [limit, offset];
  let where = "";

  if (nombre) {
    values.push(`%${nombre}%`);
    where = `WHERE nombre ILIKE $${values.length}`;
  }

  const result = await pool.query(
    `SELECT id_equipo, nombre, descripcion, elo
     FROM equipo
     ${where}
     ORDER BY id_equipo DESC
     LIMIT $1 OFFSET $2`,
    values,
  );

  return result.rows;
};

const getEquipoById = async (idEquipo) => {
  const result = await pool.query(
    `SELECT id_equipo, nombre, descripcion, elo
     FROM equipo
     WHERE id_equipo = $1`,
    [idEquipo],
  );

  return result.rows[0] || null;
};

const createEquipo = async ({ nombre, descripcion, elo }) => {
  const result = await pool.query(
    `INSERT INTO equipo (nombre, descripcion, elo)
     VALUES ($1, $2, $3)
     RETURNING id_equipo, nombre, descripcion, elo`,
    [nombre, descripcion || null, elo ?? 1200],
  );

  return result.rows[0];
};

const updateEquipo = async (idEquipo, payload) => {
  const fields = [];
  const values = [];

  if (payload.nombre !== undefined) {
    values.push(payload.nombre);
    fields.push(`nombre = $${values.length}`);
  }

  if (payload.descripcion !== undefined) {
    values.push(payload.descripcion);
    fields.push(`descripcion = $${values.length}`);
  }

  if (payload.elo !== undefined) {
    values.push(payload.elo);
    fields.push(`elo = $${values.length}`);
  }

  if (!fields.length) {
    return getEquipoById(idEquipo);
  }

  values.push(idEquipo);

  const result = await pool.query(
    `UPDATE equipo
     SET ${fields.join(", ")}
     WHERE id_equipo = $${values.length}
     RETURNING id_equipo, nombre, descripcion, elo`,
    values,
  );

  return result.rows[0] || null;
};

const deleteEquipo = async (idEquipo) => {
  const result = await pool.query(
    `DELETE FROM equipo
     WHERE id_equipo = $1
     RETURNING id_equipo`,
    [idEquipo],
  );

  return Boolean(result.rowCount);
};

module.exports = {
  listEquipos,
  getEquipoById,
  createEquipo,
  updateEquipo,
  deleteEquipo,
};
