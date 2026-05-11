const { pool } = require("../db/pool");

const listEquipos = async ({ limit, offset, nombre, categoriaId }) => {
  const values = [limit, offset];
  const filters = [];

  if (nombre) {
    values.push(`%${nombre}%`);
    filters.push(`e.nombre ILIKE $${values.length}`);
  }

  if (categoriaId) {
    values.push(categoriaId);
    filters.push(`e.id_categoria = $${values.length}`);
  }

  const where = filters.length ? `WHERE ${filters.join(" AND ")}` : "";

  const result = await pool.query(
    `SELECT e.id_equipo, e.nombre, e.descripcion, e.elo, e.id_categoria, c.nombre AS categoria_nombre
     FROM equipo e
     LEFT JOIN categoria c ON c.id_categoria = e.id_categoria
     ${where}
     ORDER BY e.id_equipo DESC
     LIMIT $1 OFFSET $2`,
    values,
  );

  return result.rows;
};

const getEquipoById = async (idEquipo) => {
  const result = await pool.query(
    `SELECT e.id_equipo, e.nombre, e.descripcion, e.elo, e.id_categoria, c.nombre AS categoria_nombre
     FROM equipo e
     LEFT JOIN categoria c ON c.id_categoria = e.id_categoria
     WHERE e.id_equipo = $1`,
    [idEquipo],
  );

  return result.rows[0] || null;
};
const getEquipoIcono = async (idEquipo) => {
  const result = await pool.query(
    `SELECT c.icono, c.icono_bin, c.icono_mime
       FROM equipo e
       LEFT JOIN categoria c ON c.id_categoria = e.id_categoria
       WHERE e.id_equipo = $1`,
    [idEquipo],
  );

  return result.rows[0] || null;
};

const getEloHistorialEquipo = async (idEquipo) => {
  const equipo = await getEquipoById(idEquipo);
  if (!equipo) {
    return null;
  }

  const historialRes = await pool.query(
    `SELECT id_historial_elo, creado_en, elo_anterior, elo_nuevo, descripcion
     FROM historial_elo
     WHERE id_equipo = $1
     ORDER BY creado_en ASC, id_historial_elo ASC`,
    [idEquipo],
  );

  return {
    equipo: {
      id_equipo: Number(equipo.id_equipo),
      nombre: equipo.nombre,
      elo_actual: Number(equipo.elo ?? 0),
    },
    historial: historialRes.rows.map((row) => ({
      id_historial_elo: Number(row.id_historial_elo),
      creado_en: row.creado_en,
      elo_anterior: Number(row.elo_anterior),
      elo_nuevo: Number(row.elo_nuevo),
      descripcion: row.descripcion,
    })),
  };
};

const createEquipo = async ({
  nombre,
  descripcion,
  elo,
  id_categoria,
  id_usuario,
}) => {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const result = await client.query(
      `INSERT INTO equipo (nombre, descripcion, elo, id_categoria)
       VALUES ($1, $2, $3, $4)
       RETURNING id_equipo`,
      [nombre, descripcion || null, elo ?? 1200, id_categoria],
    );

    const idEquipo = result.rows[0].id_equipo;

    // El creador del equipo pasa a ser miembro y entrenador del equipo.
    if (id_usuario !== undefined && id_usuario !== null) {
      await client.query(
        `INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio, fecha_fin)
         VALUES ($1, $2, CURRENT_DATE, NULL)
         ON CONFLICT (id_usuario, id_equipo, fecha_inicio) DO NOTHING`,
        [id_usuario, idEquipo],
      );

      await client.query(
        `INSERT INTO entrenador_equipo (id_usuario, id_equipo, fecha_inicio, fecha_fin)
         VALUES ($1, $2, CURRENT_DATE, NULL)
         ON CONFLICT (id_usuario, id_equipo, fecha_inicio) DO NOTHING`,
        [id_usuario, idEquipo],
      );
    }

    await client.query("COMMIT");
    return await getEquipoById(idEquipo);
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
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

  if (payload.id_categoria !== undefined) {
    values.push(payload.id_categoria);
    fields.push(`id_categoria = $${values.length}`);
  }

  if (!fields.length) {
    return getEquipoById(idEquipo);
  }

  values.push(idEquipo);

  const result = await pool.query(
    `UPDATE equipo
     SET ${fields.join(", ")}
     WHERE id_equipo = $${values.length}
     RETURNING id_equipo`,
    values,
  );

  if (!result.rowCount) {
    return null;
  }

  return getEquipoById(idEquipo);
};

const getEquiposByUsuario = async (idUsuario) => {
  // Devuelve equipos activos del usuario.
  const result = await pool.query(
    `SELECT e.id_equipo, e.nombre, e.descripcion, e.elo, e.id_categoria, c.nombre AS categoria_nombre
     FROM equipo e
     INNER JOIN pertenece p ON e.id_equipo = p.id_equipo
     LEFT JOIN categoria c ON c.id_categoria = e.id_categoria
     WHERE p.id_usuario = $1
       AND p.fecha_fin IS NULL
     ORDER BY e.id_equipo DESC`,
    [idUsuario],
  );
  return result.rows;
};

const isEntrenadorActivo = async ({ idEquipo, idUsuario }) => {
  const result = await pool.query(
    `SELECT 1
     FROM entrenador_equipo ee
     WHERE ee.id_equipo = $1
       AND ee.id_usuario = $2
       AND ee.fecha_fin IS NULL
     LIMIT 1`,
    [idEquipo, idUsuario],
  );

  return result.rows.length > 0;
};

