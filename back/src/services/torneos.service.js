const { pool } = require("../db/pool");
const { AppError } = require("../utils/errors");

const buildParticipantsCountJoin = () => `
  LEFT JOIN (
    SELECT id_torneo, COUNT(DISTINCT id_equipo)::int AS participantes_actuales
    FROM participacion_torneo_equipo
    GROUP BY id_torneo
  ) pcount ON pcount.id_torneo = t.id_torneo
`;

const listTorneos = async ({
  limit,
  offset,
  estado,
  organizadorId,
  categoriaId,
  tipoTorneoId,
}) => {
  const values = [limit, offset];
  const filters = [];

  if (estado) {
    values.push(estado);
    filters.push(`t.estado = $${values.length}`);
  }

  if (organizadorId) {
    values.push(organizadorId);
    filters.push(`t.id_organizador = $${values.length}`);
  }

  if (categoriaId) {
    values.push(categoriaId);
    filters.push(`t.id_categoria = $${values.length}`);
  }

  if (tipoTorneoId) {
    values.push(tipoTorneoId);
    filters.push(`t.id_tipo_torneo = $${values.length}`);
  }

  const where = filters.length ? `WHERE ${filters.join(" AND ")}` : "";

  const result = await pool.query(
    `SELECT
      t.id_torneo,
      t.nombre,
      t.descripcion,
      t.fecha_inicio,
      t.fecha_fin,
      t.estado,
      t.id_categoria,
      c.nombre AS categoria_nombre,
      t.id_tipo_torneo,
      tt.nombre AS tipo_torneo_nombre,
      t.id_organizador
        , c.participantes_por_partida AS participantes_por_partido
      , t.tipo_generacion_enfrentamientos
      , t.limite_equipos
      , COALESCE(pcount.participantes_actuales, 0)::int AS participantes_actuales
     FROM torneo t
     JOIN categoria c ON c.id_categoria = t.id_categoria
     JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
     ${buildParticipantsCountJoin()}
     ${where}
     ORDER BY t.id_torneo DESC
     LIMIT $1 OFFSET $2`,
    values,
  );

  return result.rows;
};

const getTorneoById = async (idTorneo) => {
  const result = await pool.query(
    `SELECT
      t.id_torneo,
      t.nombre,
      t.descripcion,
      t.fecha_inicio,
      t.fecha_fin,
      t.estado,
      t.id_categoria,
      c.nombre AS categoria_nombre,
      c.norma AS categoria_norma,
      t.id_tipo_torneo,
      tt.nombre AS tipo_torneo_nombre,
      t.id_organizador,
      c.participantes_por_partida AS participantes_por_partido,
      t.limite_equipos,
      COALESCE(pcount.participantes_actuales, 0)::int AS participantes_actuales,
      t.encuesta,
      t.norma_puntuacion,
      t.preferencia_horario,
      t.tipo_generacion_enfrentamientos
     FROM torneo t
     JOIN categoria c ON c.id_categoria = t.id_categoria
     JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
     ${buildParticipantsCountJoin()}
     WHERE t.id_torneo = $1`,
    [idTorneo],
  );

  return result.rows[0] || null;
};

const getClasificacionTorneo = async (idTorneo) => {
  // Verifica existencia
  const torneo = await getTorneoById(idTorneo);
  if (!torneo) return null;

  const result = await pool.query(
    `SELECT
       pte.id_participacion_equipo,
       e.id_equipo,
       e.nombre AS equipo_nombre,
       e.elo,
       COALESCE(pte.puntuacion, 0) AS puntos
     FROM participacion_torneo_equipo pte
     JOIN equipo e ON e.id_equipo = pte.id_equipo
     WHERE pte.id_torneo = $1
     ORDER BY COALESCE(pte.puntuacion, 0) DESC, e.nombre ASC`,
    [idTorneo],
  );

  return {
    id_torneo: Number(torneo.id_torneo),
    torneo_nombre: torneo.nombre,
    tipo_torneo_nombre: torneo.tipo_torneo_nombre,
    norma_puntuacion: torneo.norma_puntuacion,
    clasificacion: result.rows.map((r, idx) => ({
      posicion: idx + 1,
      id_participacion_equipo: Number(r.id_participacion_equipo),
      id_equipo: Number(r.id_equipo),
      equipo_nombre: r.equipo_nombre,
      elo: Number(r.elo),
      puntos: Number(r.puntos),
    })),
  };
};

const getPartidosTorneo = async (idTorneo) => {
  const torneo = await getTorneoById(idTorneo);
  if (!torneo) return null;

  const result = await pool.query(
    `SELECT
       p.id_partido,
       p.fecha_hora,
       p.lugar,
       p.estado,
       p.jornada,
       p.ronda,
       p.orden_ronda,
       p.orden_serie,
       p.id_partido_siguiente,
       p.ganador_id_participacion_equipo,
       COALESCE(
         json_agg(
           json_build_object(
             'id_participacion_equipo', pte.id_participacion_equipo,
             'id_equipo', e.id_equipo,
             'equipo_nombre', e.nombre,
             'punto', pp.punto
           )
           ORDER BY pte.id_participacion_equipo
         ) FILTER (WHERE pte.id_participacion_equipo IS NOT NULL),
         '[]'::json
       ) AS equipos
     FROM partido p
     LEFT JOIN participacion_partido pp ON pp.id_partido = p.id_partido
     LEFT JOIN participacion_torneo_equipo pte ON pte.id_participacion_equipo = pp.id_participacion_equipo
     LEFT JOIN equipo e ON e.id_equipo = pte.id_equipo
     WHERE p.id_torneo = $1
     GROUP BY p.id_partido
     ORDER BY
       p.ronda NULLS LAST,
       p.orden_ronda NULLS LAST,
       p.jornada NULLS LAST,
       p.fecha_hora ASC,
       p.id_partido ASC`,
    [idTorneo],
  );

  return {
    id_torneo: Number(torneo.id_torneo),
    torneo_nombre: torneo.nombre,
    tipo_torneo_nombre: torneo.tipo_torneo_nombre,
    norma_puntuacion: torneo.norma_puntuacion || "",
    partidos: result.rows.map((r) => {
      const rawEquipos = r.equipos;
      const equipos =
        typeof rawEquipos === "string" ? JSON.parse(rawEquipos) : rawEquipos;

      return {
        id_partido: Number(r.id_partido),
        fecha_hora: r.fecha_hora,
        lugar: r.lugar,
        estado: r.estado,
        jornada: r.jornada === null ? null : Number(r.jornada),
        ronda: r.ronda === null ? null : Number(r.ronda),
        orden_ronda: r.orden_ronda === null ? null : Number(r.orden_ronda),
        orden_serie: r.orden_serie === null ? null : Number(r.orden_serie),
        id_partido_siguiente:
          r.id_partido_siguiente === null ? null : Number(r.id_partido_siguiente),
        ganador_id_participacion_equipo:
          r.ganador_id_participacion_equipo === null
            ? null
            : Number(r.ganador_id_participacion_equipo),
        equipos: Array.isArray(equipos)
          ? equipos.map((e) => ({
              id_participacion_equipo: Number(e.id_participacion_equipo),
              id_equipo: Number(e.id_equipo),
              equipo_nombre: e.equipo_nombre,
              punto: Number(e.punto),
            }))
          : [],
      };
    }),
  };
};

