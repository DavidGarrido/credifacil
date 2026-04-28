# 📊 Estructura de Base de Datos - Credifácil

Estructura de tablas para el sistema de créditos multi-tenant, adaptada de LibreCol.

**Nota**: La estructura se divide en **Landlord DB** (centralizada) y **Tenant DB** (por comerciante). Los tenants manejan las cuotas siguiendo el patrón parent-child de LibreCol.

---

## 🏛️ LANDLORD DATABASE (Centralizada)

### 1. **credits** - Cupos de Crédito por Cliente

Almacena los cupos disponibles que el landlord otorga a los clientes.

```sql
CREATE TABLE credits (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_id BIGINT UNSIGNED NOT NULL,                  -- Cliente
    available_amount DECIMAL(12,2) NOT NULL,             -- Cupo disponible actual
    total_limit DECIMAL(12,2) NOT NULL,                  -- Límite total aprobado
    status ENUM('active','suspended','blocked') DEFAULT 'active',
    notes TEXT NULL,

    -- Relaciones
    creator_id BIGINT UNSIGNED NOT NULL,                 -- Admin que creó

    -- Claves foráneas
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE,

    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Índices
    INDEX idx_client (client_id),
    INDEX idx_status (status)
);
```

### 2. **credit_transactions** - Historial Central de Transacciones

Registra todas las operaciones reportadas por tenants.

```sql
CREATE TABLE credit_transactions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    credit_id BIGINT UNSIGNED NOT NULL,                  -- Cupo afectado
    type ENUM('purchase','payment','refund') NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    tenant_id VARCHAR(255) NOT NULL,                     -- Tenant que reporta
    previous_balance DECIMAL(12,2) NOT NULL,
    new_balance DECIMAL(12,2) NOT NULL,
    description TEXT NULL,
    metadata JSON NULL,

    -- Claves foráneas
    FOREIGN KEY (credit_id) REFERENCES credits(id) ON DELETE CASCADE,

    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Índices
    INDEX idx_credit_date (credit_id, created_at),
    INDEX idx_tenant (tenant_id),
    INDEX idx_type (type)
);
```

## 🏪 TENANT DATABASE (Por Comerciante)

### 3. **credit_installments** - Compras/Installments por Tenant

Almacena las compras realizadas por clientes (análoga a "credits" en LibreCol).

```sql
CREATE TABLE credit_installments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(255) UNIQUE NOT NULL,                   -- Código único
    amount DECIMAL(12,2) NOT NULL,                       -- Valor total de la compra
    financed_amount DECIMAL(12,2) NOT NULL,              -- Monto financiado
    interest_rate DECIMAL(8,2) NOT NULL,                 -- Tasa de interés mensual
    term INT NOT NULL,                                   -- Número de cuotas
    installment_amount DECIMAL(12,2) NOT NULL,           -- Valor de cada cuota
    insurance_percentage DECIMAL(5,2) DEFAULT 0.15,      -- % de seguro
    insurance_amount DECIMAL(12,2) NOT NULL,             -- Monto del seguro
    total_payable DECIMAL(12,2) NOT NULL,                -- Total a pagar
    frequency ENUM('mensual','quincenal') DEFAULT 'mensual',
    status ENUM('pending_approval','active','paid','cancelled') DEFAULT 'pending_approval',
    notes TEXT NULL,

    -- Relaciones
    client_id BIGINT UNSIGNED NOT NULL,
    company_id BIGINT UNSIGNED NOT NULL,                 -- Tenant actual
    creator_id BIGINT UNSIGNED NOT NULL,                 -- Usuario que creó
    landlord_credit_id BIGINT UNSIGNED NULL,             -- ID en landlord DB (asignado después de aprobación)

    -- Claves foráneas
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE,

    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Índices
    INDEX idx_code (code),
    INDEX idx_client (client_id),
    INDEX idx_company (company_id),
    INDEX idx_status (status),
    INDEX idx_landlord_credit (landlord_credit_id)
);
```

---

### 4. **credit_installment_items** - Cuotas Individuales

Almacena cada cuota específica dentro de un installment (patrón parent-child de LibreCol).

