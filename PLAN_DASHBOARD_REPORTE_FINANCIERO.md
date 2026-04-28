# Plan: Dashboard Reporte Financiero del Landlord

## Objetivo

Mostrar en el Dashboard del landlord (`/dashboard`) un reporte financiero consolidado que responda:

1. **¿Cuánto capital tengo disponible para prestar?**
2. **¿Cuánto he prestado actualmente y en cuántos créditos está distribuido?**
3. **Del total habilitado a cada cliente, ¿cuánto ha gastado y cuánto debo reservar?**
4. **¿Cuánto se ha recaudado y cuánto falta por cobrar?**
5. **A X meses, ¿cuánto tengo que pagar a los comercios y cuánto voy a recoger?**
6. **¿Cuál debería ser el máximo de cuotas para no quedarme sin capital?**
7. **¿Cuál es el riesgo de pérdida?**
8. **¿Estoy en ganancias o pérdidas?**

---

## Problema arquitectónico

El landlord **no tiene toda la información** en su propia BD. Los datos de cuotas (installments) viven en las **BDs individuales de cada tenant**:

| Dato | Dónde vive |
|------|------------|
| Créditos aprobados, cupo | Landlord BD (`credits`) |
| Transacciones de compra | Landlord BD (`credit_transactions`) |
| Deuda pendiente del aliado | Landlord BD (`ally_collection_configs.current_pending_debt`) |
| Pagos aliado → landlord | Landlord BD (`ally_payments`) |
| **Cuotas detalladas** | **Tenant BD** (`credit_installments`) |
| **Cuánto se ha cobrado por cuota** | **Tenant BD** (`credit_installments.paid_amount`) |
| **Capital + interés por periodo** | **Tenant BD** (`credit_installments`) |

Consultar todas las BDs de tenants en tiempo real en cada carga del dashboard sería **demasiado lento**.

---

## Solución: Cache incremental en Redis + tabla de respaldo

### Principio
- El dashboard **solo lee del cache** → respuesta instantánea
- El cache se **actualiza por eventos**, no por polling
- Si el cache no existe o expira → un **Job** lo reconstruye en background

### Estructura del cache

#### Resumen global (Redis key: `landlord:report:summary`)
```json
{
  "capital_disponible": 0,
  "capital_comprometido": 8200000,
  "capital_en_uso": 6080000,
  "cupo_libre": 2120000,
  "total_por_cobrar_intereses": 1265198,
  "total_recaudado": 5700750,
  "total_pendiente_cobro": 5500000,
  "total_transferido_landlord": 0,
  "aliados_activos": 2,
  "aliados_bloqueados": 0,
  "updated_at": "2026-03-12T10:00:00"
}
```

#### Por tenant (Redis key: `landlord:report:tenant:{tenant_id}`)
```json
{
  "tenant_id": "tenant_697222afedc32",
  "nombre": "Coindraw",
  "creditos_activos": 1,
  "total_prestado": 5500000,
  "total_cuotas": 24,
  "total_por_cobrar": 12269248,
  "total_recaudado": 5700750,
  "total_pendiente": 5500000,
  "transferido_landlord": 0,
  "deuda_actual_aliado": 5700750,
  "estado": "al_dia",
  "updated_at": "2026-03-12T10:00:00"
}
```

### Campo faltante: `capital_disponible`

Actualmente **no existe** un campo en la BD que registre el capital inicial que el landlord tiene para prestar. Hay que agregarlo.

**Propuesta:** Tabla `landlord_settings` con un campo `capital_inicial` que el admin configura manualmente.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `capital_inicial` | decimal(15,2) | Capital que el landlord tiene para operar |
| `capital_reserva` | decimal(15,2) | % que no se presta (reserva de liquidez) |

Con esto:
- **Capital disponible** = `capital_inicial` - `capital_comprometido` (sum total_limit activos)
- **Capital libre** = `capital_disponible` - `capital_en_uso`

---

## Datos reales actuales (snapshot 2026-03-12)

### Landlord BD

| Métrica | Valor |
|---------|-------|
| Créditos activos | 2 |
| Cupo total asignado (`total_limit`) | $8,200,000 |
| Capital en uso (gastado por clientes) | $6,080,000 |
| Cupo disponible restante | $2,120,000 |
| Capital financiado original (`financed_amount`) | $5,200,000 |
| Total a recuperar con intereses (`total_payable`) | $6,465,198 |
| **Intereses proyectados** | **$1,265,198** |
| Deuda pendiente de aliados (`current_pending_debt`) | $5,700,750 |
| Ally payments scheduled (landlord → aliado) | $5,200,000 |
| Ally payments completed | $1,347,276 |

