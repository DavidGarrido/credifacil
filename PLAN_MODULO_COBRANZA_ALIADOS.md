# Plan del Módulo de Cobranza para Aliados

## Objetivo
Crear un módulo de cobranza para aliados que tome los installments donde `paid_amount` > `transfer_to_landlord` y cobre esa diferencia al aliado.

## Flujo de Trabajo

### Flujo Normal (Cliente paga en Tenant):
1. Cliente paga en tenant → Tenant actualiza `paid_amount` y **notifica a landlord** para sumar en `current_pending_debt`
2. Landlord recibe pago del aliado → **Notifica a tenant** para actualizar `transfer_to_landlord`

### Flujo Directo (Cliente paga a Landlord):
1. Cliente paga directamente a landlord (usando el módulo de cobranza existente)
2. Landlord registra el pago en su sistema y **notifica inmediatamente al tenant** para actualizar `paid_amount` y `transfer_to_landlord`
3. Tenant marca la cuota como pagada y evita cobros duplicados
4. No hay acumulación de `current_pending_debt` en landlord (ya que el pago fue directo)
5. No hay cobro adicional al aliado por ese installment

### Módulo de Aliados:
- Muestra installments donde `paid_amount > transfer_to_landlord` (diferencia pendiente de cobro)

### Registro de Pagos Directos

Cuando un cliente paga directamente en las oficinas del landlord usando el módulo de cobranza existente:

1. **Landlord registra el pago:**
   - Crea una transacción de pago en su sistema
   - Identifica las cuotas específicas que se están pagando
   - Registra método de pago, referencia, fecha, etc.

2. **Notificación automática al Tenant:**
   - Envía webhook POST a `/api/webhooks/direct-payment-from-landlord`
   - Payload incluye: `landlord_credit_id`, `installment_id`, `amount_paid`, `payment_method`, `payment_date`, etc.
   - Tenant actualiza `paid_amount` += amount_paid y `transfer_to_landlord` += amount_paid
   - Tenant marca cuota como pagada si `remaining_amount <= 0`

3. **Prevención de doble cobro:**
   - Tenant verifica que no intente cobrar nuevamente al cliente
   - Landlord no acumula deuda pendiente del tenant (ya que pago fue directo)

## Estructura Propuesta

### Modificación de Tabla Existente

**Agregar campo a `credit_installments` (en tenant databases):**
- `transfer_to_landlord`: BigInt (default 0) - monto ya transferido a landlord

### Tablas Nuevas en Landlord

1. **ally_collection_configs**
   - `id`: Primary key
   - `tenant_id`: String unique
   - `max_pending_debt`: BigInt - límite máximo de deuda pendiente
   - `current_pending_debt`: BigInt - deuda pendiente acumulada
   - `sales_enabled`: Boolean - si puede vender (default true)
   - `payments_enabled`: Boolean - si puede recibir pagos (default true)
   - `grace_period_days`: Int - días de gracia antes de bloqueo
   - Timestamps

### Componente Livewire: CollectionManagementAllies

- **Propiedades:**
  - `selectedTenant`: String (filtro)
  - `showOverdueOnly`: Boolean (mostrar solo demorados)

- **Métodos principales:**
  - `getPendingTransfers()`: Consulta installments pendientes por tenant
  - `getOverdueTransfers()`: Installments demorados (basado en grace_period_days)
  - `generatePaymentLink($installmentData)`: Enlace para aliado pagar diferencia
  - `markAsPaid($installmentId, $amount)`: Actualizar transfer_to_landlord y descontar deuda pendiente
  - `updatePendingDebt($tenantId, $amount)`: Actualizar current_pending_debt

### Vista Blade

- **Filtros:**
  - Selector de tenant
  - Checkbox "Mostrar solo demorados"

- **Tabla con installments pendientes:**
  - Tenant/Aliado
  - Cliente
  - Installment
  - Paid Amount
  - Transfer to Landlord
  - **Diferencia (a cobrar)**
  - Días de demora
  - Estado (Normal/Demorado/Bloqueado)
  - Acciones (Generar enlace de pago)

- **Información del tenant:**
  - Deuda pendiente actual
  - Límite configurado
  - Estado de ventas (Permitido/Bloqueado)

### Lógica de Negocio

- **Monto a cobrar:** `paid_amount` - `transfer_to_landlord`
- **Deuda pendiente por tenant:** Suma de diferencias de todos sus installments
- **Control de ventas/pagos:** Flags independientes `sales_enabled` y `payments_enabled`
- **Bloqueo automático:** Si `current_pending_debt >= max_pending_debt`, deshabilitar ventas
- **Días de demora:** Basado en `grace_period_days` desde que se creó la diferencia
- **Cuando aliado paga:**
  - Actualizar `transfer_to_landlord` en installment
  - Descontar de `current_pending_debt`
  - Si baja del límite, desbloquear ventas

### Integración

- **Webhooks/APIs de notificación:**
  - Tenant → Landlord: "pago recibido" (sumar a `current_pending_debt`)
  - Landlord → Tenant: "pago recibido del aliado" (actualizar `transfer_to_landlord`)
  - **Landlord → Tenant: "pago directo del cliente" (actualizar `paid_amount` y `transfer_to_landlord`)**
- Endpoint en tenant-api para consultar installments pendientes
- Endpoint para actualizar `transfer_to_landlord`
- **Nuevo endpoint: POST `/api/webhooks/direct-payment-from-landlord`**
- Endpoint para verificar permisos de venta/pago
- Reutilizar `PaymentLink` para enlaces de pago a aliados

### Consideraciones Técnicas

- Comunicación bidireccional landlord ↔ tenant
- **Manejo de transacciones distribuidas:**
  - Cuando aliado paga: actualizar `transfer_to_landlord` en tenant Y descontar `current_pending_debt` en landlord
  - Usar transacciones locales en cada BD, con logging para compensación manual si falla
  - Evitar transacciones distribuidas complejas - mejor consistencia eventual
- Manejo de errores de red y timeouts entre sistemas
- Validación de montos y consistencia de datos
- Seguridad: autenticación y autorización entre landlord y tenants