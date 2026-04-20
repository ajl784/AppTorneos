-- Migra la restricción de estados del torneo para soportar:
-- - inscripcion_cerrada (nuevo)
-- - inscripcion_terminada (compatibilidad)
--
-- Ejecutar (desde la raíz del repo):
--   docker exec -i app_postgres psql -U admin -d app_db < Backend/BD/migrate_torneo_estado_check.sql

BEGIN;

ALTER TABLE torneo
  DROP CONSTRAINT IF EXISTS torneo_estado_check;

ALTER TABLE torneo
  ADD CONSTRAINT torneo_estado_check
  CHECK (
    estado IN (
      'inscripcion_abierta',
      'inscripcion_cerrada',
      'inscripcion_terminada',
      'en_curso',
      'acabado',
      'cancelado'
    )
  );

COMMIT;
