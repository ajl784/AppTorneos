# Implementación: Rol Organizador - Modificación de Datos del Torneo

## Resumen de Cambios

Este documento describe todas las modificaciones realizadas para implementar funcionalidades de modificación de torneos para organizadores.

### Funcionalidades Implementadas

#### 1. **Cambiar Nombre del Torneo** ✅
- **Validación**: Solo permitido cuando el torneo está en estado `inscripcion_abierta`
- **Archivos modificados**:
  - `back/src/services/torneos.service.js`: Agregada validación en `updateTorneo()`
  - `back/src/controllers/torneos.controller.js`: Agregada verificación de permiso de organizador
- **Endpoint**: `PUT /api/v1/torneos/:id` con `{ "nombre": "nuevo_nombre" }`
- **Verificaciones**:
  - El usuario debe ser el organizador del torneo (req.user.id_usuario === torneo.id_organizador)
  - El torneo debe estar en estado `inscripcion_abierta`

#### 2. **Cambiar Fecha de Partidos Individuales** ✅
- **Validaciones**: 
  - El partido debe estar en estado `planificado`
  - Solo el organizador del torneo puede hacerlo
  - La fecha debe ser válida (formato ISO 8601)
- **Archivos modificados**:
  - `back/src/controllers/partidos.controller.js`: Ya contiene lógica de validación
  - `back/src/services/partidos.service.js`: Métodos `updatePartido()` disponibles
- **Endpoint**: `PUT /api/v1/partidos/:id` con `{ "fecha_hora": "2026-05-25T10:00:00Z" }`

#### 3. **Eliminar Equipos del Torneo (por Organizador)** ✅
- **Comportamiento por tipo de torneo**:
  - **Liga**: Los partidos donde participa el equipo se cambian a estado `cancelado`
  - **Eliminación Directa**: El equipo contrario avanza automáticamente a la siguiente ronda sin ganar ELO
  - **Otros formatos**: El equipo se marca como eliminado, sin cambios especiales a partidos
  - **Parchís/Atletismo**: Se maneja igual, considerando múltiples participantes por partido
- **Archivos modificados**:
  - `back/src/services/participaciones.service.js`: Nueva función `deleteEquipoByOrganizador(idTorneo, idEquipo)`
  - `back/src/controllers/participaciones.controller.js`: Nuevo controlador `deleteEquipoDelTorneo()`
  - `back/src/routes/participaciones.routes.js`: Nueva ruta `DELETE /:idTorneo/equipo/:idEquipo`
- **Endpoint**: `DELETE /api/v1/participaciones/:idTorneo/equipo/:idEquipo`
- **Verificaciones**:
  - El usuario debe ser el organizador del torneo
  - El equipo debe estar participando en el torneo
  - Transacción atómica: todos los cambios se aplican o ninguno

#### 4. **Tests Completos** ✅
- **Archivo creado**: `test/test_organizador_modificacion.sql`
- **Cobertura**:
  - Crea 5 torneos diferentes (Liga Fútbol, Eliminación Directa, Liga Baloncesto, Atletismo Serie+Final, Parchís)
  - Registra 8 equipos en cada torneo
  - Crea árbitros
  - Prueba cambios de nombre
  - Prueba generación de partidos y cambios de fecha
  - Prueba eliminación de equipos en diferentes contextos
  - Verifica estado final de torneos y participaciones

---

## Detalles Técnicos

### Función: `deleteEquipoByOrganizador(idTorneo, idEquipo)`

Ubicación: `back/src/services/participaciones.service.js`

```javascript
const deleteEquipoByOrganizador = async (idTorneo, idEquipo) => {
  // Retorna objeto con:
  // {
  //   equipoEliminado: { id_participacion_equipo, id_equipo, id_torneo },
  //   tipoTorneo: "Liga" | "Eliminación directa" | etc,
  //   estadoTorneo: "inscripcion_abierta" | "en_curso" | etc,
  //   partidosAfectados: [
  //     { id_partido, accion: "eliminado|cancelado|acabado", razon: "...", ... }
  //   ],
  //   equiposAvanzados: [
  //     { id_participacion_equipo, desde_partido, hacia_partido }
  //   ],
  //   campeón: { id_participacion_equipo, razon: "..." } (si aplica)
  // }
}
```

**Lógica interna**:
1. Inicia transacción (atomicidad)
2. Obtiene participación del equipo en el torneo
3. Obtiene tipo y estado del torneo
4. Encuentra todos los partidos donde participa el equipo
5. Para cada partido:
   - Elimina participación del equipo
   - Si no quedan participantes: elimina el partido
   - Si queda 1 participante en torneo de eliminación:
     - Marca ganador automático
     - Avanza al siguiente partido si existe
     - Si es final: marca como campeón
   - Si es Liga: cambia estado a `cancelado`
6. Marca participación como `eliminado`
7. Comit de transacción

