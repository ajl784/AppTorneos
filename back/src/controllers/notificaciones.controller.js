const notificacionesService = require("../services/notificaciones.service");
const { ok, created, asyncHandler, parsePositiveInt } = require("../utils/http");
const { AppError } = require("../utils/errors");

const crearNotificacion = asyncHandler(async (req, res) => {
  const data = await notificacionesService.crearNotificacion(req.body);
  created(res, data);
});

const getNotificacionesUsuario = asyncHandler(async (req, res) => {
  const idUsuario = parsePositiveInt(req.params.idUsuario, "idUsuario");
  
  // Construir objeto de filtros base
  const filtros = { id_usuario_destino: idUsuario };
  
  // Agregar filtros opcionales desde query string
  if (req.query.tipo) {
    filtros.tipo = req.query.tipo;
  }
  if (req.query.leida !== undefined) {
    filtros.leida = req.query.leida; // se pasa como string "true"/"false"
  }
  
  const data = await notificacionesService.getNotificaciones(filtros);
  ok(res, data);
});

const getNotificaciones = asyncHandler(async (req, res) => {
  const filtros = req.query; // tipo, leida, etc.
  const data = await notificacionesService.getNotificaciones(filtros);
  ok(res, data);
});

const marcarComoLeida = asyncHandler(async (req, res) => {
  const idNotificacion = parsePositiveInt(req.params.idNotificacion, "idNotificacion");
  const data = await notificacionesService.marcarComoLeida(idNotificacion);
  ok(res, data);
});

const eliminarNotificacion = asyncHandler(async (req, res) => {
  const idNotificacion = parsePositiveInt(req.params.idNotificacion, "idNotificacion");
  const data = await notificacionesService.eliminarNotificacion(idNotificacion);
  ok(res, { deleted: !!data });
});

module.exports = {
  crearNotificacion,
  getNotificacionesUsuario,
  getNotificaciones,
  marcarComoLeida,
  eliminarNotificacion,
};