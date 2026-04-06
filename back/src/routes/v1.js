const express = require("express");
const usuariosRoutes = require("./usuarios.routes");
const equiposRoutes = require("./equipos.routes");
const torneosRoutes = require("./torneos.routes");
const partidosRoutes = require("./partidos.routes");
const participacionesRoutes = require("./participaciones.routes");

const router = express.Router();

router.get("/", (_req, res) => {
  res.json({
    ok: true,
    data: {
      service: "AppTorneos API v1",
      resources: {
        usuarios: "/api/v1/usuarios",
        equipos: "/api/v1/equipos",
        torneos: "/api/v1/torneos",
        partidos: "/api/v1/partidos",
        participaciones: "/api/v1/participaciones",
      },
    },
  });
});

router.use("/usuarios", usuariosRoutes);
router.use("/equipos", equiposRoutes);
router.use("/torneos", torneosRoutes);
router.use("/partidos", partidosRoutes);
router.use("/participaciones", participacionesRoutes);

module.exports = router;
