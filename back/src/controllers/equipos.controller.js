const equiposService = require("../services/equipos.service");

const {
  ok,
  created,
  parsePositiveInt,
  parsePagination,
  requireFields,
  asyncHandler,
} = require("../utils/http");
const { AppError } = require("../utils/errors");

const listEquipos = asyncHandler(async (req, res) => {
  const { limit, offset } = parsePagination(req.query);
  const data = await equiposService.listEquipos({
    limit,
    offset,
    nombre: req.query.nombre,
  });

  ok(res, data, { limit, offset, count: data.length });
});

const getEquipoById = asyncHandler(async (req, res) => {
  const idEquipo = parsePositiveInt(req.params.id, "id");
  const data = await equiposService.getEquipoById(idEquipo);

  if (!data) {
    throw new AppError(404, "Equipo no encontrado");
  }

  ok(res, data);
});

const createEquipo = asyncHandler(async (req, res) => {
  requireFields(req.body, ["nombre"]);
  const data = await equiposService.createEquipo(req.body);
  created(res, data);
});

const updateEquipo = asyncHandler(async (req, res) => {
  const idEquipo = parsePositiveInt(req.params.id, "id");
  const data = await equiposService.updateEquipo(idEquipo, req.body || {});

  if (!data) {
    throw new AppError(404, "Equipo no encontrado");
  }

  ok(res, data);
});

const deleteEquipo = asyncHandler(async (req, res) => {
  const idEquipo = parsePositiveInt(req.params.id, "id");
  const deleted = await equiposService.deleteEquipo(idEquipo);

  if (!deleted) {
    throw new AppError(404, "Equipo no encontrado");
  }

  ok(res, { deleted: true });
});

const getEquiposByUsuario = asyncHandler(async (req, res) => {
  const idUsuario = parsePositiveInt(req.params.idUsuario, "idUsuario");
  const data = await equiposService.getEquiposByUsuario(idUsuario);
  ok(res, data);
});

module.exports = {
  listEquipos,
  getEquipoById,
  createEquipo,
  updateEquipo,
  deleteEquipo,
  getEquiposByUsuario,
};
