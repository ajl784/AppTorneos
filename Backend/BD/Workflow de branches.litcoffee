## Workflow de trabajo con Git 

### 1. Cambiar a tu rama

Ver en qué rama estás:

```bash
git branch
```

Cambiar a tu rama:

```bash
git checkout nombre-de-tu-rama
```

Si la rama existe en GitHub pero no localmente:

```bash
git fetch
git checkout nombre-de-tu-rama
```

---

## 2. Trabajar y subir cambios

Después de hacer cambios en el código:

```bash
git add .
git commit -m "descripción de los cambios"
git push
```

Esto subirá los cambios **a tu propia rama**, no a `main`.

---

## 3. Descargar cambios de tu rama

Para actualizar tu rama con lo que haya en el repositorio remoto:

```bash
git pull
```

Esto solo descarga cambios de **tu misma rama**.

---

## 4. Actualizar tu rama con cambios de `main`

Si alguien ha hecho cambios en `main`, actualiza tu rama así:

```bash
git checkout main
git pull
git checkout nombre-de-tu-rama
git merge main
```

---

## 5. Integrar el trabajo (Pull Request)

Cuando termines una parte:

1. Ir al repositorio en GitHub
2. Crear **Pull Request**
3. Seleccionar:

```
base: main
compare: tu-rama
```

4. Revisar cambios
5. Hacer **Merge**

---

## Flujo típico de trabajo

```
1. git checkout tu-rama
2. trabajar en el código
3. git add .
4. git commit -m "mensaje"
5. git push
```

Actualizar con cambios del proyecto:

```
git checkout main
git pull
git checkout tu-rama
git merge main
```
