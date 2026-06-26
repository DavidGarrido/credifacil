# Snapshots Multi-tenant — Resumen de Créditos por Tenant

> **Fecha:** 24 de junio de 2026
> **Propósito:** Documentar la solución para consultar el estado de créditos de un cliente cuando tiene transacciones en múltiples tenants (comercios), sin replicar cuotas individuales ni consultar N bases de datos.

---

## 1. El Problema

Un cliente tiene un **crédito único** en el landlord con un límite global (`total_limit`, `available_amount`). Pero puede hacer compras en **múltiples comercios (tenants)**, y cada comercio guarda sus propias cuotas (`credit_installments`) en su propia base de datos.

```
Landlord DB (central)
└── credits
    ├── client_id: 123
    ├── total_limit: $1.000.000
    └── available_amount: $300.000

Tenant A DB (comercio-a)
└── credit_installments (landlord_credit_id: 1)
    ├── nro 1 | $50.000 | pendiente
    ├── nro 2 | $50.000 | pagada
    └── nro 3 | $50.000 | pendiente

Tenant B DB (comercio-b)
└── credit_installments (landlord_credit_id: 1)
    ├── nro 1 | $100.000 | pendiente
    ├── nro 2 | $100.000 | pendiente
    └── nro 3 | $100.000 | pendiente
```

**El problema:** No hay una tabla que diga "este crédito debe $150.000 en Tenant A y $300.000 en Tenant B". Para saberlo hoy, habría que consultar HTTP a cada tenant.

### ¿Por qué no funciona replicar todas las cuotas en landlord?

- Las cuotas individuales son datos transaccionales pesados
- Se duplicaría información que ya está en cada tenant
- Mayor complejidad de sincronización
- Mayor riesgo de inconsistencias

---

## 2. La Solución: Tabla de Snapshots

Crear una tabla **ligera de resúmenes** en el landlord, una fila por cada (crédito, tenant), que se actualiza vía los webhooks que **ya existen**.

### 2.1 Estructura de la tabla

```sql
CREATE TABLE credit_tenant_snapshots (
    id                   BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    credit_id            BIGINT UNSIGNED NOT NULL,      -- FK → credits
    tenant_id            VARCHAR(255) NOT NULL,          -- comercio-a, comercio-b

    -- Resumen de cuotas (conteos)
    total_installments   INT NOT NULL DEFAULT 0,
    paid_installments    INT NOT NULL DEFAULT 0,
    pending_installments INT NOT NULL DEFAULT 0,
    overdue_installments INT NOT NULL DEFAULT 0,

    -- Montos agregados
    total_amount         DECIMAL(12,2) NOT NULL DEFAULT 0,
    paid_amount          DECIMAL(12,2) NOT NULL DEFAULT 0,
    pending_amount       DECIMAL(12,2) NOT NULL DEFAULT 0,

    -- Próximo vencimiento
    next_due_date        DATE NULL,
    next_due_amount      DECIMAL(12,2) NOT NULL DEFAULT 0,

    -- Control de sincronización
    last_sync_at         TIMESTAMP NULL,   -- cuándo se actualizó por última vez
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (credit_id) REFERENCES credits(id) ON DELETE CASCADE,
    UNIQUE KEY uniq_credit_tenant (credit_id, tenant_id),

    -- Índices para consulta
    INDEX idx_credit_id (credit_id),
    INDEX idx_tenant_id (tenant_id),
    INDEX idx_next_due (next_due_date)
);
```

