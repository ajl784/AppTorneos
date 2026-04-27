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
  DEFAULT_CATEGORY_ICON_SVG,
} = require("../middleware/upload-categoria-icon");

const CATEGORY_ICONS_DIR = path.join(__dirname, "../../public/category_icons");

const getMimeByFilename = (filename) => {
  const ext = path.extname(filename || "").toLowerCase();
  switch (ext) {
    case ".jpg":
    case ".jpeg":
      return "image/jpeg";
    case ".png":
      return "image/png";
    case ".webp":
      return "image/webp";
    case ".gif":
      return "image/gif";
    case ".svg":
      return "image/svg+xml";
    default:
      return "application/octet-stream";
  }
};

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
  requireFields(req.body, ["nombre", "participantes_por_partida"]);
  req.body.icono = null;
  req.body.iconoBin = req.file?.buffer || Buffer.from(DEFAULT_CATEGORY_ICON_SVG, "utf8");
  req.body.iconoMime = req.file?.mimetype || "image/svg+xml";

  const data = await categoriasService.createCategoria(req.body);

  created(res, withIconUrl(data));
});

const getCategoriaIcono = asyncHandler(async (req, res) => {
  const idCategoria = parsePositiveInt(req.params.id, "id");
  const icono = await categoriasService.getCategoriaIcono(idCategoria);

  if (icono?.icono_bin) {
    const mime = icono.icono_mime || "application/octet-stream";
    return res.type(mime).send(icono.icono_bin);
  }

  // Compatibilidad temporal: categorías antiguas con archivo físico.
  if (icono?.icono) {
    const imgPath = path.join(CATEGORY_ICONS_DIR, icono.icono);
    if (fs.existsSync(imgPath)) {
      const fileBuffer = fs.readFileSync(imgPath);
      const mime = getMimeByFilename(icono.icono);
      await categoriasService.updateCategoriaIcono(idCategoria, fileBuffer, mime);
      return res.type(mime).send(fileBuffer);
    }
  }

  return res.type("image/svg+xml").send(DEFAULT_CATEGORY_ICON_SVG);
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
