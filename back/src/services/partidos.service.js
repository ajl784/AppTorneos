const { pool } = require("../db/pool");
const { AppError } = require("../utils/errors");
const torneosService = require("./torneos.service");

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

const parseNormaPuntuacionLiga = (raw) => {
  if (!raw || typeof raw !== "string") return null;
  const parts = raw
    .trim()
    .split(/[^0-9]+/)
    .filter(Boolean)
    .map((x) => Number.parseInt(x, 10))
    .filter((x) => Number.isInteger(x));

  if (parts.length !== 3) return null;
  const [victoria, empate, derrota] = parts;
  if (victoria < 0 || empate < 0 || derrota < 0) return null;
  return { victoria, empate, derrota };
};

const recomputeClasificacionLiga = async (client, { idTorneo, norma }) => {
  // 1) Puntos por participación: inicial 0
  const puntosLiga = new Map();

  // 2) Trae todos los marcadores de partidos acabados del torneo
  const rows = await client.query(
    `SELECT p.id_partido, pp.id_participacion_equipo, pp.punto
     FROM partido p
     JOIN participacion_partido pp ON pp.id_partido = p.id_partido
     WHERE p.id_torneo = $1
       AND p.estado = 'acabado'
     ORDER BY p.id_partido ASC`,
    [idTorneo],
  );

  // Agrupa por partido
  const byPartido = new Map();
  for (const r of rows.rows) {
    const idPartido = Number(r.id_partido);
    const arr = byPartido.get(idPartido) || [];
    arr.push({
      id_participacion_equipo: Number(r.id_participacion_equipo),
      punto: Number(r.punto),
    });
    byPartido.set(idPartido, arr);
  }

  const { victoria, empate, derrota } = norma;

  for (const entries of byPartido.values()) {
    if (!entries.length) continue;

    const puntos = entries.map((e) => e.punto);
    const max = Math.max(...puntos);
    const min = Math.min(...puntos);
    const countMax = puntos.filter((x) => x === max).length;

    for (const e of entries) {
      let add = derrota;

      // todos iguales -> empate
      if (max === min) {
        add = empate;
      } else if (e.punto === max) {
        // ganador único -> victoria; empate en primera -> empate
        add = countMax === 1 ? victoria : empate;
      }

      puntosLiga.set(
        e.id_participacion_equipo,
        (puntosLiga.get(e.id_participacion_equipo) || 0) + add,
      );
    }
  }

  // Resetea puntuación del torneo y aplica los puntos recalculados
  await client.query(
    `UPDATE participacion_torneo_equipo
     SET puntuacion = 0
     WHERE id_torneo = $1`,
    [idTorneo],
  );

  if (puntosLiga.size) {
    const ids = Array.from(puntosLiga.keys());
    const pts = ids.map((id) => puntosLiga.get(id));
    await client.query(
      `UPDATE participacion_torneo_equipo p
       SET puntuacion = src.puntos
       FROM (
         SELECT unnest($1::bigint[]) AS id_participacion_equipo,
                unnest($2::int[]) AS puntos
       ) src
       WHERE p.id_participacion_equipo = src.id_participacion_equipo
         AND p.id_torneo = $3`,
      [ids, pts, idTorneo],
    );
  }
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
      `SELECT id_partido, id_torneo, estado, ronda
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
    const rondaPartido = partidoResult.rows[0].ronda;

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

    const torneoInfoRes = await client.query(
      `SELECT tt.nombre AS tipo_torneo, t.norma_puntuacion
       FROM torneo t
       JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
       WHERE t.id_torneo = $1`,
      [idTorneo],
    );

    const torneoInfo = torneoInfoRes.rows[0] || null;
    const esLiga = (torneoInfo?.tipo_torneo || "") === "Liga";
    const esEliminacionDirecta = (torneoInfo?.tipo_torneo || "") === "Eliminación directa";
    const normaLiga = esLiga
      ? parseNormaPuntuacionLiga(torneoInfo?.norma_puntuacion)
      : null;

    if (esEliminacionDirecta) {
      const puntos = puntuaciones.map((p) => Number(p.punto));
      const max = Math.max(...puntos);
      const countMax = puntos.filter((x) => x === max).length;
      if (countMax !== 1) {
        throw new AppError(
          400,
          "En eliminación directa no se permite empate: debe haber un ganador único",
        );
      }
    }

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

      puntosPorParticipacion.set(idParticipacionEquipo, punto);

      actualizadas.push({
        id_participacion_equipo: idParticipacionEquipo,
        punto_partido: punto,
        // Se rellenará al final (en Liga se recalcula por norma; en otros, por suma)
        puntuacion_torneo: null,
      });
    }

    // Recalcular puntuación global del torneo
    if (esLiga && normaLiga) {
      await recomputeClasificacionLiga(client, { idTorneo, norma: normaLiga });
    }

    // Puntuación global para NO-Liga (suma de pp.punto)
    if (!esLiga) {
      const totalsRes = await client.query(
        `SELECT pp.id_participacion_equipo, COALESCE(SUM(pp.punto), 0)::int AS total
         FROM participacion_partido pp
         JOIN partido p ON p.id_partido = pp.id_partido
         WHERE p.id_torneo = $1
         GROUP BY pp.id_participacion_equipo`,
        [idTorneo],
      );

      const totals = new Map(
        totalsRes.rows.map((r) => [Number(r.id_participacion_equipo), Number(r.total)]),
      );

      for (const [idParticipacionEquipo, total] of totals.entries()) {
        await client.query(
          `UPDATE participacion_torneo_equipo
           SET puntuacion = $1
           WHERE id_participacion_equipo = $2`,
          [total, idParticipacionEquipo],
        );
      }
    }

    // Completa puntuacion_torneo en la respuesta
    const puntuacionActualRes = await client.query(
      `SELECT id_participacion_equipo, puntuacion
       FROM participacion_torneo_equipo
       WHERE id_torneo = $1
         AND id_participacion_equipo = ANY($2::bigint[])`,
      [idTorneo, idsParticipacion],
    );
    const puntuacionActual = new Map(
      puntuacionActualRes.rows.map((r) => [Number(r.id_participacion_equipo), Number(r.puntuacion)]),
    );
    for (const item of actualizadas) {
      item.puntuacion_torneo = puntuacionActual.get(item.id_participacion_equipo) ?? 0;
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

    // Avance automático de ronda (Eliminación directa)
    // Nota: se ejecuta DESPUÉS del commit para reutilizar la lógica existente
    // de generar ronda y evitar transacciones anidadas.
    let avance = null;
    if (esEliminacionDirecta && rondaPartido != null) {
      try {
        const maxRondaRes = await pool.query(
          `SELECT MAX(ronda) AS max_ronda FROM partido WHERE id_torneo = $1`,
          [idTorneo],
        );
        const maxRonda = Number(maxRondaRes.rows[0]?.max_ronda || 0);

        // Si ya se generó una ronda posterior, no hacemos nada.
        if (maxRonda === Number(rondaPartido)) {
          const pendientesRes = await pool.query(
            `SELECT COUNT(*)::int AS pendientes
             FROM partido
             WHERE id_torneo = $1 AND ronda = $2 AND estado <> 'acabado'`,
            [idTorneo, rondaPartido],
          );
          const pendientes = Number(pendientesRes.rows[0]?.pendientes || 0);
          if (pendientes === 0) {
            avance = await torneosService.avanzarRondaEliminacion(Number(idTorneo));
          }
        }
      } catch (_e) {
        // Si falla por concurrencia o porque otra petición ya avanzó,
        // no bloqueamos el cierre del partido.
        avance = null;
      }
    }

    return {
      id_partido: idPartido,
      id_torneo: idTorneo,
      puntuaciones_actualizadas: actualizadas,
      id_arbitro_torneo: idArbitroTorneo || null,
      elo_aplicado: eloAplicado,
      elo_actualizado: eloActualizado,
      avance_ronda: avance,
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