### 2.2 Modelo en Laravel

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CreditTenantSnapshot extends Model
{
    protected $fillable = [
        'credit_id',
        'tenant_id',
        'total_installments',
        'paid_installments',
        'pending_installments',
        'overdue_installments',
        'total_amount',
        'paid_amount',
        'pending_amount',
        'next_due_date',
        'next_due_amount',
        'last_sync_at',
    ];

    protected $casts = [
        'total_installments'   => 'integer',
        'paid_installments'    => 'integer',
        'pending_installments' => 'integer',
        'overdue_installments' => 'integer',
        'total_amount'         => 'decimal:2',
        'paid_amount'          => 'decimal:2',
        'pending_amount'       => 'decimal:2',
        'next_due_amount'      => 'decimal:2',
        'next_due_date'        => 'date',
        'last_sync_at'         => 'datetime',
    ];

    public function credit()
    {
        return $this->belongsTo(Credit::class);
    }
}
```

### 2.3 Relación en Credit

```php
// En app/Models/Credit.php
public function tenantSnapshots()
{
    return $this->hasMany(CreditTenantSnapshot::class);
}
```

---

## 3. Flujo de Datos

### 3.1 Escritura: Cómo se actualiza la snapshot

Cada vez que un tenant genera un cambio en sus cuotas, envía un webhook al landlord con un **bloque `snapshot`** adicional.

```
Tenant → POST /api/webhooks/installment-updated → Landlord
                              │
                              ▼
                    WebhookController@handleInstallmentUpdated
                              │
                              ├── 1. Procesar negocio (lo que ya hace)
                              │
                              └── 2. Guardar/actualizar snapshot
                                   CreditTenantSnapshot::updateOrCreate(
                                       { credit_id, tenant_id },
                                       { total_installments, paid_amount, ...,
                                         last_sync_at: now() }
                                   )
```

#### Webhooks que deben incluir snapshot

| Webhook | Cuándo se dispara | Datos del snapshot |
|---|---|---|
| `installment-updated` | Se paga o actualiza una cuota individual | Resumen recalculado |
| `credit-approved` | Se aprueba una compra y se generan cuotas | Nuevas cuotas creadas |
| `credit-cancelled` | Se cancela un crédito | Cuotas restantes = 0 |
| `client-payment-received` | Pago registrado | paid_amount +1, pending_amount -1 |

#### Ejemplo de payload con snapshot

```json
// POST /api/webhooks/installment-updated
{
    "landlord_credit_id": 1,
    "landlord_transaction_id": 5,
    "installment_id": 12,
    "installment_number": 2,
    "status": "pagada",
    "amount_paid": 50000.00,
    "tenant_id": "comercio-a",

    "snapshot": {
        "total_installments": 3,
        "paid_installments": 1,
        "pending_installments": 2,
        "overdue_installments": 0,
        "total_amount": 150000.00,
        "paid_amount": 50000.00,
        "pending_amount": 100000.00,
        "next_due_date": "2026-08-15",
        "next_due_amount": 50000.00
    }
}
```

#### Lógica en el tenant para generar el snapshot

```php
// En el tenant, antes de enviar el webhook
private function buildSnapshot(int $landlordCreditId): array
{
    $installments = CreditInstallment::where('landlord_credit_id', $landlordCreditId)
        ->where('installment_number', '>', 0)
        ->get();

    $pendings = $installments->whereIn('status', ['pendiente', 'parcial']);
    $nextPayment = $pendings->sortBy('due_date')->first();

    return [
        'total_installments'   => $installments->count(),
        'paid_installments'    => $installments->where('status', 'pagada')->count(),
        'pending_installments' => $pendings->count(),
        'overdue_installments' => $installments->where('status', 'vencida')->count(),
        'total_amount'         => $installments->sum('total_amount'),
        'paid_amount'          => $installments->sum('paid_amount'),
        'pending_amount'       => $installments->sum('remaining_amount'),
        'next_due_date'        => $nextPayment?->due_date?->format('Y-m-d'),
        'next_due_amount'      => (float) ($nextPayment?->total_amount ?? 0),
    ];
}
```

### 3.2 Lectura: Cómo se consulta

#### Endpoint para el dashboard del cliente

```php
// Landlord — GET /api/client/credits/{creditId}/summary
// o incluido en GET /api/client/credits (ya existe ClientCreditController)