```sql
CREATE TABLE credit_installment_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    credit_installment_id BIGINT UNSIGNED NOT NULL,      -- Parent installment
    installment_number INT NOT NULL,                     -- Número de cuota (1, 2, 3...)
    due_date DATE NOT NULL,                              -- Fecha de vencimiento
    principal_amount DECIMAL(12,2) NOT NULL,             -- Monto de capital
    interest_amount DECIMAL(12,2) NOT NULL,              -- Monto de interés
    insurance_amount DECIMAL(12,2) NOT NULL,             -- Monto de seguro
    total_amount DECIMAL(12,2) NOT NULL,                 -- Total de la cuota
    paid_amount DECIMAL(12,2) DEFAULT 0,                 -- Monto pagado
    status ENUM('pending','paid','overdue') DEFAULT 'pending',
    payment_date DATE NULL,                              -- Fecha real de pago

    -- Claves foráneas
    FOREIGN KEY (credit_installment_id) REFERENCES credit_installments(id) ON DELETE CASCADE,

    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Índices
    INDEX idx_installment_item (credit_installment_id, installment_number),
    INDEX idx_due_date (due_date),
    INDEX idx_status (status)
);
```

### 5. **credit_transactions** - Pagos Realizados por Tenant

Registra los pagos realizados por el tenant (local al tenant).

```sql
CREATE TABLE credit_transactions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    credit_installment_id BIGINT UNSIGNED NOT NULL,      -- Installment pagado
    type ENUM('payment','refund') NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_method ENUM('cash','card','transfer') NOT NULL,
    installment_item_id BIGINT UNSIGNED NULL,            -- Cuota específica (opcional)
    landlord_notified BOOLEAN DEFAULT FALSE,             -- ¿Reportado al landlord?
    description TEXT NULL,

    -- Relaciones
    user_id BIGINT UNSIGNED NOT NULL,                    -- Usuario que registró el pago

    -- Claves foráneas
    FOREIGN KEY (credit_installment_id) REFERENCES credit_installments(id) ON DELETE CASCADE,
    FOREIGN KEY (installment_item_id) REFERENCES credit_installment_items(id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,

    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Índices
    INDEX idx_installment_date (credit_installment_id, created_at),
    INDEX idx_type (type),
    INDEX idx_notified (landlord_notified)
);
```


---

## 📊 Relaciones y Flujos

### Landlord DB
```
clients (Clientes)
    │
    └─────────────────────┬──────────────────────┐
                           │                      │
                       credits            credit_transactions
                       (Cupos)             (Historial central)
```

### Tenant DB
```
clients (Clientes)
    │
    └─────────────────────┬──────────────────────┐
                           │                      │
                   credit_installments     credit_transactions
                   (Compras/Installments)  (Pagos locales)
                           │
                     ┌─────┴─────┐
                     │           │
          credit_installment_items  ← credit_transactions
          (Cuotas individuales)     (Pagos por cuota)
```

---

## 🔄 Flujos de Datos

### Flujo 1: Solicitar Compra (Tenant)

```
1. Tenant solicita compra → Crea CREDIT_INSTALLMENTS (status: pending_approval)
2. Landlord valida cupo → Descuenta de LANDLORD.CREDITS.available_amount
3. Landlord aprueba → Asigna landlord_credit_id, status: active
4. Tenant genera cuotas → Crea CREDIT_INSTALLMENT_ITEMS con amortización
```

### Flujo 2: Registrar Pago (Tenant)

```
1. Cliente paga cuota $25.000
2. Tenant actualiza CREDIT_INSTALLMENT_ITEMS.paid_amount
3. Tenant registra en CREDIT_TRANSACTIONS (type: payment)
4. Tenant reporta pago → Landlord actualiza LANDLORD.CREDIT_TRANSACTIONS
5. Landlord decide cupo → Actualiza LANDLORD.CREDITS.available_amount
```

### Flujo 3: Estado Parent-Child

```
Estado del installment (parent) se calcula basado en sus items (children):
- Si todas las cuotas pagadas → installment.status = 'paid'
- Si tiene cuotas vencidas → installment.status = 'overdue'
- Si tiene cuotas pendientes → installment.status = 'active'
```

---

## 📈 Cálculos Importantes

### Cálculo de Cuota

```
Fórmula:
cuota = (financed_amount * monthly_rate * (1 + monthly_rate)^n) / ((1 + monthly_rate)^n - 1)

Donde:
- financed_amount = amount - initial_fee
- monthly_rate = annual_rate / 12
- n = term (meses)
```

### Cálculo de Saldo

```
new_balance = previous_balance - principal_payment

En compra:
- Se descuenta del saldo disponible
- Se registra en credit_transactions

En pago:
- Se suma al saldo disponible
- Se actualiza cuota
```

### Cálculo de Mora

```
Due date (fecha de vencimiento) < today() → status: vencida

Dias en mora = today() - due_date
```