### Tenant BD (Coindraw - tenant_697222afedc32)

| Métrica | Valor |
|---------|-------|
| Total cuotas | 24 |
| Cuotas pagadas | 23 |
| Cuotas pendientes | 1 |
| Total por cobrar (capital + interés + seguro) | $12,269,248 |
| **Ya cobrado de clientes** | **$5,700,750** |
| Pendiente de cobrar | $5,500,000 |
| Transferido al landlord (`transfer_to_landlord`) | $0 |

> **Nota:** `transfer_to_landlord = $0` porque el landlord aún no ha llamado `mark-transferred`. El landlord sabe que se le debe $5,700,750 vía `current_pending_debt` (actualizado por webhook en cada pago de cuota).

---

## Métricas del reporte del dashboard

### Sección 1: Capital

| Tarjeta | Fórmula | Fuente |
|---------|---------|--------|
| Capital inicial | `landlord_settings.capital_inicial` | Landlord BD (nuevo) |
| Capital comprometido | `SUM(credits.total_limit)` where active | Landlord BD |
| Capital en uso | `SUM(total_limit - available_amount)` where active | Landlord BD |
| Capital libre | `capital_inicial - capital_comprometido` | Calculado |

### Sección 2: Recaudo

| Tarjeta | Fórmula | Fuente |
|---------|---------|--------|
| Total cobrado de clientes | `SUM(credit_installments.paid_amount)` por tenant | **Cache** (de tenant BDs) |
| Pendiente de cobrar | `SUM(credit_installments.remaining_amount)` | **Cache** (de tenant BDs) |
| En manos de aliados | `SUM(ally_collection_configs.current_pending_debt)` | Landlord BD |
| Ya recibido de aliados | `SUM(ally_payments.amount_paid)` where completed (debt) | Landlord BD |

### Sección 3: Rentabilidad

| Tarjeta | Fórmula | Fuente |
|---------|---------|--------|
| Intereses proyectados | `SUM(total_payable - financed_amount)` where active | Landlord BD |
| Intereses ya recaudados | calculado de cuotas pagadas (interés cobrado) | **Cache** (tenant BDs) |
| Comisiones por pagar | `SUM(ally_payments.amount_paid)` where scheduled | Landlord BD |

### Sección 4: Por aliado (tabla)

| Columna | Fuente |
|---------|--------|
| Nombre | `tenant_company_infos.commercial_name` |
| Ventas (transacciones aprobadas) | `credit_transactions` |
| Total prestado | `credit_transactions` sum approved |
| Recaudado | Cache (tenant BD) |
| Pendiente | Cache (tenant BD) |
| Deuda con landlord | `ally_collection_configs.current_pending_debt` |
| Estado | `sales_enabled` / `payments_enabled` |
| % límite usado | `current_pending_debt / max_pending_debt * 100` |

---

## Eventos que actualizan el cache

| Evento | Qué actualiza |
|--------|---------------|
| `InstallmentPaid` (tenant) | `total_recaudado`, `total_pendiente` del tenant |
| `CreditTransaction` approved (landlord) | `capital_en_uso`, `total_prestado` del tenant |
| `Credit` created/updated (landlord) | `capital_comprometido`, `cupo_libre` |
| `AllyPayment` completed (landlord) | `ya_recibido_de_aliados` |
| `AllyCollectionConfig` updated (landlord) | `en_manos_de_aliados`, `estado_aliado` |

---

## Componentes a crear

### 1. Migración: `landlord_settings`
```
php artisan make:migration create_landlord_settings_table
```
Campos: `capital_inicial`, `capital_reserva`, `moneda`, `updated_by`

### 2. Servicio: `ReportCacheService`
- `getGlobalSummary()` → lee Redis o reconstruye
- `getTenantSummary($tenantId)` → lee Redis o consulta tenant BD
- `updateInstallmentPaid($tenantId, $amount)` → actualiza cache incremental
- `rebuildAll()` → recorre todos los tenants y reconstruye (Job)
- `invalidate()` → limpia todo el cache

### 3. Job: `RebuildReportCache`
- Se ejecuta en background cuando el cache está vacío o expirado
- Itera cada tenant, consulta su BD via conexión dinámica, acumula métricas
- TTL del cache: 24 horas (se reconstruye cada noche vía schedule)

### 4. Livewire Component: `DashboardReport`
- Solo lee del `ReportCacheService`
- Muestra indicador si el cache está siendo reconstruido
- Botón "Actualizar" que dispara `RebuildReportCache`

