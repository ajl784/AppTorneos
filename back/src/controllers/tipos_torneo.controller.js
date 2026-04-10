const tiposTorneoService = require("../services/tipos_torneo.service");
const { ok, parsePagination, asyncHandler } = require("../utils/http");

const listTiposTorneo = asyncHandler(async (req, res) => {
  const { limit, offset } = parsePagination(req.query);
  const data = await tiposTorneoService.listTiposTorneo({ limit, offset });
  ok(res, data, { limit, offset, count: data.length });
});

module.exports = {
  listTiposTorneo,
};
