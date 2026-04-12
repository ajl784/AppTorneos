const torneosService = require("../services/torneos.service");
const {
  ok,
  created,
  parsePositiveInt,
  parsePagination,
  requireFields,
  asyncHandler,
} = require("../utils/http");
const { AppError } = require("../utils/errors");

const listTorneos = asyncHandler(async (req, res) => {
  const { limit, offset } = parsePagination(req.query);
  const data = await torneosService.listTorneos({
    limit,
    offset,
    estado: req.query.estado,
    organizadorId: req.query.organizadorId,
    categoriaId: req.query.categoriaId,
    tipoTorneoId: req.query.tipoTorneoId,
  });

  ok(res, data, { limit, offset, count: data.length });
});

const getTorneoById = asyncHandler(async (req, res) => {
  const idTorneo = parsePositiveInt(req.params.id, "id");
  const data = await torneosService.getTorneoById(idTorneo);

  if (!data) {
    throw new AppError(404, "Torneo no encontrado");
  }

  ok(res, data);
});

const createTorneo = asyncHandler(async (req, res) => {
  requireFields(req.body, ["nombre", "id_categoria", "id_tipo_torneo"]);
  const data = await torneosService.createTorneo(req.body);
  created(res, data);
});

const updateTorneo = asyncHandler(async (req, res) => {
  const idTorneo = parsePositiveInt(req.params.id, "id");
  const data = await torneosService.updateTorneo(idTorneo, req.body || {});

  if (!data) {
    throw new AppError(404, "Torneo no encontrado");
  }

  ok(res, data);
});

const deleteTorneo = asyncHandler(async (req, res) => {
  const idTorneo = parsePositiveInt(req.params.id, "id");
  const deleted = await torneosService.deleteTorneo(idTorneo);

  if (!deleted) {
    throw new AppError(404, "Torneo no encontrado");
  }

  ok(res, { deleted: true });
});

const getFormularioTorneo = asyncHandler(async (req, res) => {
  const idTorneo = parsePositiveInt(req.params.id, "id");
  const data = await torneosService.getFormularioByTorneoId(idTorneo);

  if (!data) {
    throw new AppError(404, "Torneo no encontrado");
  }

  ok(res, {
    id_torneo: data.id_torneo,
    torneo_nombre: data.nombre,
    formulario: data.encuesta,
  });
});

const updateFormularioTorneo = asyncHandler(async (req, res) => {
  const idTorneo = parsePositiveInt(req.params.id, "id");

  if (req.body.formulario === undefined) {
    throw new AppError(400, "El campo formulario es requerido");
  }

  const data = await torneosService.updateFormularioByTorneoId(
    idTorneo,
    req.body.formulario,
  );

  if (!data) {
    throw new AppError(404, "Torneo no encontrado");
  }

  ok(res, {
    id_torneo: data.id_torneo,
    torneo_nombre: data.nombre,
    formulario: data.encuesta,
  });
});

const generarEnfrentamientos = asyncHandler(async (req, res) => {
  const idTorneo = parsePositiveInt(req.params.idTorneo, "idTorneo");
  const data = await torneosService.generarEnfrentamientos(idTorneo);
  created(res, data);
});

const generarBracketEliminacion = asyncHandler(async (req, res) => {
  const idTorneo = parsePositiveInt(req.params.idTorneo, "idTorneo");
  const data = await torneosService.generarEliminacion(idTorneo);
  created(res, data);
});

const avanzarRondaEliminacion = asyncHandler(async (req, res) => {
  const idTorneo = parsePositiveInt(req.params.idTorneo, "idTorneo");
  const data = await torneosService.avanzarRondaEliminacion(idTorneo);
  created(res, data);
});

const getClasificacionTorneo = asyncHandler(async (req, res) => {
  const idTorneo = parsePositiveInt(req.params.id, "id");
  const data = await torneosService.getClasificacionTorneo(idTorneo);

  if (!data) {
    throw new AppError(404, "Torneo no encontrado");
  }

  ok(res, data);
});

const getPartidosTorneo = asyncHandler(async (req, res) => {
  const idTorneo = parsePositiveInt(req.params.id, "id");
  const data = await torneosService.getPartidosTorneo(idTorneo);

  if (!data) {
    throw new AppError(404, "Torneo no encontrado");
  }

  ok(res, data);
});

module.exports = {
  listTorneos,
  getTorneoById,
  getClasificacionTorneo,
  getPartidosTorneo,
  createTorneo,
  updateTorneo,
  deleteTorneo,
  getFormularioTorneo,
  updateFormularioTorneo,
  generarEnfrentamientos,
  generarBracketEliminacion,
  avanzarRondaEliminacion,
};
