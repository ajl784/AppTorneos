const usuariosService = require("../services/usuarios.service");
const {
  ok,
  created,
  parsePositiveInt,
  parsePagination,
  requireFields,
  asyncHandler,
} = require("../utils/http");
const { AppError } = require("../utils/errors");

const parseDateYmdOrNull = (value, fieldName) => {
  if (value === undefined || value === null || value === "") {
    return null;
  }

  if (typeof value !== "string") {
    throw new AppError(400, `${fieldName} debe ser un string YYYY-MM-DD`);
  }

  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw new AppError(400, `${fieldName} debe tener formato YYYY-MM-DD`);
  }

  return value;
};

const listUsuarios = asyncHandler(async (req, res) => {
  const { limit, offset } = parsePagination(req.query);
  const data = await usuariosService.listUsuarios({
    limit,
    offset,
    q: req.query.q,
  });

  ok(res, data, { limit, offset, count: data.length });
});

const getUsuarioById = asyncHandler(async (req, res) => {
  const idUsuario = parsePositiveInt(req.params.id, "id");
  const data = await usuariosService.getUsuarioById(idUsuario);

  if (!data) {
    throw new AppError(404, "Usuario no encontrado");
  }

  ok(res, data);
});

const createUsuario = asyncHandler(async (req, res) => {
  requireFields(req.body, ["correo", "nombre_usuario", "password"]);
  const data = await usuariosService.createUsuario(req.body);
  created(res, data);
});

const updateUsuario = asyncHandler(async (req, res) => {
  const idUsuario = parsePositiveInt(req.params.id, "id");
  const data = await usuariosService.updateUsuario(idUsuario, req.body || {});

  if (!data) {
    throw new AppError(404, "Usuario no encontrado");
  }

  ok(res, data);
});

const deleteUsuario = asyncHandler(async (req, res) => {
  const idUsuario = parsePositiveInt(req.params.id, "id");
  const deleted = await usuariosService.deleteUsuario(idUsuario);

  if (!deleted) {
    throw new AppError(404, "Usuario no encontrado");
  }

  ok(res, { deleted: true });
});

// Calendario de partidos del usuario (por equipos actuales)
const getCalendarioUsuario = asyncHandler(async (req, res) => {
  const idUsuario = parsePositiveInt(req.params.idUsuario, "idUsuario");
  const { limit, offset } = parsePagination(req.query);

  const desde = parseDateYmdOrNull(req.query.desde, "desde");
  const hasta = parseDateYmdOrNull(req.query.hasta, "hasta");
  const estado = req.query.estado ? String(req.query.estado) : null;

  const partidos = await usuariosService.getCalendarioUsuario({
    idUsuario,
    desde,
    hasta,
    estado,
    limit,
    offset,
  });

  ok(
    res,
    {
      usuario_id: idUsuario,
      desde,
      hasta,
      partidos,
      total: partidos.length,
    },
    { limit, offset, count: partidos.length },
  );
});

// Registro de usuario (alias de createUsuario, pero ruta /register)
const registerUsuario = asyncHandler(async (req, res) => {
  requireFields(req.body, ["correo", "nombre_usuario", "password"]);
  const data = await usuariosService.createUsuario(req.body);
  created(res, data);
});

// Login de usuario con JWT
const jwt = require("jsonwebtoken");
const JWT_SECRET = process.env.JWT_SECRET || "supersecreto";

const loginUsuario = asyncHandler(async (req, res) => {
  requireFields(req.body, ["correo", "password"]);
  const data = await usuariosService.loginUsuario(req.body);
  if (!data) {
    throw new AppError(401, "Credenciales inválidas");
  }
  // Generar JWT con id_usuario y correo
  const token = jwt.sign(
    { id_usuario: data.id_usuario, correo: data.correo },
    JWT_SECRET,
    { expiresIn: "7d" }
  );
  ok(res, { usuario: data, token });
});

// Dev: Devuelve todos los datos del usuario autenticado
const pruebajwteliminarluego = asyncHandler(async (req, res) => {
  const userId = req.user.id_usuario;
  const data = await usuariosService.getUsuarioById(userId);
  if (!data) {
    throw new AppError(404, "Usuario no encontrado");
  }
  // También podrías devolver la contraseña hasheada si está en el modelo
  // pero getUsuarioById no la devuelve, así que puedes ajustarlo si lo necesitas
  ok(res, data);
});

// Producción: Cambiar contraseña del usuario autenticado
const modifyPsswd = asyncHandler(async (req, res) => {
  requireFields(req.body, ["password"]);
  const userId = req.user.id_usuario;
  const data = await usuariosService.updateUsuario(userId, { password: req.body.password });
  if (!data) {
    throw new AppError(404, "Usuario no encontrado");
  }
  ok(res, { updated: true });
});

module.exports = {
  listUsuarios,
  getUsuarioById,
  createUsuario,
  updateUsuario,
  deleteUsuario,
  registerUsuario,
  loginUsuario,
  pruebajwteliminarluego,
  modifyPsswd,
  getCalendarioUsuario,
};
