INSERT INTO usuarios (name, email, password, rol, avatar, activo, intentos_fallidos) VALUES
('Juan Pérez',   'juan.perez@example.com',   '$2a$10$FIsgQkqGfYxDVypPdyjBrekRvRLfI8toXXQmCcJXdftSNDQW.0cDu', 'USER',      'https://api.dicebear.com/7.x/avataaars/svg?seed=Juan',   TRUE, 0),
('María López',  'maria.lopez@example.com',  '$2a$10$FIsgQkqGfYxDVypPdyjBrekRvRLfI8toXXQmCcJXdftSNDQW.0cDu', 'MODERATOR', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Maria',  TRUE, 0),
('Carlos Ruiz',  'carlos.ruiz@example.com',  '$2a$10$FIsgQkqGfYxDVypPdyjBrekRvRLfI8toXXQmCcJXdftSNDQW.0cDu', 'USER',      'https://api.dicebear.com/7.x/avataaars/svg?seed=Carlos', TRUE, 0),
('Ana Gómez',    'ana.gomez@example.com',    '$2a$10$FIsgQkqGfYxDVypPdyjBrekRvRLfI8toXXQmCcJXdftSNDQW.0cDu', 'USER',      'https://api.dicebear.com/7.x/avataaars/svg?seed=Ana',    TRUE, 0),
('Admin DNF',    'admin@dnf.cl',             '$2b$10$VHSKqLcBSglspNMbhnLlku.kCqJXCY.vxXU.gIsT/Lz.r7J.PaeQ2', 'ADMIN',     'https://api.dicebear.com/7.x/avataaars/svg?seed=Admin',  TRUE, 0);

INSERT INTO login_attempts (usuario_id, intento_exitoso, fecha_intento, direccion_ip, razon_fallo) VALUES
(1, TRUE,  NOW() - INTERVAL '3 days',  '192.168.1.10',  NULL),
(1, FALSE, NOW() - INTERVAL '4 days',  '192.168.1.10',  'Contraseña incorrecta'),
(2, TRUE,  NOW() - INTERVAL '2 days',  '192.168.1.11',  NULL),
(3, FALSE, NOW() - INTERVAL '1 day',   '200.54.12.45',  'Cuenta no encontrada'),
(4, TRUE,  NOW() - INTERVAL '6 hours', '190.22.4.78',   NULL),
(5, TRUE,  NOW() - INTERVAL '30 min',  '127.0.0.1',     NULL);
