const express = require("express");
const controller = require("../controllers/equipos.controller");
const authJwt = require("../middleware/auth-jwt");

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
router.get("/:idEquipo/elo-historial", controller.getEloHistorialEquipo);
router.get("/:idEquipo/solicitudes", authJwt, controller.listSolicitudesIngresoEquipo);
router.post("/:idEquipo/solicitudes", authJwt, controller.createSolicitudIngresoEquipo);
router.get("/:id", controller.getEquipoById);
router.post("/", controller.createEquipo);
router.put("/:id", controller.updateEquipo);
router.delete("/:id", controller.deleteEquipo);

module.exports = router;
