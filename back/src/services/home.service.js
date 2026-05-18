const { pool } = require("../db/pool");

const DEFAULT_CATEGORY_COUNT = 6;
const DEFAULT_TOURNAMENT_COUNT = 5;

const withIconUrl = (categoria) => ({
  ...categoria,
  icono_url: `/api/v1/categorias/${categoria.id_categoria}/icono`,
});

const getHomeOverview = async ({
  categoriasLimit = DEFAULT_CATEGORY_COUNT,
  torneosLimit = DEFAULT_TOURNAMENT_COUNT,
} = {}) => {
  const [statsResult, categoriasResult, torneosResult] = await Promise.all([
    pool.query(
      `SELECT
        (SELECT COUNT(*)::int FROM categoria) AS total_categorias,
        (SELECT COUNT(*)::int FROM torneo WHERE estado = 'inscripcion_abierta') AS torneos_abiertos,
        (SELECT COUNT(*)::int FROM torneo WHERE estado = 'en_curso') AS torneos_en_curso,
        (SELECT COUNT(*)::int FROM participacion_torneo_equipo) AS participaciones_totales`,
    ),
    pool.query(
      `SELECT
        id_categoria,
        nombre,
        participantes_por_partida,
        norma,
        descripcion,
        icono
       FROM categoria
       ORDER BY RANDOM()
       LIMIT $1`,
      [categoriasLimit],
    ),
    pool.query(
      `SELECT
        t.id_torneo,
        t.nombre,
        t.descripcion,
        t.fecha_inicio,
        t.fecha_fin,
        t.estado,
        t.id_categoria,
        c.nombre AS categoria_nombre,
        t.id_tipo_torneo,
        tt.nombre AS tipo_torneo_nombre,
        t.id_organizador,
        t.limite_equipos,
        COALESCE(pcount.participantes_actuales, 0)::int AS participantes_actuales
       FROM torneo t
       JOIN categoria c ON c.id_categoria = t.id_categoria
       JOIN tipo_torneo tt ON tt.id_tipo_torneo = t.id_tipo_torneo
       LEFT JOIN (
         SELECT id_torneo, COUNT(DISTINCT id_equipo)::int AS participantes_actuales
         FROM participacion_torneo_equipo
         GROUP BY id_torneo
       ) pcount ON pcount.id_torneo = t.id_torneo
       WHERE t.fecha_inicio IS NULL
          OR t.fecha_inicio >= NOW()
          OR t.estado IN ('inscripcion_abierta', 'en_curso')
       ORDER BY
         CASE WHEN t.fecha_inicio IS NULL THEN 1 ELSE 0 END,
         t.fecha_inicio ASC NULLS LAST,
         t.id_torneo DESC
       LIMIT $1`,
      [torneosLimit],
    ),
  ]);

  const stats = statsResult.rows[0] || {};

  return {
    hero: {
      title: "Ready for the next challenge?",
      subtitle:
        "Explora categorías vivas, sigue los torneos que vienen y entra al siguiente reto sin perder el ritmo.",
    },
    stats: {
      totalCategorias: Number(stats.total_categorias || 0),
      torneosAbiertos: Number(stats.torneos_abiertos || 0),
      torneosEnCurso: Number(stats.torneos_en_curso || 0),
      participacionesTotales: Number(stats.participaciones_totales || 0),
    },
    categorias: categoriasResult.rows.map(withIconUrl),
    torneos: torneosResult.rows.map((torneo) => ({
      ...torneo,
      id_torneo: Number(torneo.id_torneo),
      id_categoria: Number(torneo.id_categoria),
      id_tipo_torneo: Number(torneo.id_tipo_torneo),
      id_organizador: torneo.id_organizador == null ? null : Number(torneo.id_organizador),
      limite_equipos:
        torneo.limite_equipos == null ? null : Number(torneo.limite_equipos),
      participantes_actuales: Number(torneo.participantes_actuales || 0),
    })),
  };
};

module.exports = {
  getHomeOverview,
};