const createTorneo = async (payload) => {
  const result = await pool.query(
    `INSERT INTO torneo (
      nombre, descripcion, fecha_inicio, fecha_fin, estado,
      id_categoria, id_tipo_torneo, id_organizador,
      encuesta, norma_puntuacion, preferencia_horario,
      tipo_generacion_enfrentamientos
     )
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb, $10, $11::jsonb, $12)
     RETURNING id_torneo`,
    [
      payload.nombre,
      payload.descripcion || null,
      payload.fecha_inicio || null,
      payload.fecha_fin || null,
      payload.estado || "inscripcion_abierta",
      payload.id_categoria,
      payload.id_tipo_torneo,
      payload.id_organizador || null,
      payload.encuesta ? JSON.stringify(payload.encuesta) : null,
      payload.norma_puntuacion || null,
      payload.preferencia_horario
        ? JSON.stringify(payload.preferencia_horario)
        : null,
      payload.tipo_generacion_enfrentamientos || null,
    ],
  );

  return getTorneoById(result.rows[0].id_torneo);
};

const updateTorneo = async (idTorneo, payload) => {
  if (payload.estado !== undefined) {
    const current = await pool.query(
      `SELECT estado FROM torneo WHERE id_torneo = $1`,
      [idTorneo],
    );

    if (current.rowCount) {
      const currentEstado = current.rows[0].estado;
      const nextEstado = payload.estado;

      if (nextEstado === "en_curso") {
        throw new AppError(
          400,
          "El estado 'en_curso' se establece automáticamente al generar enfrentamientos",
        );
      }

      if (currentEstado === "inscripcion_abierta") {
        const allowed = new Set([
          "inscripcion_abierta",
          "inscripcion_cerrada",
          "inscripcion_terminada",
          "cancelado",
        ]);

        if (!allowed.has(nextEstado)) {
          throw new AppError(
            400,
            "Desde 'inscripcion_abierta' solo puedes pasar a 'inscripcion_cerrada' o 'cancelado'",
            { from: currentEstado, to: nextEstado },
          );
        }
      }
    }
  }

  const mapping = {
    nombre: "nombre",
    descripcion: "descripcion",
    fecha_inicio: "fecha_inicio",
    fecha_fin: "fecha_fin",
    estado: "estado",
    id_categoria: "id_categoria",
    id_tipo_torneo: "id_tipo_torneo",
    id_organizador: "id_organizador",
    norma_puntuacion: "norma_puntuacion",
    tipo_generacion_enfrentamientos: "tipo_generacion_enfrentamientos",
  };

  const fields = [];
  const values = [];

  Object.keys(mapping).forEach((key) => {
    if (payload[key] !== undefined) {
      values.push(payload[key]);
      fields.push(`${mapping[key]} = $${values.length}`);
    }
  });

  if (payload.encuesta !== undefined) {
    values.push(payload.encuesta ? JSON.stringify(payload.encuesta) : null);
    fields.push(`encuesta = $${values.length}::jsonb`);
  }

  if (payload.preferencia_horario !== undefined) {
    values.push(
      payload.preferencia_horario
        ? JSON.stringify(payload.preferencia_horario)
        : null,
    );
    fields.push(`preferencia_horario = $${values.length}::jsonb`);
  }

  if (!fields.length) {
    return getTorneoById(idTorneo);
  }

  values.push(idTorneo);

  const result = await pool.query(
    `UPDATE torneo
     SET ${fields.join(", ")}
     WHERE id_torneo = $${values.length}
     RETURNING id_torneo`,
    values,
  );

  if (!result.rowCount) {
    return null;
  }

  return getTorneoById(idTorneo);
};

const deleteTorneo = async (idTorneo) => {
  const result = await pool.query(
    `DELETE FROM torneo
     WHERE id_torneo = $1
     RETURNING id_torneo`,
    [idTorneo],
  );

  return Boolean(result.rowCount);
};

const getFormularioByTorneoId = async (idTorneo) => {
  const result = await pool.query(
    `SELECT id_torneo, nombre, encuesta
     FROM torneo
     WHERE id_torneo = $1`,
    [idTorneo],
  );

  return result.rows[0] || null;
};

