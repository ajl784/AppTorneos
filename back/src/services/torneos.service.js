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
      payload.estado || "planificado",
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

function normalizarDia(d) {
  return (d || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '');
}

function nextDateForPreferredDay(fromDate, dayName) {
  const map = {
    domingo: 0,
    lunes: 1,
    martes: 2,
    miercoles: 3,
    jueves: 4,
    viernes: 5,
    sabado: 6,
  };
  const target = map[normalizarDia(dayName)];
  if (target === undefined) throw new Error(`Día no válido: ${dayName}`);

  const d = new Date(fromDate);
  const diff = (target - d.getDay() + 7) % 7 || 7;
  d.setDate(d.getDate() + diff);
  return d;
}

async function generarEnfrentamientosLiga(idTorneo) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const torneoQ = await client.query(
      `
      SELECT t.id_torneo, t.fecha_inicio, t.preferencia_horario, tt.nombre AS tipo
      FROM torneo t
      JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
      WHERE t.id_torneo = $1
      `,
      [idTorneo]
    );
    if (!torneoQ.rowCount) throw new Error('Torneo no encontrado');

    const torneo = torneoQ.rows[0];
    if (torneo.tipo !== 'Liga') {
      throw new Error('Solo se generan enfrentamientos para tipo Liga');
    }

    const dias = Array.isArray(torneo.preferencia_horario?.dias)
      ? torneo.preferencia_horario.dias
      : [];
    if (!dias.length) throw new Error('Faltan días en preferencia_horario.dias');

    const inscQ = await client.query(
      `
      SELECT id_participacion_equipo, id_equipo
      FROM participacion_torneo_equipo
      WHERE id_torneo = $1
        AND estado IN ('aceptada', 'jugando')
      ORDER BY id_participacion_equipo ASC
      `,
      [idTorneo]
    );
    const equipos = inscQ.rows.map((r) => r.id_equipo);
    if (equipos.length < 2) throw new Error('No hay suficientes equipos');

    // Evitar duplicar generación
    const existeQ = await client.query(
      `SELECT 1 FROM partido WHERE id_torneo = $1 LIMIT 1`,
      [idTorneo]
    );
    if (existeQ.rowCount) throw new Error('Este torneo ya tiene partidos generados');

    const base = torneo.fecha_inicio ? new Date(torneo.fecha_inicio) : new Date();
    let cursorFecha = base;
    let idxDia = 0;

    async function crearPartido(idLocal, idVisitante, jornada) {
      const dia = dias[idxDia % dias.length];
      const fecha = nextDateForPreferredDay(cursorFecha, dia);
      cursorFecha = fecha;
      idxDia++;

      const partidoQ = await client.query(
        `
        INSERT INTO partido (id_torneo, jornada, fecha, estado)
        VALUES ($1, $2, $3, 'planificado')
        RETURNING id_partido
        `,
        [idTorneo, jornada, fecha]
      );
      const idPartido = partidoQ.rows[0].id_partido;

      await client.query(
        `
        INSERT INTO participacion_partido (id_partido, id_participacion_equipo)
        SELECT $1, pte.id_participacion_equipo
        FROM participacion_torneo_equipo pte
        WHERE pte.id_torneo = $2
          AND pte.id_equipo IN ($3, $4)
        `,
        [idPartido, idTorneo, idLocal, idVisitante]
      );
    }

    // Ida
    let jornada = 1;
    for (let i = 0; i < equipos.length; i++) {
      for (let j = i + 1; j < equipos.length; j++) {
        await crearPartido(equipos[i], equipos[j], jornada++);
      }
    }

    // Vuelta
    for (let i = 0; i < equipos.length; i++) {
      for (let j = i + 1; j < equipos.length; j++) {
        await crearPartido(equipos[j], equipos[i], jornada++);
      }
    }

    await client.query('COMMIT');
    return { ok: true };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}// ...existing code...
const pool = require('../db/pool');

function normalizeDay(day) {
  return String(day || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '');
}

function nextDateForDay(baseDate, dayName) {
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
  if (target === undefined) throw new Error(`Día no válido: ${dayName}`);

  const d = new Date(baseDate);
  const diff = (target - d.getDay() + 7) % 7 || 7;
  d.setDate(d.getDate() + diff);
  return d;
}

function isPowerOfTwo(n) {
  return n > 1 && (n & (n - 1)) === 0;
}

async function getTorneoBase(client, idTorneo) {
  const q = await client.query(
    `
    SELECT t.id_torneo, t.fecha_inicio, t.preferencia_horario, tt.nombre AS tipo
    FROM torneo t
    JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
    WHERE t.id_torneo = $1
    `,
    [idTorneo]
  );
  if (!q.rowCount) throw new Error('Torneo no encontrado');
  return q.rows[0];
}

async function getParticipacionesJugando(client, idTorneo) {
  const q = await client.query(
    `
    SELECT id_participacion_equipo
    FROM participacion_torneo_equipo
    WHERE id_torneo = $1
      AND estado = 'jugando'
    ORDER BY id_participacion_equipo ASC
    `,
    [idTorneo]
  );
  return q.rows.map((r) => Number(r.id_participacion_equipo));
}

async function crearPartidoConParticipaciones(client, { idTorneo, fechaHora, lugar, p1, p2 }) {
  const p = await client.query(
    `
    INSERT INTO partido (id_torneo, fecha_hora, lugar, estado)
    VALUES ($1, $2, $3, 'planificado')
    RETURNING id_partido
    `,
    [idTorneo, fechaHora, lugar]
  );
  const idPartido = p.rows[0].id_partido;

  await client.query(
    `
    INSERT INTO participacion_partido (id_partido, id_participacion_equipo)
    VALUES ($1, $2), ($1, $3)
    `,
    [idPartido, p1, p2]
  );

  return idPartido;
}

