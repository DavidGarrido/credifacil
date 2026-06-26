---
description: Agente principal para el proyecto Credifacil. Conoce el flujo entre PC local, PC2 y VPS Hostinger.
mode: primary
---

# Agente Credifacil — Flujo de Trabajo Multi-máquina

## Proyecto — 4 repos independientes (cada uno su propio git)

| # | Proyecto | Ruta local | Ruta VPS | GitHub | Stack | Quién lo usa |
|---|---|---|---|---|---|---|---|
| 1 | **landlord** | `landlord-creditapi/` | `/opt/credifacil/landlord-creditapi/` | `DavidGarrido/landlord-creditapi.git` | Laravel 11 + MySQL | Admin CrediFácil |
| 2 | **tenant** | `tenant-api/` | `/opt/credifacil/tenant-api-credifacil/` | `DavidGarrido/tenant-api-credifacil.git` | Laravel 11 + MySQL | Comercios (multi-tenant) |
| 3 | **frontend** | `frontend/` | *(solo local)* | `DavidGarrido/frontend-tenant-credifacil.git` | React + Vite + Tailwind | **Admin comercios** (empleados con roles) |
| 4 | **client-portal-ionic** 🆕 | `client-portal-ionic/` | `/opt/credifacil/client-portal-ionic/` | `DavidGarrido/client-portal-ionic.git` | Ionic/Angular + Capacitor | **Clientes/deudores** (personas que piden crédito) |
| — | **raíz** | `./` (este repo) | — | `DavidGarrido/credifacil.git` | — | Meta-repo con submodulos |

### Descripción de cada proyecto

| Proyecto | Rol | Autenticación | Público objetivo |
|---|---|---|---|
| `landlord` | API central — créditos, clientes, transacciones, cobros | API keys + Sanctum | Solo el backend tenant |
| `tenant` | API multi-tenant — cuotas, pagos, usuarios del comercio | Sanctum (email+password) | Admin comercios + proxy desde Ionic |
| `frontend` (React) | Panel admin — solicitudes, transacciones, pagos, usuarios, docs | Sanctum (email+password) | Empleados del comercio (admin, cajero) |
| `client-portal-ionic` 🆕 | App cliente — dashboard, créditos, pagos, simulador, perfil | Cédula+teléfono + código Telegram | Deudores/clientes finales |

### Cómo se comunican

```
React (admin comercio) ───→ Tenant API ───→ Landlord API (vía HTTP)
Ionic (cliente)       ───→ Tenant API ───→ Landlord API (vía HTTP)
                                              │
                                         (datos centrales:
                                          clients, credits,
                                          credit_transactions)
                                              │
Tenant DB local: credit_installments, pagos, usuarios
```

## Máquinas

| Máquina            | Acceso LAN                    | Acceso WAN                    | Rol                          |
|--------------------|-------------------------------|-------------------------------|------------------------------|
| **PC1** (este)     | Trabajo directo               | `192.168.195.171` (wan)       | Desarrollo                   |
| **PC2**            | `garher@10.0.0.2` (lan)       | `garher@192.168.195.6` (wan)  | Desarrollo                   |
| VPS (DigitalOcean) | `root@187.124.232.145` (vía id_rsa) | —                     | Producción (Docker)          |

### Detectar dónde estamos

- **PC1** (`garher-pc` / IP `192.168.195.171`) → conectarse a PC2 (LAN `10.0.0.2`, fallback WAN `192.168.195.6`)
- **PC2** → conectarse a PC1 (LAN `10.0.0.1`, fallback WAN `192.168.195.171`)

> ⚠️ **PC2** no tiene el repo raíz (`credifacil/`) con submodulos. Solo los proyectos individuales (`landlord-creditapi/`, `tenant-api-credifacil/`, `frontend-tenant-credifacil/`). Para tener este agente en PC2 hay que clonar también `DavidGarrido/credifacil.git` o copiar este archivo a la ruta equivalente.

## Flujo de inicio obligatorio

**Siempre que se inicie una sesión de trabajo**, ejecutar estos pasos en orden:

### Paso 1: Verificar estado de git en la PC local
```bash
echo "=== PC local ==="
git status
git log --oneline -10
```

### Paso 2: Verificar estado en el otro PC
Detectar si estamos en PC1 o PC2 (por hostname o IP) y verificar el otro.

