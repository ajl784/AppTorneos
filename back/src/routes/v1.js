const express = require("express");
const usuariosRoutes = require("./usuarios.routes");
const equiposRoutes = require("./equipos.routes");
const categoriasRoutes = require("./categorias.routes");
const tiposTorneoRoutes = require("./tipos_torneo.routes");
const torneosRoutes = require("./torneos.routes");
const partidosRoutes = require("./partidos.routes");
const participacionesRoutes = require("./participaciones.routes");
const estadisticasRoutes = require("./estadisticas.routes");

const router = express.Router();

router.get("/", (_req, res) => {
  res.json({
    ok: true,
    data: {
      service: "AppTorneos API v1",
      resources: {
        usuarios: "/api/v1/usuarios",
        equipos: "/api/v1/equipos",
        categorias: "/api/v1/categorias",
        tiposTorneo: "/api/v1/tipos-torneo",
        torneos: "/api/v1/torneos",
        partidos: "/api/v1/partidos",
        participaciones: "/api/v1/participaciones",
        estadisticas: "/api/v1/estadisticas",
      },
    },
  });
});

router.use("/usuarios", usuariosRoutes);
router.use("/equipos", equiposRoutes);
router.use("/categorias", categoriasRoutes);
router.use("/tipos-torneo", tiposTorneoRoutes);
router.use("/torneos", torneosRoutes);
router.use("/partidos", partidosRoutes);
router.use("/participaciones", participacionesRoutes);
router.use("/estadisticas", estadisticasRoutes);

module.exports = router;
