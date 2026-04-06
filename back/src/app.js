const express = require("express");
const cors = require("cors");
const { pool } = require("./db/pool");
const v1Routes = require("./routes/v1");
const { notFound } = require("./middleware/not-found");
const { errorHandler } = require("./middleware/error-handler");

const app = express();

app.use(
  cors({
    origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(",") : "*",
  }),
);
app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ extended: true }));

app.get("/", (_req, res) => {
  res.json({
    ok: true,
    data: {
      service: "AppTorneos backend",
      status: "running",
      health: "/health",
      api: "/api/v1",
    },
  });
});

app.get("/health", async (_req, res, next) => {
  try {
    const result = await pool.query("SELECT 1 AS ok");
    res.json({
      ok: true,
      data: {
        status: "ok",
        db: result.rows[0].ok === 1 ? "connected" : "unknown",
      },
    });
  } catch (error) {
    next(error);
  }
});

app.use("/api/v1", v1Routes);
app.use(notFound);
app.use(errorHandler);

module.exports = app;
