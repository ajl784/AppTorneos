const { pool } = require("../db/pool");

const listUsuarios = async ({ limit, offset, q }) => {
  const values = [limit, offset];
  let where = "";

  if (q) {
    values.push(`%${q}%`);
    where = `WHERE correo ILIKE $${values.length} OR nombre_usuario ILIKE $${values.length}`;
  }

  const result = await pool.query(
    `SELECT id_usuario, correo, nombre_usuario
     FROM usuario
     ${where}
     ORDER BY id_usuario DESC
     LIMIT $1 OFFSET $2`,
    values,
  );

  return result.rows;
};

const getUsuarioById = async (idUsuario) => {
  const result = await pool.query(
    `SELECT id_usuario, correo, nombre_usuario
     FROM usuario
     WHERE id_usuario = $1`,
    [idUsuario],
  );

  return result.rows[0] || null;
};

const createUsuario = async ({ correo, nombre_usuario, password }) => {
  const result = await pool.query(
    `INSERT INTO usuario (correo, nombre_usuario, password_hash)
     VALUES ($1, $2, crypt($3, gen_salt('bf')))
     RETURNING id_usuario, correo, nombre_usuario`,
    [correo, nombre_usuario, password],
  );

  return result.rows[0];
};

const updateUsuario = async (idUsuario, payload) => {
  const fields = [];
  const values = [];

  if (payload.correo !== undefined) {
    values.push(payload.correo);
    fields.push(`correo = $${values.length}`);
  }

  if (payload.nombre_usuario !== undefined) {
    values.push(payload.nombre_usuario);
    fields.push(`nombre_usuario = $${values.length}`);
  }

  if (payload.password !== undefined) {
    values.push(payload.password);
    fields.push(`password_hash = crypt($${values.length}, gen_salt('bf'))`);
  }

  if (!fields.length) {
    return getUsuarioById(idUsuario);
  }

  values.push(idUsuario);

  const result = await pool.query(
    `UPDATE usuario
     SET ${fields.join(", ")}
     WHERE id_usuario = $${values.length}
     RETURNING id_usuario, correo, nombre_usuario`,
    values,
  );

  return result.rows[0] || null;
};

const deleteUsuario = async (idUsuario) => {
  const result = await pool.query(
    `DELETE FROM usuario
     WHERE id_usuario = $1
     RETURNING id_usuario`,
    [idUsuario],
  );

  return Boolean(result.rowCount);
};

module.exports = {
  listUsuarios,
  getUsuarioById,
  createUsuario,
  updateUsuario,
  deleteUsuario,
};
