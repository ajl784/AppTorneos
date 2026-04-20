const express = require("express");

const controller = require("../controllers/estadisticas.controller");

const router = express.Router();

// Lista equipos (actuales + pasados) del usuario
router.get("/equipos-usuario/:idUsuario", controller.listEquiposUsuario);

// Historial ELO del equipo (por defecto: equipo actual; o ?equipoId=)
router.get("/elo-historial/:idUsuario", controller.getEloHistorial);

// Ranking/top10 en la categoría del equipo (por defecto: equipo actual; o ?equipoId=)
router.get("/ranking/:idUsuario", controller.getRanking);

module.exports = router;
