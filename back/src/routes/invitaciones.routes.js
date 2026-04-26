const express = require("express");
const controller = require("../controllers/invitaciones.controller");
const router = express.Router();


// Crear invitación general
router.post("/", controller.crearInvitacion);
// Crear invitación para árbitro a torneo
router.post("/arbitro", controller.invitarArbitro);
// Crear invitación para jugador a equipo
router.post("/jugador-equipo", controller.invitarJugadorEquipo);
// Aceptar invitación
router.post("/:idInvitacion/aceptar", controller.aceptarInvitacion);
// Rechazar invitación
router.post("/:idInvitacion/rechazar", controller.rechazarInvitacion);

module.exports = router;