const updateFormularioByTorneoId = async (idTorneo, formulario) => {
  const result = await pool.query(
    `UPDATE torneo
     SET encuesta = $1::jsonb
     WHERE id_torneo = $2
     RETURNING id_torneo`,
    [formulario ? JSON.stringify(formulario) : null, idTorneo],
  );

  if (!result.rowCount) {
    return null;
  }

  return getFormularioByTorneoId(idTorneo);
};
function normalizeDay(day) {
  return String(day || "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "");
}

function nextPreferredDate(from, dayName) {
  const map = {
    domingo: 0,
    lunes: 1,
    martes: 2,
    miercoles: 3,
    jueves: 4,
    viernes: 5,
    sabado: 6,
  };
  const target = map[normalizeDay(dayName)];
  if (target === undefined) throw new Error(`Día inválido: ${dayName}`);

  const d = new Date(from);
  const diff = (target - d.getDay() + 7) % 7 || 7;
  d.setDate(d.getDate() + diff);
  return d;
}

function isPowerOfTwo(n) {
  return n > 1 && (n & (n - 1)) === 0;
}

function parseNormaConfig(norma) {
  if (!norma || typeof norma !== "string") return {};

  const config = {};
  const parts = norma
    .split(/[;,]/)
    .map((p) => p.trim())
    .filter(Boolean);

  for (const part of parts) {
    const sep = part.includes("=") ? "=" : part.includes(":") ? ":" : null;
    if (!sep) continue;
    const [k, v] = part.split(sep).map((x) => x.trim());
    if (!k || !v) continue;
    const maybeNumber = Number(v);
    config[k] = Number.isNaN(maybeNumber) ? v : maybeNumber;
  }

  return config;
}

function ordenarPorPunto(rows, asc = false) {
  return rows.slice().sort((a, b) => {
    const diff = asc ? Number(a.punto) - Number(b.punto) : Number(b.punto) - Number(a.punto);
    if (diff !== 0) return diff;
    return Number(a.id_participacion_equipo) - Number(b.id_participacion_equipo);
  });
}

function agruparParticipantes(ids, tamGrupo) {
  const grupos = [];
  for (let i = 0; i < ids.length; i += tamGrupo) {
    grupos.push(ids.slice(i, i + tamGrupo));
  }

  // Evitar grupos invalidos de 1 participante.
  if (grupos.length > 1 && grupos[grupos.length - 1].length === 1) {
    const ultimo = grupos.pop()[0];
    grupos[grupos.length - 1].push(ultimo);
  }

  return grupos.filter((g) => g.length >= 2);
}

async function getParticipantesPorPartido(client, idPartido) {
  const q = await client.query(
    `
    SELECT id_participacion_equipo, punto
    FROM participacion_partido
    WHERE id_partido = $1
    ORDER BY id_participacion_equipo ASC
    `,
    [idPartido],
  );
  return q.rows;
}

async function generarSiguienteRondaMismasSeries({
  client,
  idTorneo,
  partidos,
  arbitros,
  idxArbitro,
  rondaActual,
  preferenciaDias,
}) {
  const ultimaFechaQ = await client.query(
    `SELECT MAX(fecha_hora) AS max_fecha FROM partido WHERE id_torneo = $1 AND ronda = $2`,
    [idTorneo, rondaActual],
  );

  let cursor = ultimaFechaQ.rows[0].max_fecha
    ? new Date(ultimaFechaQ.rows[0].max_fecha)
    : new Date();
  let idxDia = 0;
  const nuevaRonda = rondaActual + 1;
  let orden = 1;
  const nuevosPartidos = [];

  for (const p of partidos) {
    // Obtener orden_serie del partido anterior
    const serieQ = await client.query(
      `SELECT orden_serie FROM partido WHERE id_partido = $1`,
      [p.id_partido],
    );
    const orden_serie = serieQ.rows[0]?.orden_serie || 0;

    const participantes = await getParticipantesPorPartido(client, p.id_partido);
    const ids = participantes.map((x) => Number(x.id_participacion_equipo));
    if (ids.length < 2) {
      throw new Error(`Partido ${p.id_partido} inválido: faltan participantes`);
    }

    const fecha = nextPreferredDate(cursor, preferenciaDias[idxDia % preferenciaDias.length]);
    cursor = new Date(fecha.getTime() + 24 * 60 * 60 * 1000);
    idxDia++;

    const idPartidoNuevo = await crearPartido(client, {
      idTorneo,
      fecha,
      ronda: nuevaRonda,
      orden,
      orden_serie,
    });
    await insertarParticipacionesPartido(client, idPartidoNuevo, ids);

    const picked = await elegirArbitroDisponible(client, {
      arbitros,
      startIndex: idxArbitro,
      idPartido: idPartidoNuevo,
    });
    await asignarArbitroPartido(client, {
      idPartido: idPartidoNuevo,
      idArbitroTorneo: picked.idArbitroTorneo,
    });
    idxArbitro = picked.nextIndex;

    await client.query(
      `UPDATE partido SET id_partido_siguiente = $1 WHERE id_partido = $2`,
      [idPartidoNuevo, p.id_partido],
    );

    nuevosPartidos.push(idPartidoNuevo);
    orden++;
  }

  return {
    rondaGenerada: nuevaRonda,
    partidosGenerados: nuevosPartidos.length,
  };
}

async function getTorneo(client, idTorneo) {
  const q = await client.query(
    `
    SELECT
      t.id_torneo,
      t.fecha_inicio,
      t.preferencia_horario,
      t.norma_puntuacion,
      tt.nombre AS tipo,
      c.participantes_por_partida AS participantes_por_partido
    FROM torneo t
    JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
    JOIN categoria c ON c.id_categoria = t.id_categoria
    WHERE t.id_torneo = $1
    `,
    [idTorneo],
  );
  if (!q.rowCount) throw new Error("Torneo no encontrado");
  return q.rows[0];
}

async function getParticipacionesJugando(client, idTorneo) {
  const q = await client.query(
    `
    SELECT id_participacion_equipo, id_equipo, fecha
    FROM participacion_torneo_equipo
    WHERE id_torneo = $1 AND estado = 'jugando'
    ORDER BY fecha ASC, id_participacion_equipo ASC
    `,
    [idTorneo],
  );
  return q.rows;
}

async function crearPartido(
  client,
  { idTorneo, fecha, ronda = null, orden = null, orden_serie = 0 },
) {
  const q = await client.query(
    `
    INSERT INTO partido (id_torneo, fecha_hora, estado, jornada, ronda, orden_ronda, orden_serie)
    VALUES ($1, $2, 'planificado', $3, $4, $5, $6)
    RETURNING id_partido
    `,
    [idTorneo, fecha, null, ronda, orden, orden_serie],
  );
  return q.rows[0].id_partido;
}

async function crearPartidoLiga(client, { idTorneo, fecha, jornada }) {
  const q = await client.query(
    `
    INSERT INTO partido (id_torneo, fecha_hora, estado, jornada, ronda, orden_ronda)
    VALUES ($1, $2, 'planificado', $3, NULL, NULL)
    RETURNING id_partido
    `,
    [idTorneo, fecha, jornada],
  );
  return q.rows[0].id_partido;
}

async function insertarParticipacionesPartido(
  client,
  idPartido,
  participaciones,
) {
  const placeholders = participaciones
    .map((_, idx) => `($1, $${idx + 2})`)
    .join(", ");

  await client.query(
    `
    INSERT INTO participacion_partido (id_partido, id_participacion_equipo)
    VALUES ${placeholders}
    `,
    [idPartido, ...participaciones],
  );
}

async function getArbitrosTorneo(client, idTorneo) {
  // Compatibilidad: algunos esquemas modelan árbitros globales (sin id_torneo)
  // y otros los asocian por torneo (con id_torneo). Detectamos la columna.
  const hasIdTorneo = await client.query(
    `
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND table_name = 'arbitro_torneo'
      AND column_name = 'id_torneo'
    LIMIT 1
    `,
  );

  const q = hasIdTorneo.rowCount
    ? await client.query(
        `
        SELECT id_arbitro_torneo
        FROM arbitro_torneo
        WHERE id_torneo = $1 OR id_torneo IS NULL
        ORDER BY id_arbitro_torneo ASC
        `,
        [idTorneo],
      )
    : await client.query(
        `
        SELECT id_arbitro_torneo
        FROM arbitro_torneo
        ORDER BY id_arbitro_torneo ASC
        `,
      );

  return q.rows.map((r) => Number(r.id_arbitro_torneo));
}

async function asignarArbitroPartido(client, { idPartido, idArbitroTorneo }) {
  await client.query(
    `
    INSERT INTO arbitro_partido (id_partido, id_arbitro_torneo, acta)
    VALUES ($1, $2, NULL)
    ON CONFLICT (id_partido, id_arbitro_torneo)
    DO NOTHING
    `,
    [idPartido, idArbitroTorneo],
  );
}

async function arbitroParticipaEnPartido(client, { idArbitroTorneo, idPartido }) {
  // Un árbitro NO debe arbitrar si juega el partido (pertenece a un equipo participante
  // en la fecha del partido). Esta lógica funciona tanto para partidos 1v1 como multi.
  const q = await client.query(
    `
    SELECT 1
    FROM arbitro_torneo at
    JOIN pertenece pe ON pe.id_usuario = at.id_usuario
    JOIN partido pa ON pa.id_partido = $2
    JOIN participacion_partido pp ON pp.id_partido = pa.id_partido
    JOIN participacion_torneo_equipo pte
      ON pte.id_participacion_equipo = pp.id_participacion_equipo
     AND pte.id_equipo = pe.id_equipo
    WHERE at.id_arbitro_torneo = $1
      AND (pa.fecha_hora::date >= pe.fecha_inicio)
      AND (pe.fecha_fin IS NULL OR pa.fecha_hora::date <= pe.fecha_fin)
    LIMIT 1
    `,
    [idArbitroTorneo, idPartido],
  );
  return Boolean(q.rowCount);
}

async function elegirArbitroDisponible(client, {
  arbitros,
  startIndex,
  idPartido,
}) {
  if (!arbitros.length) {
    throw new Error("Se requiere al menos 1 árbitro para generar enfrentamientos");
  }

  for (let offset = 0; offset < arbitros.length; offset++) {
    const idx = (startIndex + offset) % arbitros.length;
    const idArbitroTorneo = arbitros[idx];

    const participa = await arbitroParticipaEnPartido(client, {
      idArbitroTorneo,
      idPartido,
    });
    if (!participa) {
      return { idArbitroTorneo, nextIndex: idx + 1 };
    }
  }

  throw new Error(
    "No hay árbitros disponibles que no participen en el partido (conflicto árbitro/jugador)",
  );
}

function construirJornadasDuelo(participaciones, dobleVuelta = true) {
  const equipos = participaciones.slice();
  if (equipos.length < 2) return [];

  const esImpar = equipos.length % 2 !== 0;
  if (esImpar) equipos.push(null);

  const total = equipos.length;
  const rondas = total - 1;
  const jornadasIda = [];
  let rot = equipos.slice();

  for (let r = 0; r < rondas; r++) {
    const partidos = [];
    for (let i = 0; i < total / 2; i++) {
      const a = rot[i];
      const b = rot[total - 1 - i];
      if (a && b)
        partidos.push([a.id_participacion_equipo, b.id_participacion_equipo]);
    }
    jornadasIda.push(partidos);
    rot = [rot[0], rot[total - 1], ...rot.slice(1, total - 1)];
  }

  if (!dobleVuelta) return jornadasIda;
  const jornadasVuelta = jornadasIda.map((j) => j.map(([a, b]) => [b, a]));
  return [...jornadasIda, ...jornadasVuelta];
}

function construirJornadasMulti(participaciones, participantesPorPartido) {
  const totalJornadas = participaciones.length;
  const jornadas = [];

  for (let j = 0; j < totalJornadas; j++) {
    const rotadas = participaciones
      .slice(j)
      .concat(participaciones.slice(0, j));
    const partidos = [];

    for (
      let i = 0;
      i + participantesPorPartido <= rotadas.length;
      i += participantesPorPartido
    ) {
      partidos.push(
        rotadas
          .slice(i, i + participantesPorPartido)
          .map((p) => p.id_participacion_equipo),
      );
    }

    if (partidos.length) jornadas.push(partidos);
  }

  return jornadas;
}

function keyPar(a, b) {
  const left = Number(a);
  const right = Number(b);
  return left < right ? `${left}-${right}` : `${right}-${left}`;
}

function elegirGrupoBalanceado({
  disponibles,
  tamGrupo,
  apariciones,
  descansos,
  paresJugados,
}) {
  const lista = Array.from(disponibles).map((id) => Number(id));
  if (lista.length < tamGrupo) return null;

  lista.sort((a, b) => {
    const diffApariciones = (apariciones.get(a) || 0) - (apariciones.get(b) || 0);
    if (diffApariciones !== 0) return diffApariciones;
    const diffDescansos = (descansos.get(b) || 0) - (descansos.get(a) || 0);
    if (diffDescansos !== 0) return diffDescansos;
    return a - b;
  });

  const grupo = [lista[0]];

  while (grupo.length < tamGrupo) {
    const candidatos = lista.filter((id) => !grupo.includes(id));
    if (!candidatos.length) return null;

    candidatos.sort((a, b) => {
      const coste = (id) => {
        let total = 0;

        for (const actual of grupo) {
          total += (paresJugados.get(keyPar(id, actual)) || 0) * 100;
        }

        total += (apariciones.get(id) || 0) * 4;
        total -= (descansos.get(id) || 0) * 3;
        return total;
      };

      const diffCoste = coste(a) - coste(b);
      if (diffCoste !== 0) return diffCoste;
      return a - b;
    });

    grupo.push(candidatos[0]);
  }

  return grupo;
}

function construirJornadasMultiBalanceada(
  participaciones,
  participantesPorPartido,
  jornadasObjetivo,
) {
  const ids = participaciones.map((p) => Number(p.id_participacion_equipo));
  const jornadas = [];
  const apariciones = new Map(ids.map((id) => [id, 0]));
  const descansos = new Map(ids.map((id) => [id, 0]));
  const paresJugados = new Map();

  for (let jornada = 0; jornada < jornadasObjetivo; jornada++) {
    const disponibles = new Set(ids);
    const partidosJornada = [];

    while (disponibles.size >= participantesPorPartido) {
      const grupo = elegirGrupoBalanceado({
        disponibles,
        tamGrupo: participantesPorPartido,
        apariciones,
        descansos,
        paresJugados,
      });

      if (!grupo || grupo.length < participantesPorPartido) {
        break;
      }

      for (const id of grupo) {
        disponibles.delete(id);
      }

      for (let i = 0; i < grupo.length; i++) {
        for (let j = i + 1; j < grupo.length; j++) {
          const key = keyPar(grupo[i], grupo[j]);
          paresJugados.set(key, (paresJugados.get(key) || 0) + 1);
        }
      }

      for (const id of grupo) {
        apariciones.set(id, (apariciones.get(id) || 0) + 1);
      }

      partidosJornada.push(grupo);
    }

    for (const id of disponibles) {
      descansos.set(id, (descansos.get(Number(id)) || 0) + 1);
    }

    if (partidosJornada.length) {
      jornadas.push(partidosJornada);
    }
  }

  return jornadas;
}

async function generarLiga(idTorneo) {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const torneo = await getTorneo(client, idTorneo);
    if (torneo.tipo !== "Liga") throw new Error("El torneo no es de tipo Liga");

    const existe = await client.query(
      `SELECT 1 FROM partido WHERE id_torneo = $1 LIMIT 1`,
      [idTorneo],
    );
    if (existe.rowCount)
      throw new Error("Este torneo ya tiene partidos generados");

    const dias = Array.isArray(torneo.preferencia_horario?.dias)
      ? torneo.preferencia_horario.dias
      : [];
    if (!dias.length)
      throw new Error("preferencia_horario.dias es obligatorio");

    const participaciones = await getParticipacionesJugando(client, idTorneo);
    if (participaciones.length < 2)
      throw new Error("Se requieren al menos 2 equipos");

    const participantesPorPartido = Number(
      torneo.participantes_por_partido || 2,
    );
    if (
      !Number.isInteger(participantesPorPartido) ||
      participantesPorPartido < 2
    ) {
      throw new Error("participantes_por_partido debe ser un entero >= 2");
    }
    if (participaciones.length < participantesPorPartido) {
      throw new Error(
        "No hay suficientes equipos para el tamano de partido configurado",
      );
    }

    const arbitros = await getArbitrosTorneo(client, idTorneo);
    if (!arbitros.length) {
      throw new Error(
        "Se requiere al menos 1 árbitro para generar enfrentamientos",
      );
    }
    let idxArbitro = 0;

    let cursor = torneo.fecha_inicio
      ? new Date(torneo.fecha_inicio)
      : new Date();
    let idxDia = 0;
    let total = 0;

    const normaConfig = parseNormaConfig(torneo.norma_puntuacion);
    const jornadasObjetivoRaw = Number(
      normaConfig.jornadas_multi || participaciones.length,
    );
    const jornadasObjetivo =
      Number.isInteger(jornadasObjetivoRaw) && jornadasObjetivoRaw > 0
        ? jornadasObjetivoRaw
        : participaciones.length;

    let jornadas = [];
    if (participantesPorPartido === 2) {
      jornadas = construirJornadasDuelo(participaciones, true);
    } else {
      const estrategiaMulti = String(
        normaConfig.estrategia_multi || "balanceada",
      ).toLowerCase();

      if (estrategiaMulti === "rotacion") {
        jornadas = construirJornadasMulti(participaciones, participantesPorPartido);
      } else {
        jornadas = construirJornadasMultiBalanceada(
          participaciones,
          participantesPorPartido,
          jornadasObjetivo,
        );

        if (!jornadas.length) {
          jornadas = construirJornadasMulti(
            participaciones,
            participantesPorPartido,
          );
        }
      }
    }

    for (let idxJornada = 0; idxJornada < jornadas.length; idxJornada++) {
      const fechaJornada = nextPreferredDate(
        cursor,
        dias[idxDia % dias.length],
      );
      cursor = new Date(fechaJornada.getTime() + 24 * 60 * 60 * 1000);
      idxDia++;

      const jornada = idxJornada + 1;
      for (const participantesDelPartido of jornadas[idxJornada]) {
        const idPartido = await crearPartidoLiga(client, {
          idTorneo,
          fecha: fechaJornada,
          jornada,
        });
        await insertarParticipacionesPartido(
          client,
          idPartido,
          participantesDelPartido,
        );

        const picked = await elegirArbitroDisponible(client, {
          arbitros,
          startIndex: idxArbitro,
          idPartido,
        });
        await asignarArbitroPartido(client, {
          idPartido,
          idArbitroTorneo: picked.idArbitroTorneo,
        });
        idxArbitro = picked.nextIndex;
        total++;
      }
    }

    await client.query(`UPDATE torneo SET estado = 'en_curso' WHERE id_torneo = $1`, [idTorneo]);

    await client.query("COMMIT");
    return { ok: true, tipo: "Liga", partidosGenerados: total };
  } catch (e) {
    await client.query("ROLLBACK");
    throw e;
  } finally {
    client.release();
  }
}

