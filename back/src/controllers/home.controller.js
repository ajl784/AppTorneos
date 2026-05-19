const homeService = require("../services/home.service");
const { ok, parsePositiveInt, asyncHandler } = require("../utils/http");

const getHomeOverview = asyncHandler(async (req, res) => {
  const categoriasLimit = req.query.categoriasLimit
    ? parsePositiveInt(req.query.categoriasLimit, "categoriasLimit")
    : 6;
  const torneosLimit = req.query.torneosLimit
    ? parsePositiveInt(req.query.torneosLimit, "torneosLimit")
    : 5;

  const data = await homeService.getHomeOverview({ categoriasLimit, torneosLimit });
  ok(res, data, { categoriasLimit, torneosLimit });
});

module.exports = {
  getHomeOverview,
};