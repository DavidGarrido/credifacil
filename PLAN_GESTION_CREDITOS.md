# 📋 Plan: Gestión de Créditos (Editar / Eliminar / Modificar)

**Fecha:** 2026-05-11
**Estado:** Planificación
**Archivo relacionado:** `INSTRUCTIONS_CORRECTION_CREDITS.md`

---

## Objetivo

Reemplazar las correcciones manuales vía SQL directo en producción por una interfaz administrativa dentro del panel landlord que permita editar, modificar y cancelar créditos, sincronizando los cambios automáticamente con los tenants correspondientes.

---

## Arquitectura actual relevante

### Landlord — `credits` table

Campos clave:
- `amount`, `total_limit`, `available_amount` — montos y cupos
- `interest_rate`, `insurance_percentage`, `insurance_amount` — tasa, seguro %
- `term`, `frequency`, `cutoff_day` — plazo, frecuencia, día de corte
- `total_payable`, `installment_amount` — total a pagar, valor cuota
- `status`: `pending` | `active` | `suspended` | `blocked` | `rejected` | `cancelado`

### Landlord — UI existente

| Ruta | Componente | Funcionalidad |
|---|---|---|
| `/credits/pending` | `PendingCredits` | Lista créditos pendientes — aprobar/rechazar |
| `/credits/active` | `ActiveCredits` | Lista créditos activos — habilitar más cupo |
| `/credits/{id}` | `CreditController@show` | Vista detalle: info del crédito, tabla de amortización, transacciones |

**No existe edición ni eliminación de créditos.**

### Tenant — `credit_installments` table

- `landlord_credit_id` — FK lógica al landlord
- `installment_number` — 0 = metadata (config JSON), >0 = cuotas reales
- `principal_amount`, `interest_amount`, `insurance_amount`, `total_amount`
- `paid_amount`, `remaining_amount`, `status`
- Campos adicionales: `paid_at`, `transfer_to_landlord`, `metadata`

### Pagos a comercios (aliados) — `ally_payments` table

Flujo actual cuando un cliente compra:
1. `CreditTransaction` (tipo `purchase`, status `approved`)
2. `AllyPaymentService::schedule()` → crea `AllyPayment` (status `scheduled`)
3. El aliado paga vía Wompi → `AllyPayment.status` → `completed`
4. `AllyCollectionConfig.current_pending_debt` rastrea la deuda neta del aliado

Campos clave de `AllyPayment`:
- `tenant_id`, `landlord_credit_id`, `transaction_id` — vinculación al crédito y transacción
- `sale_amount`, `commission_amount`, `iva_amount`, `amount_paid` — montos
- `scheduled_payment_date` — fecha programada de pago (+1 mes de la compra)
- `status`: `scheduled` | `pending_payment` | `completed` | `failed`
- `wompi_reference`, `payment_link_url` — integración Wompi

⚠️ **Problema:** Si un crédito se cancela o modifica, los `AllyPayment` asociados quedan sin actualizar.

### Comunicación Landlord → Tenant

Vía webhooks HTTP POST con firma HMAC-SHA256:
- `POST /api/webhooks/credit-approved` — crédito aprobado
- `POST /api/webhooks/credit-proposed` — propuesta de compra
- `POST /api/webhooks/credit-updated` — **nuevo** (a implementar)
- `POST /api/webhooks/credit-cancelled` — **nuevo** (a implementar)
- `POST /api/webhooks/installment-updated` — **nuevo** (a implementar)

---

## Plan de implementación

### Fase 1 — Editar configuración del crédito (Landlord)

**Objetivo:** Poder modificar los parámetros financieros de un crédito activo desde el panel admin.

**Campos editables:**
- `interest_rate` (tasa de interés %)
- `insurance_percentage` (% de seguro)
- `insurance_amount` (monto total del seguro)
- `term` (plazo máximo en cuotas)
- `frequency` (diario / semanal / quincenal / mensual)
- `cutoff_day` (día de corte, 1-31)
- `total_limit` (cupo total)
- `available_amount` (cupo disponible)
- `total_payable` (total a pagar)
- `status` (active → suspended / rejected)
- `notes`

