const express = require("express");
const controller = require("../controllers/participaciones.controller");
const authMiddleware = require("../middleware/auth-jwt");

const router = express.Router();

router.patch("/:id/decision", controller.decidirSolicitud);
router.get("/", controller.listParticipaciones);
router.get("/:id", controller.getParticipacionById);
router.post("/", controller.createParticipacion);
router.put("/:id", controller.updateParticipacion);
router.delete("/:id", authMiddleware, controller.deleteParticipacion);
router.delete("/:idTorneo/equipo/:idEquipo", authMiddleware, controller.deleteEquipoDelTorneo);

module.exports = router;
