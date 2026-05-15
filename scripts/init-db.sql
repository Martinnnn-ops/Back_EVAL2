-- ============================================================
-- init-db.sql — Inicialización de la base de datos MySQL
-- ============================================================
-- Este archivo se ejecuta AUTOMÁTICAMENTE la primera vez que
-- arranca el contenedor MySQL (cuando el volumen está vacío).
--
-- Se monta en /docker-entrypoint-initdb.d/ via docker-compose.yml
--
-- ⚠️ Si quieres re-ejecutarlo, debes BORRAR el volumen:
--   docker compose down
--   docker volume rm back_eval2_mysql_data
--   docker compose up -d
-- ============================================================


-- ─── 0. Forzar UTF-8 en la sesión que ejecuta este script ───
-- Sin esto, el cliente del entrypoint usa latin1 y las tildes
-- de este mismo archivo se guardan doblemente codificadas
-- (ej: "Pérez" termina como "PÃ©rez" en la tabla).
SET NAMES utf8mb4;


-- ─── 1. Crear la base de datos ──────────────────────────────
-- Aunque MySQL ya la crea con la variable MYSQL_DATABASE del compose,
-- la dejamos aquí por seguridad (idempotente: IF NOT EXISTS)
CREATE DATABASE IF NOT EXISTS proyecto_db
    CHARACTER SET utf8mb4              -- Soporte completo Unicode (emojis, tildes)
    COLLATE utf8mb4_unicode_ci;         -- Comparación case-insensitive

USE proyecto_db;


-- ─── 2. Crear tabla "usuarios" ──────────────────────────────
-- Columnas inferidas del código de server.js (CRUD /api/usuarios):
--   • id      → PRIMARY KEY autoincremental
--   • nombre  → string requerido
--   • email   → string único (para evitar duplicados)
--   • edad    → entero opcional
CREATE TABLE IF NOT EXISTS usuarios (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    edad        INT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                          ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email)              -- Acelera búsquedas por email
);


-- ─── 3. Insertar datos de prueba ────────────────────────────
-- INSERT IGNORE → no falla si el email ya existe (idempotente)
INSERT IGNORE INTO usuarios (nombre, email, edad) VALUES
    ('Juan Pérez',    'juan@example.com',   25),
    ('María García',  'maria@example.com',  30),
    ('Carlos López',  'carlos@example.com', 28);


-- ─── 4. Verificación visual al final ────────────────────────
-- Esto aparecerá en los logs del contenedor MySQL al iniciar
SELECT CONCAT('Base de datos inicializada. Usuarios en tabla: ',
              COUNT(*)) AS status
FROM usuarios;