**UI:**
- Botón "Editar" en `credit/show.blade.php`
- Modal o página de edición con formulario
- Si cambia `total_limit`, ajustar `available_amount` proporcionalmente
- Si cambia `insurance_percentage`, recalcular `insurance_amount` y `total_payable`

**Backend:**
- Nuevo endpoint: `PUT /credits/{credit}` → `CreditController@update`
- Validar: no permitir editar créditos con status `rejected`
- Registrar cambio como `CreditTransaction` tipo `credit_adjustment` con metadata del before/after

**Archivos:**
- `app/Http/Controllers/CreditController.php` — agregar método `update()`
- `routes/web.php` — agregar ruta `PUT /credits/{credit}`
- `resources/views/credit/show.blade.php` — agregar botón y modal de edición

---

### Fase 2 — Regenerar tabla de amortización en el Tenant

**Objetivo:** Cuando se edita la configuración del crédito en landlord, las cuotas del tenant deben recalcularse automáticamente.

**Tenant — nuevo endpoint:**
```
POST /api/webhooks/credit-updated
```
**Payload:**
```json
{
  "landlord_credit_id": 123,
  "credit_config": {
    "interest_rate": 3.5,
    "insurance_percentage": 15.0,
    "term": 12,
    "frequency": "mensual",
    "cutoff_day": 1
  }
}
```

**Lógica en el tenant:**
1. Mantener `installment_number = 0`: actualizar su `metadata.credit_config`
2. Borrar cuotas `> 0` con status `pendiente`
3. Regenerar cuotas nuevas con los parámetros actualizados
4. No tocar cuotas con status `pagada` o `parcial`

**Landlord — dispatch:**
- Después de guardar los cambios de edición, llamar al webhook del tenant
- Similar a `sendWebhookToTenant()` en `PendingCredits.php`
- Identificar el tenant a partir de `CreditTransaction.tenant_id`

**Archivos:**
- `tenant-api/routes/api.php` — agregar ruta webhook
- `tenant-api/app/Http/Controllers/Api/WebhookController.php` — método `creditUpdated()`
- `tenant-api/app/Services/AmortizationService.php` — servicio de regeneración
- `landlord-creditapi/app/Http/Controllers/CreditController.php` — dispatch al guardar

---

### Fase 3 — Editar cuotas individuales

**Objetivo:** Corregir montos de una cuota específica sin regenerar toda la tabla (ej. seguro mal calculado en una sola cuota).

**Tenant — nuevo endpoint:**
```
POST /api/webhooks/installment-updated
```
**Payload:**
```json
{
  "landlord_credit_id": 123,
  "installment_number": 5,
  "insurance_amount": 15000.00,
  "total_amount": 185000.00
}
```

**Lógica en el tenant:**
- Solo actualiza si la cuota está en status `pendiente`
- No permite modificar cuotas `pagada` o `vencida`

**UI en landlord:**
- En la tabla de amortización de `credit/show.blade.php`
- Botón ✏️ en cada fila → modal inline con campos `insurance_amount` y `total_amount`

**Archivos:**
- `tenant-api/routes/api.php` — agregar ruta
- `tenant-api/app/Http/Controllers/Api/WebhookController.php` — método `installmentUpdated()`
- `resources/views/credit/show.blade.php` — botones y modal inline

---

### Fase 4 — Cancelar crédito

**Objetivo:** Permitir cancelar un crédito completo, marcándolo como rechazado en landlord y notificando al tenant.

**Landlord:**
- Nuevo endpoint: `POST /credits/{credit}/cancel` → `CreditController@cancel`
- Cambia `status` a `'cancelado'` (estado ya existe en el ENUM por migración Libercol)
- Registra `CreditTransaction` tipo `cancellation` con metadata
- Si `available_amount > 0`, se registra en metadata (no se modifica por trazabilidad)

**Tenant:**
```
POST /api/webhooks/credit-cancelled
```
**Payload:**
```json
{
  "landlord_credit_id": 123
}
```

