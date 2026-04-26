const { pool } = require("../db/pool");


// Crear invitación generalista
async function crearInvitacion({ tipo, id_torneo, id_equipo, id_usuario_invitado, id_usuario_invitador, datos }) {
  const result = await pool.query(
    `INSERT INTO invitacion (tipo, id_torneo, id_equipo, id_usuario_invitado, id_usuario_invitador, datos)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
    [tipo, id_torneo || null, id_equipo || null, id_usuario_invitado, id_usuario_invitador, datos ? JSON.stringify(datos) : null]
  );
  return result.rows[0];
}

// Lógica de aceptación según tipo
async function aceptarInvitacion(idInvitacion) {
  // 1. Marcar como aceptada y obtener invitación
  const { rows } = await pool.query(
    `UPDATE invitacion SET estado = 'aceptada', fecha_respuesta = NOW()
     WHERE id_invitacion = $1 AND estado = 'pendiente'
     RETURNING *`,
    [idInvitacion]
  );
  const invitacion = rows[0];
  if (!invitacion) return null;

  // 2. Lógica según tipo
  if (invitacion.tipo === "arbitro_torneo") {
    // Insertar en arbitro_torneo
    await pool.query(
      `INSERT INTO arbitro_torneo (id_usuario, id_torneo) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
      [invitacion.id_usuario_invitado, invitacion.id_torneo]
    );
  } else if (invitacion.tipo === "jugador_equipo") {
    // Insertar en pertenece
    await pool.query(
      `INSERT INTO pertenece (id_usuario, id_equipo, fecha_inicio) VALUES ($1, $2, CURRENT_DATE) ON CONFLICT DO NOTHING`,
      [invitacion.id_usuario_invitado, invitacion.id_equipo]
    );
  }
  return invitacion;
}

async function rechazarInvitacion(idInvitacion) {
  const { rows } = await pool.query(
    `UPDATE invitacion SET estado = 'rechazada', fecha_respuesta = NOW()
     WHERE id_invitacion = $1 AND estado = 'pendiente'
     RETURNING *`,
    [idInvitacion]
  );
  return rows[0];
}

module.exports = {
  crearInvitacion,
  aceptarInvitacion,
  rechazarInvitacion,
};