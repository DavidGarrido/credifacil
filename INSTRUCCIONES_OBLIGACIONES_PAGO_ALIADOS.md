# Instrucciones para Implementar: Obligaciones de Pago a Aliados

## Contexto del Proyecto

Sistema multi-tenant de créditos (CrediFácil):
- **landlord-creditapi**: API central (Laravel, puerto 8020)
- **tenant-api**: API de aliados (Laravel, puerto 8021)

## Objetivo

Mostrar en el módulo "Cobranza Aliados" (`/collections/allies`) las obligaciones de pago que landlord debe a los aliados por ventas realizadas.

Actualmente el módulo muestra:
- ✅ Lo que los aliados deben a landlord (transferencias pendientes)
- ❌ Lo que landlord debe a los aliados (obligaciones de pago) - **FALTA IMPLEMENTAR**

## Datos Existentes en Base de Datos

### Tabla `credit_transactions` (landlord)
Contiene las ventas/transacciones de cada aliado:
```sql
SELECT id, credit_id, tenant_id, amount, status, created_at
FROM credit_transactions
WHERE tenant_id != 'landlord' AND status = 'approved';
```

Ejemplo de datos actuales:
| id | tenant_id | amount | created_at |
|----|-----------|--------|------------|
| 5 | tenant_695fd35066fb8 (Cafe JC) | 200000.00 | 2026-01-16 |
| 4 | tenant_695fd35066fb8 (Cafe JC) | 119999.98 | 2026-01-14 |
| 3 | tenant_69208a3194d34 (Coindraw) | 150000.00 | 2026-01-14 |
| 1 | tenant_695fd35066fb8 (Cafe JC) | 300000.00 | 2026-01-14 |

### Tabla `ally_payments` (landlord)
Registra pagos ya realizados o programados a aliados:
```sql
-- Campos existentes:
-- id, tenant_id, landlord_credit_id, transaction_id, sale_amount,
-- commission_percentage, commission_amount, amount_paid,
-- scheduled_payment_date, payment_method, payment_date, status
```

### Tabla `ally_collection_configs` (landlord)
Configuración por aliado con campos relevantes:
- `tenant_id`: ID del tenant
- `payment_term_months`: Plazo en meses para pagar al aliado
- `commission_percentage`: Porcentaje de comisión a descontar

## Lógica de Negocio

1. **Obligación de pago** = Cada registro en `credit_transactions` donde `tenant_id != 'landlord'`
2. **Ya pagado** = Existe en `ally_payments` con mismo `transaction_id` y `status = 'completed'`
3. **Pendiente** = Transacción sin registro en `ally_payments` o con `status = 'scheduled'`
4. **Monto neto a pagar** = `amount - (amount * commission_percentage / 100)`
5. **Fecha estimada de pago** = `created_at + payment_term_months`

## Archivos a Modificar

### 1. Componente Livewire: `app/Livewire/CollectionManagementAllies.php`

#### 1.1 Agregar import del modelo CreditTransaction
```php
use App\Models\CreditTransaction;
```

#### 1.2 Agregar método para obtener obligaciones pendientes
```php
/**
 * Obtener obligaciones de pago a aliados basado en credit_transactions
 */
public function getPendingObligations()
{
    try {
        // 1. Obtener transacciones de aliados (excluir las de landlord)
        $transactions = CreditTransaction::where('tenant_id', '!=', 'landlord')
            ->where('status', 'approved')
            ->orderBy('created_at', 'desc')
            ->get();

        $obligations = [];

        foreach ($transactions as $tx) {
            // 2. Verificar si ya existe un pago para esta transacción
            $existingPayment = AllyPayment::where('transaction_id', $tx->id)->first();

            // 3. Obtener configuración del aliado para comisión y plazo
            $config = AllyCollectionConfig::where('tenant_id', $tx->tenant_id)->first();
            $commissionPct = $config?->commission_percentage ?? 0;
            $termMonths = $config?->payment_term_months ?? 1;

            // 4. Calcular comisión y monto neto
            $commissionAmount = $tx->amount * ($commissionPct / 100);
            $netAmount = $tx->amount - $commissionAmount;
            $estimatedDate = $tx->created_at->copy()->addMonths($termMonths);

            // 5. Obtener nombre del tenant
            $tenantName = $this->getTenantNameById($tx->tenant_id);

            $obligations[] = [
                'transaction_id' => $tx->id,
                'tenant_id' => $tx->tenant_id,
                'tenant_name' => $tenantName,
                'credit_id' => $tx->credit_id,
                'sale_amount' => $tx->amount,
                'commission_percentage' => $commissionPct,
                'commission_amount' => $commissionAmount,
                'net_amount' => $netAmount,
                'term_months' => $termMonths,
                'created_at' => $tx->created_at,
                'estimated_payment_date' => $estimatedDate,
                'status' => $existingPayment?->status ?? 'pending',
                'payment_id' => $existingPayment?->id,
            ];
        }

        return $obligations;

    } catch (\Exception $e) {
        Log::error('Error in getPendingObligations: ' . $e->getMessage());
        return [];
    }
}

/**
 * Obtener nombre del tenant por ID
 */
private function getTenantNameById($tenantId)
{
    try {
        $tenants = $this->fetchTenantsFromAPI();
        foreach ($tenants as $tenant) {
            if ($tenant['id'] === $tenantId) {
                return $tenant['name'] ?? $tenantId;
            }
        }
        return $tenantId;
    } catch (\Exception $e) {
        return $tenantId;
    }
}
```

#### 1.3 Agregar método para marcar como pagado
```php
/**
 * Marcar una obligación como pagada
 */
public function markObligationAsPaid($transactionId)
{
    try {
        $tx = CreditTransaction::find($transactionId);
        if (!$tx) {
            session()->flash('error', 'Transacción no encontrada');
            return;
        }

        // Verificar que no exista ya un pago completado
        $existingPayment = AllyPayment::where('transaction_id', $transactionId)
            ->where('status', 'completed')
            ->first();

        if ($existingPayment) {
            session()->flash('error', 'Esta obligación ya fue pagada');
            return;
        }

        // Obtener configuración del aliado
        $config = AllyCollectionConfig::where('tenant_id', $tx->tenant_id)->first();
        $commissionPct = $config?->commission_percentage ?? 0;
        $commissionAmount = $tx->amount * ($commissionPct / 100);
        $netAmount = $tx->amount - $commissionAmount;

        // Crear o actualizar el registro de pago
        AllyPayment::updateOrCreate(
            ['transaction_id' => $transactionId],
            [
                'tenant_id' => $tx->tenant_id,
                'landlord_credit_id' => $tx->credit_id,
                'sale_amount' => $tx->amount,
                'commission_percentage' => $commissionPct,
                'commission_amount' => $commissionAmount,
                'amount_paid' => $netAmount,
                'scheduled_payment_date' => now(),
                'payment_date' => now(),
                'payment_method' => 'transfer',
                'status' => 'completed',
            ]
        );

        session()->flash('message', 'Pago registrado exitosamente: $' . number_format($netAmount, 2));

    } catch (\Exception $e) {
        Log::error('Error marking obligation as paid: ' . $e->getMessage());
        session()->flash('error', 'Error al registrar el pago: ' . $e->getMessage());
    }
}
```

#### 1.4 Actualizar método render()
```php
public function render()
{
    $pendingTransfers = $this->getPendingTransfers();
    $allyPayments = $this->getAllyPayments();
    $pendingObligations = $this->getPendingObligations(); // AGREGAR ESTA LÍNEA

    // Filter by selected tenant
    if ($this->selectedTenant) {
        $pendingTransfers = array_filter($pendingTransfers, function ($transfer) {
            return $transfer['tenant_id'] === $this->selectedTenant;
        });
        $allyPayments = array_filter($allyPayments, function ($payment) {
            return $payment['tenant_id'] === $this->selectedTenant;
        });
        // AGREGAR: filtrar obligaciones también
        $pendingObligations = array_filter($pendingObligations, function ($obligation) {
            return $obligation['tenant_id'] === $this->selectedTenant;
        });
    }

    // Filter overdue only
    if ($this->showOverdueOnly) {
        $pendingTransfers = array_filter($pendingTransfers, function ($transfer) {
            return $transfer['is_over_limit'] || $transfer['pending_amount'] > 0;
        });
    }

    return view('livewire.collection-management-allies', [
        'pendingTransfers' => $pendingTransfers,
        'allyPayments' => $allyPayments,
        'pendingObligations' => $pendingObligations, // AGREGAR ESTA LÍNEA
    ])->layout('layouts.app');
}
```

