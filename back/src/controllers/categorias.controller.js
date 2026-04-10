const categoriasService = require("../services/categorias.service");
const {
  ok,
  created,
  parsePositiveInt,
  parsePagination,
  requireFields,
  asyncHandler,
} = require("../utils/http");

const listCategorias = asyncHandler(async (req, res) => {
  const { limit, offset } = parsePagination(req.query);
  const data = await categoriasService.listCategorias({ limit, offset });
  ok(res, data, { limit, offset, count: data.length });
});

const createCategoria = asyncHandler(async (req, res) => {
  requireFields(req.body, ["nombre", "participantes_por_partida"]);
  const data = await categoriasService.createCategoria(req.body);
  created(res, data);
});

const listTiposByCategoria = asyncHandler(async (req, res) => {
  const idCategoria = parsePositiveInt(req.params.id, "id");
  const data = await categoriasService.listTiposTorneoByCategoriaId(idCategoria);
  ok(res, data);
});

module.exports = {
  listCategorias,
  createCategoria,
  listTiposByCategoria,
};