**Lógica en el tenant:**
- Marcar todas las cuotas con status `pendiente` como `cancelada`
- Requiere agregar `cancelada` al ENUM de `credit_installments.status`
- Cuotas ya `pagada` no se modifican

**UI:**
- Botón "Cancelar crédito" (rojo) en `credit/show.blade.php`
- Modal de confirmación: "¿Está seguro? Esta acción no se puede deshacer."

**Archivos:**
- `app/Http/Controllers/CreditController.php` — método `cancel()`
- `routes/web.php` — ruta `POST /credits/{credit}/cancel`
- `tenant-api/database/migrations/tenant/` — migración para agregar `cancelada` al ENUM
- `tenant-api/routes/api.php` — ruta webhook
- `tenant-api/app/Http/Controllers/Api/WebhookController.php` — método `creditCancelled()`
- `resources/views/credit/show.blade.php` — botón y modal

---

### Fase 5 — UI integrada

**Modificaciones a `credit/show.blade.php`:**

```
┌─────────────────────────────────────────────────┐
│  Crédito #123                      [Editar] [Cancelar]  │
│  ─────────────────────────────────────────────── │
│  Cliente: Juan Pérez (CC 123456)                 │
│  Cupo total: $5,000,000  |  Disponible: $2,100,000 │
│  Tasa: 3.5%  |  Seguro: 15%  |  Plazo: 12 cuotas │
│  Frecuencia: mensual  |  Corte: día 1            │
│  Estado: Activo                                  │
├─────────────────────────────────────────────────┤
│  Tabla de Amortización                          │
│  ┌──────────────────────────────────────────┐   │
│  │ # │ Vencimiento │ Capital │ ... │ Total │ ✏️ │   │
│  │ 1 │ 01/06/2026  │ 416,667 │ ... │ 520k  │ ✏️ │   │
│  │ 2 │ 01/07/2026  │ 416,667 │ ... │ 520k  │ ✏️ │   │
│  └──────────────────────────────────────────┘   │
│                                                 │
│  [Regenerar cuotas con nueva configuración]      │
├─────────────────────────────────────────────────┤
│  Transacciones                                  │
│  ...                                            │
└─────────────────────────────────────────────────┘
```

---

### Fase 6 — Gestión de pagos a comercios al cancelar/editar crédito

**Objetivo:** Cuando se cancela o modifica un crédito, actualizar o cancelar los pagos programados a los comercios (aliados) vinculados a ese crédito.

**A. Al cancelar un crédito:**

Landlord:
- Buscar todos los `AllyPayment` con `landlord_credit_id` del crédito cancelado
- Para los que están `scheduled` o `pending_payment`: cambiar status a `failed` y registrar metadata `{cancelled_reason: 'credit_cancelled', cancelled_at: '...'}`
- Para los que ya están `completed`: no modificar (el pago ya se hizo)
- Recalcular `AllyCollectionConfig.current_pending_debt` llamando a `reevaluateBlock()`

**B. Al editar montos del crédito (`total_limit`, `available_amount`):**

- Si el crédito sigue activo y los `AllyPayment` están `scheduled`, actualizar `sale_amount` proporcionalmente si cambia el cupo total
- Opción conservadora: no modificar pagos existentes, solo registrar el cambio en metadata para auditoría

**C. UI en `credit/show.blade.php`:**

En la sección de transacciones, cada `CreditTransaction` tipo `purchase` ya está vinculada a un `AllyPayment` vía `transaction_id`. Mostrar:
- Estado del pago al comercio: `scheduled` / `completed` / `failed`
- Monto neto a pagar al aliado
- Fecha programada de pago
- Si el crédito se cancela, mostrar warning: "Hay X pagos a comercios programados que serán cancelados"

**D. Nuevo endpoint (landlord):**

```
GET /credits/{credit}/ally-payments
```
Retorna todos los `AllyPayment` vinculados al crédito con su estado actual.

