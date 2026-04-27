const express = require("express");
const categoriasController = require("../controllers/categorias.controller");
const { upload } = require("../middleware/upload-categoria-icon");

const router = express.Router();

router.get("/", categoriasController.listCategorias);
router.get("/:id/icono", categoriasController.getCategoriaIcono);
router.post("/", upload.single("icono"), categoriasController.createCategoria);
router.get("/:id/tipos-torneo", categoriasController.listTiposByCategoria);

module.exports = router;
