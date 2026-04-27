const fs = require("fs");
const path = require("path");
const { pool } = require("../db/pool");
const { DEFAULT_CATEGORY_ICON_SVG } = require("../middleware/upload-categoria-icon");

const CATEGORY_ICONS_DIR = path.join(__dirname, "../../public/category_icons");

const getMimeByFilename = (filename) => {
  const ext = path.extname(filename || "").toLowerCase();
  switch (ext) {
    case ".jpg":
    case ".jpeg":
      return "image/jpeg";
    case ".png":
      return "image/png";
    case ".webp":
      return "image/webp";
    case ".gif":
      return "image/gif";
    case ".svg":
      return "image/svg+xml";
    default:
      return "application/octet-stream";
  }
};

const run = async () => {
  const defaultBuffer = Buffer.from(DEFAULT_CATEGORY_ICON_SVG, "utf8");
  const defaultMime = "image/svg+xml";

  const result = await pool.query(
    `SELECT id_categoria, icono, icono_bin
     FROM categoria
     ORDER BY id_categoria ASC`,
  );

  let migratedFromFile = 0;
  let defaulted = 0;
  let alreadyInDb = 0;
  let missingFile = 0;

  for (const categoria of result.rows) {
    if (categoria.icono_bin) {
      alreadyInDb += 1;
      continue;
    }

    let bin = null;
    let mime = null;

    if (categoria.icono) {
      const imgPath = path.join(CATEGORY_ICONS_DIR, categoria.icono);
      if (fs.existsSync(imgPath)) {
        bin = fs.readFileSync(imgPath);
        mime = getMimeByFilename(categoria.icono);
        migratedFromFile += 1;
      } else {
        missingFile += 1;
      }
    }

    if (!bin) {
      bin = defaultBuffer;
      mime = defaultMime;
      defaulted += 1;
    }

    await pool.query(
      `UPDATE categoria
       SET icono_bin = $2,
           icono_mime = $3
       WHERE id_categoria = $1`,
      [categoria.id_categoria, bin, mime],
    );
  }

  console.log("Migracion de iconos finalizada.");
  console.log(`Total categorias: ${result.rowCount}`);
  console.log(`Ya en DB: ${alreadyInDb}`);
  console.log(`Migradas desde archivo: ${migratedFromFile}`);
  console.log(`Con default en DB: ${defaulted}`);
  console.log(`Referencias a archivo faltante: ${missingFile}`);
};

run()
  .catch((error) => {
    console.error("Error ejecutando migracion de iconos:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });
