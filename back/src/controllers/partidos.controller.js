const partidosService = require("../services/partidos.service");
const {
  ok,
  created,
  parsePositiveInt,
  parsePagination,
  requireFields,
  asyncHandler,
} = require("../utils/http");
const { AppError } = require("../utils/errors");

const listPartidos = asyncHandler(async (req, res) => {
  const { limit, offset } = parsePagination(req.query);
  const data = await partidosService.listPartidos({
    limit,
    offset,
    torneoId: req.query.torneoId,
    estado: req.query.estado,
  });

  ok(res, data, { limit, offset, count: data.length });
});

const getPartidoById = asyncHandler(async (req, res) => {
  const idPartido = parsePositiveInt(req.params.id, "id");
  const data = await partidosService.getPartidoById(idPartido);

  if (!data) {
    throw new AppError(404, "Partido no encontrado");
  }

  ok(res, data);
});

const createPartido = asyncHandler(async (req, res) => {
  requireFields(req.body, ["id_torneo", "fecha_hora"]);
  const data = await partidosService.createPartido(req.body);
  created(res, data);
});

const updatePartido = asyncHandler(async (req, res) => {
  const idPartido = parsePositiveInt(req.params.id, "id");
  const data = await partidosService.updatePartido(idPartido, req.body || {});

  if (!data) {
    throw new AppError(404, "Partido no encontrado");
  }

  ok(res, data);
});

const deletePartido = asyncHandler(async (req, res) => {
  const idPartido = parsePositiveInt(req.params.id, "id");
  const deleted = await partidosService.deletePartido(idPartido);

  if (!deleted) {
    throw new AppError(404, "Partido no encontrado");
  }

  ok(res, { deleted: true });
});

const registrarPuntuacionesArbitro = asyncHandler(async (req, res) => {
  const idPartido = parsePositiveInt(req.params.id, "id");

  if (!Array.isArray(req.body.puntuaciones) || !req.body.puntuaciones.length) {
    throw new AppError(
      400,
      "puntuaciones debe ser un array con al menos un elemento",
    );
  }

  req.body.puntuaciones.forEach((item) => {
    if (
      item.id_participacion_equipo === undefined ||
      (item.punto === undefined && item.posicion === undefined)
    ) {
      throw new AppError(
        400,
        "Cada elemento debe incluir id_participacion_equipo y al menos punto o posicion",
      );
    }
  });

  const data = await partidosService.registrarPuntuacionesArbitro({
    idPartido,
    puntuaciones: req.body.puntuaciones,
    idArbitroTorneo: req.body.id_arbitro_torneo,
    acta: req.body.acta,
  });

  if (!data) {
    throw new AppError(404, "Partido no encontrado");
  }

  ok(res, data);
});

module.exports = {
  listPartidos,
  getPartidoById,
  createPartido,
  updatePartido,
  deletePartido,
  registrarPuntuacionesArbitro,
};
