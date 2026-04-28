# 🚀 Deployment Guide - Credifácil en DigitalOcean

Guía completa y actualizada del despliegue en producción.

**Última actualización:** 2026-03-01
**Estado:** ✅ Producción activa

---

## 📌 Datos del Servidor

| Campo | Valor |
|---|---|
| Proveedor | DigitalOcean |
| Plan | $6/mes — 1 vCPU / 1GB RAM / 25GB SSD |
| Región | Toronto (tor1) |
| OS | Ubuntu 24.04 LTS |
| IP | `137.184.163.131` |
| Droplet ID | `555094463` |

---

## 🔑 Acceso SSH

```bash
# Llave SSH guardada en:
~/.ssh/do_credifacil

# Conectarse al servidor:
ssh -i ~/.ssh/do_credifacil root@137.184.163.131

# Alias recomendado (agregar a ~/.zshrc o ~/.bashrc):
alias credifacil='ssh -i ~/.ssh/do_credifacil root@137.184.163.131'
```

---

## 🌐 Dominios y DNS

- Dominio registrado en **GoDaddy**, nameservers apuntando a DigitalOcean
- DNS gestionado en **DigitalOcean** (panel DNS)

| Registro | Nombre | Valor |
|---|---|---|
| A | `@` | `137.184.163.131` |
| A | `*` | `137.184.163.131` |

### URLs de producción

| URL | Descripción |
|---|---|
| `https://credifacilcolombia.com` | Frontend (React SPA) |
| `https://admin.credifacilcolombia.com` | Panel admin landlord (Laravel) |
| `https://{tenant}.credifacilcolombia.com` | App del tenant (Frontend + API) |

---

## 📁 Estructura en el Servidor

```
/opt/credifacil/
├── landlord-creditapi/     # Landlord API (Laravel Sail) → puerto 8020
├── tenant-api-credifacil/  # Tenant API (Laravel Sail) → puerto 8021
└── frontend-dist/          # Frontend React compilado (estático)
```

---

## 🔐 Credenciales de Producción

### Landlord API
```
APP_KEY: base64:94jjls9wx97Ji8LAWpLWemwuERERKNYsezsAzQL0QNQ=
DB: landlord_creditapi
DB User: landlord_user
DB Password: LandlordProd2026
```

### Tenant API
```
APP_KEY: base64:FJLPwMosXoEHCIlZOaVvOFqo2eeNs5C+HWQNfVIjMoU=
DB: tenant_api
DB User: tenant_user
DB Password: TenantProd2026
```

### Admin Landlord (usuario web)
```
Email: administrador@credifacilcolombia.com
Password: Admin202603_*
```

### Wompi (sandbox)
```
WOMPI_PUBLIC_KEY: pub_test_fVCttILTlFCCbg6TNgMpmyWK4FYVE3EA
WOMPI_PRIVATE_KEY: prv_test_F0FKXXrl3K9fQH4KZwNr0VWjmPWWRfIy
WOMPI_SANDBOX: true
WOMPI_WEBHOOK_SECRET: test_events_STddObSywrcLnEP6EPfnxZsuSURSKyXP
WOMPI_INTEGRITY_SECRET: test_integrity_f6tcb6py8IYiQEYBKxECG10HtX5ocsBd
Webhook URL configurada en Wompi: https://admin.credifacilcolombia.com/api/webhooks/wompi
```

---

## 🏗️ Arquitectura

```
Internet
   │ HTTPS (443)
   ▼
Nginx (Reverse Proxy + SSL Wildcard)
   ├── credifacilcolombia.com        → /opt/credifacil/frontend-dist/ (estático)
   ├── admin.credifacilcolombia.com  → localhost:8020 (Landlord API)
   └── *.credifacilcolombia.com      → /opt/credifacil/frontend-dist/ (estático)
                                        + /api/* → localhost:8021 (Tenant API)
                                        + /sanctum/* → localhost:8021

Docker (Landlord) puerto 8020        Docker (Tenant) puerto 8021
├── laravel.test (PHP/Sail)          ├── laravel.test (PHP/Sail)
├── mysql (MySQL 8.0)                ├── mysql (MySQL 8.0)
├── redis                            ├── redis
└── soketi (WebSockets :8081)        └── soketi (WebSockets :8082)

Swap: 2GB (/swapfile) — necesario por el 1GB de RAM
```

