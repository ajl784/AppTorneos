const participacionesService = require("../services/participaciones.service");
const {
  ok,
  created,
  parsePositiveInt,
  parsePagination,
  requireFields,
  asyncHandler,
} = require("../utils/http");
const { AppError } = require("../utils/errors");

const listParticipaciones = asyncHandler(async (req, res) => {
  const { limit, offset } = parsePagination(req.query);
  const data = await participacionesService.listParticipaciones({
    limit,
    offset,
    torneoId: req.query.torneoId,
    equipoId: req.query.equipoId,
    estado: req.query.estado,
  });

  ok(res, data, { limit, offset, count: data.length });
});

const getParticipacionById = asyncHandler(async (req, res) => {
  const idParticipacion = parsePositiveInt(req.params.id, "id");
  const data =
    await participacionesService.getParticipacionById(idParticipacion);

  if (!data) {
    throw new AppError(404, "Participacion no encontrada");
  }

  ok(res, data);
});

const createParticipacion = asyncHandler(async (req, res) => {
  requireFields(req.body, ["id_torneo", "id_equipo"]);
  const data = await participacionesService.createParticipacion(req.body);
  created(res, data);
});

const updateParticipacion = asyncHandler(async (req, res) => {
  const idParticipacion = parsePositiveInt(req.params.id, "id");
  const data = await participacionesService.updateParticipacion(
    idParticipacion,
    req.body || {},
  );

  if (!data) {
    throw new AppError(404, "Participacion no encontrada");
  }

  ok(res, data);
});

const deleteParticipacion = asyncHandler(async (req, res) => {
  const idParticipacion = parsePositiveInt(req.params.id, "id");
  const deleted =
    await participacionesService.deleteParticipacion(idParticipacion);

  if (!deleted) {
    throw new AppError(404, "Participacion no encontrada");
  }

  ok(res, { deleted: true });
});

const listSolicitudesByTorneo = asyncHandler(async (req, res) => {
  const idTorneo = parsePositiveInt(req.params.id, "id");
  const data = await participacionesService.listSolicitudesByTorneo({
    idTorneo,
    estado: req.query.estado,
  });

  ok(res, data, { count: data.length });
});

const createSolicitudByTorneo = asyncHandler(async (req, res) => {
  const idTorneo = parsePositiveInt(req.params.id, "id");
  requireFields(req.body, ["id_equipo", "respuesta"]);

  const data = await participacionesService.createSolicitudByTorneo({
    idTorneo,
    idEquipo: req.body.id_equipo,
    respuesta: req.body.respuesta,
  });

  created(res, data);
});

const decidirSolicitud = asyncHandler(async (req, res) => {
  const idParticipacion = parsePositiveInt(req.params.id, "id");

  if (typeof req.body.aceptar !== "boolean") {
    throw new AppError(400, "aceptar debe ser booleano");
  }

  const data = await participacionesService.decideSolicitud({
    idParticipacionEquipo: idParticipacion,
    aceptar: req.body.aceptar,
  });

  if (!data) {
    throw new AppError(404, "Participacion no encontrada");
  }

  ok(res, data);
});

module.exports = {
  listParticipaciones,
  getParticipacionById,
  createParticipacion,
  updateParticipacion,
  deleteParticipacion,
  listSolicitudesByTorneo,
  createSolicitudByTorneo,
  decidirSolicitud,
};