async function generarEliminacion(idTorneo) {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const torneo = await getTorneo(client, idTorneo);
    if (torneo.tipo !== "Eliminación directa") {
      throw new Error("El torneo no es de eliminación directa");
    }

    const existe = await client.query(
      `SELECT 1 FROM partido WHERE id_torneo = $1 LIMIT 1`,
      [idTorneo],
    );
    if (existe.rowCount)
      throw new Error("Este torneo ya tiene partidos generados");

    const dias = Array.isArray(torneo.preferencia_horario?.dias)
      ? torneo.preferencia_horario.dias
      : [];
    if (!dias.length)
      throw new Error("preferencia_horario.dias es obligatorio");

    const participaciones = await getParticipacionesJugando(client, idTorneo);
    if (!isPowerOfTwo(participaciones.length)) {
      throw new Error("En eliminación directa, equipos debe ser potencia de 2");
    }

    const arbitros = await getArbitrosTorneo(client, idTorneo);
    if (!arbitros.length) {
      throw new Error(
        "Se requiere al menos 1 árbitro para generar enfrentamientos",
      );
    }
    let idxArbitro = 0;

    let cursor = torneo.fecha_inicio
      ? new Date(torneo.fecha_inicio)
      : new Date();
    let idxDia = 0;
    let orden = 1;

    for (let i = 0; i < participaciones.length; i += 2) {
      const a = participaciones[i];
      const b = participaciones[i + 1];
      const fecha = nextPreferredDate(cursor, dias[idxDia % dias.length]);
      cursor = new Date(fecha.getTime() + 24 * 60 * 60 * 1000);
      idxDia++;

      const idPartido = await crearPartido(client, {
        idTorneo,
        fecha,
        ronda: 1,
        orden,
      });
      await insertarParticipacionesPartido(client, idPartido, [
        a.id_participacion_equipo,
        b.id_participacion_equipo,
      ]);

      const picked = await elegirArbitroDisponible(client, {
        arbitros,
        startIndex: idxArbitro,
        idPartido,
      });
      await asignarArbitroPartido(client, {
        idPartido,
        idArbitroTorneo: picked.idArbitroTorneo,
      });
      idxArbitro = picked.nextIndex;
      orden++;
    }

    await client.query(`UPDATE torneo SET estado = 'en_curso' WHERE id_torneo = $1`, [idTorneo]);

    await client.query("COMMIT");
    return { ok: true, tipo: "Eliminación directa", rondaGenerada: 1 };
  } catch (e) {
    await client.query("ROLLBACK");
    throw e;
  } finally {
    client.release();
  }
}

