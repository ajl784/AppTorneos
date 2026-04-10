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

### 4.5 Flujo organizador: generacion de enfrentamientos

Endpoint principal:

- `POST /torneos/:idTorneo/generar-enfrentamientos`

Comportamiento por tipo de torneo:

- Liga:
  - usa `categoria.participantes_por_partida`,
  - guarda `partido.jornada` para organizar calendario,
  - si participantes por partido = 2, genera round robin con ida y vuelta,
  - si participantes por partido > 2, genera jornadas por grupos rotativos de tamano N,
  - usa `torneo.preferencia_horario.dias` para asignar fechas,
  - en el modelo actual los partidos de liga no usan `ronda`.
- Eliminacion directa:
  - genera un bracket inicial (ronda 1),
  - cada avance crea la siguiente ronda hasta final,
  - usa `partido.ronda`, `partido.orden_ronda` y `partido.id_partido_siguiente`.
- Serie + final (con tiempos):
  - genera series en ronda 1 con `participantes_por_partido`,
  - al avanzar, clasifica a final segun `norma_puntuacion`,
  - permite criterio por tiempo (`criterio=asc`) o por puntos (`criterio=desc`).
- Eliminatorias por rondas:
  - genera ronda 1 por series,
  - en cada avance clasifica por serie y opcionalmente mejores globales,
  - crea nuevas rondas hasta final.
- Eliminación progresiva:
  - genera ronda 1 por grupos,
  - en cada avance elimina un porcentaje de peores,
  - continua hasta quedar un campeon.

Endpoints adicionales de eliminacion:

- `POST /torneos/:idTorneo/bracket/eliminacion/generar`
- `POST /torneos/:idTorneo/bracket/eliminacion/avanzar`

Regla actual para avanzar en eliminacion:

- todos los partidos de la ronda actual deben estar en estado `acabado`.

Parametros soportados en `norma_puntuacion` para eliminaciones multi-participante:

- `criterio=asc|desc`:
  - `asc`: menor punto/tiempo es mejor.
  - `desc`: mayor punto es mejor.
- `clasifican_por_serie=N`: clasificados directos por serie.
- `mejores_tiempos=N`: cupos extra por ranking global de no clasificados.
- `finalistas=N`: tamano de final para "Serie + final (con tiempos)".
- `porcentaje_eliminacion=N`: porcentaje eliminado por ronda en "Eliminación progresiva".

### 4.6 Reglas de negocio de categorias y puntuacion (importante)

La app esta pensada para categorias generales, no solo futbol.

Campos clave en base de datos:

- `categoria.participantes_por_partida`: cuantos participantes compiten en un partido/evento.
- `torneo.norma_puntuacion`: regla de puntos del torneo (win/draw/loss u otras variantes).
- `partido.jornada`: numero de jornada para calendario de liga.

Criterio funcional objetivo:

- la generacion de enfrentamientos debe considerar `participantes_por_partida`.
- para categorias de mas de 2 participantes por partido (ejemplo: atletismo con 8),
  la asignacion de participantes debe formar grupos de tamano N por partido.
- `norma_puntuacion` define como se asignan puntos en `participacion_torneo_equipo.puntuacion`.

Estado actual de implementacion (v1):

- la carga de resultados y calculo ELO en backend esta implementada para 1v1,
- partidos con mas de 2 participaciones para ELO no estan soportados aun,
- en eliminacion actual se exige cantidad de equipos potencia de 2,
- en liga con mas de 2 participantes por partido se usa agrupacion rotativa por jornada (primera version).

Convencion recomendada para `norma_puntuacion`:

- usar formato textual estable para poder parsear luego en backend,
- ejemplo simple para liga: `3-1-0` (ganar-empatar-perder),
- para formatos de ranking (mas de 2 participantes), definir una convención explicita.

Ejemplo sugerido para ranking:

- `rank:8,6,4,3,2,1,0,0`
  - indica puntuacion por posicion final en un evento de 8 participantes.

Nota tecnica:

- conviene mantener `norma_puntuacion` como texto por ahora,
- y centralizar su parser en backend cuando se implemente soporte multi-participante.

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
