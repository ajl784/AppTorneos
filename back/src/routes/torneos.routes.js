
const express = require("express");
const controller = require("../controllers/torneos.controller");
const solicitudesController = require("../controllers/participaciones.controller");
const authMiddleware = require("../middleware/auth-jwt");

const router = express.Router();

router.get("/", controller.listTorneos);
router.get("/:id", controller.getTorneoById);
router.get("/:id/clasificacion", controller.getClasificacionTorneo);
router.get("/:id/partidos", controller.getPartidosTorneo);
router.get("/:id/formulario", controller.getFormularioTorneo);
router.get("/:id/solicitudes", solicitudesController.listSolicitudesByTorneo);
router.post("/", controller.createTorneo);
router.post("/:id/solicitudes", solicitudesController.createSolicitudByTorneo);
router.put("/:id", authMiddleware, controller.updateTorneo);
router.put("/:id/formulario", controller.updateFormularioTorneo);
router.delete("/:id", controller.deleteTorneo);
router.post(
  "/:idTorneo/generar-enfrentamientos",
  controller.generarEnfrentamientos,
);
router.post(
  "/:idTorneo/bracket/eliminacion/generar",
  controller.generarBracketEliminacion,
);
router.post(
  "/:idTorneo/bracket/eliminacion/avanzar",
  controller.avanzarRondaEliminacion,
);

module.exports = router;
