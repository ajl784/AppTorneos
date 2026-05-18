# Backend Design & Development Guidelines

Este documento establece las convenciones y directrices de diseño para el desarrollo del backend de la aplicación (`AppTorneos`). Sigue este esquema para mantener un código ordenado, mantenible y escalable.

## 1. Arquitectura en Capas

El backend utiliza una arquitectura basada en capas (MVC adaptado para APIs REST), separando claramente las responsabilidades en la carpeta `src/`:

*   **`routes/`**: Define los endpoints de la API y vincula las rutas con sus controladores correspondientes.
*   **`controllers/`**: Maneja las solicitudes HTTP, procesa y valida los parámetros, invoca la lógica de negocio (services) y devuelve la respuesta HTTP formateada.
*   **`services/`**: Contiene la lógica de negocio y realiza las interacciones directas con la base de datos.
*   **`middleware/`**: Contiene funciones intermedias (manejo de errores, rutas no encontradas, subida de archivos).
*   **`db/`**: Configuración y conexión con la base de datos (PostgreSQL usando `pg`).
*   **`utils/`**: Funciones auxiliares y utilidades compartidas (`http.js`, `errors.js`).

---

## 2. Controllers (Controladores)

Los controladores son responsables de orquestar la petición HTTP. **No deben contener lógica de base de datos directa ni lógica de negocio compleja**.

### Reglas para Controladores:
*   **Usar `asyncHandler`**: Envuelve todos los métodos asíncronos con `asyncHandler` (de `../utils/http`) para manejar automáticamente los errores sin necesidad de usar bloques `try/catch` redundantes.
*   **Validación de Datos**: Utiliza los helpers provistos en `../utils/http.js` para extraer y validar datos:
    *   `requireFields(req.body, ['campo1', 'campo2'])` para verificar campos obligatorios en el body.
    *   `parsePositiveInt(req.params.id, 'id')` para extraer IDs válidos de los parámetros.
    *   `parsePagination(req.query)` para extraer automáticamente `limit` y `offset`.
*   **Respuestas Estándar**: Usa las funciones auxiliares para devolver la respuesta HTTP de forma uniforme:
    *   `ok(res, data, meta)` para respuestas 200 (OK).
    *   `created(res, data)` para respuestas 201 (Created).

**Ejemplo de Controller:**
```javascript
const myService = require("../services/my.service");
const { ok, created, parsePositiveInt, requireFields, asyncHandler } = require("../utils/http");

const createElement = asyncHandler(async (req, res) => {
  requireFields(req.body, ["nombre", "descripcion"]);
  
  const data = await myService.createElement(req.body);
  created(res, data);
});

const getElement = asyncHandler(async (req, res) => {
  const id = parsePositiveInt(req.params.id, "id");
  const data = await myService.getElement(id);
  ok(res, data);
});

module.exports = { createElement, getElement };
```

---

## 3. Services (Servicios) y Base de Datos

Los servicios manejan la **lógica de negocio real y las consultas SQL**. 

### Reglas para Servicios:
*   **Sin respuestas HTTP**: Un servicio no debe conocer sobre `req`, `res`, o el estado de HTTP (no hacer res.status ni res.json en los servicios). Debe retornar datos (o lanzar errores) que el controlador luego manipulará.
*   **PostgreSQL Crudo (Raw SQL)**: No se usa ORM. Las consultas se realizan usando `pool.query()` importado de `../db/pool`.
*   **Consultas Parametrizadas**: Utiliza *siempre* consultas preparadas (`$1`, `$2`, etc.) para prevenir inyecciones SQL.
*   **Retorno de datos**: Normalmente retornan `.rows` para listas, `.rows[0]` (o null) para elementos únicos, o el resultado directo tras una inserción con la cláusula `RETURNING`.

**Ejemplo de Service:**
```javascript
const { pool } = require("../db/pool");

const createElement = async (payload) => {
  const result = await pool.query(
    `INSERT INTO element (nombre, descripcion)
     VALUES ($1, $2)
     RETURNING id_element, nombre, descripcion`,
    [payload.nombre, payload.descripcion]
  );
  return result.rows[0];
};

module.exports = { createElement };
```

---

## 4. Routes (Rutas)

Las rutas se agrupan en versiones (ej. `v1.js`) y por módulos lógicos.

### Reglas para Rutas:
*   Usa `express.Router()`.
*   Evita colocar lógica directamente en la declaración de rutas. 
*   Importa el controlador y mapea la ruta con la función correspondiente.

**Ejemplo de Route:**
```javascript
const express = require("express");
const controller = require("../controllers/my.controller");

const router = express.Router();

router.get("/", controller.listElements);
router.post("/", controller.createElement);
router.get("/:id", controller.getElement);

module.exports = router;
```

---

## 5. Manejo de Errores (Error Handling)

El manejo de excepciones es centralizado para asegurar respuestas consistentes al frontend.

*   **Errores de Negocio/Cliente**: Lanza `AppError` (de `../utils/errors`) para enviar mensajes al usuario (errores 400, 403, 404). 
    *   Ejemplo: `throw new AppError(404, "Elemento no encontrado");`
*   **El Middleware Atrapa Todo**: Si lanzas un error dentro de un servicio o controlador envuelto en `asyncHandler`, el error viajará automáticamente al middleware global `errorHandler` definido en `src/middleware/error-handler.js`.
*   **Formato de Error**: El frontend siempre recibe la misma estructura cuando algo falla:
    ```json
    {
      "ok": false,
      "error": {
        "message": "Mensaje legible",
        "details": null
      }
    }
    ```

## Resumen de Flujo de Trabajo
1. El request entra en `routes/`.
2. Es dirigido al `controller/`, que extrae variables y valida (con utilidades).
3. El `controller/` llama a una función en el `service/` pasándole los datos en crudo (primitivas u objetos, pero NUNCA objetos del request).
4. El `service/` hace el query a la DB mediante `pool.query` usando `$1, $2`.
5. El `service/` retorna la data o lanza un `AppError`.
6. Si hay error, el `asyncHandler` lo atrapa y `errorHandler` devuelve el error al cliente.
7. Si no hay error, el `controller/` da formato a la respuesta final con `ok(res, data)`.
