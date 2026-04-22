const categoriasService = require("../services/categorias.service");
const fs = require("fs");
const path = require("path");
const {
  ok,
  created,
  parsePositiveInt,
  parsePagination,
  requireFields,
  asyncHandler,
} = require("../utils/http");

const { CATEGORY_ICONS_DIR } = require("../middleware/upload-categoria-icon");

const listCategorias = asyncHandler(async (req, res) => {
  const { limit, offset } = parsePagination(req.query);
  const data = await categoriasService.listCategorias({ limit, offset });
  ok(res, data, { limit, offset, count: data.length });
});

const createCategoria = asyncHandler(async (req, res) => {
  requireFields(req.body, ["nombre", "participantes_por_partida"]);
  if (req.file) {
    req.body.icono = req.file.filename;
  }
  const data = await categoriasService.createCategoria(req.body);
  created(res, data);
});

const getCategoriaIcono = asyncHandler(async (req, res) => {
  const idCategoria = parsePositiveInt(req.params.id, "id");
  const icono = await categoriasService.getCategoriaIcono(idCategoria);

  if (!icono) {
    return res.status(404).json({ ok: false, error: { message: "Icono no encontrado" } });
  }

  const imgPath = path.join(CATEGORY_ICONS_DIR, icono);
  if (!fs.existsSync(imgPath)) {
    return res.status(404).json({ ok: false, error: { message: "Icono no encontrado" } });
  }

  return res.sendFile(imgPath);
});

const listTiposByCategoria = asyncHandler(async (req, res) => {
  const idCategoria = parsePositiveInt(req.params.id, "id");
  const data = await categoriasService.listTiposTorneoByCategoriaId(idCategoria);
  ok(res, data);
});

module.exports = {
  listCategorias,
  createCategoria,
  getCategoriaIcono,
  listTiposByCategoria,
};
