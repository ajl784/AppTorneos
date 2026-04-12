const express = require("express");

const controller = require("../controllers/usuarios.controller");
const authJwt = require("../middleware/auth-jwt");

const router = express.Router();

// Ruta de prueba protegida con JWT (dev only)
router.get("/pruebajwteliminarluego", authJwt, controller.pruebajwteliminarluego);

// Ruta de cambio de contraseña protegida con JWT
router.post("/modifyPsswd", authJwt, controller.modifyPsswd);

// Nuevas rutas para registro y login
router.post("/register", controller.registerUsuario);
router.post("/login", controller.loginUsuario);

// Calendario de partidos del usuario (por equipos actuales)
router.get("/:idUsuario/calendario", controller.getCalendarioUsuario);

// Actualizar datos de perfil del usuario autenticado
router.put("/me", authJwt, controller.updateMe);

// Imagen de perfil de usuario por id
router.get("/:idUsuario/profile-pic", controller.getUsuarioProfilePic);
// Subir foto de perfil del usuario autenticado
const upload = require("../middleware/upload-profile-pic");
router.post("/me/profile-pic", authJwt, upload.single("foto"), controller.uploadProfilePic);

router.get("/", controller.listUsuarios);
router.get("/:id", controller.getUsuarioById);
router.post("/", controller.createUsuario);
router.put("/:id", controller.updateUsuario);
router.delete("/:id", controller.deleteUsuario);

// Eliminar foto de perfil del usuario autenticado
router.delete("/me/profile-pic", authJwt, controller.deleteProfilePic);

module.exports = router;
