-- =====================================================
-- Migration: Agregar orden_serie a tabla partido
-- Descripción: Rastrea a qué serie (grupo) pertenece cada partido en torneos de eliminación por serie
-- =====================================================

BEGIN;

-- Agregar columna orden_serie con default 0 para registros existentes
ALTER TABLE partido ADD COLUMN orden_serie INTEGER DEFAULT 0;

-- Agregar constraint para validar que sea mayor a 0
ALTER TABLE partido ADD CONSTRAINT check_orden_serie CHECK (orden_serie >= 0);

-- Crear índice para búsquedas rápidas por serie
CREATE INDEX idx_partido_serie 
ON partido (id_torneo, ronda, orden_serie);

-- Agregar comentario
COMMENT ON COLUMN partido.orden_serie IS 'Identifica la serie/grupo al que pertenece un partido en torneos de eliminación por serie. 0 = no es serie, 1+ = número de serie';

COMMIT;