**Archivos:**
- `landlord-creditapi/app/Http/Controllers/CreditController.php` — agregar `allyPayments()` y lógica en `cancel()`
- `landlord-creditapi/routes/web.php` — ruta `GET /credits/{credit}/ally-payments`
- `landlord-creditapi/resources/views/credit/show.blade.php` — columna de pagos a aliados

---

### Fase 7 — Correcciones en reportes para créditos cancelados

**Objetivo:** Asegurar que el dashboard financiero y los reportes reflejen correctamente los créditos cancelados, corrigiendo bugs existentes y adaptando las queries al nuevo estado `'cancelado'`.

**🐛 Bugs encontrados en reportería actual:**

| Archivo | Línea | Bug | Impacto |
|---|---|---|---|
| `ReportCacheService.php` | 128 | `whereIn('status', ['active', 'approved', 'pending_payment'])` | `'approved'` y `'pending_payment'` **no existen** en el ENUM de `credits` — son estados de `CreditTransaction`. Solo devuelve créditos `active` |
| `ReportCacheService.php` | 222 | Mismo bug en `rebuildCreditSummaries()` | Solo cachea créditos `active` |
| `DashboardReport.php` | 112 | Mismo bug en `getCreditsDistribution()` | Solo muestra créditos `active` en la distribución |

El ENUM real de `credits.status` (según migraciones):
```
'pending', 'active', 'suspended', 'blocked', 'rejected'
(+ 'cancelado', 'pendiente', 'activo', 'pagado', 'vencido' de Libercol — presentes en BD pero no usados en código)
```

**A. Corrección de queries de reporte:**

Corregir los 3 lugares para usar estados reales:

```php
// Antes (bug)
Credit::whereIn('status', ['active', 'approved', 'pending_payment'])

// Después
Credit::where('status', 'active')  // Solo créditos activos para métricas financieras
```

Si se quiere incluir créditos `pending` (pendientes de aprobación que ya tienen monto asignado):
```php
Credit::whereIn('status', ['active', 'pending'])
```

**B. Exclusión de créditos cancelados de métricas activas:**

| Métrica | Comportamiento con crédito `cancelado` |
|---|---|
| `capital_comprometido` | ✅ Se excluye — `where('status', 'active')` no lo incluye |
| `capital_en_uso` | ✅ Se excluye |
| `capital_libre` | ✅ Aumenta — se libera el capital que estaba comprometido |
| `intereses_proyectados` | ✅ Se excluyen — los intereses de un crédito cancelado no se cobrarán |
| `total_recaudado` | ✅ No afecta — `AllyPayment` completed no se modifican |
| `total_pendiente_cobro` | ✅ Se recalcula vía `reevaluateBlock()` al cancelar AllyPayments |
| `cartera_en_riesgo` | ✅ El crédito sale de cartera — sus cuotas `pendiente` pasan a `cancelada` |
| Proyección flujo de caja | ✅ Los `AllyPayment` `scheduled` → `failed` ya no se proyectan |

**C. Nueva sección en dashboard: "Créditos Cancelados" (opcional):**

Si se desea trazabilidad, agregar un contador o tabla de créditos cancelados en el período:

```php
$creditosCancelados = Credit::where('status', 'cancelado')
    ->where('updated_at', '>=', now()->subDays(30))
    ->count();
```

Mostrar en el dashboard como KPI secundario (sin afectar métricas principales).

**D. Invalidación del cache de reportes:**

Después de cancelar un crédito, forzar reconstrucción del cache:
```php
$this->reportService->invalidate();  // Ya existe en DashboardReport::refreshCache()
```

Llamar desde `CreditController::cancel()`:
```php
app(ReportCacheService::class)->invalidate();
```

**E. Actualizar `credit_installments` ENUM en tenant:**

Agregar `'cancelada'` al ENUM de `credit_installments.status`:
```sql
ALTER TABLE credit_installments MODIFY COLUMN status 
ENUM('pendiente', 'pending_user_acceptance', 'pagada', 'vencida', 'parcial', 'cancelada') 
DEFAULT 'pendiente';
```