### 5. Vista: `resources/views/livewire/dashboard-report.blade.php`
- 4 secciones de tarjetas KPI
- Tabla por aliado con colores por estado
- Indicador de última actualización del cache

### 6. Vista: `resources/views/dashboard.blade.php`
- Reemplazar el welcome de Jetstream con el componente `<livewire:dashboard-report />`

---

## Conexión dinámica a BDs de tenants

El tenant-api usa Stancl Tenancy con BDs separadas. Para que el landlord consulte las BDs de los tenants, se crea una conexión dinámica en el Job:

```php
// En RebuildReportCache::handle()
foreach ($tenants as $tenant) {
    $dbName = 'tenant' . $tenant->id; // prefijo de Stancl
    config(['database.connections.tenant_temp' => [
        'driver'   => 'mysql',
        'host'     => env('TENANT_DB_HOST', 'tenant-api-mysql-1'),
        'port'     => 3306,
        'database' => $dbName,
        'username' => env('TENANT_DB_USERNAME', 'sail'),
        'password' => env('TENANT_DB_PASSWORD', 'password'),
    ]]);
    DB::purge('tenant_temp');

    $totals = DB::connection('tenant_temp')
        ->table('credit_installments')
        ->selectRaw('SUM(total_amount) as total, SUM(paid_amount) as cobrado, SUM(remaining_amount) as pendiente')
        ->first();

    // Guardar en cache
    Cache::put("landlord:report:tenant:{$tenant->id}", [...], now()->addHours(24));
}
```

---

## Variables de entorno necesarias (landlord .env)

```env
TENANT_DB_HOST=tenant-api-mysql-1
TENANT_DB_PORT=3306
TENANT_DB_USERNAME=sail
TENANT_DB_PASSWORD=password
TENANT_DB_PREFIX=tenant  # prefijo que usa Stancl: "tenant" + tenant_id
```

---

## Sección 5: Distribución del capital por crédito

Responde: **¿en cuántos créditos está distribuido el capital y cuánto reservar por cada uno?**

Cada crédito activo tiene tres estados de su cupo:

```
total_limit = gastado + reservado
gastado   = total_limit - available_amount  (ya usado por el cliente)
reservado = available_amount                (el cliente puede gastarlo en cualquier momento → DEBE estar en caja)
```

| Crédito | Cliente | Total habilitado | Gastado | Reservado (en caja) | % usado |
|---------|---------|-----------------|---------|---------------------|---------|
| #1 | Alexander G. | $7,000,000 | $5,480,000 | $1,520,000 | 78% |
| #2 | Ana H. | $1,200,000 | $600,000 | $600,000 | 50% |
| **TOTAL** | | **$8,200,000** | **$6,080,000** | **$2,120,000** | **74%** |

> **Regla crítica:** El landlord SIEMPRE debe tener en caja el total de `available_amount` ($2,120,000) porque los clientes pueden gastarlo en cualquier momento. Este dinero NO está disponible para nuevos créditos.

### Implicación para capital nuevo disponible

```
Capital inicial (configurable)          = X
- Capital comprometido (total_limit)    = $8,200,000
- Reserva obligatoria (available_amount)= $2,120,000  ← ya incluida en comprometido
= Capital libre para nuevos créditos    = X - $8,200,000
```

---

## Sección 6: Proyección de flujo de caja a N meses

Responde: **¿a X meses cuánto pago a comercios y cuánto recojo?**

### Entradas (lo que el landlord recibirá)

Por cada cuota futura en tenant BDs con `due_date <= hoy + N meses`:
```
recaudo_proyectado = SUM(credit_installments.total_amount) where status='pendiente' AND due_date <= fecha_limite
```

Desglose del recaudo:
- `principal_amount` → recuperación de capital (no es ganancia, es devolución)
- `interest_amount` → **ganancia real del landlord**
- `insurance_amount` → cobertura de riesgo

### Salidas (lo que el landlord pagará a comercios)

Los `ally_payments` con `status='scheduled'` y `scheduled_payment_date <= fecha_limite`:
```
pagos_a_comercios = SUM(ally_payments.amount_paid) where status IN ('scheduled','pending') AND scheduled_payment_date <= fecha_limite
```

### Flujo neto proyectado

```
flujo_neto = recaudo_proyectado - pagos_a_comercios
```

Si `flujo_neto > 0` → el landlord tiene liquidez en ese período
Si `flujo_neto < 0` → el landlord necesita capital adicional en ese período

### Ejemplo con datos actuales