---

### 2. Vista Blade: `resources/views/livewire/collection-management-allies.blade.php`

#### 2.1 Actualizar los cards de resumen (después de línea ~7)
Reemplazar el bloque de `@php` con los cálculos de resumen:

```blade
@php
    $totalPending = collect($pendingTransfers)->sum('pending_amount');
    $totalAllies = count($pendingTransfers);
    $alliesWithDebt = collect($pendingTransfers)->filter(fn($t) => $t['pending_amount'] > 0)->count();

    // Calcular obligaciones de pago
    $pendingObligationsFiltered = collect($pendingObligations)->where('status', 'pending');
    $completedObligations = collect($pendingObligations)->where('status', 'completed');
    $totalObligations = $pendingObligationsFiltered->sum('net_amount');
    $totalPaidToAllies = $completedObligations->sum('net_amount');
    $pendingObligationsCount = $pendingObligationsFiltered->count();
@endphp
```

#### 2.2 Actualizar los cards para mostrar datos reales
Reemplazar los cards existentes con:

```blade
<!-- Summary Cards -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
    <!-- Card 1: Lo que aliados deben a landlord -->
    <div class="bg-white rounded-lg shadow p-4">
        <div class="text-sm font-medium text-gray-500">Por Cobrar a Aliados</div>
        <div class="text-2xl font-bold text-red-600">${{ number_format($totalPending, 2) }}</div>
        <div class="text-xs text-gray-400">{{ $alliesWithDebt }} aliados con deuda</div>
    </div>

    <!-- Card 2: Lo que landlord debe a aliados (pendiente) -->
    <div class="bg-white rounded-lg shadow p-4">
        <div class="text-sm font-medium text-gray-500">Por Pagar a Aliados</div>
        <div class="text-2xl font-bold text-orange-600">${{ number_format($totalObligations, 2) }}</div>
        <div class="text-xs text-gray-400">{{ $pendingObligationsCount }} ventas pendientes</div>
    </div>

    <!-- Card 3: Ya pagado a aliados -->
    <div class="bg-white rounded-lg shadow p-4">
        <div class="text-sm font-medium text-gray-500">Pagado a Aliados</div>
        <div class="text-2xl font-bold text-green-600">${{ number_format($totalPaidToAllies, 2) }}</div>
        <div class="text-xs text-gray-400">{{ $completedObligations->count() }} pagos realizados</div>
    </div>

    <!-- Card 4: Balance neto -->
    <div class="bg-white rounded-lg shadow p-4">
        <div class="text-sm font-medium text-gray-500">Balance Neto</div>
        @php $balance = $totalPending - $totalObligations; @endphp
        <div class="text-2xl font-bold {{ $balance >= 0 ? 'text-green-600' : 'text-red-600' }}">
            ${{ number_format(abs($balance), 2) }}
        </div>
        <div class="text-xs text-gray-400">{{ $balance >= 0 ? 'A favor de landlord' : 'A favor de aliados' }}</div>
    </div>
</div>
```

#### 2.3 Actualizar la sección "Obligaciones de Pago Pendientes"
Buscar la sección que dice "Obligaciones de Pago Pendientes" y reemplazar la tabla vacía con:

