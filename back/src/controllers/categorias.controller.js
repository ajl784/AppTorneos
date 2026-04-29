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

const {
  CATEGORY_ICONS_DIR,
  DEFAULT_CATEGORY_ICON,
} = require("../middleware/upload-categoria-icon");

const withIconUrl = (categoria) => {
  if (!categoria) {
    return categoria;
  }

  return {
    ...categoria,
    icono_url: `/api/v1/categorias/${categoria.id_categoria}/icono`,
  };
};

const listCategorias = asyncHandler(async (req, res) => {
  const { limit, offset } = parsePagination(req.query);
  const data = await categoriasService.listCategorias({ limit, offset });
  const enriched = data.map(withIconUrl);
  ok(res, enriched, { limit, offset, count: enriched.length });
});

const createCategoria = asyncHandler(async (req, res) => {
  console.log("Body:", req.body); // Log the body to verify received data
  console.log("File:", req.file); // Log the file to verify received file

  requireFields(req.body, ["nombre", "participantes_por_partida"]);
  req.body.icono = req.file ? req.file.filename : null;
  let data;
  try {
    data = await categoriasService.createCategoria(req.body);
  } catch (error) {
    if (req.file) {
      const imgPath = path.join(CATEGORY_ICONS_DIR, req.file.filename);
      if (fs.existsSync(imgPath)) {
        fs.unlinkSync(imgPath);
      }
    }
    throw error;
  }

  created(res, withIconUrl(data));
});

const getCategoriaIcono = asyncHandler(async (req, res) => {
  const idCategoria = parsePositiveInt(req.params.id, "id");
  const icono = await categoriasService.getCategoriaIcono(idCategoria);
  const iconoFilename = icono || DEFAULT_CATEGORY_ICON;

  const imgPath = path.join(CATEGORY_ICONS_DIR, iconoFilename);
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
