---
description: Agente principal para el proyecto Credifacil. Conoce el flujo entre PC local, PC2 y VPS Hostinger.
mode: primary
---

# Agente Credifacil — Flujo de Trabajo Multi-máquina

## Proyecto

Monorepo con tres submódulos (cada uno es un repo independiente):
- `landlord-creditapi/` — API central de créditos (Laravel 11, MySQL)
- `tenant-api/` — API multi-tenant por comercio (Laravel 11, MySQL)
- `frontend/` — Cliente web (React + Vite + Tailwind CSS)

Los tres están en `.gitignore` del repo raíz como submódulos. Cada uno tiene su propio git.

## Máquinas

| Máquina          | Acceso                                                                    | Rol                          |
|------------------|---------------------------------------------------------------------------|------------------------------|
| PC local (este)  | Trabajo directo                                                           | Desarrollo                   |
| PC2              | `pc2-zt` (alias → `ssh garher@192.168.195.6`)                            | Desarrollo                   |
| VPS (DigitalOcean) | `ssh -i ~/.ssh/id_rsa root@187.124.232.145`                             | Producción (Docker)          |

## Flujo de inicio obligatorio

**Siempre que se inicie una sesión de trabajo**, ejecutar estos pasos en orden:

### Paso 1: Verificar estado de git en la PC local
```bash
echo "=== PC local ==="
git status
git log --oneline -10
```

### Paso 2: Verificar estado en PC2
```bash
echo "=== PC2 ==="
ssh garher@192.168.195.6 "cd ~/Documentos/credifacil && echo '--- status ---' && git status && echo '--- log ---' && git log --oneline -5 && echo '--- stashes ---' && git stash list"
```

### Paso 3: Verificar estado en VPS (producción)
```bash
echo "=== VPS (DigitalOcean) ==="
echo "--- última versión desplegada ---"
ssh -i ~/.ssh/id_rsa root@187.124.232.145 "cd /opt/credifacil && \
  echo '--- landlord-creditapi ---' && \
  git -C landlord-creditapi log --oneline -3 2>/dev/null && \
  echo '--- tenant-api ---' && \
  git -C tenant-api-credifacil log --oneline -3 2>/dev/null && \
  echo '--- contenedores activos ---' && \
  docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null"
```

### Paso 4: Verificar si hay commits sin subir
```bash
echo "=== Por enviar a origin ==="
git log --oneline --branches --not --remotes 2>/dev/null || echo "  (sin remote configurado)"
```

### Paso 5: Comparar versiones local vs VPS
Comparar el log local de `landlord-creditapi` y `tenant-api` con lo que está desplegado en el VPS. Si difieren, mostrar cuántos commits de diferencia hay.

### Paso 6: Backup de BD desde VPS (opcional, preguntar)
Verificar la fecha del último backup local en `/tmp/credifacil_dumps/`. Si no existe o es viejo (>1 día), preguntar si quiere ejecutar `./backup_vps_hostinger.sh`.

## Flujo al finalizar sesión

1. Hacer commit y push de los cambios en cada submódulo que haya modificado
2. Hacer commit y push del repo raíz
3. Preguntar si quiere sincronizar a PC2 vía `git pull` desde allá
4. Preguntar si quiere desplegar al VPS (recordar que producción requiere Docker y los pasos de DEPLOYMENT.md)

## Submódulos

Los submódulos `landlord-creditapi/`, `tenant-api/` y `frontend/` apuntan a commits específicos. Después de modificarlos:
```bash
cd landlord-creditapi && git add -A && git commit -m "..." && git push
cd ../tenant-api && git add -A && git commit -m "..." && git push
cd ../frontend && git add -A && git commit -m "..." && git push
cd .. && git add landlord-creditapi tenant-api frontend && git commit -m "chore: update submodules" && git push
```

## Scripts importantes

- `./backup_vps_hostinger.sh` — Trae dumps de producción (DO) y restaura en Docker local
- `./start-project.sh` — Inicia los contenedores
- `./stop-project.sh` — Detiene los contenedores

## Documentación clave en la raíz

- `TAREAS.md` — Prioridades actuales
- `CREDIT_FLOW.md` — Flujo de créditos
- `DEPLOYMENT.md` — Despliegue
- `DATABASE_STRUCTURE.md` — Estructura de BD
- `QUICK_START.md` — Inicio rápido
