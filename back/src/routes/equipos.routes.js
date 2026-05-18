const express = require("express");
const controller = require("../controllers/equipos.controller");
const authJwt = require("../middleware/auth-jwt");
const { upload } = require("../middleware/upload-equipo-icon");

const router = express.Router();

router.get("/", controller.listEquipos);
router.get(
  "/solicitudes/usuario/:idUsuario",
  authJwt,
  controller.listSolicitudesIngresoUsuario,
);
router.patch(
  "/solicitudes/:idSolicitudEquipo/decision",
  authJwt,
  controller.decidirSolicitudIngresoEquipo,
);
router.get("/usuario/:idUsuario", controller.getEquiposByUsuario);
router.get(
  "/:idEquipo/solicitudes",
  authJwt,
  controller.listSolicitudesIngresoEquipo,
);
router.post(
  "/:idEquipo/solicitudes",
  authJwt,
  controller.createSolicitudIngresoEquipo,
);
// Historial ELO del equipo
router.get("/:idEquipo/elo-historial", controller.getEloHistorialEquipo);
router.get("/:id", controller.getEquipoById);
router.post("/", controller.createEquipo);
router.put("/:id", controller.updateEquipo);
router.get("/:id/icono", controller.getEquipoIcono);
router.post("/", upload.single("icono"), controller.createEquipo);

module.exports = router;