const createSolicitudIngresoEquipo = async ({
  idEquipo,
  idUsuario,
  respuesta,
}) => {
  const existing = await pool.query(
    `SELECT id_solicitud_equipo
     FROM solicitud_equipo
     WHERE id_equipo = $1
       AND id_usuario = $2
       AND estado = 'pendiente'
     LIMIT 1`,
    [idEquipo, idUsuario],
  );

  if (existing.rows.length) {
    return getSolicitudIngresoById(existing.rows[0].id_solicitud_equipo);
  }

  const result = await pool.query(
    `INSERT INTO solicitud_equipo (id_equipo, id_usuario, respuesta, estado)
     VALUES ($1, $2, $3::jsonb, 'pendiente')
     RETURNING id_solicitud_equipo`,
    [idEquipo, idUsuario, respuesta ? JSON.stringify(respuesta) : null],
  );

  return getSolicitudIngresoById(result.rows[0].id_solicitud_equipo);
};

const listSolicitudesIngresoEquipo = async ({ idEquipo, estado }) => {
  const values = [idEquipo];
  let whereEstado = "";

  if (estado) {
    values.push(estado);
    whereEstado = `AND se.estado = $${values.length}`;
  }

  const result = await pool.query(
    `SELECT
      se.id_solicitud_equipo,
      se.id_equipo,
      e.nombre AS equipo_nombre,
      se.id_usuario,
      u.nombre_usuario,
      u.correo,
      se.fecha,
      se.respuesta,
      se.estado,
      se.id_entrenador_decisor,
      se.fecha_decision
     FROM solicitud_equipo se
     JOIN equipo e ON e.id_equipo = se.id_equipo
     JOIN usuario u ON u.id_usuario = se.id_usuario
     WHERE se.id_equipo = $1
       ${whereEstado}
     ORDER BY se.id_solicitud_equipo DESC`,
    values,
  );

  return result.rows;
};

const listSolicitudesIngresoUsuario = async ({ idUsuario, estado }) => {
  const values = [idUsuario];
  let whereEstado = "";

  if (estado) {
    values.push(estado);
    whereEstado = `AND se.estado = $${values.length}`;
  }

  const result = await pool.query(
    `SELECT
      se.id_solicitud_equipo,
      se.id_equipo,
      e.nombre AS equipo_nombre,
      se.id_usuario,
      se.fecha,
      se.respuesta,
      se.estado,
      se.id_entrenador_decisor,
      se.fecha_decision
     FROM solicitud_equipo se
     JOIN equipo e ON e.id_equipo = se.id_equipo
     WHERE se.id_usuario = $1
       ${whereEstado}
     ORDER BY se.id_solicitud_equipo DESC`,
    values,
  );

  return result.rows;
};

const getSolicitudIngresoById = async (idSolicitudEquipo) => {
  const result = await pool.query(
    `SELECT
      se.id_solicitud_equipo,
      se.id_equipo,
      e.nombre AS equipo_nombre,
      se.id_usuario,
      u.nombre_usuario,
      u.correo,
      se.fecha,
      se.respuesta,
      se.estado,
      se.id_entrenador_decisor,
      se.fecha_decision
     FROM solicitud_equipo se
     JOIN equipo e ON e.id_equipo = se.id_equipo
     JOIN usuario u ON u.id_usuario = se.id_usuario
     WHERE se.id_solicitud_equipo = $1`,
    [idSolicitudEquipo],
  );

  return result.rows[0] || null;
};

const decideSolicitudIngresoEquipo = async ({
  idSolicitudEquipo,
  aceptar,
  idEntrenadorDecisor,
}) => {
  const estado = aceptar ? "aceptada" : "rechazada";
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const rowResult = await client.query(
      `SELECT id_equipo, id_usuario, estado
       FROM solicitud_equipo
       WHERE id_solicitud_equipo = $1
       FOR UPDATE`,
      [idSolicitudEquipo],
    );

    const solicitud = rowResult.rows[0];

    if (solicitud.estado !== "pendiente") {
      await client.query("ROLLBACK");
      return getSolicitudIngresoById(idSolicitudEquipo);
    }

    await client.query(
      `UPDATE solicitud_equipo
       SET estado = $1,
           id_entrenador_decisor = $2,
           fecha_decision = NOW()
       WHERE id_solicitud_equipo = $3`,
      [estado, idEntrenadorDecisor ?? null, idSolicitudEquipo],
    );

    if (aceptar) {
      await client.query(
        `INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio, fecha_fin)
         VALUES ($1, $2, CURRENT_DATE, NULL)
         ON CONFLICT (id_usuario, id_equipo, fecha_inicio) DO NOTHING`,
        [solicitud.id_usuario, solicitud.id_equipo],
      );
    }

    await client.query("COMMIT");
    return getSolicitudIngresoById(idSolicitudEquipo);
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
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
  getEloHistorialEquipo,
  createEquipo,
  updateEquipo,
  deleteEquipo,
  getEquiposByUsuario,
  createSolicitudIngresoEquipo,
  listSolicitudesIngresoEquipo,
  listSolicitudesIngresoUsuario,
  getSolicitudIngresoById,
  decideSolicitudIngresoEquipo,
  isEntrenadorActivo,
  getEquipoIcono,
};