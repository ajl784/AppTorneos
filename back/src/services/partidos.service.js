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

const computePairwisePlacementScore = (team, rivals, scoreFn) => {
  if (!rivals.length) {
    return 0.5;
  }

  const total = rivals.reduce((accumulator, rival) => {
    return accumulator + scoreFn(team, rival);
  }, 0);

  return total / rivals.length;
};

const getMultiTeamEloAdjustment = (team, rivals) => {
  const scoreEsperado = computePairwisePlacementScore(
    team,
    rivals,
    (currentTeam, rival) => expectedScore(currentTeam.elo, rival.elo),
  );
  const scoreReal = computePairwisePlacementScore(
    team,
    rivals,
    (currentTeam, rival) => scoreFromPoints(currentTeam.punto, rival.punto),
  );
  const totalEquipos = rivals.length + 1;
  const posicionEsperada = 1 + (totalEquipos - 1) * (1 - scoreEsperado);
  const posicionReal = 1 + (totalEquipos - 1) * (1 - scoreReal);
  const delta = Math.round(ELO_K_FACTOR * (scoreReal - scoreEsperado));

  return {
    scoreEsperado,
    scoreReal,
    posicionEsperada,
    posicionReal,
    delta,
  };
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

  const idsParticipacion = puntuaciones.map((item) => item.id_participacion_equipo);
  if (new Set(idsParticipacion).size !== idsParticipacion.length) {
    throw new AppError(
      400,
      "Las puntuaciones deben pertenecer a participaciones distintas",
    );
  }

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const partidoResult = await client.query(
      `SELECT id_partido, id_torneo, estado
       FROM partido
       WHERE id_partido = $1`,
      [idPartido],
    );

    if (!partidoResult.rowCount) {
      await client.query("ROLLBACK");
      return null;
    }

    const idTorneo = partidoResult.rows[0].id_torneo;
    const estadoPartido = partidoResult.rows[0].estado;

    // Reglas de negocio: las puntuaciones (y el ELO) solo se consolidan
    // cuando el partido está cerrado.
    if (estadoPartido !== "acabado") {
      throw new AppError(
        400,
        "El partido debe estar en estado 'acabado' para registrar puntuaciones",
      );
    }
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

    if (eloRows.rowCount !== idsParticipacion.length) {
      throw new AppError(
        400,
        "No se pudieron resolver todos los equipos del partido para calcular ELO",
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

    if (historialPartido.rowCount === eloRows.rowCount) {
      eloActualizado = eloRows.rows.map((row) => ({
        id_equipo: row.id_equipo,
        equipo_nombre: row.nombre,
        elo_anterior: row.elo,
        elo_nuevo: row.elo,
        delta: 0,
      }));
    } else {
      const equiposConPunto = eloRows.rows.map((row) => ({
        ...row,
        punto: puntosPorParticipacion.get(row.id_participacion_equipo) ?? 0,
      }));

      const actualizaciones = equiposConPunto.map((team) => {
        const rivals = equiposConPunto.filter(
          (candidate) => candidate.id_equipo !== team.id_equipo,
        );

        return {
          ...team,
          ...getMultiTeamEloAdjustment(team, rivals),
        };
      });

      for (const update of actualizaciones) {
        const nuevoElo = Math.max(0, update.elo + update.delta);

        await client.query(
          `UPDATE equipo
           SET elo = $1
           WHERE id_equipo = $2`,
          [nuevoElo, update.id_equipo],
        );

        await client.query(
          `INSERT INTO historial_elo (id_equipo, elo_anterior, elo_nuevo, descripcion)
           VALUES ($1, $2, $3, $4)`,
          [
            update.id_equipo,
            update.elo,
            nuevoElo,
            `partido:${idPartido}`,
          ],
        );

        eloActualizado.push({
          id_equipo: update.id_equipo,
          equipo_nombre: update.nombre,
          elo_anterior: update.elo,
          elo_nuevo: nuevoElo,
          delta: nuevoElo - update.elo,
          posicion_esperada: Number(update.posicionEsperada.toFixed(2)),
          posicion_real: Number(update.posicionReal.toFixed(2)),
          score_esperado: Number(update.scoreEsperado.toFixed(4)),
          score_real: Number(update.scoreReal.toFixed(4)),
        });
      }
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
