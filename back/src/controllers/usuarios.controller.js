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
const path = require("path");
const fs = require("fs");
const { pool } = require("../db/pool");

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

// Devuelve la imagen de perfil del usuario (o default.jpg)
const PROFILE_PICS_DIR = "/workspace/back/public/profile_pics";

const getUsuarioProfilePic = async (req, res, next) => {
  try {
    const { idUsuario } = req.params;
    const result = await pool.query(
      "SELECT fotoperfil FROM usuario WHERE id_usuario = $1",
      [idUsuario]
    );
    let filename = "default.jpg";
    if (result.rows.length > 0) {
      const foto = result.rows[0].fotoperfil;
      if (foto && foto !== "default.jpg") {
        filename = foto;
      }
    }
    const imgPath = path.join(PROFILE_PICS_DIR, filename);
    console.log("Buscando imagen en:", imgPath);
    if (!fs.existsSync(imgPath)) {
      const defaultPath = path.join(PROFILE_PICS_DIR, "default.jpg");
      console.log("Buscando default en:", defaultPath);
      if (!fs.existsSync(defaultPath)) {
        return res.status(404).json({ ok: false, error: { message: "Imagen de perfil no encontrada (ni default.jpg)" } });
      }
      return res.sendFile(defaultPath);
    }
    res.sendFile(imgPath);
  } catch (err) {
    next(err);
  }
};

// Actualiza todos los datos del usuario autenticado excepto id_usuario
const updateMe = asyncHandler(async (req, res) => {
  const idUsuario = req.user.id_usuario;
  // Solo permitir campos válidos
  const camposPermitidos = [
    "correo",
    "nombre_usuario",
    "password",
    "nombre",
    "apellidos",
    "fechanacimiento",
    "genero"
  ];
  const payload = {};
  for (const campo of camposPermitidos) {
    if (req.body[campo] !== undefined) {
      payload[campo] = req.body[campo];
    }
  }
  // Validar fecha
  if (payload.fechanacimiento) {
    payload.fechanacimiento = parseDateYmdOrNull(payload.fechanacimiento, "fechanacimiento");
  }
  const data = await pool.query(
    `UPDATE usuario SET
      correo = COALESCE($1, correo),
      nombre_usuario = COALESCE($2, nombre_usuario),
      password_hash = COALESCE(CASE WHEN $3 IS NOT NULL THEN crypt($3, gen_salt('bf')) ELSE NULL END, password_hash),
      nombre = COALESCE($4, nombre),
      apellidos = COALESCE($5, apellidos),
      fechanacimiento = COALESCE($6, fechanacimiento),
      genero = COALESCE($7, genero)
    WHERE id_usuario = $8
    RETURNING id_usuario, correo, nombre_usuario, nombre, apellidos, fechanacimiento, genero, fotoperfil`,
    [
      payload.correo ?? null,
      payload.nombre_usuario ?? null,
      payload.password ?? null,
      payload.nombre ?? null,
      payload.apellidos ?? null,
      payload.fechanacimiento ?? null,
      payload.genero ?? null,
      idUsuario
    ]
  );
  if (!data.rows.length) {
    throw new AppError(404, "Usuario no encontrado");
  }
  ok(res, data.rows[0]);
});

// Subida de foto de perfil
const uploadProfilePic = asyncHandler(async (req, res) => {
  const idUsuario = req.user.id_usuario;
  if (!req.file) {
    throw new AppError(400, "No se subió ninguna imagen");
  }
  // Guardar el nombre del archivo en la BD (ej: 123.jpg)
  const filename = req.file.filename;
  await pool.query(
    "UPDATE usuario SET fotoperfil = $1 WHERE id_usuario = $2",
    [filename, idUsuario]
  );
  ok(res, { updated: true, fotoperfil: filename });
});

// Permite eliminar la foto de perfil (deja fotoperfil en NULL)
const deleteProfilePic = asyncHandler(async (req, res) => {
  const idUsuario = req.user.id_usuario;
  // Obtener nombre de archivo actual
  const result = await pool.query(
    "SELECT fotoperfil FROM usuario WHERE id_usuario = $1",
    [idUsuario]
  );
  if (!result.rows.length) {
    throw new AppError(404, "Usuario no encontrado");
  }
  const filename = result.rows[0].fotoperfil;
  // Eliminar archivo físico si existe y no es null ni default.jpg
  if (filename && filename !== "default.jpg") {
    const imgPath = path.join(PROFILE_PICS_DIR, filename);
    if (fs.existsSync(imgPath)) {
      fs.unlinkSync(imgPath);
    }
  }
  // Poner fotoperfil a NULL
  await pool.query(
    "UPDATE usuario SET fotoperfil = NULL WHERE id_usuario = $1",
    [idUsuario]
  );
  ok(res, { deleted: true });
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
  getUsuarioProfilePic,
  updateMe,
  uploadProfilePic,
  deleteProfilePic,
};
