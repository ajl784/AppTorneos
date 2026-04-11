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

router.get("/", controller.listUsuarios);
router.get("/:id", controller.getUsuarioById);
router.post("/", controller.createUsuario);
router.put("/:id", controller.updateUsuario);
router.delete("/:id", controller.deleteUsuario);

module.exports = router;
