const { pool } = require("../db/pool");


async function crearNotificacion({ id_usuario_destino, tipo, titulo, mensaje, datos }) {
  const result = await pool.query(
    `INSERT INTO notificacion (id_usuario_destino, tipo, titulo, mensaje, datos)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [id_usuario_destino, tipo, titulo, mensaje, datos ? JSON.stringify(datos) : null]
  );
  return result.rows[0];
}

async function getNotificaciones(filtros = {}) {
  let query = "SELECT * FROM notificacion WHERE 1=1";
  const params = [];
  let idx = 1;

  if (filtros.id_usuario_destino) {
    query += ` AND id_usuario_destino = $${idx++}`;
    params.push(filtros.id_usuario_destino);
  }
  if (filtros.tipo) {
    query += ` AND tipo = $${idx++}`;
    params.push(filtros.tipo);
  }
  if (filtros.leida !== undefined) {
    query += ` AND leida = $${idx++}`;
    params.push(filtros.leida === "true");
  }
  query += " ORDER BY fecha_creacion DESC";
  const result = await pool.query(query, params);
  return result.rows;
}

async function marcarComoLeida(idNotificacion) {
  const result = await pool.query(
    `UPDATE notificacion SET leida = TRUE, fecha_leida = NOW() WHERE id_notificacion = $1 RETURNING *`,
    [idNotificacion]
  );
  return result.rows[0];
}

async function eliminarNotificacion(idNotificacion) {
  const result = await pool.query(
    `DELETE FROM notificacion WHERE id_notificacion = $1 RETURNING *`,
    [idNotificacion]
  );
  return result.rows[0];
}

module.exports = {
  crearNotificacion,
  getNotificaciones,
  marcarComoLeida,
  eliminarNotificacion,
};