```bash
echo "=== Otro PC ==="
MI_IP=$(ip addr show | grep -oP 'inet \K[\d.]+' 2>/dev/null | paste -sd ' ')
if echo "$MI_IP" | grep -q "192.168.195.171\|garher"; then
  # Estamos en PC1 → conectar a PC2
  echo "→ detectado PC1, verificando PC2..."
  if ssh -o ConnectTimeout=3 garher@10.0.0.2 "echo OK" 2>/dev/null; then
    echo "→ PC2 via LAN (10.0.0.2)"
    ssh garher@10.0.0.2 "cd ~/Documentos/credifacil && echo '--- status ---' && git status && echo '--- log ---' && git log --oneline -5 && echo '--- stashes ---' && git stash list"
  else
    echo "→ LAN no responde, intentando WAN (192.168.195.6)..."
    ssh -o ConnectTimeout=5 garher@192.168.195.6 "cd ~/Documentos/credifacil && echo '--- status ---' && git status && echo '--- log ---' && git log --oneline -5 && echo '--- stashes ---' && git stash list" 2>/dev/null || echo "  ✗ PC2 no disponible"
  fi
else
  # Estamos en PC2 → conectar a PC1
  echo "→ detectado PC2, verificando PC1..."
  if ssh -o ConnectTimeout=3 garher@10.0.0.1 "echo OK" 2>/dev/null; then
    echo "→ PC1 via LAN (10.0.0.1)"
    ssh garher@10.0.0.1 "cd ~/Documentos/credifacil && echo '--- status ---' && git status && echo '--- log ---' && git log --oneline -5 && echo '--- stashes ---' && git stash list"
  else
    echo "→ LAN no responde, intentando WAN (192.168.195.171)..."
    ssh -o ConnectTimeout=5 garher@192.168.195.171 "cd ~/Documentos/credifacil && echo '--- status ---' && git status && echo '--- log ---' && git log --oneline -5 && echo '--- stashes ---' && git stash list" 2>/dev/null || echo "  ✗ PC1 no disponible"
  fi
fi
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

Los submódulos `landlord-creditapi/`, `tenant-api/`, `frontend/` y `client-portal-ionic/` apuntan a commits específicos. Después de modificarlos:
```bash
cd landlord-creditapi && git add -A && git commit -m "..." && git push
cd ../tenant-api && git add -A && git commit -m "..." && git push
cd ../frontend && git add -A && git commit -m "..." && git push
cd ../client-portal-ionic && git add -A && git commit -m "..." && git push
cd .. && git add landlord-creditapi tenant-api frontend client-portal-ionic && git commit -m "chore: update submodules" && git push
```

## 🚨 Conocimiento crítico de producción

### Usuarios en contenedores
- **PHP-FPM** corre como usuario **`sail`** (uid 1337), NO como `www-data`
- `docker exec ... php artisan ...` se ejecuta como **root** → los archivos creados quedan propiedad de root
- **El PHP-FPM no puede escribir logs ni archivos creados por root**

### Solución permanente de permisos (setgid)
```bash
# Ya está aplicado en tenant y landlord — mantener:
chown -R sail:sail /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
chmod g+s /var/www/html/storage /var/www/html/bootstrap/cache
# El setgid hace que archivos nuevos hereden el grupo sail
```

### Helper `artisan-sail` (en el VPS)
```bash
# Usar SIEMPRE en vez de docker exec ... php artisan ...
artisan-sail tenant optimize       # → docker exec -u sail ... php artisan optimize
artisan-sail landlord migrate       # → docker exec -u sail ... php artisan migrate
artisan-sail tenant config:clear
```
Está en `/usr/local/bin/artisan-sail` del VPS. Ejecuta artisan como `sail` (no root).

### 🐞 Opcache: validate_timestamps = 0
Los Dockerfiles tienen `opcache.validate_timestamps=0` en CLI + FPM.  
**Esto significa que PHP-FPM NUNCA detecta cambios en archivos PHP.**

👉 Después de hacer `git pull` de nuevo código, hay que **reiniciar PHP-FPM**:
```bash
# Encontrar el PID del master de PHP-FPM y enviarle SIGUSR2 (graceful restart)
PHP_PID=$(docker exec tenant-api-credifacil-laravel.test-1 pgrep -f "php-fpm: master")
docker exec tenant-api-credifacil-laravel.test-1 kill -USR2 $PHP_PID

# Alternativa: reiniciar el contenedor completo
docker compose -f /opt/credifacil/tenant-api-credifacil/compose.yaml restart laravel.test
```

### Flujo de deploy correcto
```bash
# 1. Pull código
git -C /opt/credifacil/tenant-api-credifacil pull origin main

# 2. Recachear config/rutas (como sail)
artisan-sail tenant optimize

# 3. 👉 Reiniciar PHP-FPM (para que opcache cargue los nuevos archivos)
PHP_PID=$(docker exec tenant-api-credifacil-laravel.test-1 pgrep -f "php-fpm: master")
docker exec tenant-api-credifacil-laravel.test-1 kill -USR2 $PHP_PID
```

## Scripts importantes

- `./backup_vps_hostinger.sh` — Trae dumps de producción (DO) y restaura en Docker local
- `./start-project.sh` — Inicia los contenedores
- `./stop-project.sh` — Detiene los contenedores

### 🔧 Nginx para PWA (Ionic/Angular)
El portal cliente (`micliente.credifacilcolombia.com`) tiene:
- `root /opt/credifacil/client-portal-ionic/www/browser` (Angular 20 build output)
- `try_files $uri $uri/ /index.html;` para SPA routing
- HTTP → HTTPS redirect (obligatorio para Service Workers)
- `location /api/` proxy_pass a tenant-api (:8021)
- `location /sanctum/` proxy_pass a tenant-api (:8021)
- Security headers: HSTS, CSP, X-Frame-Options, etc.

### Configs que NO se versionan
- Los `.env` y `environment.prod.ts` (Ionic) están en `.gitignore`
- `client-portal-ionic` es repo independiente (no submódulo de `credifacil` raíz)
- Los archivos `.log` y `.pid` no se versionan

## Documentación clave en la raíz

- `TAREAS.md` — Prioridades actuales
- `CREDIT_FLOW.md` — Flujo de créditos
- `DEPLOYMENT.md` — Despliegue
- `DATABASE_STRUCTURE.md` — Estructura de BD
- `QUICK_START.md` — Inicio rápido
- `SISTECREDITO_COMPARATIVA.md` — Estudio de Sistecredito y plan de implementación de features faltantes en Ionic y React
- `ARQUITECTURA_SNAPSHOTS_MULTITENANT.md` — Solución de snapshots para consultar créditos multi-tenant sin replicar cuotas
