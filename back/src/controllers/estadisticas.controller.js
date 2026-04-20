const estadisticasService = require("../services/estadisticas.service");
const { ok, parsePositiveInt, asyncHandler } = require("../utils/http");
const { AppError } = require("../utils/errors");

const listEquiposUsuario = asyncHandler(async (req, res) => {
  const idUsuario = parsePositiveInt(req.params.idUsuario, "idUsuario");
  const data = await estadisticasService.listEquiposUsuario(idUsuario);
  ok(res, data);
});

const getEloHistorial = asyncHandler(async (req, res) => {
  const idUsuario = parsePositiveInt(req.params.idUsuario, "idUsuario");
  const equipoIdRaw = req.query.equipoId;
  const equipoId = equipoIdRaw ? parsePositiveInt(equipoIdRaw, "equipoId") : null;

  const data = await estadisticasService.getEloHistorial({
    idUsuario,
    idEquipo: equipoId,
  });

  if (!data) {
    throw new AppError(404, "No se encontró un equipo para este usuario");
  }

  if (data.forbidden) {
    throw new AppError(403, "El equipo no pertenece a este usuario");
  }

  ok(res, data);
});

const getRanking = asyncHandler(async (req, res) => {
  const idUsuario = parsePositiveInt(req.params.idUsuario, "idUsuario");
  const equipoIdRaw = req.query.equipoId;
  const equipoId = equipoIdRaw ? parsePositiveInt(equipoIdRaw, "equipoId") : null;

  const data = await estadisticasService.getRanking({
    idUsuario,
    idEquipo: equipoId,
  });

  if (!data) {
    throw new AppError(404, "No se encontró un equipo para este usuario");
  }

  if (data.forbidden) {
    throw new AppError(403, "El equipo no pertenece a este usuario");
  }

  ok(res, data);
});

module.exports = {
  listEquiposUsuario,
  getEloHistorial,
  getRanking,
};
