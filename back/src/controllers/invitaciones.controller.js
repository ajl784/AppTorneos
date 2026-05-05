const invitacionesService = require("../services/invitaciones.service");
const notificacionesService = require("../services/notificaciones.service");
const { ok, created, asyncHandler, parsePositiveInt, requireFields } = require("../utils/http");
const { AppError } = require("../utils/errors");

const crearInvitacion = asyncHandler(async (req, res) => {
  requireFields(req.body, ["tipo", "id_usuario_invitado", "id_usuario_invitador"]);
  const invitacion = await invitacionesService.crearInvitacion(req.body);
  await notificacionesService.crearNotificacion({
    id_usuario_destino: req.body.id_usuario_invitado,
    tipo: req.body.tipo,
    titulo: req.body.titulo || "Tienes una invitación",
    mensaje: req.body.mensaje || "Tienes una invitación pendiente.",
    datos: { id_invitacion: invitacion.id_invitacion, ...req.body.datos }
  });
  created(res, invitacion);
});

// Consultar invitaciones pendientes por id_usuario_invitado
const obtenerPendientesPorUsuario = asyncHandler(async (req, res) => {
  const id_usuario_invitado = parsePositiveInt(req.params.idUsuario, "idUsuario");
  const invitaciones = await invitacionesService.obtenerInvitacionesPendientesPorUsuario(id_usuario_invitado);
  ok(res, invitaciones);
});

const aceptarInvitacion = asyncHandler(async (req, res) => {
  const idInvitacion = parsePositiveInt(req.params.idInvitacion, "idInvitacion");
  const invitacion = await invitacionesService.aceptarInvitacion(idInvitacion);
  if (!invitacion) throw new AppError(404, "Invitación no encontrada o ya gestionada");
  ok(res, invitacion);
});

const rechazarInvitacion = asyncHandler(async (req, res) => {
  const idInvitacion = parsePositiveInt(req.params.idInvitacion, "idInvitacion");
  const invitacion = await invitacionesService.rechazarInvitacion(idInvitacion);
  if (!invitacion) throw new AppError(404, "Invitación no encontrada o ya gestionada");
  ok(res, invitacion);
});

// Invitación específica: árbitro a torneo
const invitarArbitro = asyncHandler(async (req, res) => {
  requireFields(req.body, ["id_torneo", "id_usuario_invitado", "id_usuario_invitador"]);
  const body = {
    tipo: "arbitro_torneo",
    id_torneo: req.body.id_torneo,
    id_usuario_invitado: req.body.id_usuario_invitado,
    id_usuario_invitador: req.body.id_usuario_invitador,
    datos: req.body.datos || {},
    titulo: req.body.titulo || "Invitación para ser árbitro",
    mensaje: req.body.mensaje || "Has sido invitado como árbitro a un torneo."
  };
  const invitacion = await invitacionesService.crearInvitacion(body);
  await notificacionesService.crearNotificacion({
    id_usuario_destino: body.id_usuario_invitado,
    tipo: body.tipo,
    titulo: body.titulo,
    mensaje: body.mensaje,
    datos: { id_invitacion: invitacion.id_invitacion, ...body.datos }
  });
  created(res, invitacion);
});

// Invitación específica: jugador a equipo
const invitarJugadorEquipo = asyncHandler(async (req, res) => {
  requireFields(req.body, ["id_equipo", "id_usuario_invitado", "id_usuario_invitador"]);
  const body = {
    tipo: "jugador_equipo",
    id_equipo: req.body.id_equipo,
    id_usuario_invitado: req.body.id_usuario_invitado,
    id_usuario_invitador: req.body.id_usuario_invitador,
    datos: req.body.datos || {},
    titulo: req.body.titulo || "Invitación para unirte al equipo",
    mensaje: req.body.mensaje || "Has sido invitado a un equipo."
  };
  const invitacion = await invitacionesService.crearInvitacion(body);
  await notificacionesService.crearNotificacion({
    id_usuario_destino: body.id_usuario_invitado,
    tipo: body.tipo,
    titulo: body.titulo,
    mensaje: body.mensaje,
    datos: { id_invitacion: invitacion.id_invitacion, ...body.datos }
  });
  created(res, invitacion);
});

module.exports = {
  crearInvitacion,
  aceptarInvitacion,
  rechazarInvitacion,
  invitarArbitro,
  invitarJugadorEquipo,
  obtenerPendientesPorUsuario,
};