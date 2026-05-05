# Liga Parchís Test

Test completo que crea un torneo de liga de parchís con múltiples usuarios (organizador, árbitro) y procesa toda la competición.

## Setup previo

### 1. Ejecutar el script SQL de setup

Este script creará todos los datos necesarios en la BD (usuarios, categorías, equipos, torneo).

```bash
psql -U postgres -d app_torneos -f test/setup_liga_basket_test.sql
```

Si usas otra herramienta (pgAdmin, DBeaver), copia el contenido de `setup_liga_basket_test.sql` y ejecútalo directamente.

### 2. Usuarios creados

El script crea automáticamente:

```
Organizador:
  - correo: organizador_parchis@app.com
  - password: password123

Árbitro:
  - correo: arbitro_parchis@app.com
  - password: password123

Admin:
  - correo: admin@app.com
  - password: password123
```

### 3. Datos del torneo

- **Nombre:** Liga Parchís
- **Tipo:** Liga (todos contra todos)
- **Categoría:** Parchís
- **Participantes por partido:** 4
- **Equipos:** 6 (Equipo Parchís A-F)
- **Estado equipos:** Aceptado
- **Organizador:** organizador_parchis@app.com
- **Árbitro:** arbitro_parchis@app.com

## Ejecutar el test

```bash
npm test -- test/test_liga_basket.js
```

## ¿Qué hace el test?

1. ✅ Login como organizador
2. ✅ Login como árbitro
3. ✅ Login como admin
4. ✅ Busca el torneo "Liga Parchís"
5. ✅ Genera todos los emparejamientos
6. ✅ Procesa todas las jornadas (árbitro marca resultados)
7. ✅ Muestra clasificación final

## Output esperado

```
Torneo Liga Parchís
  ✓ should log in organizador
  ✓ should log in arbitro
  ✓ should log in admin
  ✓ should find Torneo Liga Parchís tournament
  ✓ should generate matches for the tournament
  ✓ should process all jornadas and finish the league
  ✓ should get tournament standings and verify final classification

7 passing (20s)
```

## Archivos generados

Después de correr el test:
```
test/test_requests_liga_basket.txt
```

Contiene un log detallado de todas las peticiones HTTP.

## Troubleshooting

### "Tournament 'Liga Parchís' not found"
1. Ejecuta el script SQL: `psql -U postgres -d app_torneos -f test/setup_liga_basket_test.sql`
2. Verifica que los usuarios estén creados en la BD

### "Arbitro login error"
- Verifica que el usuario `arbitro_parchis@app.com` exista en la BD
- Ejecuta nuevamente el script SQL de setup

### "No matches found"
- Verifica que haya 6 equipos registrados en el torneo
- Revisa los logs del backend para más detalles

## Notas

- El test es **idempotente**: puedes ejecutarlo múltiples veces
- Los usuarios se crean con hashes de password cifrados correctamente usando pgcrypto
- Los resultados se asignan automáticamente: primer equipo gana, segundo pierde, etc.
- La contraseña de todos los usuarios es `password123`
- La categoría Parchís requiere 4 participantes por partido
