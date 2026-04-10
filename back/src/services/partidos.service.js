const { pool } = require("../db/pool");
const { AppError } = require("../utils/errors");

const ELO_K_FACTOR = 32;

const expectedScore = (eloA, eloB) => 1 / (1 + 10 ** ((eloB - eloA) / 400));

const scoreFromPoints = (pointsA, pointsB) => {
  if (pointsA > pointsB) {
    return 1;
  }

  if (pointsA < pointsB) {
    return 0;
  }

  return 0.5;
};

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
  if (puntuaciones.length < 2) {
    throw new AppError(400, "Debe haber al menos 2 puntuaciones para registrar el partido");
  }

  if (puntuaciones.length > 2) {
    throw new AppError(
      400,
      "Funcionalidad en desarrollo: ELO para partidos con mas de 2 equipos",
    );
  }

  const idsParticipacion = puntuaciones.map((item) => item.id_participacion_equipo);
  if (new Set(idsParticipacion).size !== 2) {
    throw new AppError(
      400,
      "Las puntuaciones 1v1 deben pertenecer a dos participaciones distintas",
    );
  }

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
    const puntosPorParticipacion = new Map();

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

      puntosPorParticipacion.set(idParticipacionEquipo, punto);

      actualizadas.push({
        id_participacion_equipo: idParticipacionEquipo,
        punto_partido: punto,
        puntuacion_torneo: total,
      });
    }

    const eloRows = await client.query(
      `SELECT pte.id_participacion_equipo, pte.id_equipo, e.elo, e.nombre
       FROM participacion_torneo_equipo pte
       JOIN equipo e ON e.id_equipo = pte.id_equipo
       WHERE pte.id_participacion_equipo = ANY($1::bigint[])
         AND pte.id_torneo = $2`,
      [idsParticipacion, idTorneo],
    );

    if (eloRows.rowCount !== 2) {
      throw new AppError(
        400,
        "No se pudieron resolver los dos equipos del partido para calcular ELO",
      );
    }

    const historialPartido = await client.query(
      `SELECT id_equipo
       FROM historial_elo
       WHERE descripcion = $1
         AND id_equipo = ANY($2::bigint[])`,
      [
        `partido:${idPartido}`,
        eloRows.rows.map((row) => row.id_equipo),
      ],
    );

    let eloActualizado = [];
    let eloAplicado = false;

    if (historialPartido.rowCount === 2) {
      eloActualizado = eloRows.rows.map((row) => ({
        id_equipo: row.id_equipo,
        equipo_nombre: row.nombre,
        elo_anterior: row.elo,
        elo_nuevo: row.elo,
      }));
    } else {
      const [teamA, teamB] = eloRows.rows;
      const puntosA = puntosPorParticipacion.get(teamA.id_participacion_equipo) ?? 0;
      const puntosB = puntosPorParticipacion.get(teamB.id_participacion_equipo) ?? 0;

      const resultadoA = scoreFromPoints(puntosA, puntosB);
      const resultadoB = 1 - resultadoA;

      const esperadoA = expectedScore(teamA.elo, teamB.elo);
      const esperadoB = expectedScore(teamB.elo, teamA.elo);

      const deltaA = Math.round(ELO_K_FACTOR * (resultadoA - esperadoA));
      const deltaB = Math.round(ELO_K_FACTOR * (resultadoB - esperadoB));

      const nuevoEloA = Math.max(0, teamA.elo + deltaA);
      const nuevoEloB = Math.max(0, teamB.elo + deltaB);

      await client.query(
        `UPDATE equipo
         SET elo = $1
         WHERE id_equipo = $2`,
        [nuevoEloA, teamA.id_equipo],
      );

      await client.query(
        `UPDATE equipo
         SET elo = $1
         WHERE id_equipo = $2`,
        [nuevoEloB, teamB.id_equipo],
      );

      await client.query(
        `INSERT INTO historial_elo (id_equipo, elo_anterior, elo_nuevo, descripcion)
         VALUES ($1, $2, $3, $4), ($5, $6, $7, $8)`,
        [
          teamA.id_equipo,
          teamA.elo,
          nuevoEloA,
          `partido:${idPartido}`,
          teamB.id_equipo,
          teamB.elo,
          nuevoEloB,
          `partido:${idPartido}`,
        ],
      );

      eloActualizado = [
        {
          id_equipo: teamA.id_equipo,
          equipo_nombre: teamA.nombre,
          elo_anterior: teamA.elo,
          elo_nuevo: nuevoEloA,
          delta: nuevoEloA - teamA.elo,
        },
        {
          id_equipo: teamB.id_equipo,
          equipo_nombre: teamB.nombre,
          elo_anterior: teamB.elo,
          elo_nuevo: nuevoEloB,
          delta: nuevoEloB - teamB.elo,
        },
      ];
      eloAplicado = true;
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
      elo_aplicado: eloAplicado,
      elo_actualizado: eloActualizado,
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
