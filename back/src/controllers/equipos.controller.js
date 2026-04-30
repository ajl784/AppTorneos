const equiposService = require("../services/equipos.service");

const {
  ok,
  created,
  parsePositiveInt,
  parsePagination,
  requireFields,
  asyncHandler,
} = require("../utils/http");
const { AppError } = require("../utils/errors");
const fs = require("fs");
const path = require("path");
const {
  EQUIPO_ICONS_DIR,
  DEFAULT_EQUIPO_ICON,
} = require("../middleware/upload-equipo-icon");

const withIconUrl = (equipo) => {
  if (!equipo) {
    return equipo;
  }

  return {
    ...equipo,
    icono_url: `/api/v1/equipos/${equipo.id_equipo}/icono`,
  };
};

const getEquipoIcono = asyncHandler(async (req, res) => {
  const idEquipo = parsePositiveInt(req.params.id, "id");
  const icono = await equiposService.getEquipoIcono(idEquipo);

  if (icono?.icono_bin) {
    const mime = icono.icono_mime || "application/octet-stream";
    return res.type(mime).send(icono.icono_bin);
  }

  if (icono?.icono) {
    const imgPath = path.join(EQUIPO_ICONS_DIR, icono.icono);
    if (fs.existsSync(imgPath)) {
      return res.sendFile(imgPath);
    }
  }

  const fallbackPath = path.join(EQUIPO_ICONS_DIR, DEFAULT_EQUIPO_ICON);
  if (!fs.existsSync(fallbackPath)) {
    return res
      .status(404)
      .json({ ok: false, error: { message: "Icono no encontrado" } });
  }

  return res.sendFile(fallbackPath);
});

const listEquipos = asyncHandler(async (req, res) => {
  const { limit, offset } = parsePagination(req.query);
  const data = await equiposService.listEquipos({
    limit,
    offset,
    nombre: req.query.nombre,
    categoriaId: req.query.categoriaId,
  });

  const enriched = data.map(withIconUrl);
  ok(res, enriched, { limit, offset, count: enriched.length });
});

const getEquipoById = asyncHandler(async (req, res) => {
  const idEquipo = parsePositiveInt(req.params.id, "id");
  const data = await equiposService.getEquipoById(idEquipo);

  if (!data) {
    throw new AppError(404, "Equipo no encontrado");
  }

  ok(res, withIconUrl(data));
});

const getEloHistorialEquipo = asyncHandler(async (req, res) => {
  const idEquipo = parsePositiveInt(req.params.idEquipo, "idEquipo");
  const data = await equiposService.getEloHistorialEquipo(idEquipo);

  if (!data) {
    throw new AppError(404, "Equipo no encontrado");
  }

  ok(res, data);
});

const createEquipo = asyncHandler(async (req, res) => {
  requireFields(req.body, ["nombre", "id_categoria"]);
  const payload = {
    ...req.body,
    id_categoria: parsePositiveInt(req.body.id_categoria, "id_categoria"),
  };

  if (req.body.id_usuario !== undefined && req.body.id_usuario !== null) {
    payload.id_usuario = parsePositiveInt(req.body.id_usuario, "id_usuario");
  }

  payload.icono = req.file ? req.file.filename : null;
  let data;
  try {
    data = await equiposService.createEquipo(payload);
  } catch (error) {
    if (req.file) {
      const imgPath = path.join(EQUIPO_ICONS_DIR, req.file.filename);
      if (fs.existsSync(imgPath)) {
        fs.unlinkSync(imgPath);
      }
    }
    throw error;
  }
  created(res, withIconUrl(data));
});

const updateEquipo = asyncHandler(async (req, res) => {
  const idEquipo = parsePositiveInt(req.params.id, "id");
  const data = await equiposService.updateEquipo(idEquipo, req.body || {});

  if (!data) {
    throw new AppError(404, "Equipo no encontrado");
  }

  ok(res, data);
});