async function generarEliminacionMultiInicio(idTorneo, tipoEsperado) {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const torneo = await getTorneo(client, idTorneo);
    if (torneo.tipo !== tipoEsperado) {
      throw new Error(`El torneo no es de tipo ${tipoEsperado}`);
    }

    const existe = await client.query(
      `SELECT 1 FROM partido WHERE id_torneo = $1 LIMIT 1`,
      [idTorneo],
    );
    if (existe.rowCount) {
      throw new Error("Este torneo ya tiene partidos generados");
    }

    const dias = Array.isArray(torneo.preferencia_horario?.dias)
      ? torneo.preferencia_horario.dias
      : [];
    if (!dias.length) {
      throw new Error("preferencia_horario.dias es obligatorio");
    }

    const participaciones = await getParticipacionesJugando(client, idTorneo);
    const limiteEquipos = Number(torneo.limite_equipos || 0);
    const participacionesBracket =
      Number.isInteger(limiteEquipos) && limiteEquipos > 0
        ? participaciones.slice(0, limiteEquipos)
        : participaciones;
    const tamGrupo = Number(torneo.participantes_por_partido || 2);
    if (!Number.isInteger(tamGrupo) || tamGrupo < 2) {
      throw new Error("participantes_por_partido debe ser un entero >= 2");
    }
    if (tipoEsperado === "Eliminación por serie" && tamGrupo <= 2) {
      throw new Error("El tipo 'Eliminación por serie' solo está soportado para categorías multi (>2)");
    }
    if (participacionesBracket.length < 2) {
      throw new Error("Se requieren al menos 2 participantes para generar eliminacion");
    }

    const ids = participacionesBracket.map((p) => p.id_participacion_equipo);
    const grupos = agruparParticipantes(ids, tamGrupo);
    if (!grupos.length) {
      throw new Error("No se pudieron formar series validas para la primera ronda");
    }

    const arbitros = await getArbitrosTorneo(client, idTorneo);
    if (!arbitros.length) {
      throw new Error(
        "Se requiere al menos 1 árbitro para generar enfrentamientos",
      );
    }
    let idxArbitro = 0;

    let cursor = torneo.fecha_inicio ? new Date(torneo.fecha_inicio) : new Date();
    let idxDia = 0;
    let orden = 1;

    for (let idxSerie = 0; idxSerie < grupos.length; idxSerie++) {
      const grupo = grupos[idxSerie];
      const orden_serie = idxSerie + 1; // Serie 1, 2, 3, ... para "Eliminación por serie"
      const fecha = nextPreferredDate(cursor, dias[idxDia % dias.length]);
      cursor = new Date(fecha.getTime() + 24 * 60 * 60 * 1000);
      idxDia++;

      const idPartido = await crearPartido(client, {
        idTorneo,
        fecha,
        ronda: 1,
        orden,
        orden_serie, // Rastrar a qué serie pertenece este partido
      });

      await insertarParticipacionesPartido(client, idPartido, grupo);

      const picked = await elegirArbitroDisponible(client, {
        arbitros,
        startIndex: idxArbitro,
        idPartido,
      });
      await asignarArbitroPartido(client, {
        idPartido,
        idArbitroTorneo: picked.idArbitroTorneo,
      });
      idxArbitro = picked.nextIndex;
      orden++;
    }

    await client.query(`UPDATE torneo SET estado = 'en_curso' WHERE id_torneo = $1`, [idTorneo]);

    await client.query("COMMIT");
    return {
      ok: true,
      tipo: tipoEsperado,
      rondaGenerada: 1,
      partidosGenerados: grupos.length,
    };
  } catch (e) {
    await client.query("ROLLBACK");
    throw e;
  } finally {
    client.release();
  }
}