---

## 🔐 Consideraciones de Seguridad

```
✓ Cada tenant ve solo sus propios créditos (filtro company_id)
✓ Todas las transacciones auditadas (user_id, created_at)
✓ Cambios de balance registrados en credit_transactions
✓ Tokens JWT para acceso a API
✓ Validación de montos antes de operación
```

---

## 📝 Migraciones para Credifácil

### Landlord DB
```bash
# Tablas centrales
php artisan migrate --path=database/migrations/xxxx_create_credits_table.php
php artisan migrate --path=database/migrations/xxxx_create_credit_transactions_table.php
```

### Tenant DB (por cada tenant)
```bash
# Tablas de compras y cuotas
php artisan migrate --path=database/migrations/xxxx_create_credit_installments_table.php
php artisan migrate --path=database/migrations/xxxx_create_credit_installment_items_table.php
php artisan migrate --path=database/migrations/xxxx_create_credit_transactions_table.php

# Opcionales
php artisan migrate --path=database/migrations/xxxx_create_credit_plans_table.php
```

---

## 📊 Ejemplos de Datos

### Ejemplo 1: Cupo en Landlord DB

```json
{
  "id": 1,
  "client_id": 123,
  "available_amount": 500000.00,
  "total_limit": 1000000.00,
  "status": "active",
  "creator_id": 1
}
```

### Ejemplo 2: Compra/Installment en Tenant DB

```json
{
  "id": 1,
  "code": "INST-EMP1-20251117-001",
  "client_id": 123,
  "amount": 300000.00,
  "financed_amount": 285000.00,
  "interest_rate": 2.5,
  "term": 6,
  "installment_amount": 50000.00,
  "status": "active",
  "landlord_credit_id": 1,
  "company_id": 1
}
```

### Ejemplo 3: Cuota Individual (Item)

```json
{
  "id": 1,
  "credit_installment_id": 1,
  "installment_number": 1,
  "due_date": "2025-12-17",
  "principal_amount": 45000.00,
  "interest_amount": 3750.00,
  "insurance_amount": 1250.00,
  "total_amount": 50000.00,
  "paid_amount": 0.00,
  "status": "pending"
}
```

### Ejemplo 4: Pago Registrado

```json
{
  "id": 1,
  "credit_installment_id": 1,
  "type": "payment",
  "amount": 50000.00,
  "payment_method": "transfer",
  "installment_item_id": 1,
  "landlord_notified": true,
  "user_id": 5
}
```

---

## 🔍 Queries Útiles

### Landlord DB

#### Obtener cupo disponible de cliente
```sql
SELECT available_amount, total_limit, status
FROM credits
WHERE client_id = ? AND status = 'active';
```

#### Historial de transacciones por tenant
```sql
SELECT * FROM credit_transactions
WHERE tenant_id = ? AND created_at >= ?
ORDER BY created_at DESC;
```

### Tenant DB

#### Obtener installments activos de cliente
```sql
SELECT * FROM credit_installments
WHERE client_id = ? AND status IN ('active', 'pending_approval')
ORDER BY created_at DESC;
```

#### Cuotas pendientes de pago
```sql
SELECT * FROM credit_installment_items
WHERE credit_installment_id = ? AND status = 'pending'
ORDER BY due_date ASC;
```

#### Pagos realizados en período
```sql
SELECT SUM(amount) as total_pagos
FROM credit_transactions
WHERE credit_installment_id = ?
AND type = 'payment'
AND created_at BETWEEN ? AND ?;
```

#### Estado general de un installment
```sql
SELECT
    i.status as installment_status,
    COUNT(CASE WHEN ii.status = 'paid' THEN 1 END) as cuotas_pagadas,
    COUNT(CASE WHEN ii.status = 'overdue' THEN 1 END) as cuotas_vencidas,
    COUNT(ii.id) as total_cuotas
FROM credit_installments i
LEFT JOIN credit_installment_items ii ON i.id = ii.credit_installment_id
WHERE i.id = ?
GROUP BY i.id, i.status;
```

---

## 📚 Documentación Relacionada

- [README.md](./README.md) - Arquitectura general
- [CREDIT_FLOW.md](./CREDIT_FLOW.md) - Flujos de crédito
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Deployment en producción

---

**Última actualización**: 2025-11-20
**Versión**: 2.0 - Adaptado a arquitectura multi-tenant
**Basado en**: LibreCol Sistema de Créditos + análisis de contenedor Docker
**Autor**: Claude Code
