const express = require("express");
const controller = require("../controllers/equipos.controller");

const router = express.Router();

router.get("/", controller.listEquipos);
router.get("/:id", controller.getEquipoById);
router.post("/", controller.createEquipo);
router.put("/:id", controller.updateEquipo);
router.delete("/:id", controller.deleteEquipo);

module.exports = router;