---

## 🚀 Despliegue Inicial (desde cero)

Estos pasos sirven si el droplet fue eliminado y hay que crear uno nuevo.

### PASO 1 — Crear Droplet en DigitalOcean

- Plan: Basic, $6/mes, 1 vCPU / 1GB RAM / 25GB SSD
- Región: Toronto (tor1)
- OS: Ubuntu 24.04 LTS
- Autenticación: SSH key existente o nueva
- Actualizar IP en los registros DNS de DigitalOcean

### PASO 2 — Configuración inicial del servidor

```bash
ssh -i ~/.ssh/do_credifacil root@<nueva-ip>

# Actualizar sistema
apt update && apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com | sh

# Instalar utilidades
apt install -y nginx certbot python3-certbot-dns-digitalocean ufw git

# Configurar UFW (firewall)
ufw allow 22 && ufw allow 80 && ufw allow 443
ufw --force enable

# Agregar 2GB de swap (CRÍTICO con 1GB de RAM)
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

### PASO 3 — Clonar repositorios

```bash
mkdir -p /opt/credifacil
cd /opt/credifacil

# Copiar llave SSH para GitHub (si no está en el servidor)
# cat ~/.ssh/id_rsa  ← llave en la máquina local, copiarla al servidor

# Clonar repos (ajustar URLs de GitHub)
git clone git@github.com:<org>/landlord-creditapi.git landlord-creditapi
git clone git@github.com:<org>/tenant-api-credifacil.git tenant-api-credifacil
```

### PASO 4 — Instalar dependencias PHP (Composer)

```bash
cd /opt/credifacil/landlord-creditapi
docker run --rm -v $(pwd):/app -w /app composer:2 composer install --ignore-platform-reqs

cd /opt/credifacil/tenant-api-credifacil
docker run --rm -v $(pwd):/app -w /app composer:2 composer install --ignore-platform-reqs
```

### PASO 5 — Crear archivos .env de producción

**Landlord** (`/opt/credifacil/landlord-creditapi/.env`):
```env
APP_NAME="Landlord Credit API"
APP_ENV=production
APP_KEY=base64:94jjls9wx97Ji8LAWpLWemwuERERKNYsezsAzQL0QNQ=
APP_DEBUG=false
APP_URL=https://admin.credifacilcolombia.com
APP_PORT=8020

LOG_CHANNEL=stack
LOG_STACK=single
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=landlord_creditapi
DB_USERNAME=landlord_user
DB_PASSWORD=LandlordProd2026

FORWARD_DB_PORT=3320
FORWARD_REDIS_PORT=6382

CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=database

REDIS_HOST=redis
REDIS_PORT=6379

MAIL_MAILER=log
MAIL_FROM_ADDRESS=noreply@credifacilcolombia.com
MAIL_FROM_NAME="Credifácil"

SANCTUM_STATEFUL_DOMAINS=credifacilcolombia.com,admin.credifacilcolombia.com

ASSET_URL=https://admin.credifacilcolombia.com
TRUSTED_PROXIES=*

WOMPI_PUBLIC_KEY=pub_test_fVCttILTlFCCbg6TNgMpmyWK4FYVE3EA
WOMPI_PRIVATE_KEY=prv_test_F0FKXXrl3K9fQH4KZwNr0VWjmPWWRfIy
WOMPI_SANDBOX=true
WOMPI_WEBHOOK_SECRET=test_events_STddObSywrcLnEP6EPfnxZsuSURSKyXP
WOMPI_INTEGRITY_SECRET=test_integrity_f6tcb6py8IYiQEYBKxECG10HtX5ocsBd
WEBHOOK_SECRET=credifacil_webhook_secret_2025_secure_token_hmac_sha256
```

**Tenant** (`/opt/credifacil/tenant-api-credifacil/.env`):
```env
APP_NAME="Tenant API"
APP_ENV=production
APP_KEY=base64:FJLPwMosXoEHCIlZOaVvOFqo2eeNs5C+HWQNfVIjMoU=
APP_DEBUG=false
APP_URL=https://app.credifacilcolombia.com
APP_PORT=8021

