const { Pool } = require("pg");

const pool = new Pool({
  host: process.env.DB_HOST || "postgres",
  port: parseInt(process.env.DB_PORT || "5432", 10),
  user: process.env.DB_USER || "admin",
  password: process.env.DB_PASSWORD || "password123",
  database: process.env.DB_NAME || "app_db",
});

module.exports = { pool };
