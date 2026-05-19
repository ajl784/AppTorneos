const express = require("express");
const controller = require("../controllers/partidos.controller");
const authMiddleware = require("../middleware/auth-jwt");

const router = express.Router();

router.get("/", controller.listPartidos);
router.get("/:id", controller.getPartidoById);
router.get("/:id/prediccion", controller.getPrediccionPartido);
router.post("/:id/puntuaciones", controller.registrarPuntuacionesArbitro);
router.post("/", controller.createPartido);
router.put("/:id", authMiddleware, controller.updatePartido);
router.delete("/:id", controller.deletePartido);

module.exports = router;