LOG_CHANNEL=stack
LOG_STACK=single
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=tenant_api
DB_USERNAME=tenant_user
DB_PASSWORD=TenantProd2026

FORWARD_DB_PORT=3321
FORWARD_REDIS_PORT=6383

BROADCAST_CONNECTION=pusher
CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=cookie
SESSION_DOMAIN=.credifacilcolombia.com

SANCTUM_STATEFUL_DOMAINS=credifacilcolombia.com,*.credifacilcolombia.com

REDIS_HOST=redis
REDIS_PORT=6379

MAIL_MAILER=log
MAIL_FROM_ADDRESS=noreply@credifacilcolombia.com
MAIL_FROM_NAME="Credifácil"

LANDLORD_API_URL=https://admin.credifacilcolombia.com/api

REVERB_APP_ID=286283
REVERB_HOST=app.credifacilcolombia.com
REVERB_PORT=443
REVERB_SCHEME=https

REVERB_APP_KEY=30aae8278616e395ab20b870e4c5f22d3c16279a
REVERB_APP_SECRET=5ddb03ae8fbadc6e9b4d727e1394850248b9aebce351a0556d777d1c1c83b58c

PUSHER_APP_ID=286283
PUSHER_APP_KEY=30aae8278616e395ab20b870e4c5f22d3c16279a
PUSHER_APP_SECRET=5ddb03ae8fbadc6e9b4d727e1394850248b9aebce351a0556d777d1c1c83b58c
PUSHER_HOST=soketi
PUSHER_PORT=6001
PUSHER_SCHEME=http

TENANT_DOMAIN_SUFFIX=credifacilcolombia.com
WEBHOOK_SECRET=credifacil_webhook_secret_2025_secure_token_hmac_sha256
```

### PASO 6 — Ajustar compose.yaml (Sail) — Quitar puertos Vite

En ambos proyectos, editar `compose.yaml` y eliminar estas líneas si existen:
```yaml
# ELIMINAR estas líneas del servicio laravel.test:
- VITE_PORT=${VITE_PORT:-5173}
ports:
  - '${VITE_PORT:-5173}:${VITE_PORT:-5173}'
```

Para Soketi del **tenant**, cambiar el puerto para evitar conflicto con SSL:
```yaml
# En tenant-api-credifacil/compose.yaml, servicio soketi:
ports:
  - '8082:8080'  # No usar 443
```

### PASO 7 — Levantar contenedores

```bash
# Landlord
cd /opt/credifacil/landlord-creditapi
docker compose up -d

# Tenant
cd /opt/credifacil/tenant-api-credifacil
docker compose up -d

# Verificar que están corriendo
docker compose ps
```

### PASO 8 — Permisos de storage (usuario Sail = UID 1337)

```bash
# Landlord
chown -R 1337:0 /opt/credifacil/landlord-creditapi/storage
chown -R 1337:0 /opt/credifacil/landlord-creditapi/bootstrap/cache

# Tenant
chown -R 1337:0 /opt/credifacil/tenant-api-credifacil/storage
chown -R 1337:0 /opt/credifacil/tenant-api-credifacil/bootstrap/cache
```

### PASO 9 — Crear base de datos y usuario MySQL

```bash
# Landlord DB
cd /opt/credifacil/landlord-creditapi
docker compose exec mysql mysql -u root -ppassword -e "
  CREATE DATABASE IF NOT EXISTS landlord_creditapi;
  CREATE USER IF NOT EXISTS 'landlord_user'@'%' IDENTIFIED BY 'LandlordProd2026';
  GRANT ALL PRIVILEGES ON landlord_creditapi.* TO 'landlord_user'@'%';
  FLUSH PRIVILEGES;
"

# Tenant DB (necesita CREATE DATABASE para multi-tenancy)
cd /opt/credifacil/tenant-api-credifacil
docker compose exec mysql mysql -u root -ppassword -e "
  CREATE DATABASE IF NOT EXISTS tenant_api;
  CREATE USER IF NOT EXISTS 'tenant_user'@'%' IDENTIFIED BY 'TenantProd2026';
  GRANT ALL PRIVILEGES ON *.* TO 'tenant_user'@'%' WITH GRANT OPTION;
  FLUSH PRIVILEGES;
