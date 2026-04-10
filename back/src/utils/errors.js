class AppError extends Error {
  constructor(statusCode, message, details) {
    super(message);
    this.statusCode = statusCode;
    this.details = details;
  }
}

const mapDatabaseError = (error) => {
  if (!error || !error.code) {
    return null;
  }

  if (error.code === "23505") {
    return new AppError(409, "Conflicto: el recurso ya existe", {
      dbCode: error.code,
      detail: error.detail,
      constraint: error.constraint,
    });
  }

  if (error.code === "23503") {
    return new AppError(400, "Referencia invalida: clave foranea no valida", {
      dbCode: error.code,
      detail: error.detail,
      constraint: error.constraint,
    });
  }

  if (error.code === "22P02") {
    return new AppError(400, "Tipo de dato invalido", {
      dbCode: error.code,
      detail: error.detail,
    });
  }

  return null;
};

module.exports = {
  AppError,
  mapDatabaseError,
};
