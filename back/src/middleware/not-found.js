const notFound = (_req, res) => {
  res.status(404).json({
    ok: false,
    error: {
      message: "Ruta no encontrada",
      details: null,
    },
  });
};

module.exports = { notFound };
