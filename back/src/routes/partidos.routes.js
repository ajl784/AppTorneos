const express = require("express");
const controller = require("../controllers/partidos.controller");

const router = express.Router();

router.get("/", controller.listPartidos);
router.get("/:id", controller.getPartidoById);
router.post("/:id/puntuaciones", controller.registrarPuntuacionesArbitro);
router.post("/", controller.createPartido);
router.put("/:id", controller.updatePartido);
router.delete("/:id", controller.deletePartido);

module.exports = router;
