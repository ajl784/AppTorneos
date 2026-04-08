const { pool } = require("../db/pool");
const { AppError } = require("../utils/errors");

const listPartidos = async ({ limit, offset, torneoId, estado }) => {
  const values = [limit, offset];
  const filters = [];

  if (torneoId) {
    values.push(torneoId);
    filters.push(`p.id_torneo = $${values.length}`);
  }

  if (estado) {
    values.push(estado);
    filters.push(`p.estado = $${values.length}`);
  }

  const where = filters.length ? `WHERE ${filters.join(" AND ")}` : "";

  const result = await pool.query(
    `SELECT
      p.id_partido,
      p.id_torneo,
      t.nombre AS torneo_nombre,
      p.fecha_hora,
      p.lugar,
      p.estado
     FROM partido p
     JOIN torneo t ON t.id_torneo = p.id_torneo
     ${where}
     ORDER BY p.id_partido DESC
     LIMIT $1 OFFSET $2`,
    values,
  );

  return result.rows;
};

const getPartidoById = async (idPartido) => {
  const result = await pool.query(
    `SELECT
      p.id_partido,
      p.id_torneo,
      t.nombre AS torneo_nombre,
      p.fecha_hora,
      p.lugar,
      p.estado
     FROM partido p
     JOIN torneo t ON t.id_torneo = p.id_torneo
     WHERE p.id_partido = $1`,
    [idPartido],
  );

  return result.rows[0] || null;
};

const createPartido = async ({ id_torneo, fecha_hora, lugar, estado }) => {
  const result = await pool.query(
    `INSERT INTO partido (id_torneo, fecha_hora, lugar, estado)
     VALUES ($1, $2, $3, $4)
     RETURNING id_partido`,
    [id_torneo, fecha_hora, lugar || null, estado || "planificado"],
  );

  return getPartidoById(result.rows[0].id_partido);
};

const updatePartido = async (idPartido, payload) => {
  const mapping = {
    id_torneo: "id_torneo",
    fecha_hora: "fecha_hora",
    lugar: "lugar",
    estado: "estado",
  };

  const fields = [];
  const values = [];

  Object.keys(mapping).forEach((key) => {
    if (payload[key] !== undefined) {
      values.push(payload[key]);
      fields.push(`${mapping[key]} = $${values.length}`);
    }
  });

  if (!fields.length) {
    return getPartidoById(idPartido);
  }

  values.push(idPartido);

  const result = await pool.query(
    `UPDATE partido
     SET ${fields.join(", ")}
     WHERE id_partido = $${values.length}
     RETURNING id_partido`,
    values,
  );

  if (!result.rowCount) {
    return null;
  }

  return getPartidoById(idPartido);
};

const deletePartido = async (idPartido) => {
  const result = await pool.query(
    `DELETE FROM partido
     WHERE id_partido = $1
     RETURNING id_partido`,
    [idPartido],
  );

  return Boolean(result.rowCount);
};

const registrarPuntuacionesArbitro = async ({
  idPartido,
  puntuaciones,
  idArbitroTorneo,
  acta,
}) => {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const partidoResult = await client.query(
      `SELECT id_partido, id_torneo
       FROM partido
       WHERE id_partido = $1`,
      [idPartido],
    );

    if (!partidoResult.rowCount) {
      await client.query("ROLLBACK");
      return null;
    }

    const idTorneo = partidoResult.rows[0].id_torneo;
    const actualizadas = [];

    for (const item of puntuaciones) {
      const idParticipacionEquipo = item.id_participacion_equipo;
      const punto = item.punto;

      if (!Number.isInteger(punto) || punto < 0) {
        throw new AppError(400, "punto debe ser un entero mayor o igual a 0");
      }

      const validacionParticipacion = await client.query(
        `SELECT id_participacion_equipo
         FROM participacion_torneo_equipo
         WHERE id_participacion_equipo = $1
           AND id_torneo = $2`,
        [idParticipacionEquipo, idTorneo],
      );

      if (!validacionParticipacion.rowCount) {
        throw new AppError(
          400,
          "La participacion no pertenece al torneo de este partido",
          {
            id_participacion_equipo: idParticipacionEquipo,
            id_torneo: idTorneo,
          },
        );
      }

      await client.query(
        `INSERT INTO participacion_partido (id_partido, id_participacion_equipo, punto)
         VALUES ($1, $2, $3)
         ON CONFLICT (id_partido, id_participacion_equipo)
         DO UPDATE SET punto = EXCLUDED.punto`,
        [idPartido, idParticipacionEquipo, punto],
      );

      const totalResult = await client.query(
        `SELECT COALESCE(SUM(pp.punto), 0)::int AS total
         FROM participacion_partido pp
         JOIN partido p ON p.id_partido = pp.id_partido
         WHERE pp.id_participacion_equipo = $1
           AND p.id_torneo = $2`,
        [idParticipacionEquipo, idTorneo],
      );

      const total = totalResult.rows[0].total;

      await client.query(
        `UPDATE participacion_torneo_equipo
         SET puntuacion = $1
         WHERE id_participacion_equipo = $2`,
        [total, idParticipacionEquipo],
      );

      actualizadas.push({
        id_participacion_equipo: idParticipacionEquipo,
        punto_partido: punto,
        puntuacion_torneo: total,
      });
    }

    if (idArbitroTorneo) {
      await client.query(
        `INSERT INTO arbitro_partido (id_partido, id_arbitro_torneo, acta)
         VALUES ($1, $2, $3::jsonb)
         ON CONFLICT (id_partido, id_arbitro_torneo)
         DO UPDATE SET acta = EXCLUDED.acta`,
        [idPartido, idArbitroTorneo, acta ? JSON.stringify(acta) : null],
      );
    }

    await client.query("COMMIT");

    return {
      id_partido: idPartido,
      id_torneo: idTorneo,
      puntuaciones_actualizadas: actualizadas,
      id_arbitro_torneo: idArbitroTorneo || null,
    };
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  listPartidos,
  getPartidoById,
  createPartido,
  updatePartido,
  deletePartido,
  registrarPuntuacionesArbitro,
};
