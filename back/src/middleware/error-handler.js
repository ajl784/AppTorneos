const { AppError, mapDatabaseError } = require("../utils/errors");

const errorHandler = (error, _req, res, _next) => {
  const mapped = mapDatabaseError(error);
  const finalError = mapped || error;

  if (finalError instanceof AppError) {
    return res.status(finalError.statusCode).json({
      ok: false,
      error: {
        message: finalError.message,
        details: finalError.details || null,
      },
    });
  }

  console.error("Unhandled error:", error);
  return res.status(500).json({
    ok: false,
    error: {
      message: "Error interno del servidor",
      details: process.env.NODE_ENV === "development" ? error.message : null,
    },
  });
};

module.exports = { errorHandler };
