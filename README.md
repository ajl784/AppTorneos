# AppTorneos

Aplicación de gestión de torneos para la asignatura 21782 - Laboratori de Projectes de Software.

Este README está pensado para el equipo de front.

## 1) Pregunta frecuente: para que sirve back/nada.js

Si, sirve.

`back/nada.js` es el punto de arranque del backend:

- levanta el servidor Node en el puerto configurado,
- usa `back/src/app.js` (donde estan rutas y middlewares),
- cierra correctamente el pool de PostgreSQL cuando se para el proceso.

En resumen: `back/nada.js` no tiene logica de negocio, pero es el archivo que inicia la API.

## 2) Arranque rapido para front

Levantar backend + BD:

```bash
docker compose up --build -d
```

Comprobar que esta vivo:

```bash
curl http://localhost:3000/health
```

Respuesta esperada:

```json
{ "ok": true, "data": { "status": "ok", "db": "connected" } }
```

Base URL para front:

```text
http://localhost:3000/api/v1
```

## 3) Contrato de respuesta (importante para front)

Exito:

```json
{
  "ok": true,
  "data": {},
  "meta": null
}
```

Error:

```json
{
  "ok": false,
  "error": {
    "message": "descripcion del error",
    "details": null
  }
}
```

Recomendacion front:

- si `ok === false`, mostrar `error.message` al usuario.
- si hay `error.details`, usarlo para debug/log.

## 4) Endpoints por casos de uso de front

### 4.1 Listados y detalle

- `GET /usuarios?limit=50&offset=0&q=`
- `GET /usuarios/:id`
- `GET /equipos?limit=50&offset=0&nombre=`
- `GET /equipos/:id`
- `GET /torneos?limit=50&offset=0&estado=&organizadorId=&categoriaId=&tipoTorneoId=`
- `GET /torneos/:id`
- `GET /partidos?limit=50&offset=0&torneoId=&estado=`
- `GET /partidos/:id`
- `GET /participaciones?limit=50&offset=0&torneoId=&equipoId=&estado=`
- `GET /participaciones/:id`

### 4.2 CRUD basico

- `POST /usuarios`
- `PUT /usuarios/:id`
- `DELETE /usuarios/:id`
- `POST /equipos`
- `PUT /equipos/:id`
- `DELETE /equipos/:id`
- `POST /torneos`
- `PUT /torneos/:id`
- `DELETE /torneos/:id`
- `POST /partidos`
- `PUT /partidos/:id`
- `DELETE /partidos/:id`
- `POST /participaciones`
- `PUT /participaciones/:id`
- `DELETE /participaciones/:id`

### 4.3 Flujo especial: formulario del torneo + solicitudes

1. Organizador define formulario JSON del torneo:

- `PUT /torneos/:id/formulario`

Body ejemplo:

```json
{
  "formulario": {
    "preguntas": [
      { "id": "p1", "texto": "Cuantos jugadores sois", "tipo": "numero" },
      { "id": "p2", "texto": "Nivel del equipo", "tipo": "texto" }
    ]
  }
}
```

2. Front consulta formulario para pintarlo:

- `GET /torneos/:id/formulario`

3. Equipo envia solicitud con respuestas:

- `POST /torneos/:id/solicitudes`

Body ejemplo:

```json
{
  "id_equipo": 3,
  "respuesta": {
    "p1": 12,
    "p2": "Intermedio"
  }
}
```

4. Organizador lista solicitudes:

- `GET /torneos/:id/solicitudes?estado=pendiente`

5. Organizador decide aceptar o rechazar:

- `PATCH /participaciones/:id/decision`

Body:

```json
{ "aceptar": true }
```

Estados resultantes:

- `aceptar=true` -> `jugando`
- `aceptar=false` -> `eliminado`

### 4.4 Flujo arbitro: cargar puntuaciones del partido

Endpoint:

- `POST /partidos/:id/puntuaciones`

Body ejemplo:

```json
{
  "id_arbitro_torneo": 2,
  "acta": { "observaciones": "Partido limpio" },
  "puntuaciones": [
    { "id_participacion_equipo": 10, "punto": 3 },
    { "id_participacion_equipo": 11, "punto": 1 }
  ]
}
```

Al guardar:

- se actualiza `participacion_partido.punto` (puntos de ese partido),
- se recalcula `participacion_torneo_equipo.puntuacion` (acumulado del torneo),
- se guarda el acta en `arbitro_partido` si se envia `id_arbitro_torneo`.

## 5) Ejemplos cortos para tests de front

Listar torneos:

```bash
curl "http://localhost:3000/api/v1/torneos?limit=10&offset=0"
```

Ver solicitudes pendientes de un torneo:

```bash
curl "http://localhost:3000/api/v1/torneos/1/solicitudes?estado=pendiente"
```

## 6) Notas utiles para el equipo de front

- No hay autenticacion en v1, por lo que no hace falta token.
- CORS esta habilitado para desarrollo.
- Todas las fechas se tratan como valores de PostgreSQL (`timestamptz` en varios campos).
- Si envias IDs que no existen, recibiras error 400/404 segun el caso.

## 7) Cliente Python (opcional para pruebas)

Hay helper en `python/nada.py` para probar endpoints rapido:

```bash
python3 python/nada.py
```

## 8) Comandos de soporte

Ver logs:

```bash
docker compose logs app
docker compose logs postgres
```

Recrear BD desde cero (borra datos):

```bash
docker compose down -v
docker compose up --build -d
```
