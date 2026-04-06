const express = require("express");
const { Pool } = require("pg");

const app = express();
const port = parseInt(process.env.PORT || "3000", 10);

const pool = new Pool({
  host: process.env.DB_HOST || "postgres",
  port: parseInt(process.env.DB_PORT || "5432", 10),
  user: process.env.DB_USER || "admin",
  password: process.env.DB_PASSWORD || "password123",
  database: process.env.DB_NAME || "app_db",
});

app.get("/", (_req, res) => {
  res.json({
    service: "AppTorneos backend",
    status: "running",
    health: "/health",
  });
});

app.get("/health", async (_req, res) => {
  try {
    const result = await pool.query("SELECT 1 AS ok");
    res.json({
      status: "ok",
      db: result.rows[0].ok === 1 ? "connected" : "unknown",
    });
  } catch (error) {
    res.status(500).json({
      status: "error",
      db: "disconnected",
      message: error.message,
    });
  }
});

app.get("/health/usuarios", async (_req, res) => {
  try {
    const result = await pool.query(
      "SELECT id_usuario, correo, nombre_usuario FROM usuario ORDER BY id_usuario DESC LIMIT 10",
    );
    res.json({
      status: "ok",
      count: result.rowCount,
      usuarios: result.rows,
    });
  } catch (error) {
    res.status(500).json({
      status: "error",
      message: error.message,
    });
  }
});

app.listen(port, () => {
  console.log(`Backend listening on port ${port}`);
});

const shutdown = async () => {
  await pool.end();
  process.exit(0);
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