"
```

### PASO 10 — Ejecutar migraciones

```bash
# Landlord
cd /opt/credifacil/landlord-creditapi
docker compose exec laravel.test php artisan migrate --force

# Tenant
cd /opt/credifacil/tenant-api-credifacil
docker compose exec laravel.test php artisan migrate --force

# Crear admin landlord
cd /opt/credifacil/landlord-creditapi
docker compose exec laravel.test php artisan tinker --execute="
App\Models\User::create([
  'name' => 'Administrador',
  'email' => 'administrador@credifacilcolombia.com',
  'password' => bcrypt('Admin202603_*'),
]);
"
```

### PASO 11 — SSL con Certbot (wildcard via DigitalOcean DNS)

```bash
# Instalar plugin DNS de DigitalOcean
pip3 install certbot-dns-digitalocean

# Crear credenciales DO
mkdir -p /root/.secrets
cat > /root/.secrets/digitalocean.ini << 'EOF'
dns_digitalocean_token = <TOKEN_API_DIGITALOCEAN>
EOF
chmod 600 /root/.secrets/digitalocean.ini

# Obtener certificado wildcard
certbot certonly \
  --dns-digitalocean \
  --dns-digitalocean-credentials /root/.secrets/digitalocean.ini \
  -d credifacilcolombia.com \
  -d '*.credifacilcolombia.com' \
  --non-interactive \
  --agree-tos \
  --email admin@credifacilcolombia.com
```

### PASO 12 — Configurar Nginx

```bash
cat > /etc/nginx/sites-available/credifacil << 'NGINX'
# HTTP → HTTPS
server {
    listen 80;
    server_name credifacilcolombia.com www.credifacilcolombia.com admin.credifacilcolombia.com ~^.+\.credifacilcolombia\.com$;
    return 301 https://$host$request_uri;
}

# Frontend principal
server {
    listen 443 ssl;
    server_name credifacilcolombia.com www.credifacilcolombia.com;
    ssl_certificate /etc/letsencrypt/live/credifacilcolombia.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/credifacilcolombia.com/privkey.pem;
    root /opt/credifacil/frontend-dist;
    index index.html;
    add_header Content-Security-Policy upgrade-insecure-requests;
    add_header Strict-Transport-Security max-age=31536000 always;
    location / { try_files $uri $uri/ /index.html; }
}

