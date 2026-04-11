const { pool } = require("../db/pool");

const listEquiposUsuario = async (idUsuario) => {
  const result = await pool.query(
    `SELECT DISTINCT ON (e.id_equipo)
       e.id_equipo,
       e.nombre,
       (p.fecha_fin IS NULL) AS es_actual,
       p.fecha_inicio,
       p.fecha_fin
     FROM pertenece p
     JOIN equipo e ON e.id_equipo = p.id_equipo
     WHERE p.id_usuario = $1
     ORDER BY e.id_equipo, (p.fecha_fin IS NULL) DESC, p.fecha_inicio DESC`,
    [idUsuario],
  );

  return result.rows.map((r) => ({
    id_equipo: Number(r.id_equipo),
    nombre: r.nombre,
    es_actual: Boolean(r.es_actual),
  }));
};

const _getEquipoUsuario = async (idUsuario, idEquipo) => {
  const result = await pool.query(
    `SELECT e.id_equipo, e.nombre, e.elo, (p.fecha_fin IS NULL) AS es_actual
     FROM pertenece p
     JOIN equipo e ON e.id_equipo = p.id_equipo
     WHERE p.id_usuario = $1 AND p.id_equipo = $2
     ORDER BY (p.fecha_fin IS NULL) DESC, p.fecha_inicio DESC
     LIMIT 1`,
    [idUsuario, idEquipo],
  );
  return result.rows[0] || null;
};

const _getEquipoActualUsuario = async (idUsuario) => {
  const result = await pool.query(
    `SELECT e.id_equipo, e.nombre, e.elo
     FROM pertenece p
     JOIN equipo e ON e.id_equipo = p.id_equipo
     WHERE p.id_usuario = $1 AND p.fecha_fin IS NULL
     ORDER BY p.fecha_inicio DESC
     LIMIT 1`,
    [idUsuario],
  );

  return result.rows[0] || null;
};

const getEloHistorial = async ({ idUsuario, idEquipo }) => {
  const targetEquipoId = idEquipo || (await _getEquipoActualUsuario(idUsuario))?.id_equipo;
  if (!targetEquipoId) {
    return null;
  }

  const equipoRow = await _getEquipoUsuario(idUsuario, targetEquipoId);
  if (!equipoRow) {
    return { forbidden: true };
  }

  const historialRes = await pool.query(
    `SELECT creado_en, elo_nuevo
     FROM historial_elo
     WHERE id_equipo = $1
     ORDER BY creado_en ASC`,
    [targetEquipoId],
  );

  return {
    equipo: {
      id_equipo: Number(equipoRow.id_equipo),
      nombre: equipoRow.nombre,
      elo_actual: Number(equipoRow.elo),
    },
    historial: historialRes.rows.map((r) => ({
      creado_en: r.creado_en,
      elo_nuevo: Number(r.elo_nuevo),
    })),
  };
};

const getRanking = async ({ idUsuario, idEquipo }) => {
  const targetEquipoId = idEquipo || (await _getEquipoActualUsuario(idUsuario))?.id_equipo;
  if (!targetEquipoId) {
    return null;
  }

  const equipoRow = await _getEquipoUsuario(idUsuario, targetEquipoId);
  if (!equipoRow) {
    return { forbidden: true };
  }

  const categoriaRes = await pool.query(
    `SELECT t.id_categoria, c.nombre AS categoria_nombre
     FROM participacion_torneo_equipo p
     JOIN torneo t ON t.id_torneo = p.id_torneo
     JOIN categoria c ON c.id_categoria = t.id_categoria
     WHERE p.id_equipo = $1
     ORDER BY t.fecha_inicio DESC NULLS LAST, t.id_torneo DESC
     LIMIT 1`,
    [targetEquipoId],
  );

  const categoriaRow = categoriaRes.rows[0] || null;

  if (!categoriaRow) {
    return {
      categoria: null,
      equipo_usuario: {
        posicion: null,
        id_equipo: Number(equipoRow.id_equipo),
        nombre: equipoRow.nombre,
        elo: Number(equipoRow.elo),
      },
      top10: [],
    };
  }

  const idCategoria = Number(categoriaRow.id_categoria);

  const top10Res = await pool.query(
    `WITH teams AS (
       SELECT DISTINCT e.id_equipo, e.nombre, e.elo
       FROM equipo e
       JOIN participacion_torneo_equipo p ON p.id_equipo = e.id_equipo
       JOIN torneo t ON t.id_torneo = p.id_torneo
       WHERE t.id_categoria = $1
     ), ranked AS (
       SELECT
         ROW_NUMBER() OVER (ORDER BY elo DESC, nombre ASC) AS posicion,
         id_equipo,
         nombre,
         elo
       FROM teams
     )
     SELECT posicion, id_equipo, nombre, elo
     FROM ranked
     ORDER BY posicion
     LIMIT 10`,
    [idCategoria],
  );

  const meRes = await pool.query(
    `WITH teams AS (
       SELECT DISTINCT e.id_equipo, e.nombre, e.elo
       FROM equipo e
       JOIN participacion_torneo_equipo p ON p.id_equipo = e.id_equipo
       JOIN torneo t ON t.id_torneo = p.id_torneo
       WHERE t.id_categoria = $1
     ), ranked AS (
       SELECT
         ROW_NUMBER() OVER (ORDER BY elo DESC, nombre ASC) AS posicion,
         id_equipo,
         nombre,
         elo
       FROM teams
     )
     SELECT posicion, id_equipo, nombre, elo
     FROM ranked
     WHERE id_equipo = $2
     LIMIT 1`,
    [idCategoria, targetEquipoId],
  );

  const meRow = meRes.rows[0] || null;

  return {
    categoria: {
      id_categoria: idCategoria,
      nombre: categoriaRow.categoria_nombre,
    },
    equipo_usuario: {
      posicion: meRow ? Number(meRow.posicion) : null,
      id_equipo: Number(equipoRow.id_equipo),
      nombre: equipoRow.nombre,
      elo: Number(equipoRow.elo),
    },
    top10: top10Res.rows.map((r) => ({
      posicion: Number(r.posicion),
      id_equipo: Number(r.id_equipo),
      nombre: r.nombre,
      elo: Number(r.elo),
    })),
  };
};

module.exports = {
  listEquiposUsuario,
  getEloHistorial,
  getRanking,
};
