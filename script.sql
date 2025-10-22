-- 0. Preparar (borra si existe)
DROP DATABASE IF EXISTS campus_sustentable;
CREATE DATABASE campus_sustentable CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE campus_sustentable;

-- 1. Tabla de usuarios
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(150),
  avatar_url VARCHAR(500),
  bio TEXT,
  theme ENUM('light','dark') DEFAULT 'light',
  points INT NOT NULL DEFAULT 0,
  role ENUM('student','teacher','admin') DEFAULT 'student',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_username (username),
  INDEX idx_email (email)
);

-- 2. Tabla para sesiones (login tokens, opcional para gestión)
CREATE TABLE sessions (
  id CHAR(36) PRIMARY KEY, -- uuid
  user_id INT NOT NULL,
  token VARCHAR(255) NOT NULL,
  user_agent VARCHAR(255),
  ip_address VARCHAR(50),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  expires_at DATETIME,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 3. Acciones sustentables (registro)
CREATE TABLE actions (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  action_type VARCHAR(100) NOT NULL,   -- ej: 'reciclaje','ahorro-energia','compostaje'
  description TEXT,
  evidence_url VARCHAR(500),            -- foto o documento
  action_date DATE NOT NULL,
  points_awarded INT DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_action_date (user_id, action_date)
);

-- 4. Recompensas / catálogo
CREATE TABLE rewards (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(150) NOT NULL,
  description TEXT,
  cost_points INT NOT NULL,
  stock INT DEFAULT NULL, -- NULL = sin límite
  image_url VARCHAR(500),
  active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_cost (cost_points)
);

-- 5. Canjes (redenciones)
CREATE TABLE redemptions (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  reward_id INT NOT NULL,
  cost_points INT NOT NULL,
  status ENUM('pending','completed','cancelled') DEFAULT 'pending',
  note TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (reward_id) REFERENCES rewards(id) ON DELETE RESTRICT
);

-- 6. Eventos y talleres
CREATE TABLE events (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  event_date DATETIME NOT NULL,
  location VARCHAR(255),
  capacity INT DEFAULT NULL, -- null = sin límite
  created_by INT,
  image_url VARCHAR(500),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_event_date (event_date)
);

-- 7. Inscripciones a eventos (relaciona usuario + evento)
CREATE TABLE event_registrations (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  event_id INT NOT NULL,
  user_id INT NOT NULL,
  registered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  status ENUM('registered','attended','cancelled') DEFAULT 'registered',
  UNIQUE KEY ux_event_user (event_id, user_id),
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 8. Notificaciones / recordatorios
CREATE TABLE notifications (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NULL, -- null -> notificación global
  title VARCHAR(200),
  body TEXT,
  link VARCHAR(500),
  is_read BOOLEAN DEFAULT FALSE,
  level ENUM('info','success','warning','alert') DEFAULT 'info',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 9. Recursos/Guías
CREATE TABLE resources (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  resource_type ENUM('pdf','link','video','article') DEFAULT 'link',
  url VARCHAR(1000),
  uploaded_by INT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 10. Alianzas / partners
CREATE TABLE partners (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  website VARCHAR(500),
  logo_url VARCHAR(500),
  contact_email VARCHAR(200),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 11. Mapa del campus (puntos como contenedores, huertos, talleres)
CREATE TABLE map_points (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  type ENUM('contenedor','huerto','centro-acopio','taller','otro') DEFAULT 'otro',
  description TEXT,
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  image_url VARCHAR(500),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 12. Blog / Noticias
CREATE TABLE posts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(250) NOT NULL,
  slug VARCHAR(300) NOT NULL UNIQUE,
  excerpt VARCHAR(500),
  body TEXT,
  author_id INT,
  published_at DATETIME,
  is_published BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 13. Testimonios / experiencias breves
CREATE TABLE testimonials (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NULL,
  content TEXT NOT NULL,
  title VARCHAR(200),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  visible BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 14. Log de puntos (auditoría) -- cada vez que se otorgan o restan puntos se registra
CREATE TABLE points_log (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  change INT NOT NULL, -- positivo o negativo
  reason VARCHAR(200),
  related_table VARCHAR(100),
  related_id BIGINT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_points_user (user_id)
);

-- 15. Índices y vistas para estadísticas rápidas
CREATE VIEW v_user_points AS
SELECT u.id AS user_id, u.username, u.full_name, u.points
FROM users u;

CREATE VIEW v_actions_summary AS
SELECT user_id, COUNT(*) AS total_actions, SUM(points_awarded) AS total_points
FROM actions
GROUP BY user_id;

-- 16. Trigger: al insertar una acción, sumar puntos al usuario y registrar en points_log y notificación
DELIMITER $$
CREATE TRIGGER trg_actions_after_insert
AFTER INSERT ON actions
FOR EACH ROW
BEGIN
  DECLARE pts INT;
  SET pts = NEW.points_awarded;
  IF pts IS NULL THEN
    SET pts = 0;
  END IF;

  -- actualizar puntos del usuario
  UPDATE users SET points = points + pts WHERE id = NEW.user_id;

  -- insertar registro en points_log
  INSERT INTO points_log(user_id, change, reason, related_table, related_id)
  VALUES (NEW.user_id, pts, CONCAT('Acción registrada: ', NEW.action_type), 'actions', NEW.id);

  -- insertar notificación al usuario
  INSERT INTO notifications(user_id, title, body, link, level)
  VALUES (NEW.user_id, 'Puntos por acción registrada', CONCAT('Tu acción "', NEW.action_type, '" te otorgó ', pts, ' puntos.'), NULL, 'success');
END$$
DELIMITER ;

-- 17. Procedimiento para canjear puntos (transaccional)
DELIMITER $$
CREATE PROCEDURE sp_redeem_reward(IN p_user_id INT, IN p_reward_id INT, OUT p_success BOOLEAN, OUT p_message VARCHAR(255))
BEGIN
  DECLARE v_cost INT;
  DECLARE v_stock INT;
  DECLARE v_user_points INT;

  START TRANSACTION;

  SELECT cost_points, stock INTO v_cost, v_stock FROM rewards WHERE id = p_reward_id FOR UPDATE;
  IF v_cost IS NULL THEN
    SET p_success = FALSE;
    SET p_message = 'Recompensa no encontrada.';
    ROLLBACK;
    LEAVE proc_end;
  END IF;

  SELECT points INTO v_user_points FROM users WHERE id = p_user_id FOR UPDATE;
  IF v_user_points IS NULL THEN
    SET p_success = FALSE;
    SET p_message = 'Usuario no encontrado.';
    ROLLBACK;
    LEAVE proc_end;
  END IF;

  IF v_stock IS NOT NULL AND v_stock <= 0 THEN
    SET p_success = FALSE;
    SET p_message = 'Recompensa sin stock.';
    ROLLBACK;
    LEAVE proc_end;
  END IF;

  IF v_user_points < v_cost THEN
    SET p_success = FALSE;
    SET p_message = 'Puntos insuficientes.';
    ROLLBACK;
    LEAVE proc_end;
  END IF;

  -- restar puntos al usuario
  UPDATE users SET points = points - v_cost WHERE id = p_user_id;

  -- decrementar stock si aplica
  IF v_stock IS NOT NULL THEN
    UPDATE rewards SET stock = stock - 1 WHERE id = p_reward_id;
  END IF;

  -- insertar redención
  INSERT INTO redemptions (user_id, reward_id, cost_points, status)
  VALUES (p_user_id, p_reward_id, v_cost, 'completed');

  -- registrar en points_log
  INSERT INTO points_log(user_id, change, reason, related_table, related_id)
  VALUES (p_user_id, -v_cost, 'Canje de recompensa', 'rewards', LAST_INSERT_ID());

  -- notificación
  INSERT INTO notifications(user_id, title, body, level)
  VALUES (p_user_id, 'Canje de recompensa', CONCAT('Has canjeado una recompensa por ', v_cost, ' puntos.'), 'success');

  COMMIT;
  SET p_success = TRUE;
  SET p_message = 'Canje realizado con éxito.';

  proc_end: BEGIN END;
END$$
DELIMITER ;

-- 18. Procedimiento simple para inscribirse a evento (evita duplicados y respeta capacidad)
DELIMITER $$
CREATE PROCEDURE sp_register_event(IN p_user_id INT, IN p_event_id INT, OUT p_success BOOLEAN, OUT p_message VARCHAR(255))
BEGIN
  DECLARE v_capacity INT;
  DECLARE v_count INT;

  START TRANSACTION;

  SELECT capacity INTO v_capacity FROM events WHERE id = p_event_id FOR UPDATE;
  IF v_capacity IS NULL THEN
    -- sin límite
    SET v_capacity = -1;
  END IF;

  SELECT COUNT(*) INTO v_count FROM event_registrations WHERE event_id = p_event_id FOR UPDATE;

  IF v_capacity != -1 AND v_count >= v_capacity THEN
    SET p_success = FALSE;
    SET p_message = 'El evento está completo.';
    ROLLBACK;
    LEAVE proc_end;
  END IF;

  -- intentar insertar (la tabla tiene UNIQUE event_id,user_id para evitar duplicados)
  INSERT IGNORE INTO event_registrations (event_id, user_id) VALUES (p_event_id, p_user_id);
  IF ROW_COUNT() = 0 THEN
    SET p_success = FALSE;
    SET p_message = 'Usuario ya inscrito.';
    ROLLBACK;
    LEAVE proc_end;
  END IF;

  -- opcional: otorgar puntos por inscribirse (ej. 10 puntos)
  UPDATE users SET points = points + 10 WHERE id = p_user_id;
  INSERT INTO points_log(user_id, change, reason, related_table, related_id)
    VALUES (p_user_id, 10, 'Puntos por inscripción a evento', 'events', p_event_id);

  INSERT INTO notifications(user_id, title, body, level)
    VALUES (p_user_id, 'Inscripción confirmada', CONCAT('Te has inscrito al evento con id ', p_event_id), 'info');

  COMMIT;
  SET p_success = TRUE;
  SET p_message = 'Inscripción exitosa.';
  proc_end: BEGIN END;
END$$
DELIMITER ;

-- 19. Datos de ejemplo (seed)
INSERT INTO users (username, email, password_hash, full_name, avatar_url, role, points)
VALUES
('juanp', 'juan@example.com', '$2y$12$examplehash', 'Juan Pérez', NULL, 'student', 50),
('maria', 'maria@example.com', '$2y$12$examplehash', 'María López', NULL, 'student', 120),
('admin', 'admin@example.com', '$2y$12$examplehash', 'Administrador', NULL, 'admin', 1000);

INSERT INTO rewards (title, description, cost_points, stock, image_url)
VALUES
('Botella reutilizable', 'Botella de acero inoxidable', 100, 20, NULL),
('Entrada taller compostaje', 'Acceso a taller práctico de compostaje', 200, 10, NULL),
('Tarjeta regalo cafetería', 'Vale para café', 50, 100, NULL);

INSERT INTO events (title, description, event_date, location, capacity, created_by)
VALUES
('Taller de reciclaje', 'Aprende a separar residuos correctamente', '2025-11-05 10:00:00', 'Aula Magna', 30, 3),
('Plantación comunitaria', 'Siembra de árboles en el campus', '2025-10-28 09:00:00', 'Jardín central', NULL, 3);

INSERT INTO resources (title, description, resource_type, url)
VALUES
('Guía rápido de reciclaje', 'PDF con pasos básicos', 'pdf', 'https://example.org/guia-reciclaje.pdf'),
('Video compostaje', 'Video tutorial de 8 minutos', 'video', 'https://youtube.com/example');

INSERT INTO map_points (title, type, description, latitude, longitude)
VALUES
('Contenedor zona A','contenedor','Contenedor para plástico y PET',19.4326,-99.1332),
('Huerto orgánico','huerto','Huerto comunitario estudiantil',19.4327,-99.1335);

-- 20. Vistas / consultas útiles (para front)
-- a) acciones de un usuario
CREATE VIEW v_user_actions AS
SELECT a.id, a.user_id, u.username, a.action_type, a.description, a.action_date, a.points_awarded, a.evidence_url, a.created_at
FROM actions a
JOIN users u ON u.id = a.user_id;

-- b) eventos próximos
CREATE VIEW v_upcoming_events AS
SELECT * FROM events WHERE event_date >= NOW() ORDER BY event_date ASC;

-- c) eventos pasados
CREATE VIEW v_past_events AS
SELECT * FROM events WHERE event_date < NOW() ORDER BY event_date DESC;

-- 21. Procedimientos / funciones adicionales para estadísticas
-- Ejemplo: total de acciones registradas
CREATE VIEW v_total_actions AS
SELECT COUNT(*) AS total_actions FROM actions;

-- 22. Permisos iniciales (ejemplo: crear un user para la app - ajustar según tu entorno)
-- GRANT USAGE, SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX ON campus_sustentable.* TO 'app_user'@'localhost' IDENTIFIED BY 'tu_password_segura';
