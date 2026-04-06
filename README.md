# AppTorneos

Aplicación de gestión de torneos para la asignatura "21782 - Laboratori de Projectes de Software"

## Backend + PostgreSQL (Docker)

### Levantar servicios

```bash
docker compose up --build -d
```

### Verificar estado

```bash
docker compose ps
docker compose logs postgres
docker compose logs app
```

### Probar backend

```bash
curl http://localhost:3000/health
```

Respuesta esperada:

```json
{ "status": "ok", "db": "connected" }
```

### Verificar tablas en PostgreSQL

```bash
docker compose exec postgres psql -U admin -d app_db -c "\\dt"
```

Nota: los scripts en `/docker-entrypoint-initdb.d/` solo se ejecutan cuando el volumen de datos de Postgres se crea por primera vez. Si ya existia, recrea volumen:

```bash
docker compose down -v
docker compose up --build -d
```