async function generarBracketEliminacion(idTorneo) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const torneo = await getTorneoBase(client, idTorneo);
    if (torneo.tipo !== 'Eliminación directa') {
      throw new Error('El torneo no es de eliminación directa');
    }

    const yaExiste = await client.query(
      `SELECT 1 FROM partido WHERE id_torneo = $1 AND lugar LIKE 'ELIM|R%' LIMIT 1`,
      [idTorneo]
    );
    if (yaExiste.rowCount) throw new Error('El bracket ya fue generado');

    const dias = Array.isArray(torneo.preferencia_horario?.dias)
      ? torneo.preferencia_horario.dias
      : [];
    if (!dias.length) throw new Error('Faltan días en preferencia_horario.dias');

    const participantes = await getParticipacionesJugando(client, idTorneo);
    if (!isPowerOfTwo(participantes.length)) {
      throw new Error('Para eliminación directa se requiere cantidad de equipos potencia de 2');
    }

    let cursor = torneo.fecha_inicio ? new Date(torneo.fecha_inicio) : new Date();
    let idxDia = 0;

    for (let i = 0; i < participantes.length; i += 2) {
      const fecha = nextDateForDay(cursor, dias[idxDia % dias.length]);
      cursor = fecha;
      idxDia += 1;

      await crearPartidoConParticipaciones(client, {
        idTorneo,
        fechaHora: fecha,
        lugar: `ELIM|R1|M${i / 2 + 1}`,
        p1: participantes[i],
        p2: participantes[i + 1],
      });
    }

    await client.query('COMMIT');
    return { ok: true, ronda: 1 };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function avanzarRondaEliminacion(idTorneo) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const torneo = await getTorneoBase(client, idTorneo);
    if (torneo.tipo !== 'Eliminación directa') {
      throw new Error('El torneo no es de eliminación directa');
    }

    const partidosQ = await client.query(
      `
      SELECT id_partido, estado, lugar, fecha_hora
      FROM partido
      WHERE id_torneo = $1
        AND lugar LIKE 'ELIM|R%|M%'
      ORDER BY id_partido ASC
      `,
      [idTorneo]
    );
    if (!partidosQ.rowCount) throw new Error('Primero debes generar el bracket inicial');

    const partidos = partidosQ.rows.map((r) => ({
      ...r,
      round: Number((r.lugar.match(/^ELIM\|R(\d+)\|M\d+$/) || [])[1] || 0),
    }));

    const rondaActual = Math.max(...partidos.map((p) => p.round));
    if (!rondaActual) throw new Error('No se pudo detectar la ronda actual');

    const rondaActualPartidos = partidos.filter((p) => p.round === rondaActual);
    if (rondaActualPartidos.some((p) => p.estado !== 'acabado')) {
      throw new Error('Todos los partidos de la ronda actual deben estar acabados');
    }

    const yaSiguiente = partidos.some((p) => p.round === rondaActual + 1);
    if (yaSiguiente) throw new Error('La siguiente ronda ya fue generada');

    const ganadores = [];

    for (const partido of rondaActualPartidos) {
      const pp = await client.query(
        `
        SELECT id_participacion_equipo, punto
        FROM participacion_partido
        WHERE id_partido = $1
        ORDER BY punto DESC
        `,
        [partido.id_partido]
      );
      if (pp.rowCount !== 2) throw new Error(`Partido ${partido.id_partido} inválido`);

      const a = pp.rows[0];
      const b = pp.rows[1];
      if (Number(a.punto) === Number(b.punto)) {
        throw new Error(`Empate no permitido en eliminación (partido ${partido.id_partido})`);
      }

      const ganador = Number(a.id_participacion_equipo);
      const perdedor = Number(b.id_participacion_equipo);
      ganadores.push(ganador);

      await client.query(
        `
        UPDATE participacion_torneo_equipo
        SET estado = 'eliminado'
        WHERE id_participacion_equipo = $1
        `,
        [perdedor]
      );
    }

    if (ganadores.length === 1) {
      await client.query('COMMIT');
      return { ok: true, campeon_id_participacion_equipo: ganadores[0] };
    }

    let cursor = new Date(
      Math.max(...partidos.map((p) => new Date(p.fecha_hora).getTime()))
    );

    const dias = Array.isArray(torneo.preferencia_horario?.dias)
      ? torneo.preferencia_horario.dias
      : [];
    if (!dias.length) throw new Error('Faltan días en preferencia_horario.dias');

    let idxDia = 0;
    const nuevaRonda = rondaActual + 1;

    for (let i = 0; i < ganadores.length; i += 2) {
      const fecha = nextDateForDay(cursor, dias[idxDia % dias.length]);
      cursor = fecha;
      idxDia += 1;

      await crearPartidoConParticipaciones(client, {
        idTorneo,
        fechaHora: fecha,
        lugar: `ELIM|R${nuevaRonda}|M${i / 2 + 1}`,
        p1: ganadores[i],
        p2: ganadores[i + 1],
      });
    }

    await client.query('COMMIT');
    return { ok: true, ronda: nuevaRonda };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

// ...existing code...
module.exports = {
  // ...existing exports...
  generarBracketEliminacion,
  avanzarRondaEliminacion,
};


module.exports = {
  listTorneos,
  getTorneoById,
  createTorneo,
  updateTorneo,
  deleteTorneo,
  getFormularioByTorneoId,
  updateFormularioByTorneoId,
};