**Archivos:**
- `landlord-creditapi/app/Services/ReportCacheService.php` — corregir `whereIn` (líneas 128, 222)
- `landlord-creditapi/app/Livewire/DashboardReport.php` — corregir `whereIn` (línea 112)
- `landlord-creditapi/app/Http/Controllers/CreditController.php` — llamar `invalidate()` en `cancel()`
- `tenant-api/database/migrations/tenant/` — migración para agregar `'cancelada'` al ENUM

---

## ⚠️ Restricciones y reglas de negocio

| Acción | Permitido si | Bloqueado si |
|---|---|---|
| Editar configuración | `status` = `active` o `pending` | `status` = `rejected` |
| Regenerar cuotas | `status` = `active`, hay cuotas sin pagar | todas las cuotas `pagada` |
| Editar cuota individual | cuota `pendiente` | cuota `pagada` o `vencida` |
| Cancelar crédito | `status` ≠ `cancelado` ni `rejected` | — |
| Cancelar pago a aliado | AllyPayment `scheduled` o `pending_payment` | AllyPayment `completed` |

---

## 📁 Resumen de archivos a crear/modificar

| Archivo | Tipo | Fase |
|---|---|---|
| `landlord-creditapi/app/Http/Controllers/CreditController.php` | Editar | 1, 4, 6, 7 |
| `landlord-creditapi/routes/web.php` | Editar | 1, 4 |
| `landlord-creditapi/resources/views/credit/show.blade.php` | Editar | 1, 3, 4, 5 |
| `landlord-creditapi/app/Livewire/CreditEdit.php` | Nuevo | 1 |
| `landlord-creditapi/app/Services/ReportCacheService.php` | Editar | 7 |
| `landlord-creditapi/app/Livewire/DashboardReport.php` | Editar | 7 |
| `tenant-api/routes/api.php` | Editar | 2, 3, 4 |
| `tenant-api/app/Http/Controllers/Api/WebhookController.php` | Editar | 2, 3, 4 |
| `tenant-api/app/Services/AmortizationService.php` | Nuevo | 2 |
| `tenant-api/database/migrations/tenant/` | Nuevo | 4 |
| `landlord-creditapi/app/Models/AllyPayment.php` | Editar | 6 |

---

## 🔄 Flujo de despliegue

1. Implementar cambios en `landlord-creditapi` y `tenant-api` localmente
2. Commit y push a GitHub (`DavidGarrido/landlord-creditapi`)
3. SSH a Hostinger: `ssh -i ~/.ssh/id_rsa root@187.124.232.145`
4. `git pull` en `/opt/credifacil/landlord-creditapi` y `/opt/credifacil/tenant-api-credifacil`
5. Ejecutar migraciones en ambos contenedores
6. `view:clear` y `config:clear`
7. `npm run build` en landlord (admin assets)

---

## 📝 Notas

- Todas las acciones deben registrar `CreditTransaction` con metadata `{action: 'edit'|'cancel'|'regenerate', admin: '...', changes: {...}}` para trazabilidad
- La "cuota 0" (`installment_number = 0`) NUNCA debe eliminarse — solo actualizarse
- Los webhooks usan firma HMAC-SHA256 (`X-Webhook-Signature`) para autenticación
- El tenant usa `Host` header para identificar el dominio en el proxy de Nginx
- Los pagos a aliados (`AllyPayment`) están vinculados al crédito vía `landlord_credit_id` y `transaction_id`. Cualquier modificación al crédito debe reflejarse en estos registros
- `AllyCollectionConfig.reevaluateBlock()` debe llamarse después de cualquier cambio en `AllyPayment` para mantener actualizado el estado de bloqueo del aliado
- **Bug corregido (Fase 7):** `ReportCacheService` y `DashboardReport` usaban `whereIn('status', ['active', 'approved', 'pending_payment'])` donde `'approved'` y `'pending_payment'` no existen en el ENUM de `credits`. Se corrige a `where('status', 'active')`
- El cache de reportes DEBE invalidarse (`ReportCacheService::invalidate()`) después de cancelar un crédito para que las métricas reflejen la liberación de capital
