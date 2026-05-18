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
  const pairs = raw
    .split(/[;,]/)
    .map((part) => part.trim())
    .filter(Boolean)
    .map((part) => {
      const separator = part.includes("=") ? "=" : part.includes(":") ? ":" : null;
      if (!separator) return null;
      const [key, value] = part.split(separator).map((token) => token.trim());
      if (!key || !value) return null;
      return [key.toLowerCase(), value];
    })
    .filter((item) => item !== null);

  const config = Object.fromEntries(pairs);
  const modo = String(config.modo || "").toLowerCase();

  const posiciones = Object.entries(config)
    .filter(([key]) => /^pos\d+$/.test(key))
    .map(([key, value]) => ({
      posicion: Number.parseInt(key.slice(3), 10),
      puntos: Number.parseInt(String(value), 10),
    }))
    .filter(
      (item) =>
        Number.isInteger(item.posicion) &&
        item.posicion >= 1 &&
        Number.isInteger(item.puntos) &&
        item.puntos >= 0,
    )
    .sort((a, b) => a.posicion - b.posicion);

  if (modo === "posiciones" || posiciones.length > 0) {
    if (!posiciones.length) return null;
    return {
      modo: "posiciones",
      puntosPorPosicion: posiciones.map((item) => item.puntos),
    };
  }

  const victoria = Number.parseInt(String(config.victoria), 10);
  const empate = Number.parseInt(String(config.empate), 10);
  const derrota = Number.parseInt(String(config.derrota), 10);

  if (
    Number.isInteger(victoria) &&
    Number.isInteger(empate) &&
    Number.isInteger(derrota) &&
    victoria >= 0 &&
    empate >= 0 &&
    derrota >= 0
  ) {
    return { modo: "duelo", victoria, empate, derrota };
  }

  const legacyParts = raw
    .trim()
    .split(/[^0-9]+/)
    .filter(Boolean)
    .map((x) => Number.parseInt(x, 10))
    .filter((x) => Number.isInteger(x));

  if (legacyParts.length === 3) {
    const [legacyVictoria, legacyEmpate, legacyDerrota] = legacyParts;
    if (legacyVictoria >= 0 && legacyEmpate >= 0 && legacyDerrota >= 0) {
      return {
        modo: "duelo",
        victoria: legacyVictoria,
        empate: legacyEmpate,
        derrota: legacyDerrota,
      };
    }
  }

  return null;
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

  const esModoPosiciones = norma?.modo === "posiciones";
  const puntosPorPosicion = Array.isArray(norma?.puntosPorPosicion)
    ? norma.puntosPorPosicion
    : [];
  const victoria = Number.isInteger(norma?.victoria) ? norma.victoria : 3;
  const empate = Number.isInteger(norma?.empate) ? norma.empate : 1;
  const derrota = Number.isInteger(norma?.derrota) ? norma.derrota : 0;

  for (const entries of byPartido.values()) {
    if (!entries.length) continue;

    if (esModoPosiciones) {
      const ordenados = entries
        .slice()
        .sort((a, b) => {
          const diff = Number(b.punto) - Number(a.punto);
          if (diff !== 0) return diff;
          return (
            Number(a.id_participacion_equipo) - Number(b.id_participacion_equipo)
          );
        });

      let posicionActual = 0;
      let ultimoPunto = null;

      for (let idx = 0; idx < ordenados.length; idx++) {
        const entry = ordenados[idx];
        if (ultimoPunto === null || Number(entry.punto) !== ultimoPunto) {
          posicionActual = idx + 1;
          ultimoPunto = Number(entry.punto);
        }

        const add = puntosPorPosicion[posicionActual - 1] ?? 0;
        puntosLiga.set(
          entry.id_participacion_equipo,
          (puntosLiga.get(entry.id_participacion_equipo) || 0) + add,
        );
      }

      continue;
    }

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
    const esEliminacionPorSerie = (torneoInfo?.tipo_torneo || "") === "Eliminación por serie";
    const normaLiga = esLiga
      ? parseNormaPuntuacionLiga(torneoInfo?.norma_puntuacion)
      : null;

    const totalParticipantes = puntuaciones.length;
    const puntuacionesNormalizadas = puntuaciones.map((item) => ({
      id_participacion_equipo: item.id_participacion_equipo,
      punto: item.punto,
      posicion: item.posicion,
    }));
    

    const usaReglaPosiciones =
      (esLiga && normaLiga?.modo === "posiciones") || esEliminacionPorSerie;
    if (usaReglaPosiciones) {
      const usaPosiciones = puntuacionesNormalizadas.every(
        (item) => item.posicion !== undefined && item.posicion !== null,
      );

      if (usaPosiciones) {
        const posiciones = puntuacionesNormalizadas.map((item) =>
          Number.parseInt(String(item.posicion), 10),
        );

        if (
          posiciones.some(
            (pos) =>
              !Number.isInteger(pos) || pos < 1 || pos > totalParticipantes,
          )
        ) {
          throw new AppError(
            400,
            `En modo posiciones, cada posicion debe ser entero entre 1 y ${totalParticipantes}`,
          );
        }

        if (new Set(posiciones).size !== posiciones.length) {
          throw new AppError(
            400,
            "En modo posiciones, no puede haber posiciones repetidas",
          );
        }

        for (let i = 0; i < puntuacionesNormalizadas.length; i++) {
          // Convertimos posicion (1 = mejor) a puntaje interno (mayor = mejor)
          // para mantener consistencia con ranking/ELO existentes.
          puntuacionesNormalizadas[i].punto = totalParticipantes - posiciones[i] + 1;
        }
      }
    }
    

    const actualizadas = [];
    // Nota: id_participacion_equipo es BIGINT en PG y node-postgres suele
    // devolverlo como string en resultados. Usamos claves string para evitar
    // desajustes al cruzar con el payload (que suele venir como number).
    const puntosPorParticipacion = new Map();

    if (esEliminacionDirecta || esEliminacionPorSerie) {
      const puntos = puntuacionesNormalizadas.map((p) => Number(p.punto));

      if (puntos.some((x) => !Number.isFinite(x))) {
        throw new AppError(
          400,
          "Cada puntuacion debe incluir punto o posicion valida",
        );
      }

      const max = Math.max(...puntos);
      const countMax = puntos.filter((x) => x === max).length;
      if (countMax !== 1) {
        throw new AppError(
          400,
          "En eliminacion no se permite empate: debe haber un ganador unico",
        );
      }
    }
    


    for (const item of puntuacionesNormalizadas) {
      const idParticipacionEquipo = item.id_participacion_equipo;
      const punto = Number(item.punto);

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

      puntosPorParticipacion.set(String(idParticipacionEquipo), punto);

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

    const equiposPartido = eloRows.rows.map((row) => row.id_equipo);

    const historialPartido = await client.query(
      `SELECT id_equipo, elo_anterior, elo_nuevo
       FROM historial_elo
       WHERE descripcion = $1
         AND id_equipo = ANY($2::bigint[])`,
      [`partido:${idPartido}`, equiposPartido],
    );

    let eloActualizado = [];
    let eloAplicado = false;

    const puntosPayload = puntuacionesNormalizadas.map((p) => Number(p.punto));
    const esEmpateMarcador =
      puntosPayload.length > 0 &&
      Math.max(...puntosPayload) === Math.min(...puntosPayload);

    const historialPorEquipo = new Map(
      historialPartido.rows.map((r) => [
        Number(r.id_equipo),
        {
          elo_anterior: Number(r.elo_anterior),
          elo_nuevo: Number(r.elo_nuevo),
        },
      ]),
    );

    const historialCompleto = historialPorEquipo.size === eloRows.rowCount;
    const historialTieneCambios = Array.from(historialPorEquipo.values()).some(
      (h) => h.elo_anterior !== h.elo_nuevo,
    );

    // Si existe historial para todos los equipos y:
    // - el partido fue empate -> delta 0 es válido
    // - o ya había cambios -> consideramos ELO aplicado
    // Si NO es empate y el historial es todo 0-delta, lo tratamos como caso
    // heredado por bug de mapeo y recalculamos/corregimos.
    if (historialCompleto && (esEmpateMarcador || historialTieneCambios)) {
      eloActualizado = eloRows.rows.map((row) => ({
        id_equipo: Number(row.id_equipo),
        equipo_nombre: row.nombre,
        elo_anterior: Number(row.elo),
        elo_nuevo: Number(row.elo),
        delta: 0,
      }));
    } else {
      const equiposConPunto = eloRows.rows.map((row) => {
        const idParticipacionKey = String(row.id_participacion_equipo);
        return {
          ...row,
          punto: puntosPorParticipacion.get(idParticipacionKey) ?? 0,
        };
      });

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
        const eloAnterior = Number(update.elo);
        const nuevoElo = Math.max(0, eloAnterior + update.delta);

        await client.query(
          `UPDATE equipo
           SET elo = $1
           WHERE id_equipo = $2`,
          [nuevoElo, update.id_equipo],
        );

        if (historialCompleto) {
          // Corrige el historial existente del partido (caso bug previo).
          await client.query(
            `UPDATE historial_elo
             SET elo_anterior = $1,
                 elo_nuevo = $2
             WHERE descripcion = $3
               AND id_equipo = $4`,
            [eloAnterior, nuevoElo, `partido:${idPartido}`, update.id_equipo],
          );
        } else {
          await client.query(
            `INSERT INTO historial_elo (id_equipo, elo_anterior, elo_nuevo, descripcion)
             VALUES ($1, $2, $3, $4)`,
            [update.id_equipo, eloAnterior, nuevoElo, `partido:${idPartido}`],
          );
        }

        eloActualizado.push({
          id_equipo: update.id_equipo,
          equipo_nombre: update.nombre,
          elo_anterior: eloAnterior,
          elo_nuevo: nuevoElo,
          delta: nuevoElo - eloAnterior,
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

const cancelPartido = async (idPartido) => {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    // Obtener información del partido
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

    // Validar que el partido está en estado "planificado"
    if (estadoPartido !== "planificado") {
      throw new AppError(
        400,
        `No se puede cancelar un partido en estado "${estadoPartido}". Solo se pueden cancelar partidos planificados.`
      );
    }

    // Obtener información del torneo
    const torneoResult = await client.query(
      `SELECT tt.nombre AS tipo_torneo, t.norma_puntuacion
       FROM torneo t
       JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
       WHERE t.id_torneo = $1`,
      [idTorneo],
    );

    const torneoInfo = torneoResult.rows[0] || null;
    const tipoTorneo = torneoInfo?.tipo_torneo || "";

    // Cambiar estado del partido a "cancelado"
    await client.query(
      `UPDATE partido
       SET estado = 'cancelado'
       WHERE id_partido = $1`,
      [idPartido],
    );

    // Manejar lógica específica por tipo de torneo
    if (tipoTorneo === "Liga") {
      // Para Liga, recomputar clasificación
      const normaLiga = parseNormaPuntuacionLiga(torneoInfo?.norma_puntuacion);
      if (normaLiga) {
        await recomputeClasificacionLiga(client, { idTorneo, norma: normaLiga });
      }
    } else if (tipoTorneo === "Eliminación directa") {
      // Para Eliminación directa, cancelar partidos siguientes que dependan de este
      await cancelarPartidosSiguientes(client, idPartido, idTorneo);
    } else if (tipoTorneo === "Eliminación por serie") {
      // Para Eliminación por serie, recomputar clasificación
      const normaLiga = parseNormaPuntuacionLiga(torneoInfo?.norma_puntuacion);
      if (normaLiga) {
        await recomputeClasificacionLiga(client, { idTorneo, norma: normaLiga });
      }
    } else {
      // Para otros formatos (Serie+final, Eliminatorias por rondas, Eliminación progresiva)
      // Por ahora, solo cambiar el estado
      // TODO: Implementar lógica específica si es necesario
    }

    await client.query("COMMIT");
    return getPartidoById(idPartido);
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
};

const cancelarPartidosSiguientes = async (client, idPartido, idTorneo) => {
  // Obtener el partido siguiente (para Eliminación directa)
  const siguienteResult = await client.query(
    `SELECT id_partido_siguiente FROM partido
     WHERE id_partido = $1`,
    [idPartido],
  );

  if (siguienteResult.rowCount && siguienteResult.rows[0].id_partido_siguiente) {
    const idPartidoSiguiente = siguienteResult.rows[0].id_partido_siguiente;
    
    // Cancelar el partido siguiente si está planificado
    await client.query(
      `UPDATE partido SET estado = 'cancelado'
       WHERE id_partido = $1 AND estado = 'planificado'`,
      [idPartidoSiguiente],
    );
    
    // Recursivamente cancelar los siguientes (aunque típicamente solo hay uno)
    await cancelarPartidosSiguientes(client, idPartidoSiguiente, idTorneo);
  }
};

module.exports = {
  listPartidos,
  getPartidoById,
  createPartido,
  updatePartido,
  deletePartido,
  registrarPuntuacionesArbitro,
  cancelPartido,
};