| Período | Recaudo esperado | Pagos a comercios | Flujo neto |
|---------|-----------------|-------------------|------------|
| 1 mes | ~$574,420 | $0 (ya programados) | +$574,420 |
| 3 meses | ~$1,723,260 | $5,200,000 | **-$3,476,740** ⚠️ |
| 6 meses | ~$3,446,520 | $5,200,000 | **-$1,753,480** ⚠️ |
| 12 meses | ~$6,465,198 | $5,200,000 | **+$1,265,198** ✓ |

> El déficit a corto plazo ocurre porque hay `ally_payments` grandes pendientes ($5,200,000 scheduled). Una vez pagados, el flujo se normaliza.

---

## Sección 7: Recomendación de cuotas máximas

Responde: **¿cuál es el máximo de cuotas que puedo ofrecer sin quedarme sin capital?**

### El problema

Más cuotas = más tiempo hasta recuperar el capital = menos capital disponible para nuevos préstamos durante ese tiempo.

### Fórmula del máximo de cuotas sostenible

```
cuotas_max = floor(capital_libre_para_prestar / cuota_promedio_mensual)
```

Donde:
- `capital_libre_para_prestar` = capital_inicial - total_limit_activos
- `cuota_promedio_mensual` = promedio de `installment_amount` de créditos activos
- `cuotas_max` = cuántos meses puede el landlord sostener sin recibir de vuelta capital

### Indicador semáforo de salud del plazo

```
ratio_rotacion = recaudo_mensual_promedio / capital_en_uso

Verde  (ratio > 15%): rotación saludable, puedes ofrecer hasta 12 cuotas
Amarillo (5-15%):     rotación lenta, máximo recomendado 6 cuotas
Rojo   (< 5%):        capital inmovilizado, revisar política de cuotas
```

### Fórmula del límite de nuevas aprobaciones

Para no quedar sin capital al aprobar una nueva solicitud:

```
max_cupo_aprobable = capital_inicial - total_limit_activos - reserva_minima

Donde:
  total_limit_activos = SUM(credits.total_limit) where active   ← capital comprometido
  reserva_minima      = capital_inicial * porcentaje_reserva    ← % configurable (ej: 20%)
```

Si `max_cupo_aprobable <= 0` → **bloquear nuevas aprobaciones automáticamente**

---

## Estructura del cache ampliada

### Resumen global (`landlord:report:summary`)
```json
{
  "capital_inicial": 0,
  "capital_comprometido": 8200000,
  "capital_en_uso": 6080000,
  "capital_reservado": 2120000,
  "capital_libre_nuevos_creditos": 0,
  "total_intereses_proyectados": 1265198,
  "total_recaudado": 5700750,
  "total_pendiente_cobro": 5500000,
  "aliados_activos": 2,
  "aliados_bloqueados": 0,
  "flujo_neto_1m": 574420,
  "flujo_neto_3m": -3476740,
  "flujo_neto_6m": -1753480,
  "flujo_neto_12m": 1265198,
  "cuotas_max_recomendadas": 12,
  "ratio_rotacion": 0.09,
  "semaforo_salud": "amarillo",
  "updated_at": "2026-03-12T10:00:00"
}
```

### Por crédito (`landlord:report:credit:{credit_id}`)
```json
{
  "credit_id": 1,
  "client_name": "Alexander Garrido",
  "total_limit": 7000000,
  "gastado": 5480000,
  "reservado": 1520000,
  "porcentaje_uso": 78,
  "total_cuotas": 24,
  "cuotas_pagadas": 23,
  "cuotas_pendientes": 1,
  "recaudo_pendiente": 5500000,
  "intereses_pendientes": 800000
}
```

### Proyección mensual (`landlord:report:cashflow`)
```json
[
  { "mes": "2026-03", "recaudo": 574420, "pagos_comercios": 0, "neto": 574420 },
  { "mes": "2026-04", "recaudo": 574420, "pagos_comercios": 5200000, "neto": -4625580 },
  ...
]
```

---

## Orden de implementación

1. [ ] Migración `landlord_settings` + Model + seeder con capital inicial y % reserva
2. [ ] `ReportCacheService` con todos los métodos (summary, por crédito, cashflow, tenant)
3. [ ] Job `RebuildReportCache` con conexión dinámica a tenant BDs
4. [ ] Enganchar listeners existentes para actualización incremental del cache
5. [ ] Componente Livewire `DashboardReport` con selector de horizonte (1/3/6/12 meses)
6. [ ] Vista blade: 7 secciones (capital, distribución, reserva, recaudo, proyección, cuotas max, por aliado)
7. [ ] Actualizar `dashboard.blade.php`
8. [ ] Schedule: reconstruir cache cada noche a las 2am
9. [ ] Panel de configuración para que el admin ingrese `capital_inicial` y `reserva_minima`
