const express = require("express");
const controller = require("../controllers/usuarios.controller");

const router = express.Router();

router.get("/", controller.listUsuarios);
router.get("/:id", controller.getUsuarioById);
router.post("/", controller.createUsuario);
router.put("/:id", controller.updateUsuario);
router.delete("/:id", controller.deleteUsuario);

module.exports = router;
