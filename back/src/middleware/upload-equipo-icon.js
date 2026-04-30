const fs = require("fs");
const multer = require("multer");
const path = require("path");
const { AppError } = require("../utils/errors");

const EQUIPO_ICONS_DIR = path.join(__dirname, "../../public/equipo_icons");
const DEFAULT_EQUIPO_ICON = "default-equipo-icon.svg";
const DEFAULT_EQUIPO_ICON_PATH = path.join(
  EQUIPO_ICONS_DIR,
  DEFAULT_EQUIPO_ICON,
);
fs.mkdirSync(EQUIPO_ICONS_DIR, { recursive: true });

if (!fs.existsSync(DEFAULT_EQUIPO_ICON_PATH)) {
  fs.writeFileSync(
    DEFAULT_EQUIPO_ICON_PATH,
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" role="img" aria-label="Team"><rect width="128" height="128" rx="24" fill="#d1d5db"/><circle cx="42" cy="40" r="14" fill="#6b7280"/><circle cx="86" cy="40" r="14" fill="#6b7280"/><path d="M22 110c2-12 14-20 20-20h44c6 0 18 8 20 20" fill="#6b7280"/><circle cx="64" cy="55" r="12" fill="#6b7280"/></svg>',
    "utf8",
  );
}

const storage = multer.diskStorage({
  destination: function (_req, _file, cb) {
    cb(null, EQUIPO_ICONS_DIR);
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
  EQUIPO_ICONS_DIR,
  DEFAULT_EQUIPO_ICON,
};
