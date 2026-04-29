-- =====================================================
-- Debug: Usuario único
-- =====================================================

BEGIN;

-- Crear un único usuario
INSERT INTO usuario (correo, nombre_usuario, password_hash, nombre, apellidos)
VALUES
  ('usuario_unico@debug.com', 'usuario_unico', crypt('password123', gen_salt('bf')), 'Usuario', 'Único')
ON CONFLICT (correo) DO NOTHING;

COMMIT;