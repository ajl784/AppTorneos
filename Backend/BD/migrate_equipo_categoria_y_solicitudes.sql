-- Migracion: categoria obligatoria en equipo + solicitudes de ingreso a equipo

BEGIN;

ALTER TABLE equipo
  ADD COLUMN IF NOT EXISTS id_categoria BIGINT;

-- Si hay equipos sin categoria, se asigna la primera categoria disponible.
WITH cat_default AS (
  SELECT id_categoria
  FROM categoria
  ORDER BY id_categoria
  LIMIT 1
)
UPDATE equipo e
SET id_categoria = c.id_categoria
FROM cat_default c
WHERE e.id_categoria IS NULL;

ALTER TABLE equipo
  ALTER COLUMN id_categoria SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'equipo_id_categoria_fkey'
  ) THEN
    ALTER TABLE equipo
      ADD CONSTRAINT equipo_id_categoria_fkey
      FOREIGN KEY (id_categoria)
      REFERENCES categoria(id_categoria);
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS solicitud_equipo (
  id_solicitud_equipo BIGSERIAL PRIMARY KEY,
  id_equipo BIGINT NOT NULL REFERENCES equipo(id_equipo) ON DELETE CASCADE,
  id_usuario BIGINT NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  respuesta JSONB,
  estado VARCHAR(20) NOT NULL DEFAULT 'pendiente',
  id_entrenador_decisor BIGINT REFERENCES usuario(id_usuario) ON DELETE SET NULL,
  fecha_decision TIMESTAMPTZ,
  CHECK (estado IN ('pendiente', 'aceptada', 'rechazada'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_solicitud_equipo_pendiente
ON solicitud_equipo (id_equipo, id_usuario)
WHERE estado = 'pendiente';

COMMIT;
