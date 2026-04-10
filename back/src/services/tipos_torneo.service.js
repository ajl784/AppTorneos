const { pool } = require("../db/pool");

const listTiposTorneo = async ({ limit, offset }) => {
  const result = await pool.query(
    `SELECT id_tipo_torneo, nombre, descripcion
     FROM tipo_torneo
     ORDER BY nombre ASC
     LIMIT $1 OFFSET $2`,
    [limit, offset],
  );

  return result.rows;
};

module.exports = {
  listTiposTorneo,
};
