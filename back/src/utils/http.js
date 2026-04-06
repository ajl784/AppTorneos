const { AppError } = require("./errors");

const ok = (res, data, meta) => {
  res.json({
    ok: true,
    data,
    meta: meta || null,
  });
};

const created = (res, data) => {
  res.status(201).json({
    ok: true,
    data,
  });
};

const parsePositiveInt = (value, fieldName) => {
  const parsed = parseInt(value, 10);
  if (Number.isNaN(parsed) || parsed <= 0) {
    throw new AppError(400, `${fieldName} debe ser un entero positivo`);
  }
  return parsed;
};

const parsePagination = (query) => {
  const limit = query.limit ? parseInt(query.limit, 10) : 50;
  const offset = query.offset ? parseInt(query.offset, 10) : 0;

  if (Number.isNaN(limit) || limit < 1 || limit > 200) {
    throw new AppError(400, "limit debe estar entre 1 y 200");
  }

  if (Number.isNaN(offset) || offset < 0) {
    throw new AppError(400, "offset debe ser 0 o mayor");
  }

  return { limit, offset };
};

const requireFields = (obj, fields) => {
  const missing = fields.filter((field) => {
    const value = obj[field];
    return value === undefined || value === null || value === "";
  });

  if (missing.length) {
    throw new AppError(400, `Faltan campos requeridos: ${missing.join(", ")}`);
  }
};

const asyncHandler = (fn) => async (req, res, next) => {
  try {
    await fn(req, res, next);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  ok,
  created,
  parsePositiveInt,
  parsePagination,
  requireFields,
  asyncHandler,
};