```blade
<!-- Obligaciones de Pago Pendientes -->
<div class="bg-white rounded-lg shadow mt-6">
    <div class="px-6 py-4 border-b border-gray-200">
        <h2 class="text-lg font-medium text-gray-900">Obligaciones de Pago a Aliados</h2>
        <p class="text-sm text-gray-500">Ventas realizadas por aliados que landlord debe pagar (descontando comisión)</p>
    </div>

    <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Aliado</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Crédito</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Monto Venta</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Plazo</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Comisión</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Monto Neto</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Fecha Pago Est.</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Estado</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
                @forelse($pendingObligations as $obligation)
                    <tr class="{{ $obligation['status'] === 'completed' ? 'bg-green-50' : '' }}">
                        <td class="px-6 py-4 whitespace-nowrap">
                            <div class="text-sm font-medium text-gray-900">{{ $obligation['tenant_name'] }}</div>
                            <div class="text-xs text-gray-500">{{ $obligation['tenant_id'] }}</div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            #{{ $obligation['credit_id'] }}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            ${{ number_format($obligation['sale_amount'], 2) }}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {{ $obligation['term_months'] }} {{ $obligation['term_months'] == 1 ? 'mes' : 'meses' }}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm">
                            <span class="text-gray-500">{{ $obligation['commission_percentage'] }}%</span>
                            <span class="text-red-500">(-${{ number_format($obligation['commission_amount'], 2) }})</span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                            <span class="text-lg font-semibold text-green-600">${{ number_format($obligation['net_amount'], 2) }}</span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {{ $obligation['estimated_payment_date']->format('d/m/Y') }}
                            @if($obligation['estimated_payment_date']->isPast() && $obligation['status'] === 'pending')
                                <span class="ml-1 text-red-500 text-xs">(Vencido)</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                            @if($obligation['status'] === 'completed')
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                                    PAGADO
                                </span>
                            @elseif($obligation['status'] === 'scheduled')
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                                    PROGRAMADO
                                </span>
                            @else
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-800">
                                    PENDIENTE
                                </span>
                            @endif
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                            @if($obligation['status'] === 'pending')
                                <button wire:click="markObligationAsPaid({{ $obligation['transaction_id'] }})"
                                        wire:confirm="¿Confirmar pago de ${{ number_format($obligation['net_amount'], 2) }} a {{ $obligation['tenant_name'] }}?"
                                        class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded-md text-white bg-[#009161] hover:bg-[#007a51]">
                                    Marcar Pagado
                                </button>
                            @elseif($obligation['status'] === 'completed')
                                <span class="text-green-600 text-xs">✓ Completado</span>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="9" class="px-6 py-8 text-center text-sm text-gray-500">
                            <div class="flex flex-col items-center">
                                <svg class="w-12 h-12 text-gray-300 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                                </svg>
                                <span>No hay obligaciones de pago</span>
                                <span class="text-xs text-gray-400 mt-1">Las ventas de aliados aparecerán aquí</span>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
```

---

### 3. Verificar que exista el modelo CreditTransaction

Archivo: `app/Models/CreditTransaction.php`

Si no existe, crearlo:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CreditTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'credit_id',
        'tenant_id',
        'amount',
        'status',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Relaciones
    public function credit()
    {
        return $this->belongsTo(Credit::class);
    }
}
```

---

## Resultado Esperado

Después de implementar, la sección "Obligaciones de Pago a Aliados" mostrará:

| Aliado | Crédito | Venta | Plazo | Comisión | Neto | Fecha Est. | Estado | Acción |
|--------|---------|-------|-------|----------|------|------------|--------|--------|
| Cafe JC | #1 | $200,000 | 1 mes | 3% (-$6,000) | $194,000 | 16/Feb/2026 | PENDIENTE | [Marcar Pagado] |
| Cafe JC | #1 | $119,999 | 1 mes | 3% (-$3,600) | $116,399 | 14/Feb/2026 | PENDIENTE | [Marcar Pagado] |
| Coindraw | #1 | $150,000 | 1 mes | 3% (-$4,500) | $145,500 | 14/Feb/2026 | PENDIENTE | [Marcar Pagado] |
| Cafe JC | #1 | $300,000 | 1 mes | 3% (-$9,000) | $291,000 | 14/Feb/2026 | PENDIENTE | [Marcar Pagado] |

Los cards de resumen mostrarán:
- **Por Cobrar a Aliados**: $233,248 (lo que aliados deben)
- **Por Pagar a Aliados**: $746,899 (lo que landlord debe)
- **Pagado a Aliados**: $0 (pagos completados)
- **Balance Neto**: $513,651 a favor de aliados

---

## Notas Importantes

1. La comisión y plazo se toman de `ally_collection_configs`. Si no existe configuración, usa 0% comisión y 1 mes de plazo.

2. Al marcar como pagado, se crea un registro en `ally_payments` con `status = 'completed'`.

3. Las transacciones con `tenant_id = 'landlord'` se excluyen (son movimientos internos).

4. La fecha estimada de pago se calcula como: `fecha_venta + plazo_meses`.
