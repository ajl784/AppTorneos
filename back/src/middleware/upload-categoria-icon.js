const fs = require("fs");
const multer = require("multer");
const path = require("path");
const { AppError } = require("../utils/errors");

const CATEGORY_ICONS_DIR = path.join(__dirname, "../../public/category_icons");
const DEFAULT_CATEGORY_ICON = "default-category-icon.svg";
const DEFAULT_CATEGORY_ICON_PATH = path.join(CATEGORY_ICONS_DIR, DEFAULT_CATEGORY_ICON);
fs.mkdirSync(CATEGORY_ICONS_DIR, { recursive: true });

if (!fs.existsSync(DEFAULT_CATEGORY_ICON_PATH)) {
  fs.writeFileSync(
    DEFAULT_CATEGORY_ICON_PATH,
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" role="img" aria-label="Category"><rect width="128" height="128" rx="24" fill="#e5e7eb"/><circle cx="64" cy="44" r="18" fill="#6b7280"/><path d="M28 98c4-16 18-27 36-27s32 11 36 27" fill="#6b7280"/></svg>',
    "utf8",
  );
}

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
  DEFAULT_CATEGORY_ICON,
};