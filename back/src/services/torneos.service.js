const { pool } = require("../db/pool");

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
     FROM torneo t
     JOIN categoria c ON c.id_categoria = t.id_categoria
     JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
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
      t.id_tipo_torneo,
      tt.nombre AS tipo_torneo_nombre,
      t.id_organizador,
      t.encuesta,
      t.norma_puntuacion,
      t.preferencia_horario
     FROM torneo t
     JOIN categoria c ON c.id_categoria = t.id_categoria
     JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
     WHERE t.id_torneo = $1`,
    [idTorneo],
  );

  return result.rows[0] || null;
};

const createTorneo = async (payload) => {
  const result = await pool.query(
    `INSERT INTO torneo (
      nombre, descripcion, fecha_inicio, fecha_fin, estado,
      id_categoria, id_tipo_torneo, id_organizador,
      encuesta, norma_puntuacion, preferencia_horario
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb, $10, $11::jsonb)
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
    ],
  );

  return getTorneoById(result.rows[0].id_torneo);
};

const updateTorneo = async (idTorneo, payload) => {
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

async function getTorneo(client, idTorneo) {
  const q = await client.query(
    `
    SELECT t.id_torneo, t.fecha_inicio, t.preferencia_horario, tt.nombre AS tipo
    FROM torneo t
    JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
    WHERE t.id_torneo = $1
    `,
    [idTorneo]
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
    [idTorneo]
  );
  return q.rows;
}

async function crearPartido(client, { idTorneo, fecha, ronda = null, orden = null }) {
  const q = await client.query(
    `
    INSERT INTO partido (id_torneo, fecha_hora, estado, ronda, orden_ronda)
    VALUES ($1, $2, 'planificado', $3, $4)
    RETURNING id_partido
    `,
    [idTorneo, fecha, ronda, orden]
  );
  return q.rows[0].id_partido;
}

async function insertarParticipacionesPartido(client, idPartido, p1, p2) {
  await client.query(
    `
    INSERT INTO participacion_partido (id_partido, id_participacion_equipo)
    VALUES ($1, $2), ($1, $3)
    `,
    [idPartido, p1, p2]
  );
}

async function generarLiga(idTorneo) {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const torneo = await getTorneo(client, idTorneo);
    if (torneo.tipo !== "Liga") throw new Error("El torneo no es de tipo Liga");

    const existe = await client.query(
      `SELECT 1 FROM partido WHERE id_torneo = $1 LIMIT 1`,
      [idTorneo]
    );
    if (existe.rowCount) throw new Error("Este torneo ya tiene partidos generados");

    const dias = Array.isArray(torneo.preferencia_horario?.dias)
      ? torneo.preferencia_horario.dias
      : [];
    if (!dias.length) throw new Error("preferencia_horario.dias es obligatorio");

    const participaciones = await getParticipacionesJugando(client, idTorneo);
    if (participaciones.length < 2) throw new Error("Se requieren al menos 2 equipos");

    let cursor = torneo.fecha_inicio ? new Date(torneo.fecha_inicio) : new Date();
    let idxDia = 0;
    let total = 0;

    const ida = [];
    for (let i = 0; i < participaciones.length; i++) {
      for (let j = i + 1; j < participaciones.length; j++) {
        ida.push([participaciones[i], participaciones[j]]);
      }
    }

    const vuelta = ida.map(([a, b]) => [b, a]);

    for (const [a, b] of [...ida, ...vuelta]) {
      const fecha = nextPreferredDate(cursor, dias[idxDia % dias.length]);
      cursor = new Date(fecha.getTime() + 24 * 60 * 60 * 1000);
      idxDia++;

      const idPartido = await crearPartido(client, {
        idTorneo,
        fecha,
        ronda: null,
        orden: null,
      });
      await insertarParticipacionesPartido(
        client,
        idPartido,
        a.id_participacion_equipo,
        b.id_participacion_equipo
      );
      total++;
    }

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
      [idTorneo]
    );
    if (existe.rowCount) throw new Error("Este torneo ya tiene partidos generados");

    const dias = Array.isArray(torneo.preferencia_horario?.dias)
      ? torneo.preferencia_horario.dias
      : [];
    if (!dias.length) throw new Error("preferencia_horario.dias es obligatorio");

    const participaciones = await getParticipacionesJugando(client, idTorneo);
    if (!isPowerOfTwo(participaciones.length)) {
      throw new Error("En eliminación directa, equipos debe ser potencia de 2");
    }

    let cursor = torneo.fecha_inicio ? new Date(torneo.fecha_inicio) : new Date();
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
      await insertarParticipacionesPartido(
        client,
        idPartido,
        a.id_participacion_equipo,
        b.id_participacion_equipo
      );
      orden++;
    }

    await client.query("COMMIT");
    return { ok: true, tipo: "Eliminación directa", rondaGenerada: 1 };
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
    if (torneo.tipo !== "Eliminación directa") {
      throw new Error("El torneo no es de eliminación directa");
    }

    const maxRondaQ = await client.query(
      `SELECT MAX(ronda) AS max_ronda FROM partido WHERE id_torneo = $1`,
      [idTorneo]
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
      [idTorneo, rondaActual]
    );
    const partidos = partidosQ.rows;
    if (partidos.some((p) => p.estado !== "acabado")) {
      throw new Error("Todos los partidos de la ronda actual deben estar acabados");
    }

    const ganadores = [];
    for (const p of partidos) {
      const ganadorSet = await client.query(
        `
        SELECT ganador_id_participacion_equipo
        FROM partido
        WHERE id_partido = $1
        `,
        [p.id_partido]
      );

      let ganador = ganadorSet.rows[0].ganador_id_participacion_equipo;
      if (!ganador) {
        const pp = await client.query(
          `
          SELECT id_participacion_equipo, punto
          FROM participacion_partido
          WHERE id_partido = $1
          ORDER BY punto DESC, id_participacion_equipo ASC
          `,
          [p.id_partido]
        );
        if (pp.rowCount !== 2) throw new Error(`Partido ${p.id_partido} inválido`);
        if (Number(pp.rows[0].punto) === Number(pp.rows[1].punto)) {
          throw new Error(`Empate en partido ${p.id_partido}; define ganador manualmente`);
        }
        ganador = pp.rows[0].id_participacion_equipo;

        await client.query(
          `UPDATE partido SET ganador_id_participacion_equipo = $1 WHERE id_partido = $2`,
          [ganador, p.id_partido]
        );
      }

      ganadores.push({
        id_partido_origen: p.id_partido,
        id_participacion_equipo: Number(ganador),
      });
    }

    if (ganadores.length === 1) {
      await client.query("COMMIT");
      return {
        ok: true,
        torneoFinalizado: true,
        campeonIdParticipacionEquipo: ganadores[0].id_participacion_equipo,
      };
    }

    const dias = Array.isArray(torneo.preferencia_horario?.dias)
      ? torneo.preferencia_horario.dias
      : [];
    if (!dias.length) throw new Error("preferencia_horario.dias es obligatorio");

    const ultimaFechaQ = await client.query(
      `SELECT MAX(fecha_hora) AS max_fecha FROM partido WHERE id_torneo = $1 AND ronda = $2`,
      [idTorneo, rondaActual]
    );
    let cursor = ultimaFechaQ.rows[0].max_fecha
      ? new Date(ultimaFechaQ.rows[0].max_fecha)
      : new Date();
    let idxDia = 0;
    const nuevaRonda = rondaActual + 1;
    let orden = 1;

    for (let i = 0; i < ganadores.length; i += 2) {
      const g1 = ganadores[i];
      const g2 = ganadores[i + 1];

      const fecha = nextPreferredDate(cursor, dias[idxDia % dias.length]);
      cursor = new Date(fecha.getTime() + 24 * 60 * 60 * 1000);
      idxDia++;

      const idPartidoNuevo = await crearPartido(client, {
        idTorneo,
        fecha,
        ronda: nuevaRonda,
        orden,
      });

      await insertarParticipacionesPartido(
        client,
        idPartidoNuevo,
        g1.id_participacion_equipo,
        g2.id_participacion_equipo
      );

      await client.query(
        `
        UPDATE partido
        SET id_partido_siguiente = $1
        WHERE id_partido IN ($2, $3)
        `,
        [idPartidoNuevo, g1.id_partido_origen, g2.id_partido_origen]
      );

      orden++;
    }

    await client.query("COMMIT");
    return { ok: true, torneoFinalizado: false, rondaGenerada: nuevaRonda };
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
    if (torneo.tipo === "Eliminación directa") return await generarEliminacion(idTorneo);
    throw new Error(`Tipo de torneo no soportado: ${torneo.tipo}`);
  } finally {
    client.release();
  }
}


module.exports = {
  listTorneos,
  getTorneoById,
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