public function summary(Request $request, int $creditId): JsonResponse
{
    $clientToken = $request->attributes->get('client_token');

    // Verificar ownership
    // ...

    $credit = Credit::with('tenantSnapshots')
        ->with('client')
        ->findOrFail($creditId);

    return response()->json([
        'success' => true,
        'data'    => [
            'credit' => [
                'id'               => $credit->id,
                'total_limit'      => (float) $credit->total_limit,
                'available_amount' => (float) $credit->available_amount,
                'status'           => $credit->status,
            ],
            'client' => [
                'name' => $credit->client->full_name,
            ],
            'tenants' => $credit->tenantSnapshots->map(fn($s) => [
                'tenant_id'           => $s->tenant_id,
                'total_installments'  => $s->total_installments,
                'paid_installments'   => $s->paid_installments,
                'pending_installments'=> $s->pending_installments,
                'overdue_installments'=> $s->overdue_installments,
                'pending_amount'      => (float) $s->pending_amount,
                'paid_amount'         => (float) $s->paid_amount,
                'next_due_date'       => $s->next_due_date?->format('Y-m-d'),
                'next_due_amount'     => (float) $s->next_due_amount,
                'last_sync_at'        => $s->last_sync_at?->toIso8601String(),
            ]),
            'summary' => [
                'total_pending'    => $credit->tenantSnapshots->sum('pending_amount'),
                'total_paid'       => $credit->tenantSnapshots->sum('paid_amount'),
                'total_overdue'    => $credit->tenantSnapshots->sum('overdue_installments'),
                'next_due_date'    => $credit->tenantSnapshots
                    ->where('next_due_date', '>=', now())
                    ->sortBy('next_due_date')
                    ->first()?->next_due_date?->format('Y-m-d'),
                'next_due_amount'  => $credit->tenantSnapshots
                    ->where('next_due_date', '>=', now())
                    ->sortBy('next_due_date')
                    ->first()?->next_due_amount ?? 0,
                'updated_at'       => $credit->tenantSnapshots
                    ->max('last_sync_at')?->toIso8601String(),
            ],
        ],
    ]);
}
```

**Una sola consulta SQL:**
```sql
SELECT * FROM credit_tenant_snapshots
WHERE credit_id = 1;
-- Resultado: 2 filas (comercio-a, comercio-b)
-- Tiempo: < 1ms
```

#### Contraparte en el Tenant (para drill-down a cuotas individuales)

```php
// Tenant — GET /api/installments/amortization/{creditId}
// Ya existe en PurchaseRequestController@getAmortizationTable
// Se consulta solo cuando el cliente hace clic en "Ver cuotas"
```

---

## 4. Vistas del Cliente y Datos

### 4.1 Dashboard

```
┌─────────────────────────────────────────────┐
│ 👋 Hola, Juan                               │
│                                             │
│ ┌──────────┐ ┌──────────┐ ┌──────────────┐ │
│ │ 💰       │ │ 📊       │ │ 🏪           │ │
│ │ $300.000 │ │ $450.000 │ │ 2 comercios  │ │
│ │Disp.     │ │Pendiente │ │              │ │
│ └──────────┘ └──────────┘ └──────────────┘ │
│                                             │
│ 📅 Próximo pago: 15 jul · $50.000          │
│                                             │
│ ── Resumen por comercio ──                  │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ 🏪 Comercio A                           │ │
│ │  Pendiente: $150.000 · 2/3 cuotas       │ │
│ │  Próximo: 15 jul → $50.000              │ │
│ │  Última act: hoy 10:30                  │ │
│ ├─────────────────────────────────────────┤ │
│ │ 🏪 Comercio B                           │ │
│ │  Pendiente: $300.000 · 3/3 cuotas       │ │
│ │  Próximo: 20 jul → $100.000             │ │
│ │  Última act: hoy 09:15                  │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

| Dato | Fuente |
|---|---|
| `clientName` | `clients.full_name` (landlord) |
| `availableAmount` | `credits.available_amount` (landlord) |
| `grandTotalPending` | `SUM(snapshots.pending_amount)` |
| `tenantCount` | `COUNT(snapshots.tenant_id)` |
| `nextDueDate`, `nextDueAmount` | `MIN(snapshots.next_due_date)` con su monto |
| Por tenant: `pending_amount` | `snapshots.pending_amount` |
| Por tenant: `installments_count` | `snapshots.pending_installments / total_installments` |
| Por tenant: `next_due_date/amount` | `snapshots.next_due_date` |
| `last_sync_at` | `MAX(snapshots.last_sync_at)` |

### 4.2 Detalle del Crédito

```
Crédito CrediFácil
Límite: $1.000.000 · Disponible: $300.000
Estado: Activo · Actualizado: hoy 10:30

── Compras por comercio ──

🏪 Comercio A
  3 cuotas · $50.000 c/u · Total: $150.000
  Pagado: $50.000 · Pendiente: $100.000  [Ver cuotas →]
  Próximo: 15 jul · $50.000

🏪 Comercio B
  3 cuotas · $100.000 c/u · Total: $300.000
  Pagado: $0 · Pendiente: $300.000       [Ver cuotas →]
  Próximo: 20 jul · $100.000
```

