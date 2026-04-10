const express = require("express");
const categoriasController = require("../controllers/categorias.controller");

const router = express.Router();

router.get("/", categoriasController.listCategorias);
router.post("/", categoriasController.createCategoria);
router.get("/:id/tipos-torneo", categoriasController.listTiposByCategoria);

module.exports = router;