# Landlord admin
server {
    listen 443 ssl;
    server_name admin.credifacilcolombia.com;
    ssl_certificate /etc/letsencrypt/live/credifacilcolombia.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/credifacilcolombia.com/privkey.pem;
    location / {
        proxy_pass http://localhost:8020;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Tenant subdomains
server {
    listen 443 ssl;
    server_name ~^(?<tenant>.+)\.credifacilcolombia\.com$;
    ssl_certificate /etc/letsencrypt/live/credifacilcolombia.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/credifacilcolombia.com/privkey.pem;
    root /opt/credifacil/frontend-dist;
    index index.html;
    add_header Content-Security-Policy upgrade-insecure-requests;
    add_header Strict-Transport-Security max-age=31536000 always;
    location /api/ {
        proxy_pass http://localhost:8021;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    location /sanctum/ {
        proxy_pass http://localhost:8021;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    location / { try_files $uri $uri/ /index.html; }
}
NGINX

ln -sf /etc/nginx/sites-available/credifacil /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

### PASO 13 — Deploy del frontend

```bash
# En la máquina LOCAL:
cd /mnt/almacenamiento/garher/Documentos/credifacil/frontend

# Verificar .env.production
cat .env.production
# VITE_TENANT_API_URL=https://api.credifacilcolombia.com
# VITE_PUSHER_APP_KEY=c6c1f821c1ee7a451add
# VITE_PUSHER_APP_CLUSTER=us2

# Compilar
npm run build

# Subir al servidor
rsync -az --delete \
  -e "ssh -i ~/.ssh/do_credifacil" \
  dist/ \
  root@137.184.163.131:/opt/credifacil/frontend-dist/
```

### PASO 14 — Limpiar cachés Laravel

```bash
# Landlord
cd /opt/credifacil/landlord-creditapi
docker compose exec laravel.test php artisan config:clear
docker compose exec laravel.test php artisan route:clear
docker compose exec laravel.test php artisan view:clear

# Tenant
cd /opt/credifacil/tenant-api-credifacil
docker compose exec laravel.test php artisan config:clear
docker compose exec laravel.test php artisan route:clear
docker compose exec laravel.test php artisan view:clear
```

---

## 🔄 Actualizar el código en producción

Cuando hay cambios en los repos:

```bash
ssh -i ~/.ssh/do_credifacil root@137.184.163.131

# Actualizar landlord
cd /opt/credifacil/landlord-creditapi
git pull
docker compose exec laravel.test php artisan migrate --force
docker compose exec laravel.test php artisan config:clear
docker compose exec laravel.test php artisan route:clear
docker compose exec laravel.test php artisan view:clear

# Actualizar tenant
cd /opt/credifacil/tenant-api-credifacil
git pull
docker compose exec laravel.test php artisan migrate --force
docker compose exec laravel.test php artisan config:clear
docker compose exec laravel.test php artisan route:clear
docker compose exec laravel.test php artisan view:clear
```

Para el frontend (desde local):
```bash
cd /mnt/almacenamiento/garher/Documentos/credifacil/frontend
npm run build
rsync -az --delete -e "ssh -i ~/.ssh/do_credifacil" dist/ root@137.184.163.131:/opt/credifacil/frontend-dist/
```

---

## 🛠️ Comandos útiles de mantenimiento

```bash
# Ver logs en tiempo real
cd /opt/credifacil/landlord-creditapi && docker compose logs -f laravel.test
cd /opt/credifacil/tenant-api-credifacil && docker compose logs -f laravel.test

# Ver log de Laravel directamente
tail -f /opt/credifacil/landlord-creditapi/storage/logs/laravel.log
tail -f /opt/credifacil/tenant-api-credifacil/storage/logs/laravel.log

# Ver logs de Nginx
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Estado de contenedores
cd /opt/credifacil/landlord-creditapi && docker compose ps
cd /opt/credifacil/tenant-api-credifacil && docker compose ps

# Reiniciar un servicio
cd /opt/credifacil/landlord-creditapi && docker compose restart laravel.test
cd /opt/credifacil/tenant-api-credifacil && docker compose restart laravel.test

# Acceder a MySQL landlord
cd /opt/credifacil/landlord-creditapi
docker compose exec mysql mysql -u landlord_user -pLandlordProd2026 landlord_creditapi

# Acceder a MySQL tenant
cd /opt/credifacil/tenant-api-credifacil
docker compose exec mysql mysql -u tenant_user -pTenantProd2026 tenant_api

# Ejecutar artisan
cd /opt/credifacil/landlord-creditapi
docker compose exec laravel.test php artisan <comando>

# Ver uso de recursos
free -h && df -h / && docker stats --no-stream
```

---

## 🔒 Renovación SSL

El certificado wildcard vence el **2026-05-29**. Para renovar:

```bash
ssh -i ~/.ssh/do_credifacil root@137.184.163.131
certbot renew
nginx -t && systemctl reload nginx
```

> La renovación automática con cron debería hacerse sola. Verificar con:
> `systemctl status certbot.timer` o `crontab -l`

---

## ⚠️ Notas importantes

1. **RAM limitada (1GB)** — El swap de 2GB es fundamental. Si el servidor se pone lento o los contenedores mueren, revisar: `free -h`
2. **APP_DEBUG=true en landlord** — Actualmente en modo debug para facilitar diagnóstico. Cambiar a `false` y reiniciar cuando esté estable.
3. **Wompi en sandbox** — Las credenciales actuales son de prueba. Para producción real, obtener credenciales de producción en el panel de Wompi.
4. **Token de DigitalOcean** — El token de API usado para el SSL wildcard debe rotarse periódicamente.
5. **host.docker.internal** — Mapeado via `extra_hosts` en ambos `compose.yaml`. Permite que el landlord se comunique con el tenant internamente.
6. **trustProxies** — Configurado en `bootstrap/app.php` de ambas APIs para que Laravel detecte HTTPS correctamente detrás de Nginx.
