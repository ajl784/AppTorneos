const express = require("express");
const controller = require("../controllers/torneos.controller");
const solicitudesController = require("../controllers/participaciones.controller");

const router = express.Router();

router.get("/", controller.listTorneos);
router.get("/:id", controller.getTorneoById);
router.get("/:id/formulario", controller.getFormularioTorneo);
router.get("/:id/solicitudes", solicitudesController.listSolicitudesByTorneo);
router.post("/", controller.createTorneo);
router.post("/:id/solicitudes", solicitudesController.createSolicitudByTorneo);
router.put("/:id", controller.updateTorneo);
router.put("/:id/formulario", controller.updateFormularioTorneo);
router.delete("/:id", controller.deleteTorneo);

module.exports = router;