async function avanzarRondaEliminacion(idTorneo) {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const torneo = await getTorneo(client, idTorneo);
    const tiposSoportados = [
      "Eliminación directa",
      "Serie + final (con tiempos)",
      "Eliminatorias por rondas",
      "Eliminación progresiva",
      "Eliminación por serie",
    ];
    if (!tiposSoportados.includes(torneo.tipo)) {
      throw new Error("El torneo no es de un tipo de eliminación soportado");
    }

    const arbitros = await getArbitrosTorneo(client, idTorneo);
    if (!arbitros.length) {
      throw new Error(
        "Se requiere al menos 1 árbitro para generar la siguiente ronda",
      );
    }
    let idxArbitro = 0;

    const maxRondaQ = await client.query(
      `SELECT MAX(ronda) AS max_ronda FROM partido WHERE id_torneo = $1`,
      [idTorneo],
    );
    const rondaActual = Number(maxRondaQ.rows[0].max_ronda || 0);
    if (!rondaActual) throw new Error("No hay bracket generado");

    const partidosQ = await client.query(
      `
      SELECT id_partido, estado, orden_ronda
      FROM partido
      WHERE id_torneo = $1 AND ronda = $2
      ORDER BY orden_ronda
      `,
      [idTorneo, rondaActual],
    );
    const partidos = partidosQ.rows;
    if (partidos.some((p) => p.estado !== "acabado")) {
      throw new Error(
        "Todos los partidos de la ronda actual deben estar acabados",
      );
    }

    const normaConfig = parseNormaConfig(torneo.norma_puntuacion);
    const criterioAsc = String(normaConfig.criterio || "desc").toLowerCase() === "asc";
    const tamGrupo = Number(torneo.participantes_por_partido || 2);

    if (torneo.tipo === "Eliminación por serie") {
      if (!Number.isInteger(tamGrupo) || tamGrupo <= 2) {
        throw new Error("El tipo 'Eliminación por serie' requiere participantes_por_partido > 2");
      }

      const rondasPorSerieRaw = Number(normaConfig.rondas_por_serie || normaConfig.rondasSerie || 1);
      const rondasPorSerie =
        Number.isInteger(rondasPorSerieRaw) && rondasPorSerieRaw > 0
          ? rondasPorSerieRaw
          : 1;

      const dias = Array.isArray(torneo.preferencia_horario?.dias)
        ? torneo.preferencia_horario.dias
        : [];
      if (!dias.length) {
        throw new Error("preferencia_horario.dias es obligatorio");
      }

      const subRondaActual = ((rondaActual - 1) % rondasPorSerie) + 1;
      const ultimaSubRondaSerie = subRondaActual === rondasPorSerie;

      if (!ultimaSubRondaSerie) {
        const repeticion = await generarSiguienteRondaMismasSeries({
          client,
          idTorneo,
          partidos,
          arbitros,
          idxArbitro,
          rondaActual,
          preferenciaDias: dias,
        });

        await client.query("COMMIT");
        return {
          ok: true,
          torneoFinalizado: false,
          modo: "eliminacion_por_serie",
          etapaCompletada: false,
          subRondaActual,
          rondasPorSerie,
          rondaGenerada: repeticion.rondaGenerada,
          partidosGenerados: repeticion.partidosGenerados,
        };
      }

      const inicioBloque = rondaActual - (rondasPorSerie - 1);
      const rankingRonda = [];

      for (const p of partidos) {
        const idsRes = await client.query(
          `
          SELECT id_participacion_equipo
          FROM participacion_partido
          WHERE id_partido = $1
          ORDER BY id_participacion_equipo ASC
          `,
          [p.id_partido],
        );
        const idsSerie = idsRes.rows.map((r) => Number(r.id_participacion_equipo));
        if (idsSerie.length < 2) {
          throw new Error(`Partido ${p.id_partido} inválido: faltan participantes`);
        }

        const puntajeBloque = await client.query(
          `
          SELECT
            pp.id_participacion_equipo,
            COALESCE(SUM(pp.punto), 0)::numeric AS punto
          FROM partido p
          JOIN participacion_partido pp ON pp.id_partido = p.id_partido
          WHERE p.id_torneo = $1
            AND p.ronda BETWEEN $2 AND $3
            AND pp.id_participacion_equipo = ANY($4::bigint[])
          GROUP BY pp.id_participacion_equipo
          `,
          [idTorneo, inicioBloque, rondaActual, idsSerie],
        );

        const filas = idsSerie.map((id) => {
          const hit = puntajeBloque.rows.find(
            (x) => Number(x.id_participacion_equipo) === Number(id),
          );
          return {
            id_participacion_equipo: Number(id),
            punto: Number(hit?.punto || 0),
          };
        });

        const ordenados = ordenarPorPunto(filas, criterioAsc);
        rankingRonda.push({
          id_partido: p.id_partido,
          ranking: ordenados.map((r, idx) => ({
            id_participacion_equipo: Number(r.id_participacion_equipo),
            punto: Number(r.punto),
            posicion: idx + 1,
          })),
        });
      }

      const participantesActuales = rankingRonda.flatMap((x) =>
        x.ranking.map((r) => r.id_participacion_equipo),
      );
      const totalActuales = participantesActuales.length;

      // En etapas intermedias clasifica por serie; en etapa final queda campeón.
      const finalistas = totalActuales <= tamGrupo;
      const clasifPorSerieCfg = Number(
        normaConfig.clasifican_por_serie || normaConfig.clasificados_por_serie || Math.ceil(tamGrupo / 2),
      );
      const clasifPorSerie = finalistas
        ? 1
        : Math.max(1, Math.min(tamGrupo - 1, Number.isFinite(clasifPorSerieCfg) ? clasifPorSerieCfg : Math.ceil(tamGrupo / 2)));

      let clasificados = rankingRonda.flatMap((serie) =>
        serie.ranking.slice(0, clasifPorSerie).map((r) => r.id_participacion_equipo),
      );

      clasificados = Array.from(new Set(clasificados));

      const clasificadosSet = new Set(clasificados);
      const eliminados = participantesActuales.filter((id) => !clasificadosSet.has(id));

      if (eliminados.length) {
        await client.query(
          `UPDATE participacion_torneo_equipo SET estado = 'eliminado' WHERE id_participacion_equipo = ANY($1::bigint[])`,
          [eliminados],
        );
      }

      if (clasificados.length <= 1) {
        const campeon = clasificados[0] || null;
        if (campeon) {
          await client.query(
            `UPDATE torneo SET estado = 'finalizado', id_campeon_participacion = $1 WHERE id_torneo = $2`,
            [campeon, idTorneo],
          );
        } else {
          await client.query(
            `UPDATE torneo SET estado = 'finalizado' WHERE id_torneo = $1`,
            [idTorneo],
          );
        }
        await client.query("COMMIT");
        return {
          ok: true,
          torneoFinalizado: true,
          modo: "eliminacion_por_serie",
          campeonIdParticipacionEquipo: campeon,
        };
      }

      const ultimaFechaQ = await client.query(
        `SELECT MAX(fecha_hora) AS max_fecha FROM partido WHERE id_torneo = $1 AND ronda = $2`,
        [idTorneo, rondaActual],
      );
      let cursor = ultimaFechaQ.rows[0].max_fecha
        ? new Date(ultimaFechaQ.rows[0].max_fecha)
        : new Date();
      let idxDia = 0;

      const nuevaRonda = rondaActual + 1;
      const gruposSiguiente =
        clasificados.length <= tamGrupo
          ? [clasificados]
          : agruparParticipantes(clasificados, tamGrupo);

      let orden = 1;
      const nuevosPartidos = [];
      for (let idxSerie = 0; idxSerie < gruposSiguiente.length; idxSerie++) {
        const grupo = gruposSiguiente[idxSerie];
        const orden_serie = idxSerie + 1; // Nueva serie en siguiente ronda
        const fecha = nextPreferredDate(cursor, dias[idxDia % dias.length]);
        cursor = new Date(fecha.getTime() + 24 * 60 * 60 * 1000);
        idxDia++;

        const idPartidoNuevo = await crearPartido(client, {
          idTorneo,
          fecha,
          ronda: nuevaRonda,
          orden,
          orden_serie, // Rastrar nueva serie
        });
        await insertarParticipacionesPartido(client, idPartidoNuevo, grupo);

        const picked = await elegirArbitroDisponible(client, {
          arbitros,
          startIndex: idxArbitro,
          idPartido: idPartidoNuevo,
        });
        await asignarArbitroPartido(client, {
          idPartido: idPartidoNuevo,
          idArbitroTorneo: picked.idArbitroTorneo,
        });
        idxArbitro = picked.nextIndex;
        nuevosPartidos.push(idPartidoNuevo);
        orden++;
      }

      await client.query("COMMIT");
      return {
        ok: true,
        torneoFinalizado: false,
        modo: "eliminacion_por_serie",
        etapaCompletada: true,
        subRondaActual,
        rondasPorSerie,
        rondaGenerada: nuevaRonda,
        partidosGenerados: nuevosPartidos.length,
        clasificados: clasificados.length,
      };
    }

    const rankingRonda = [];
    const ganadores = [];
    for (const p of partidos) {
      const ganadorSet = await client.query(
        `
        SELECT ganador_id_participacion_equipo
        FROM partido
        WHERE id_partido = $1
        `,
        [p.id_partido],
      );

      let ganador = ganadorSet.rows[0].ganador_id_participacion_equipo;
      const pp = await client.query(
        `
        SELECT id_participacion_equipo, punto
        FROM participacion_partido
        WHERE id_partido = $1
        `,
        [p.id_partido],
      );

      if (pp.rowCount < 2) {
        throw new Error(`Partido ${p.id_partido} inválido: faltan resultados`);
      }

      const ordenados = ordenarPorPunto(pp.rows, criterioAsc);
      if (!ganador) {
        ganador = ordenados[0].id_participacion_equipo;
        await client.query(
          `UPDATE partido SET ganador_id_participacion_equipo = $1 WHERE id_partido = $2`,
          [ganador, p.id_partido],
        );
      }

      rankingRonda.push({
        id_partido: p.id_partido,
        ranking: ordenados.map((r, idx) => ({
          id_participacion_equipo: Number(r.id_participacion_equipo),
          punto: Number(r.punto),
          posicion: idx + 1,
        })),
      });

      ganadores.push({
        id_partido_origen: p.id_partido,
        id_participacion_equipo: Number(ordenados[0].id_participacion_equipo),
      });
    }

    let clasificados = [];
    if (torneo.tipo === "Eliminación directa") {
      clasificados = ganadores.map((g) => g.id_participacion_equipo);
    } else if (torneo.tipo === "Serie + final (con tiempos)") {
      if (rondaActual >= 2) {
        const campeon = ganadores[0].id_participacion_equipo;
        if (campeon) {
          await client.query(
            `UPDATE torneo SET estado = 'finalizado', id_campeon_participacion = $1 WHERE id_torneo = $2`,
            [campeon, idTorneo],
          );
        } else {
          await client.query(`UPDATE torneo SET estado = 'finalizado' WHERE id_torneo = $1`, [idTorneo]);
        }
        await client.query("COMMIT");
        return {
          ok: true,
          torneoFinalizado: true,
          campeonIdParticipacionEquipo: campeon,
        };
      }

      const porSerie = Number(normaConfig.clasifican_por_serie || 1);
      const finalistasObjetivo = Number(normaConfig.finalistas || tamGrupo || 8);

      const directos = [];
      const resto = [];
      for (const serie of rankingRonda) {
        directos.push(...serie.ranking.slice(0, porSerie));
        resto.push(...serie.ranking.slice(porSerie));
      }
      const ordenResto = criterioAsc
        ? resto.sort((a, b) => a.punto - b.punto || a.id_participacion_equipo - b.id_participacion_equipo)
        : resto.sort((a, b) => b.punto - a.punto || a.id_participacion_equipo - b.id_participacion_equipo);

      clasificados = [
        ...directos.map((x) => x.id_participacion_equipo),
        ...ordenResto.map((x) => x.id_participacion_equipo),
      ].slice(0, Math.max(2, finalistasObjetivo));
    } else if (torneo.tipo === "Eliminatorias por rondas") {
      const porSerie = Number(normaConfig.clasifican_por_serie || 2);
      const mejoresGlobales = Number(normaConfig.mejores_tiempos || 0);

      const directos = [];
      const resto = [];
      for (const serie of rankingRonda) {
        directos.push(...serie.ranking.slice(0, porSerie));
        resto.push(...serie.ranking.slice(porSerie));
      }
      const ordenResto = criterioAsc
        ? resto.sort((a, b) => a.punto - b.punto || a.id_participacion_equipo - b.id_participacion_equipo)
        : resto.sort((a, b) => b.punto - a.punto || a.id_participacion_equipo - b.id_participacion_equipo);

      clasificados = [
        ...directos.map((x) => x.id_participacion_equipo),
        ...ordenResto.slice(0, Math.max(0, mejoresGlobales)).map((x) => x.id_participacion_equipo),
      ];
    } else if (torneo.tipo === "Eliminación progresiva") {
      const porcentaje = Math.min(95, Math.max(1, Number(normaConfig.porcentaje_eliminacion || 50)));
      const rankingGlobal = rankingRonda
        .flatMap((x) => x.ranking)
        .sort((a, b) => {
          if (criterioAsc) {
            return a.punto - b.punto || a.id_participacion_equipo - b.id_participacion_equipo;
          }
          return b.punto - a.punto || a.id_participacion_equipo - b.id_participacion_equipo;
        });

      const supervivientes = Math.max(
        1,
        Math.ceil(rankingGlobal.length * (100 - porcentaje) / 100),
      );
      clasificados = rankingGlobal.slice(0, supervivientes).map((x) => x.id_participacion_equipo);
    }

    const clasificadosSet = new Set(clasificados);
    const todosParticipantesActual = rankingRonda.flatMap((x) =>
      x.ranking.map((r) => r.id_participacion_equipo),
    );
    const eliminados = todosParticipantesActual.filter((id) => !clasificadosSet.has(id));
    if (eliminados.length) {
      await client.query(
        `UPDATE participacion_torneo_equipo SET estado = 'eliminado' WHERE id_participacion_equipo = ANY($1::bigint[])`,
        [eliminados],
      );
    }

    if (clasificados.length <= 1) {
      const campeon = clasificados[0] || null;
      if (campeon) {
        await client.query(
          `UPDATE torneo SET estado = 'finalizado', id_campeon_participacion = $1 WHERE id_torneo = $2`,
          [campeon, idTorneo],
        );
      } else {
        await client.query(`UPDATE torneo SET estado = 'finalizado' WHERE id_torneo = $1`, [idTorneo]);
      }
      await client.query("COMMIT");
      return {
        ok: true,
        torneoFinalizado: true,
        campeonIdParticipacionEquipo: campeon,
      };
    }

    const dias = Array.isArray(torneo.preferencia_horario?.dias)
      ? torneo.preferencia_horario.dias
      : [];
    if (!dias.length)
      throw new Error("preferencia_horario.dias es obligatorio");

    const ultimaFechaQ = await client.query(
      `SELECT MAX(fecha_hora) AS max_fecha FROM partido WHERE id_torneo = $1 AND ronda = $2`,
      [idTorneo, rondaActual],
    );
    let cursor = ultimaFechaQ.rows[0].max_fecha
      ? new Date(ultimaFechaQ.rows[0].max_fecha)
      : new Date();
    let idxDia = 0;
    const nuevaRonda = rondaActual + 1;
    const tamSiguiente = torneo.tipo === "Eliminación directa" ? 2 : Math.max(2, tamGrupo);
    const gruposSiguiente =
      clasificados.length <= tamSiguiente
        ? [clasificados]
        : agruparParticipantes(clasificados, tamSiguiente);

    let orden = 1;
    const nuevosPartidos = [];
    for (const grupo of gruposSiguiente) {
      const fecha = nextPreferredDate(cursor, dias[idxDia % dias.length]);
      cursor = new Date(fecha.getTime() + 24 * 60 * 60 * 1000);
      idxDia++;

      const idPartidoNuevo = await crearPartido(client, {
        idTorneo,
        fecha,
        ronda: nuevaRonda,
        orden,
      });
      await insertarParticipacionesPartido(client, idPartidoNuevo, grupo);

      const picked = await elegirArbitroDisponible(client, {
        arbitros,
        startIndex: idxArbitro,
        idPartido: idPartidoNuevo,
      });
      await asignarArbitroPartido(client, {
        idPartido: idPartidoNuevo,
        idArbitroTorneo: picked.idArbitroTorneo,
      });
      idxArbitro = picked.nextIndex;
      nuevosPartidos.push(idPartidoNuevo);
      orden++;
    }

    if (torneo.tipo === "Eliminación directa" && partidos.length * 2 === clasificados.length * 2) {
      // Mantener trazabilidad en el caso clasico 1v1.
      for (let i = 0; i < partidos.length; i += 2) {
        const target = nuevosPartidos[Math.floor(i / 2)];
        if (!target) continue;
        await client.query(
          `UPDATE partido SET id_partido_siguiente = $1 WHERE id_partido IN ($2, $3)`,
          [target, partidos[i].id_partido, partidos[i + 1].id_partido],
        );
      }
    }

    await client.query("COMMIT");
    return {
      ok: true,
      torneoFinalizado: false,
      rondaGenerada: nuevaRonda,
      partidosGenerados: nuevosPartidos.length,
      clasificados: clasificados.length,
    };
  } catch (e) {
    await client.query("ROLLBACK");
    throw e;
  } finally {
    client.release();
  }
}

