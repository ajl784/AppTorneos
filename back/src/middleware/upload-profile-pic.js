const multer = require("multer");
const path = require("path");

// Almacena la foto con el nombre <idUsuario>.ext en la carpeta profile_pics
const PROFILE_PICS_DIR = "/workspace/back/public/profile_pics";
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, PROFILE_PICS_DIR);
  },
  filename: function (req, file, cb) {
    // El idUsuario debe estar en req.user.id_usuario (por JWT)
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, req.user.id_usuario + ext);
  },
});

const fileFilter = (req, file, cb) => {
  // Solo permitir imágenes
  if (!file.mimetype.startsWith("image/")) {
    return cb(new Error("Solo se permiten imágenes"), false);
  }
  cb(null, true);
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB máx
});

module.exports = upload;
