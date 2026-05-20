# Testing: Modificación de Fecha de Partidos

## 📋 Requisitos Previos

- Backend corriendo en `http://localhost:3000`
- Flutter app corriendo
- Usuario autenticado como organizador
- Torneo con estado `'planificado'` y al menos 1 partido

## ✅ Flujo de Prueba Paso a Paso

### 1. Acceder al Calendario
1. Abre la aplicación Flutter
2. Ve al tab "Calendario" 

### 2. Ver Partidos en el Calendario
- Se muestran todos los partidos del mes
- Cada partido aparece como un card con: equipo vs equipo, fecha, hora

### 3. Hacer Click en un Partido
1. Haz click en cualquier partido
2. Se abre un **AlertDialog** con opciones de edición

### 4. Editar Fecha del Partido 👈 NUEVO
En el diálogo verás estos campos:
- **Fecha (DD/MM/YYYY)** - Campo editable con date picker
- **Hora (HH:MM)** - Campo editable con time picker
- **Lugar (opcional)** - Campo de texto editable
- **Estado** - Dropdown con opciones
- **Árbitro** - Texto (read-only)

### 5. Cambiar la Fecha
1. Tap en el campo "Fecha (DD/MM/YYYY)"
2. Se abre un date picker (calendario)
3. Selecciona una nueva fecha
4. La fecha se actualiza en el campo

### 6. Cambiar la Hora
1. Tap en el campo "Hora (HH:MM)"
2. Se abre un time picker
3. Selecciona una nueva hora
4. La hora se actualiza en el campo

### 7. Cambiar el Lugar
1. Escribe o modifica el lugar directamente en el TextFormField

### 8. Guardar Cambios
1. Tap en botón **"Guardar"**
2. Se envía la actualización al backend con:
   - `fecha_hora` (en formato ISO: YYYY-MM-DDTHH:MM:SS.000Z)
   - `lugar` (si se especificó)
   - `estado` (puede cambiar o mantenerse igual)

### 9. Validaciones del Backend

| Intento | Esperado |
|---------|----------|
| Cambiar fecha si estado ≠ 'planificado' | ❌ 400 Bad Request |
| Cambiar fecha si NO eres organizador | ❌ 403 Forbidden |
| Cambiar fecha siendo organizador y estado='planificado' | ✅ 200 OK |

---

## 🧪 Casos de Prueba

### Caso 1: Cambiar fecha de un partido 'planificado'
```
Pre: Partido en estado 'planificado', estado actual
Acción: Cambiar fecha a 25/05/2026 14:00
Esperado: ✅ Guardado exitoso, partido se actualiza en calendario
```

### Caso 2: Cambiar lugar del partido
```
Pre: Partido sin lugar
Acción: Escribir "Cancha 1" en el campo Lugar
Esperado: ✅ Lugar se guarda
```

### Caso 3: Intentar cambiar fecha de partido 'acabado'
```
Pre: Partido en estado 'acabado'
Acción: Cambiar fecha
Esperado: ❌ Error: "Solo se puede modificar la fecha si el partido está en 'planificado'"
```

### Caso 4: Verificar que no se puede editar si no eres organizador
```
Pre: Conectado como usuario normal (no organizador)
Acción: Intentar cambiar fecha del partido
Esperado: ❌ Error 403: "Solo el organizador del torneo puede modificarlo"
```

---

## 🔄 Restricciones Implementadas

### Backend (`partidos.controller.js`)
- ✅ Valida que `estado === 'planificado'`
- ✅ Valida que usuario sea organizador del torneo
- ✅ Valida formato de fecha_hora (ISO datetime)

### Frontend (`calendario_tab.dart`)
- ✅ Campos visibles y editables siempre
- ✅ Date/time pickers integrados
- ✅ Parsing correcto de DD/MM/YYYY → ISO datetime
- ✅ Validación de parseo antes de enviar

---

## 📝 Notas

- La UI permite editar **siempre**, pero el backend validará la lógica
- El error del backend se muestra en un SnackBar
- Los campos se reciclan correctamente (dispose)
- Compatible con todos los estados de partido (el backend rechazará si no es 'planificado')

