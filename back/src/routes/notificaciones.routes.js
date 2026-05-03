const express = require("express");
const router = express.Router();
const notificacionesController = require("../controllers/notificaciones.controller");

// Crear notificación
router.post("/", notificacionesController.crearNotificacion);

// Consultar notificaciones de un usuario
router.get("/usuario/:idUsuario", notificacionesController.getNotificacionesUsuario);

// Consultar notificaciones con filtros
router.get("/", notificacionesController.getNotificaciones);

// Marcar como leída
router.patch("/:idNotificacion/leida", notificacionesController.marcarComoLeida);

// Eliminar notificación
router.delete("/:idNotificacion", notificacionesController.eliminarNotificacion);

module.exports = router;