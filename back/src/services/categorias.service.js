const { pool } = require("../db/pool");

const listCategorias = async ({ limit, offset }) => {
  const result = await pool.query(
    `SELECT
      id_categoria,
      nombre,
      participantes_por_partida,
      norma,
      descripcion,
      icono
     FROM categoria
     ORDER BY nombre ASC
     LIMIT $1 OFFSET $2`,
    [limit, offset],
  );

  return result.rows;
};

const createCategoria = async (payload) => {
  const inserted = await pool.query(
    `INSERT INTO categoria (nombre, participantes_por_partida, norma, descripcion, icono)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id_categoria`,
    [
      payload.nombre,
      payload.participantes_por_partida,
      payload.norma || null,
      payload.descripcion || null,
      payload.icono,
    ],
  );

  const idCategoria = inserted.rows[0].id_categoria;

  // Por defecto, asociar la categoría con todos los tipos de torneo existentes.
  await pool.query(
    `INSERT INTO categoria_tipo_torneo (id_categoria, id_tipo_torneo)
     SELECT $1, tt.id_tipo_torneo
     FROM tipo_torneo tt
     ON CONFLICT (id_categoria, id_tipo_torneo) DO NOTHING`,
    [idCategoria],
  );

  const result = await pool.query(
    `SELECT id_categoria, nombre, participantes_por_partida, norma, descripcion, icono
     FROM categoria
     WHERE id_categoria = $1`,
    [idCategoria],
  );

  return result.rows[0] || null;
};

const getCategoriaIcono = async (idCategoria) => {
  const result = await pool.query(
    `SELECT icono
     FROM categoria
     WHERE id_categoria = $1`,
    [idCategoria],
  );

  return result.rows[0]?.icono || null;
};

const listTiposTorneoByCategoriaId = async (idCategoria) => {
  const result = await pool.query(
    `SELECT
      tt.id_tipo_torneo,
      tt.nombre,
      tt.descripcion
     FROM categoria_tipo_torneo ctt
     JOIN tipo_torneo tt ON tt.id_tipo_torneo = ctt.id_tipo_torneo
     WHERE ctt.id_categoria = $1
     ORDER BY tt.nombre ASC`,
    [idCategoria],
  );

  return result.rows;
};

module.exports = {
  listCategorias,
  createCategoria,
  getCategoriaIcono,
  listTiposTorneoByCategoriaId,
};