const deleteEquipo = asyncHandler(async (req, res) => {
  const idEquipo = parsePositiveInt(req.params.id, "id");
  const deleted = await equiposService.deleteEquipo(idEquipo);

  if (!deleted) {
    throw new AppError(404, "Equipo no encontrado");
  }

  ok(res, { deleted: true });
});

const getEquiposByUsuario = asyncHandler(async (req, res) => {
  const idUsuario = parsePositiveInt(req.params.idUsuario, "idUsuario");
  const data = await equiposService.getEquiposByUsuario(idUsuario);
  ok(res, data);
});

const createSolicitudIngresoEquipo = asyncHandler(async (req, res) => {
  const idEquipo = parsePositiveInt(req.params.idEquipo, "idEquipo");
  requireFields(req.body, ["descripcion"]);

  const data = await equiposService.createSolicitudIngresoEquipo({
    idEquipo,
    idUsuario: parsePositiveInt(req.user.id_usuario, "id_usuario"),
    respuesta: {
      descripcion: String(req.body.descripcion || "").trim(),
    },
  });

  created(res, data);
});

const listSolicitudesIngresoEquipo = asyncHandler(async (req, res) => {
  const idEquipo = parsePositiveInt(req.params.idEquipo, "idEquipo");
  const idUsuario = parsePositiveInt(req.user.id_usuario, "id_usuario");

  const isEntrenador = await equiposService.isEntrenadorActivo({
    idEquipo,
    idUsuario,
  });

  if (!isEntrenador) {
    throw new AppError(
      403,
      "Solo el entrenador del equipo puede ver solicitudes",
    );
  }

  const data = await equiposService.listSolicitudesIngresoEquipo({
    idEquipo,
    estado: req.query.estado,
  });

  ok(res, data, { count: data.length });
});

const listSolicitudesIngresoUsuario = asyncHandler(async (req, res) => {
  const idUsuario = parsePositiveInt(req.params.idUsuario, "idUsuario");
  const authIdUsuario = parsePositiveInt(req.user.id_usuario, "id_usuario");

  if (idUsuario !== authIdUsuario) {
    throw new AppError(403, "Solo puedes ver tus propias solicitudes");
  }

  const data = await equiposService.listSolicitudesIngresoUsuario({
    idUsuario,
    estado: req.query.estado,
  });

  ok(res, data, { count: data.length });
});

const decidirSolicitudIngresoEquipo = asyncHandler(async (req, res) => {
  const idSolicitudEquipo = parsePositiveInt(
    req.params.idSolicitudEquipo,
    "idSolicitudEquipo",
  );

  if (typeof req.body.aceptar !== "boolean") {
    throw new AppError(400, "aceptar debe ser booleano");
  }

  const idEntrenadorDecisor = parsePositiveInt(
    req.user.id_usuario,
    "id_usuario",
  );

  const solicitud =
    await equiposService.getSolicitudIngresoById(idSolicitudEquipo);
  if (!solicitud) {
    throw new AppError(404, "Solicitud de ingreso no encontrada");
  }

  const isEntrenador = await equiposService.isEntrenadorActivo({
    idEquipo: parsePositiveInt(solicitud.id_equipo, "id_equipo"),
    idUsuario: idEntrenadorDecisor,
  });

  if (!isEntrenador) {
    throw new AppError(
      403,
      "Solo el entrenador del equipo puede decidir solicitudes",
    );
  }

  const data = await equiposService.decideSolicitudIngresoEquipo({
    idSolicitudEquipo,
    aceptar: req.body.aceptar,
    idEntrenadorDecisor,
  });

  if (!data) {
    throw new AppError(404, "Solicitud de ingreso no encontrada");
  }

  ok(res, data);
});

module.exports = {
  listEquipos,
  getEquipoById,
  getEloHistorialEquipo,
  createEquipo,
  updateEquipo,
  deleteEquipo,
  getEquiposByUsuario,
  createSolicitudIngresoEquipo,
  listSolicitudesIngresoEquipo,
  listSolicitudesIngresoUsuario,
  decidirSolicitudIngresoEquipo,
  getEquipoIcono,
};
