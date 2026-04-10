const express = require("express");
const controller = require("../controllers/participaciones.controller");

const router = express.Router();

router.patch("/:id/decision", controller.decidirSolicitud);
router.get("/", controller.listParticipaciones);
router.get("/:id", controller.getParticipacionById);
router.post("/", controller.createParticipacion);
router.put("/:id", controller.updateParticipacion);
router.delete("/:id", controller.deleteParticipacion);

module.exports = router;
