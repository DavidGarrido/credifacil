# Bug Report: Registro de Tenant y Subida de Documentación

**Fecha:** 2026-04-08  
**Entorno:** Producción  
**Severidad:** Alta — flujo de onboarding completamente bloqueado

---

## Resumen

Dos fallos encadenados bloqueaban el registro de nuevos comerciantes en `https://credifacilcolombia.com`:

1. `POST /api/tenants/register` → 500 Internal Server Error
2. `POST /api/company-documentation` → 413 Content Too Large

---

## Fallo 1: 500 en registro de tenant

### Síntoma

```
POST https://api.credifacilcolombia.com/api/tenants/register 500
```

### Causa raíz

Al registrar un nuevo tenant, el `TenantRegistrationController` del **tenant-api** ejecuta `\Artisan::call('tenants:migrate')` para inicializar la base de datos del nuevo tenant. Durante esa migración, dos archivos intentaban agregar la misma columna `transfer_to_landlord` a la tabla `credit_installments`:

| Archivo | Comportamiento |
|---|---|
| `2026_01_15_005231_add_transfer_to_landlord_and_paid_at_...php` | Agrega la columna con `hasColumn()` check — seguro |
| `2026_01_15_030000_add_transfer_to_landlord_to_credit_installments.php` | Agrega la columna **sin** check — falla si ya existe |

Como `005231` tiene timestamp menor, corre primero y crea la columna. Luego `030000` intenta crearla de nuevo y MySQL lanza:

```
SQLSTATE[42S21]: Column already exists: 1060 Duplicate column name 'transfer_to_landlord'
```

**Nota adicional:** La petición llegaba al **tenant-api** (no al landlord) porque nginx usaba el wildcard `~^(?<tenant>.+)\.credifacilcolombia\.com$` para capturar `api.credifacilcolombia.com`, enrutando a puerto 8021 (tenant-api).

### Corrección

Agregado `hasColumn()` check en la migración `030000`:

```php
// tenant-api/database/migrations/tenant/2026_01_15_030000_...php
if (!Schema::hasColumn('credit_installments', 'transfer_to_landlord')) {
    Schema::table('credit_installments', function (Blueprint $table) {
        $table->decimal('transfer_to_landlord', 12, 2)->default(0)->after('remaining_amount');
    });
}
```

---

## Fallo 2: 413 en subida de documentación

### Síntoma

```
POST https://caficultor.credifacilcolombia.com/api/company-documentation 413
Error al enviar documentación al servidor central
```

### Causa raíz (cadena de 3 niveles)

El flujo de documentación tiene dos saltos HTTP:

```
Browser → [nginx host] → tenant-api (8021) → [nginx host admin] → landlord (8020)
```

**Nivel 1 — nginx tenant (resuelto rápido):** El bloque wildcard de nginx no tenía `client_max_body_size`, usando el default de 1MB. Subido a 50M.

**Nivel 2 — Validador Laravel tenant-api:** Los archivos tenían `max:5120` (5MB). Subido a `max:10240` (10MB).

**Nivel 3 — nginx admin (causa real del 413 persistente):**  
El tenant-api reenvía los archivos al landlord usando la URL `https://admin.credifacilcolombia.com/api` (configurada en `.env` como `LANDLORD_API_URL`). Esta petición pasa por el bloque `admin.credifacilcolombia.com` de nginx, que **no tenía** `client_max_body_size`. El nginx del host rechazaba el multipart con 413 antes de llegar al landlord.

El síntoma fue confuso porque el log del landlord estaba vacío — la petición nunca llegaba a PHP.

**Causa secundaria investigada:** El uso de `fopen()` en el tenant-api para construir el multipart hacía que guzzle usara `Transfer-Encoding: chunked` sin `Content-Length`. Corregido a `file_get_contents()` para garantizar que guzzle calcule el tamaño correcto.

### Correcciones aplicadas

**nginx `/etc/nginx/sites-available/credifacil`:**
```nginx
# Bloque tenant wildcard
server {
    server_name ~^(?<tenant>.+)\.credifacilcolombia\.com$;
    client_max_body_size 50M;   # agregado
    ...
}

# Bloque admin (causa raíz del 413 persistente)
server {
    server_name admin.credifacilcolombia.com;
    client_max_body_size 50M;   # agregado
    ...
}
```

**tenant-api validador** (`CompanyDocumentationController.php`):
```php
// Antes: max:5120 (5MB)
// Después: max:10240 (10MB)
'camara_comercio'        => 'required|file|mimes:pdf,jpg,jpeg,png|max:10240',
'rut'                    => 'required|file|mimes:pdf,jpg,jpeg,png|max:10240',
'certificado_bancario'   => 'required|file|mimes:pdf,jpg,jpeg,png|max:10240',
'cedula_representante'   => 'required|file|mimes:pdf,jpg,jpeg,png|max:10240',
```

**tenant-api multipart** (`CompanyDocumentationController.php`):
```php
// Antes (causaba chunked transfer):
'contents' => fopen($file->getRealPath(), 'r'),

// Después (guzzle calcula Content-Length correctamente):
'contents' => file_get_contents($file->getRealPath()),
'headers'  => ['Content-Type' => $file->getMimeType()],
```

---

## Archivos modificados

| Archivo | Tipo de cambio |
|---|---|
| `tenant-api/database/migrations/tenant/2026_01_15_030000_add_transfer_to_landlord_to_credit_installments.php` | Agregar `hasColumn()` check |
| `tenant-api/app/Http/Controllers/Api/CompanyDocumentationController.php` | Límite de archivos 5MB→10MB, `fopen` → `file_get_contents` |
| `/etc/nginx/sites-available/credifacil` (servidor) | `client_max_body_size 50M` en bloques tenant y admin |
