const fs = require("fs");
const multer = require("multer");
const path = require("path");
const { AppError } = require("../utils/errors");

const CATEGORY_ICONS_DIR = path.join(__dirname, "../../public/category_icons");
fs.mkdirSync(CATEGORY_ICONS_DIR, { recursive: true });

const storage = multer.diskStorage({
  destination: function (_req, _file, cb) {
    cb(null, CATEGORY_ICONS_DIR);
  },
  filename: function (_req, file, cb) {
    const ext = path.extname(file.originalname).toLowerCase() || ".png";
    const safeSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${safeSuffix}${ext}`);
  },
});

const fileFilter = (_req, file, cb) => {
  const allowedExtensions = new Set([".jpg", ".jpeg", ".png", ".webp", ".gif"]);
  const ext = path.extname(file.originalname || "").toLowerCase();
  const hasImageMime = (file.mimetype || "").startsWith("image/");
  const hasAllowedExt = allowedExtensions.has(ext);

  // En algunos clientes (especialmente desktop/web), el multipart llega como
  // application/octet-stream aunque el archivo sí sea una imagen.
  if (!hasImageMime && !hasAllowedExt) {
    return cb(new AppError(400, "Solo se permiten imágenes"), false);
  }
  cb(null, true);
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 },
});

module.exports = {
  upload,
  CATEGORY_ICONS_DIR,
};