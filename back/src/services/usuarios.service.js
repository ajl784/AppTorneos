const { pool } = require("../db/pool");

const getCalendarioUsuario = async ({
  idUsuario,
  desde,
  hasta,
  estado,
  limit,
  offset,
}) => {
  const values = [idUsuario, limit, offset];
  const filters = [];

  if (desde) {
    values.push(desde);
    filters.push(`p.fecha_hora >= $${values.length}::date`);
  }

  if (hasta) {
    values.push(hasta);
    filters.push(`p.fecha_hora < ($${values.length}::date + INTERVAL '1 day')`);
  }

  if (estado) {
    values.push(estado);
    filters.push(`p.estado = $${values.length}`);
  }

  const where = filters.length ? `WHERE ${filters.join(" AND ")}` : "";

  const result = await pool.query(
    `WITH my_teams AS (
      SELECT pe.id_equipo
      FROM pertenece pe
      WHERE pe.id_usuario = $1
        AND pe.fecha_fin IS NULL
    ),
    my_jugador_partidos AS (
      SELECT DISTINCT pp.id_partido
      FROM participacion_partido pp
      JOIN participacion_torneo_equipo pte
        ON pte.id_participacion_equipo = pp.id_participacion_equipo
      WHERE pte.id_equipo IN (SELECT id_equipo FROM my_teams)
    ),
    my_arbitro AS (
      SELECT at.id_arbitro_torneo
      FROM arbitro_torneo at
      WHERE at.id_usuario = $1
    ),
    my_arbitro_partidos AS (
      SELECT DISTINCT ap.id_partido
      FROM arbitro_partido ap
      JOIN my_arbitro ma ON ma.id_arbitro_torneo = ap.id_arbitro_torneo
    ),
    my_roles AS (
      SELECT id_partido, true AS es_jugador, false AS es_arbitro
      FROM my_jugador_partidos
      UNION ALL
      SELECT id_partido, false AS es_jugador, true AS es_arbitro
      FROM my_arbitro_partidos
    ),
    my_partidos AS (
      SELECT
        id_partido,
        bool_or(es_jugador) AS es_jugador,
        bool_or(es_arbitro) AS es_arbitro
      FROM my_roles
      GROUP BY id_partido
    )
    SELECT
      p.id_partido,
      p.id_torneo,
      t.nombre AS torneo_nombre,
      p.fecha_hora,
      p.lugar,
      p.estado,
      p.jornada,
      p.ronda,
      p.orden_ronda,
      mp.es_jugador,
      mp.es_arbitro,
      ar.arbitro_nombre,
      json_agg(
        json_build_object(
          'id_equipo', e.id_equipo,
          'nombre', e.nombre,
          'es_mi_equipo', (e.id_equipo IN (SELECT id_equipo FROM my_teams))
        )
        ORDER BY e.nombre
      ) AS equipos
    FROM my_partidos mp
    JOIN partido p ON p.id_partido = mp.id_partido
    JOIN torneo t ON t.id_torneo = p.id_torneo
    LEFT JOIN LATERAL (
      SELECT
        string_agg(u.nombre_usuario, ', ' ORDER BY u.nombre_usuario) AS arbitro_nombre
      FROM arbitro_partido ap
      JOIN arbitro_torneo at ON at.id_arbitro_torneo = ap.id_arbitro_torneo
      JOIN usuario u ON u.id_usuario = at.id_usuario
      WHERE ap.id_partido = p.id_partido
    ) ar ON true
    JOIN participacion_partido pp_all ON pp_all.id_partido = p.id_partido
    JOIN participacion_torneo_equipo pte_all
      ON pte_all.id_participacion_equipo = pp_all.id_participacion_equipo
    JOIN equipo e ON e.id_equipo = pte_all.id_equipo
    ${where}
    GROUP BY
      p.id_partido,
      p.id_torneo,
      t.nombre,
      p.fecha_hora,
      p.lugar,
      p.estado,
      p.jornada,
      p.ronda,
      p.orden_ronda,
      mp.es_jugador,
      mp.es_arbitro,
      ar.arbitro_nombre
    ORDER BY p.fecha_hora ASC
    LIMIT $2 OFFSET $3`,
    values,
  );

  return result.rows;
};

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

const loginUsuario = async ({ correo, password }) => {
  const result = await pool.query(
    `SELECT id_usuario, correo, nombre_usuario
     FROM usuario
     WHERE correo = $1 AND password_hash = crypt($2, password_hash)`,
    [correo, password]
  );
  return result.rows[0] || null;
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
  loginUsuario,
  getCalendarioUsuario,
  updateUsuario,
  deleteUsuario,
};