async function generarEnfrentamientos(idTorneo) {
  const client = await pool.connect();
  try {
    const torneo = await getTorneo(client, idTorneo);
    if (torneo.tipo === "Liga") return await generarLiga(idTorneo);
    if (torneo.tipo === "Eliminación directa")
      return await generarEliminacion(idTorneo);
    if (torneo.tipo === "Eliminación por serie") {
      return await generarEliminacionMultiInicio(
        idTorneo,
        "Eliminación por serie",
      );
    }
    if (torneo.tipo === "Serie + final (con tiempos)") {
      return await generarEliminacionMultiInicio(
        idTorneo,
        "Serie + final (con tiempos)",
      );
    }
    if (torneo.tipo === "Eliminatorias por rondas") {
      return await generarEliminacionMultiInicio(
        idTorneo,
        "Eliminatorias por rondas",
      );
    }
    if (torneo.tipo === "Eliminación progresiva") {
      return await generarEliminacionMultiInicio(
        idTorneo,
        "Eliminación progresiva",
      );
    }
    throw new Error(`Tipo de torneo no soportado: ${torneo.tipo}`);
  } finally {
    client.release();
  }
}

const getParticipacionesTorneo = async (idTorneo) => {
  const result = await pool.query(
    `SELECT
       pte.id_participacion_equipo,
       pte.id_torneo,
       pte.id_equipo,
       pte.estado,
       pte.puntuacion,
       e.nombre AS equipo_nombre,
       e.elo
     FROM participacion_torneo_equipo pte
     JOIN equipo e ON e.id_equipo = pte.id_equipo
     WHERE pte.id_torneo = $1
     ORDER BY pte.id_participacion_equipo ASC`,
    [idTorneo],
  );

  return result.rows.map((r) => ({
    id_participacion_equipo: Number(r.id_participacion_equipo),
    id_torneo: Number(r.id_torneo),
    id_equipo: Number(r.id_equipo),
    equipo_nombre: r.equipo_nombre,
    estado: r.estado,
    puntuacion: Number(r.puntuacion),
    elo: Number(r.elo),
  }));
};

module.exports = {
  listTorneos,
  getTorneoById,
  getClasificacionTorneo,
  getPartidosTorneo,
  getParticipacionesTorneo,
  createTorneo,
  updateTorneo,
  deleteTorneo,
  getFormularioByTorneoId,
  updateFormularioByTorneoId,
  generarEnfrentamientos,
  generarLiga,
  generarEliminacion,
  avanzarRondaEliminacion,
};
