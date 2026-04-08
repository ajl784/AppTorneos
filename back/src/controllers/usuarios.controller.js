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

module.exports = {
  listUsuarios,
  getUsuarioById,
  createUsuario,
  updateUsuario,
  deleteUsuario,
};
