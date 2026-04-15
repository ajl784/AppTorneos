require("dotenv").config();

const app = require("./src/app");
const { pool } = require("./src/db/pool");

const port = parseInt(process.env.PORT || "3000", 10);

app.listen(port, () => {
  console.log(`Backend listening on port ${port}`);
});

const shutdown = async () => {
  try {
    await pool.end();
  } finally {
    process.exit(0);
  }
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