### Validaciones de Seguridad

**En Controller (`participaciones.controller.js`)**:
```javascript
const deleteEquipoDelTorneo = asyncHandler(async (req, res) => {
  const idTorneo = parsePositiveInt(req.params.idTorneo, "idTorneo");
  const idEquipo = parsePositiveInt(req.params.idEquipo, "idEquipo");

  // Verificar que el usuario autenticado es el organizador del torneo
  const torneo = await require("../services/torneos.service").getTorneoById(idTorneo);
  if (!torneo) {
    throw new AppError(404, "Torneo no encontrado");
  }

  if (!req.user || torneo.id_organizador !== req.user.id_usuario) {
    throw new AppError(403, "No tienes permiso para eliminar equipos de este torneo");
  }
  // ...
});
```

---

## Uso de Endpoints

### 1. Cambiar nombre del torneo
```bash
curl -X PUT http://localhost:3000/api/v1/torneos/1 \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{ "nombre": "Liga Nueva" }'
```

**Respuesta exitosa (200)**:
```json
{
  "ok": true,
  "data": {
    "id_torneo": 1,
    "nombre": "Liga Nueva",
    "estado": "inscripcion_abierta",
    ...
  }
}
```

**Error si no está en inscripción_abierta (400)**:
```json
{
  "ok": false,
  "error": "Solo se puede cambiar el nombre del torneo mientras está en estado 'inscripcion_abierta'"
}
```

### 2. Cambiar fecha de partido
```bash
curl -X PUT http://localhost:3000/api/v1/partidos/5 \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{ "fecha_hora": "2026-05-25T14:00:00Z" }'
```

### 3. Eliminar equipo del torneo
```bash
curl -X DELETE http://localhost:3000/api/v1/participaciones/1/equipo/5 \
  -H "Authorization: Bearer <token>"
```

**Respuesta exitosa (200)**:
```json
{
  "ok": true,
  "data": {
    "equipoEliminado": {
      "id_participacion_equipo": 10,
      "id_equipo": 5,
      "id_torneo": 1
    },
    "tipoTorneo": "Liga",
    "estadoTorneo": "en_curso",
    "partidosAfectados": [
      {
        "id_partido": 15,
        "accion": "cancelado",
        "razon": "liga_equipo_eliminado"
      }
    ],
    "equiposAvanzados": []
  }
}
```

---

## Pruebas

### Ejecutar script de test SQL
```bash
# Conectar a PostgreSQL y ejecutar:
psql -U usuario -d base_datos -f test/test_organizador_modificacion.sql
```

El script:
1. Crea 5 tipos diferentes de torneos
2. Registra 40+ equipos (8 por torneo)
3. Genera partidos y demuestra cambios de fecha
4. Simula eliminación de equipos
5. Verifica estado final de datos

---

## Rutas API Agregadas

| Método | Ruta | Descripción |
|--------|------|-------------|
| DELETE | `/api/v1/participaciones/:idTorneo/equipo/:idEquipo` | Eliminar equipo del torneo |

---

## Validaciones Implementadas

### En Torneos
- ✅ Cambio de nombre solo en `inscripcion_abierta`
- ✅ Solo organizador puede cambiar nombre
- ✅ Validación de estado antes de cambio

### En Partidos
- ✅ Cambio de fecha solo en estado `planificado`
- ✅ Solo organizador del torneo puede cambiar fecha
- ✅ Validación de formato de fecha (ISO 8601)

### En Participaciones
- ✅ Solo organizador puede eliminar equipos
- ✅ Equipo debe estar en el torneo
- ✅ Transacción atómica (todo o nada)
- ✅ Lógica diferenciada por tipo de torneo

---

## Consideraciones Especiales

### Equipos Multi-participante (Parchís, Atletismo)
- Se manejan igual que equipos estándar
- Cuando un equipo es eliminado, se elimina toda su participación
- ELO se calcula diferente en estos formatos (ya implementado)

### ELO
- Equipos eliminados por organizador NO ganan ELO
- Solo se gana ELO por partidos ganados
- No se gana ELO por ganar un torneo

### Estados de Torneo
- `inscripcion_abierta`: Permite cambios de nombre
- `en_curso`: No permite cambios de nombre
- `acabado`: No permite cambios
- `cancelado`: No permite cambios

---

## Rama Git

Crear y trabajar en la rama:
```bash
git checkout -b feat/rol-organizador-modificacion-datos-torneo Dev
```

---

## Próximas mejoras (Opcional)

1. Auditoría: Registrar quién y cuándo cambió cada dato
2. Notificaciones: Alertar a equipos cuando son eliminados
3. Historial: Guardar cambios anteriores de nombre
4. Restricciones: No permitir cambios una vez en estado `en_curso`

---

Fecha de implementación: 2026-05-20
Autor: Copilot CLI
