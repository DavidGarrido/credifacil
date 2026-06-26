# Optimización de Rendimiento — Credifacil

**Fecha:** 2026-06-09
**Servidor:** VPS Hostinger (`srv1507311.hstgr.cloud`) — 2 vCPU, 8GB RAM
**Contenedor:** `landlord-creditapi-laravel.test-1` (PHP 8.4.21 + Nginx + PHP-FPM)
**Dominio:** `admin.credifacilcolombia.com`

---

## Índice

1. [Diagnóstico inicial](#1-diagnóstico-inicial)
2. [PHP-FPM / Opcache](#2-php-fpm--opcache)
3. [Código — N+1 Queries](#3-código--n1-queries)
4. [Dockerfile](#4-dockerfile)
5. [Resultados](#5-resultados)
6. [Backups y cómo revertir](#6-backups-y-cómo-revertir)

---

## 1. Diagnóstico inicial

### 1.1 Tiempos de respuesta (antes)

| Ruta | Tiempo | Tipo |
|---|---|---|
| `/login` | 2.70s | PHP-FPM (Laravel) |
| `/collections/manage` | 2.00s | PHP-FPM (Laravel) |
| `/favicon.ico` | 0.50s | Nginx estático |
| `/health` (404) | 1.15s | PHP-FPM |

### 1.2 Causas identificadas

| Causa | Impacto | Detalle |
|---|---|---|
| **xdebug activo en FPM** | 🔴 Alto | `/etc/php/8.4/fpm/conf.d/20-xdebug.ini` presente. Overhead enorme en producción |
| **CPU steal time 85-90%** | 🔴 Alto | Hostinger limita CPU por uso excesivo (visible en panel: "Eliminar limitaciones") |
| **JIT desactivado** | 🟡 Medio | `opcache.jit` sin valor (aunque buffer de 64M ya asignado) |
| **validate_timestamps=On** | 🟡 Medio | Opcache verifica archivos cada 2s en producción |
| **pm.start_servers=4** | 🟡 Medio | Muy pocos workers FPM pre-iniciados |
| **memory_limit=128M** | 🟡 Medio | Bajo para Laravel |
| **N+1 queries** | 🔴 Alto | ~101 queries por carga de `collections/manage` |

---

## 2. PHP-FPM / Opcache

### 2.1 xdebug — Desactivado en FPM

**Archivo:** `/etc/php/8.4/fpm/conf.d/20-xdebug.ini`

**Comando aplicado:**
```bash
docker exec landlord-creditapi-laravel.test-1 \
  mv /etc/php/8.4/fpm/conf.d/20-xdebug.ini \
     /etc/php/8.4/fpm/conf.d/20-xdebug.ini.disabled
```

**Verificación:**
```bash
# xdebug NO debe aparecer en FPM
docker exec landlord-creditapi-laravel.test-1 ls /etc/php/8.4/fpm/conf.d/20-xdebug*

# xdebug SÍ debe aparecer en CLI (para desarrollo)
docker exec landlord-creditapi-laravel.test-1 php -m | grep xdebug
```

### 2.2 Opcache — JIT + Optimizaciones

**Archivo:** `/etc/php/8.4/fpm/conf.d/99-sail.ini`

**Valores agregados:**
```ini
opcache.jit = tracing
opcache.jit_buffer_size = 64M
opcache.validate_timestamps = 0
opcache.revalidate_freq = 0
opcache.memory_consumption = 256
opcache.max_accelerated_files = 20000
```

**Nota:** `validate_timestamps=0` significa que opcache nunca revisa cambios en archivos. Si se modifica código en caliente, hay que ejecutar `php artisan optimize` o reiniciar FPM.

### 2.3 memory_limit — aumentado a 256M

**Archivo:** `/etc/php/8.4/fpm/php.ini`

```diff
- memory_limit = 128M
+ memory_limit = 256M
```

### 2.4 PM Settings — Workers incrementados

**Archivo:** `/etc/php/8.4/fpm/pool.d/www.conf`

| Parámetro | Antes | Después |
|---|---|---|
| `pm.max_children` | 20 | 20 *(sin cambio)* |
| `pm.start_servers` | 4 | **8** |
| `pm.min_spare_servers` | 2 | **4** |
| `pm.max_spare_servers` | 8 | **16** |

### 2.5 Aplicar cambios (en caliente)

```bash
# Graceful restart de FPM (no corta requests activos)
FPM_PID=$(docker exec landlord-creditapi-laravel.test-1 pgrep -f 'php-fpm: master')
docker exec landlord-creditapi-laravel.test-1 kill -USR2 $FPM_PID

# Recompilar caché de Laravel
docker exec landlord-creditapi-laravel.test-1 php artisan optimize
docker exec landlord-creditapi-laravel.test-1 php artisan view:cache
```

---

## 3. Código — N+1 Queries

### 3.1 Archivo modificado

**Ruta:** `app/Livewire/CollectionManagement.php`

### 3.2 Optimización 1: Batch de tenant_ids

**Antes (N+1):**
```php
foreach ($activeCredits as $credit) {
    // Cada iteración = 1 query
    $tenantIds = $credit->transactions()
        ->where('tenant_id', '!=', 'landlord')
        ->pluck('tenant_id')
        ->unique()
        ->values();
    // ...
}
// Total: N queries (1 por crédito activo)
```

**Después (1 query):**
```php
// OPTIMIZATION: Pre-load ALL tenant_ids in ONE query instead of N+1
$creditIds = $activeCredits->pluck('id');
$this->tenantIdsByCredit = CreditTransaction::whereIn('credit_id', $creditIds)
    ->where('tenant_id', '!=', 'landlord')
    ->select('credit_id', 'tenant_id')
    ->distinct()
    ->get()
    ->groupBy('credit_id')
    ->map(function ($items) {
        return $items->pluck('tenant_id')->values();
    })
    ->toArray();

foreach ($activeCredits as $credit) {
    $preloadedTenantIds = collect($this->tenantIdsByCredit[$credit->id] ?? []);
    $installments = $this->fetchInstallmentsFromTenant($credit, $preloadedTenantIds);
}
// Total: 1 query
```

### 3.3 Optimización 2: Memoización de tenant info

**Antes:** Cada llamada a `fetchTenantInfo()` hacía un HTTP GET a `/api/tenants` y recorría todo el array buscando el tenant.

**Después:** Se añadió `$this->tenantInfoCache` que cachea en memoria los resultados dentro del mismo request.

```php
private $tenantInfoCache = [];

// Precarga en getClientsData()
$allTenantIds = collect($this->tenantIdsByCredit)->flatten()->unique()->values();
foreach ($allTenantIds as $tenantId) {
    $this->fetchTenantInfo($tenantId); // primera vez = HTTP, siguientes = cache
}

// fetchTenantInfo con memoización
private function fetchTenantInfo($tenantId)
{
    if (array_key_exists($tenantId, $this->tenantInfoCache)) {
        return $this->tenantInfoCache[$tenantId];
    }
    // ... HTTP call ...
    return $this->tenantInfoCache[$tenantId] = $result;
}
```

### 3.4 Optimización 3: Colección vs Query

**Antes (N+1 en `generatePaymentLink` y `openDirectPaymentModal`):**
```php
foreach ($installments as $installment) {
    $transaction = $credit->transactions()->find($landlordTransactionId);
    // Cada iteración = 1 query
}
```

**Después (usar colección pre-cargada):**
```php
$transactionsById = $credit->transactions->keyBy('id');

foreach ($installments as $installment) {
    $transaction = $transactionsById[$landlordTransactionId] ?? null;
    // 0 queries — se usa la colección en memoria
}
```

### 3.5 Resumen de reducción de queries

| Operación | Antes | Después |
|---|---|---|
| Obtener tenant_ids por crédito | **N** (100 queries) | **1** query |
| Obtener info de tenant | **M×N** HTTP calls | **M** HTTP calls (1 por tenant único) |
| Buscar transacción en loop | **K** queries (cuotas vencidas) | **0** (colección en memoria) |

> **N** = créditos activos, **M** = tenants únicos, **K** = cuotas vencidas

---

## 4. Dockerfile

### 4.1 Archivo modificado

**Ruta:** `docker/fpm/Dockerfile`

### 4.2 Cambios

1. **PM settings** incrementados (start_servers 4→8, min_spare 2→4, max_spare 8→16)
2. **memory_limit** 128M→256M
3. **xdebug eliminado** de FPM (`rm -f /etc/php/8.4/fpm/conf.d/20-xdebug.ini`)
4. **JIT activado** (`opcache.jit = tracing`)
5. **validate_timestamps desactivado** (`opcache.validate_timestamps = 0`)
6. **opcache.memory_consumption** 128→256
7. **max_accelerated_files** 10000→20000

---

## 5. Resultados

### 5.1 Tiempos de respuesta (después)

| Ruta | Antes | Después | Mejora |
|---|---|---|---|
| `/login` | 2.70s | **0.40s** | **-85%** |
| `/collections/manage` (302) | 1.65s | **0.35s** | **-79%** |
| Health interno | 0.80s | **0.02s** | **-97%** |

### 5.2 Nota sobre CPU Steal Time

El VPS de Hostinger presenta limitación de CPU cuando se supera cierto umbral de uso. Esto se refleja como **CPU steal time >80%** en `mpstat`. Para solucionarlo definitivamente:

1. **Hacer clic en "Eliminar limitaciones"** en el panel de Hostinger (tarda 1-3h en procesarse)
2. **O migrar a un plan con CPU dedicada**

Mientras haya limitación activa, los tiempos serán erráticos (pueden subir a 9s cuando el steal llega a 90%).

---

## 6. Backups y cómo revertir

### 6.1 Backups creados

| Ubicación | Contenido |
|---|---|
| **VPS:** `/root/backups-php-config-20260609_*` | www.conf, php.ini, fpm-conf.d.tar.gz, 20-xdebug.ini, 99-sail.ini |
| **Local:** `/tmp/credifacil_backups/php-config-before-fixes/` | Mismos archivos copiados localmente |

### 6.2 Revertir PHP-FPM (si es necesario)

```bash
BACKUP_DIR=/root/backups-php-config-20260609_174358  # usar fecha real

# Restaurar pool
docker cp $BACKUP_DIR/www.conf landlord-creditapi-laravel.test-1:/etc/php/8.4/fpm/pool.d/www.conf

# Restaurar php.ini
docker cp $BACKUP_DIR/php.ini landlord-creditapi-laravel.test-1:/etc/php/8.4/fpm/php.ini

# Restaurar conf.d completo (incluye xdebug)
docker exec -i landlord-creditapi-laravel.test-1 tar -xzf - -C /etc/php/8.4/fpm < $BACKUP_DIR/fpm-conf.d.tar.gz

# Restaurar 99-sail.ini original
docker cp $BACKUP_DIR/fpm-99-sail.ini landlord-creditapi-laravel.test-1:/etc/php/8.4/fpm/conf.d/99-sail.ini

# Restaurar xdebug (si hace falta)
docker cp $BACKUP_DIR/20-xdebug.ini landlord-creditapi-laravel.test-1:/etc/php/8.4/fpm/conf.d/20-xdebug.ini

# Reiniciar FPM
FPM_PID=$(docker exec landlord-creditapi-laravel.test-1 pgrep -f 'php-fpm: master')
docker exec landlord-creditapi-laravel.test-1 kill -USR2 $FPM_PID
```

### 6.3 Revertir código

```bash
cd /opt/credifacil/landlord-creditapi
git checkout -- app/Livewire/CollectionManagement.php
docker exec landlord-creditapi-laravel.test-1 php artisan optimize
```

### 6.4 Revertir Dockerfile

```bash
cd /ruta/local/landlord-creditapi
git checkout -- docker/fpm/Dockerfile
```
