# Estado de sesión — 2026-03-11

## Qué estamos haciendo

Deployando el módulo de cobranza entre landlord y aliados a producción (droplet DigitalOcean).

---

## Lo que se hizo hoy

### 1. Fix crítico: queue workers nunca corrían
**Problema:** `CACHE_STORE` no estaba definido en `.env` del tenant (solo `CACHE_DRIVER`). El config usa `CACHE_STORE`. Laravel usaba cache `database`, la tabla no existe → worker crasheaba al arrancar → jobs `NotifyLandlordOfPayment` nunca se procesaban → landlord nunca se enteraba de pagos → `current_pending_debt` siempre en 0 → nadie se bloqueaba.

**Fix:**
- Agregar `CACHE_STORE=redis` al `.env` y `.env.example` del tenant-api
- En `start-project.sh`: verificar y agregar `CACHE_STORE=redis` automáticamente
- Queue workers locales: lanzar via `docker exec -d` desde el host

### 2. Módulo de cobranza: push a producción
Archivos deployados:
- **Tenant:** `AppServiceProvider.php` (listener InstallmentPaid), `DebtController.php`, `AlliesController.php`, `routes/tenant.php`
- **Landlord:** `AllyPaymentController.php`, `WebhookController.php`, `AllyCollectionConfig.php`, `CollectionManagementAllies.php`, `routes/api.php`, migración `iva_amount`

### 3. Producción: fixes aplicados
- `CACHE_STORE=redis` → `/opt/credifacil/tenant-api-credifacil/.env`
- `WEBHOOK_SECRET` faltaba en tenant → agregado
- Tabla `failed_jobs` no existía → migración creada
- Llaves Wompi sandbox → producción (`pub_prod_*`, `prv_prod_*`, `WOMPI_SANDBOX=false`)
- Permisos log landlord dañados por git pull → corregidos (`chown 1337:root`)
- Queue workers: systemd service `credifacil-queues.service` + `restart: unless-stopped` en todos los containers

### 4. Fix generateLink: monto incorrecto
**Problema:** `generateLink` usaba `current_pending_debt` (puede desincronizarse). UI usaba `fetchPendingTransfersFromTenant` (monto real del tenant). Generaba links por monto incorrecto.

**Fix:** `generateLink` ahora llama `fetchPendingTransfersFromTenant($tenantId)` para obtener monto real, sincroniza `current_pending_debt` y llama `reevaluateBlock()`.

---

## Estado actual: PENDIENTE ⚠️

### Botón "Pagar deuda" → Server Error

**Flujo:** Frontend → `POST /api/debt/generate-payment-link` (tenant) → landlord `POST /api/ally-payments/generate-link` → `fetchPendingTransfersFromTenant` → `getTenantData` → `http://host.docker.internal:8021/api/tenants`

**El problema:** `getTenantData` llama a `http://host.docker.internal:8021/api/tenants` y esta ruta da **timeout** en producción. Sin embargo, `http://host.docker.internal:8021/api/health` con Host header sí funciona.

**Lo que hay que investigar:**
1. ¿Qué hace `/api/tenants` en el tenant-api? ¿Requiere autenticación?
2. ¿Por qué funciona `/api/health` pero no `/api/tenants`?
3. Revisar `getTenantData()` en `AllyPaymentController` (línea ~293)

```php
// Línea 293 aprox:
private function getTenantData(string $tenantId): ?array
{
    // llama http://host.docker.internal:8021/api/tenants
    // TIMEOUT en producción
}
```

**Workaround temporal aplicado:** Corrección manual de `current_pending_debt` en BD.

---

## Datos de producción relevantes

| Aliado | tenant_id | current_pending_debt | Estado |
|---|---|---|---|
| Rifaloop | tenant_69a3531463029 | 2000 (manual) | BLOQUEADO |
| Drogas Circasia | tenant_69a34e0501d15 | 3755 (manual) | BLOQUEADO |
| Libercol | tenant_69a3541bc406a | 601412 | BLOQUEADO |

---

## Próximo paso inmediato

Revisar `getTenantData()` en `AllyPaymentController.php` línea ~293 para entender por qué `/api/tenants` da timeout y cómo arreglarlo o reemplazarlo.

```bash
# Ver el método:
grep -A 30 'function getTenantData' landlord-creditapi/app/Http/Controllers/Api/AllyPaymentController.php
```