| Dato | Fuente |
|---|---|
| Resumen por tenant | `snapshots` (1 query) |
| Cuotas individuales (drill-down) | HTTP al tenant → `GET /api/installments/amortization/{creditId}` |

### 4.3 Historial de Transacciones

```
Filtro: [Todos | Comercio A | Comercio B]

10 jun · Compra           · $600.000 · Comercio B
 3 jun · Compra           · $300.000 · Comercio A
20 jun · Pago · Cuota 1/3 · $200.000 · Comercio B
15 jun · Pago · Cuota 1/3 ·  $50.000 · Comercio A
```

| Dato | Fuente |
|---|---|
| Todas las transacciones | `credit_transactions` (landlord) — ya tiene `tenant_id` |

### 4.4 Perfil

| Dato | Fuente |
|---|---|
| Nombre, cédula, email, teléfono | `clients` (landlord) |
| Cerrar sesión | ClientAuth |

---

## 5. Plan de Implementación

### Fase 1: Landlord (backend)

| Paso | Archivo | Descripción |
|---|---|---|
| 1.1 | `database/migrations/xxxx_create_credit_tenant_snapshots_table.php` | Crear la tabla |
| 1.2 | `app/Models/CreditTenantSnapshot.php` | Modelo |
| 1.3 | `app/Models/Credit.php` | Agregar `tenantSnapshots()` relación |
| 1.4 | `app/Http/Controllers/Api/WebhookController.php` | Agregar lógica para procesar snapshot en cada webhook |
| 1.5 | `routes/api.php` | Endpoint `GET /client/credits/{id}/summary` |

### Fase 2: Tenant (backend)

| Paso | Archivo | Descripción |
|---|---|---|
| 2.1 | `app/Http/Controllers/Api/WebhookController.php` | Agregar método `buildSnapshot()` y enviarlo en cada webhook |
| 2.2 | Webhooks afectados | `creditApproved`, `installmentUpdated`, `clientPaymentReceived`, `creditCancelled` |

### Fase 3: Ionic (frontend)

| Paso | Archivo | Descripción |
|---|---|---|
| 3.1 | `src/app/services/credit.ts` | Método `getCreditSummary(creditId)` que consuma el nuevo endpoint |
| 3.2 | `src/app/pages/dashboard/dashboard.component.ts` | Mostrar lista de tenants con resumen |
| 3.3 | `src/app/pages/credits/detail/detail.component.ts` | Mostrar desglose por tenant + botón "Ver cuotas" |
| 3.4 | `src/app/pages/transactions/transactions.component.ts` | Filtro por tenant (usando `tenant_id` de `credit_transactions`) |

---

## 6. Comparación con Alternativas

| Alternativa | Ventajas | Desventajas |
|---|---|---|
| **Snapshot** (elegida) | 1 query, tiempo real vía webhooks, liviana | Mantener sincronización vía webhooks |
| **Consultar cada tenant vía HTTP** | Sin tabla nueva | N queries, latencia, caída de un tenant afecta |
| **Replicar cuotas en landlord** | Consulta local siempre | Dato duplicado, migración masiva, riesgo inconsistencia |
| **Vista materializada** | Sin código en tenants | Complejidad de BD, no funciona con DB separadas |

---

## 7. Impacto en Arquitectura

```
ANTES (el cliente ve solo su tenant actual):
    Ionic → Tenant A → Landlord (balance)
         ↳ solo ve cuotas de Tenant A
         ↳ no sabe que debe en Tenant B

DESPUÉS (el cliente ve todo):
    Ionic → Landlord (balance + snapshots)
         ↳ ve resumen de Tenant A + Tenant B
         ↳ hace drill-down HTTP al tenant específico
```

### Relación con el portal del cliente

Si el cliente se autentica en el **subdominio de un comercio** específico (como hoy), la snapshot permite que el dashboard muestre los otros comercios donde también tiene deuda.

Si en el futuro se crea un **portal unificado** (`app.credifacilcolombia.com`), la snapshot ya tiene toda la data lista en una sola tabla.

---

## 8. Documentación Relacionada

- `SISTECREDITO_COMPARATIVA.md` — Estudio de Sistecredito y plan de features
- `CREDIT_FLOW.md` — Flujo de créditos
- `DATABASE_STRUCTURE.md` — Estructura de BD actual
