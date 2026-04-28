# Plan: Pago de Deuda al Landlord desde el Frontend Tenant

## Objetivo
Permitir que un aliado (tenant) vea su estado de deuda y pague directamente desde su
frontend, generando un link de Wompi a través del landlord. Al pagar, el sistema
habilita automáticamente las ventas y cobros.

---

## Contexto del flujo actual

```
Frontend Tenant → Tenant API → Landlord API → Wompi
                                    ↑
                         generatePaymentLink() (Livewire)
                         ya existe en CollectionManagementAllies
```

El método `generatePaymentLink()` en el landlord:
1. Consulta la deuda pendiente del tenant via tenant API
2. Crea un `AllyPayment` con status `pending_payment`
3. Llama a `WompiService::createPaymentLink()` y obtiene la URL
4. Devuelve la URL de Wompi

---

## Corrección previa requerida (bug detectado)

**Archivo:** `landlord-creditapi/app/Http/Controllers/Api/WebhookController.php`
**Método:** `handleWompiPayment()`

Después de reducir `current_pending_debt` al recibir el pago de Wompi, falta llamar
`reevaluateBlock()` para re-habilitar ventas y cobros automáticamente:

```php
// Línea ~233 — después de $config->save():
$config->reevaluateBlock();
```

Sin esto, aunque el aliado pague, `sales_enabled` y `payments_enabled` quedan en
`false` indefinidamente.

---

## Punto 1 — Botón de pago de deuda en Frontend Tenant

### 1.1 Nuevo endpoint en Landlord API

**Archivo:** `landlord-creditapi/routes/api.php`

```
POST /api/ally-payments/generate-link
```

**Archivo:** `landlord-creditapi/app/Http/Controllers/Api/AllyPaymentController.php`

Nuevo método `generateLink(Request $request)`:
- Recibe: `tenant_id`
- Reutiliza la lógica de `CollectionManagementAllies::generatePaymentLink()`:
  1. Consulta deuda pendiente via `fetchPendingTransfersFromTenant()`
  2. Si deuda > 0: crea `AllyPayment` + llama `WompiService::createPaymentLink()`
  3. Devuelve: `{ payment_link_url, amount, reference }`
- Si ya existe un `AllyPayment` con status `pending_payment` para el tenant,
  reutiliza ese link en lugar de crear uno nuevo

### 1.2 Nuevo endpoint proxy en Tenant API

**Archivo:** `tenant-api/routes/tenant.php`

```
POST /api/debt/generate-payment-link
```

**Archivo:** `tenant-api/app/Http/Controllers/Api/DebtController.php` (nuevo)

Método `generatePaymentLink(Request $request)`:
- Obtiene `tenant_id` desde `tenant('id')`
- Hace POST al landlord: `/api/ally-payments/generate-link`
- Devuelve la respuesta con `payment_link_url` al frontend

### 1.3 Nuevo método en `frontend/src/services/api.js`

```js
async generateDebtPaymentLink() {
  // POST /api/debt/generate-payment-link
  // Devuelve { payment_link_url, amount }
}
```

### 1.4 Componente frontend `DebtWarning.jsx` (nuevo)

Condiciones para mostrar:
- `permissions.sales_enabled === false` O `permissions.payments_enabled === false`

Contenido:
```
⚠️ Has superado el límite de deuda con Credifácil.
   Debes transferir $XXX para continuar vendiendo y cobrando.

[💳 Pagar ahora]
```

Al hacer clic en "Pagar ahora":
1. Llama a `api.generateDebtPaymentLink()`
2. Muestra modal con el monto a pagar
3. Redirige a `payment_link_url` (Wompi) en nueva pestaña

### 1.5 Integración en el layout del tenant

**Archivo:** `frontend/src/components/Layout.jsx` o `Sidebar.jsx`

- Al cargar, consultar `/api/company-documentation/permissions`
- Si `sales_enabled === false`, renderizar `<DebtWarning />` en la parte superior
  de todas las páginas (banner persistente)

---

## Punto 2 — Advertencia de límite superado en Frontend Tenant

### Banner persistente en todas las páginas

**Archivo:** `frontend/src/components/Layout.jsx`

```jsx
{!permissions.sales_enabled && (
  <div className="bg-red-50 border-l-4 border-red-500 p-4">
    <div className="flex items-center justify-between">
      <div>
        <p className="text-red-800 font-semibold">
          ⚠️ Ventas y cobros bloqueados
        </p>
        <p className="text-red-600 text-sm">
          Superaste el límite de deuda con Credifácil.
          Realiza el pago para continuar vendiendo y cobrando.
        </p>
      </div>
      <button onClick={handleGeneratePaymentLink}
              className="bg-red-600 text-white px-4 py-2 rounded-md text-sm">
        💳 Pagar deuda
      </button>
    </div>
  </div>
)}
```

### Bloqueo visual en PurchaseRequest y PaymentsPage

- `PurchaseRequest.jsx`: si `!sales_enabled`, mostrar overlay con mensaje de bloqueo
  en lugar del formulario de venta
- `PaymentsPage.jsx`: si `!payments_enabled`, ya tiene "Recaudo Deshabilitado" —
  agregar botón "Pagar deuda" que llame al mismo flujo

---

## Flujo completo

```
1. Cliente paga cuota a Libercol
2. PaymentService → InstallmentPaid event → NotifyLandlordOfPayment listener
3. Webhook POST /api/webhooks/tenant-payment-received al landlord
4. Landlord: current_pending_debt += amount → reevaluateBlock()
5. Si current_pending_debt >= max_pending_debt:
   → sales_enabled = false, payments_enabled = false
6. Frontend tenant consulta /permissions → muestra banner de deuda
7. Tenant hace clic en "Pagar deuda"
8. Frontend → Tenant API POST /api/debt/generate-payment-link
9. Tenant API → Landlord API POST /api/ally-payments/generate-link
10. Landlord crea AllyPayment + genera link Wompi
11. Frontend redirige al tenant a Wompi
12. Tenant paga en Wompi
13. Wompi → Webhook POST /api/webhooks/wompi al landlord
14. Landlord: AllyPayment status = completed
              current_pending_debt -= amount_paid
              reevaluateBlock()  ← (corrección del bug)
15. Si current_pending_debt < max_pending_debt:
    → sales_enabled = true, payments_enabled = true
16. Frontend tenant consulta /permissions → banner desaparece
    → puede vender y cobrar nuevamente
```

---

## Archivos a crear/modificar

| Archivo | Acción |
|---|---|
| `landlord-creditapi/app/Http/Controllers/Api/AllyPaymentController.php` | Agregar método `generateLink()` |
| `landlord-creditapi/app/Http/Controllers/Api/WebhookController.php` | Agregar `reevaluateBlock()` en `handleWompiPayment()` |
| `landlord-creditapi/routes/api.php` | Agregar ruta `POST /ally-payments/generate-link` |
| `tenant-api/app/Http/Controllers/Api/DebtController.php` | Crear nuevo controlador |
| `tenant-api/routes/tenant.php` | Agregar ruta `/debt/generate-payment-link` |
| `frontend/src/services/api.js` | Agregar `generateDebtPaymentLink()` |
| `frontend/src/components/DebtWarning.jsx` | Crear componente nuevo |
| `frontend/src/components/Layout.jsx` | Integrar `DebtWarning` y consulta de permisos |
| `frontend/src/components/PurchaseRequest.jsx` | Agregar bloqueo visual si `!sales_enabled` |
