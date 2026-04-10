const express = require("express");
const tiposTorneoController = require("../controllers/tipos_torneo.controller");

const router = express.Router();

router.get("/", tiposTorneoController.listTiposTorneo);

module.exports = router;
