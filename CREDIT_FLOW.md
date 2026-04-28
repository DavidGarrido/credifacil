# 💳 Flujo de Aprobación y Uso de Créditos - Credifácil

Documentación completa del flujo de aprobación, validación y uso de créditos en el sistema multi-tenant.

---

## 📚 Tabla de Contenidos

1. [Conceptos Generales](#conceptos-generales)
2. [Actores del Sistema](#actores-del-sistema)
3. [Flujo de Aprobación de Crédito](#flujo-de-aprobación-de-crédito)
4. [Flujo de Uso de Crédito](#flujo-de-uso-de-crédito)
5. [Endpoints Landlord API](#endpoints-landlord-api)
6. [Endpoints Tenant API](#endpoints-tenant-api)
7. [Webhooks](#webhooks)
8. [Errores y Validaciones](#errores-y-validaciones)
9. [Seguridad](#seguridad)
10. [Ejemplos Prácticos](#ejemplos-prácticos)

---

## 🎯 Conceptos Generales

### ¿Qué es un Crédito?

Un **crédito** es una cantidad de dinero que el Landlord (administrador central) otorga a un **cliente final** para que pueda realizar compras en los tenants (comerciantes). Los tenants generan las cuotas de amortización y gestionan los pagos periódicos.

### Flujo General

```
┌────────────────────────────────────────────────────────────┐
│                   FLUJO GENERAL DE CRÉDITOS                 │
└────────────────────────────────────────────────────────────┘

PARTE 1: SOLICITUD DE COMPRA (Responsabilidad Tenant)
═════════════════════════════════════════════════════════════

1. SOLICITUD DE COMPRA
    Tenant → Landlord API: Solicitar aprobación de compra con datos del cliente

2. VALIDACIÓN
    Landlord API: Valida identidad del cliente y cupo disponible

3. RESPUESTA
    Landlord → Tenant: Aprobado/Rechazado

4. GENERACIÓN DE CUOTAS
    Tenant: Si aprobado, genera tabla de amortización con tasa de interés y seguro

5. NOTIFICACIÓN DE COMPRA
    Tenant → Landlord: Registra la transacción completada


PARTE 2: GESTIÓN DE PAGOS (Responsabilidad Tenant + Landlord)
═════════════════════════════════════════════════════════════════════

6. GESTIÓN DE PAGOS
    Tenant: Cobra cuotas periódicas al cliente

7. NOTIFICACIÓN DE PAGO
    Tenant → Landlord: Reporta pagos realizados

8. DECISIÓN DE CUPO
    Landlord: Decide si autorizar restauración del cupo

9. NOTIFICACIÓN
    Landlord → Tenant: Webhook con actualización de cupo
```

**Nota Importante**:
- **Landlord**: Controla la identidad, cupos y autorizaciones
- **Tenant**: Genera cuotas, cobra pagos y gestiona relación con cliente

---

## 👥 Actores del Sistema

### 1. **Cliente Final** (End User)
- Persona que solicita crédito
- Realiza compras en los tenants
- Recibe confirmación de compra

### 2. **Landlord API** (Sistema Central)
- Gestiona solicitudes de crédito (aprobación)
- Verifica identidad de clientes
- Asigna y controla créditos (saldo, validación)
- **Descuenta crédito cuando se usa en compras** (débito/crédito)
- Procesa reembolsos de crédito
- Notifica a tenants vía webhooks de cambios en créditos

### 3. **Tenant API** (Comerciante)
- Recibe notificaciones de clientes aprovados
- **Gestiona pagos de compras** (cobra al cliente con diferentes medios)
- Consulta saldo de crédito en tiempo real
- Solicita validación de crédito al landlord
- Procesa pagos: dinero en efectivo, tarjeta, transferencia, crédito
- Notifica al landlord cuando se usa crédito

### 4. **Frontend Cliente**
- Interfaz para solicitar crédito
- Muestra saldo de crédito
- Permite realizar compras

### 5. **Frontend Tenant**
- Panel de control de comerciante
- Ver clientes aprovados
- Historial de transacciones

---

## 💰 Flujo de Aprobación de Crédito

### FASE 1: Solicitud de Crédito

```
┌─────────────────────────────────────────┐
│   CLIENTE solicita CRÉDITO               │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│   POST /api/credits/request              │
│   (Landlord API)                        │
└─────────────────────────────────────────┘
```

#### Request
```json
{
  "email": "juan@example.com",
  "phone": "+573001234567",
  "document_type": "CC",           // Cedula de Ciudadanía
  "document_number": "123456789",
  "full_name": "Juan Pérez García",
  "address": "Calle 123 #456, Bogotá",
  "credit_amount": 500000,         // Solicita $500.000
  "credit_plan": "6_months"        // Paga en 6 meses
}
```

#### Response (201 Created)
```json
{
  "credit_id": "CRD-20251117-001",
  "status": "pending_verification",
  "client_email": "juan@example.com",
  "requested_amount": 500000,
  "credit_plan": "6_months",
  "created_at": "2025-11-17T18:30:00Z",
  "estimated_decision_date": "2025-11-17T20:00:00Z",
  "message": "Solicitud recibida. Se te notificará por email."
}
```

---

### FASE 2: Verificación de Identidad

```
┌─────────────────────────────────────────┐
│   Landlord verifica identidad             │
│   (validación con bases de datos)        │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│   POST /api/credits/{id}/verify           │
│   (Endpoint Interno - Admin)             │
└─────────────────────────────────────────┘
```

#### Request (desde Backend/Admin)
```json
{
  "credit_id": "CRD-20251117-001",
  "verified": true,
  "verification_method": "official_id",
  "verification_details": {
    "id_checked": true,
    "age_verified": true,
    "address_confirmed": true,
    "score": 850
  },
  "verified_by": "admin@landlord.com"
}
```

#### Response
```json
{
  "credit_id": "CRD-20251117-001",
  "status": "approved",
  "client_id": "CLT-20251117-001",
  "approved_amount": 500000,
  "requested_amount": 500000,
  "credit_plan": "6_months",
  "monthly_payment": 83333.33,
  "interest_rate": 2.5,
  "approval_date": "2025-11-17T19:00:00Z",
  "first_payment_date": "2025-12-17T00:00:00Z"
}
```

---

### FASE 3: Notificación a Tenants

```
┌─────────────────────────────────────────┐
│   Landlord aprobó crédito                 │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│   POST /webhooks/client-approved          │
│   (Webhook → Tenant API)                 │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│   Tenant almacena cliente aprovado        │
│   y su saldo de crédito                  │
└─────────────────────────────────────────┘
```

#### Webhook Payload
```json
{
  "event": "client.approved",
  "event_id": "EVT-20251117-001",
  "timestamp": "2025-11-17T19:05:00Z",
  "data": {
    "client_id": "CLT-20251117-001",
    "email": "juan@example.com",
    "phone": "+573001234567",
    "document": "CC-123456789",
    "approved_credit": 500000,
    "available_credit": 500000,
    "credit_plan": "6_months",
    "credit_expiry_date": "2026-05-17",
    "status": "active"
  },
  "signature": "hmac-sha256-signature-here"
}
```

---

## 🛒 Flujo de Uso de Crédito (Cuando se paga con Crédito)

### FASE 1: Cliente Realiza Compra

```
┌─────────────────────────────────────────┐
│   Cliente intenta comprar en Tenant      │
│   (elige pago con CRÉDITO)              │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│   POST /api/orders                        │
│   (Tenant API)                           │
│   + payment_method: "credit"             │
│   + amount: 150000                       │
└─────────────────────────────────────────┘
```

#### Request
```json
{
  "client_email": "juan@example.com",
  "client_phone": "+573001234567",
  "items": [
    {
      "product_id": "PROD-001",
      "quantity": 2,
      "unit_price": 75000
    }
  ],
  "total_amount": 150000,
  "payment_method": "credit",  // ← PAGO CON CRÉDITO
  "tenant_order_id": "ORD-EMPRESA1-001"
}
```

---

### FASE 2: Tenant Valida Crédito en Landlord

```
┌─────────────────────────────────────────┐
│   Tenant necesita validar crédito         │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│   POST /api/credits/validate              │
│   (Llamada a Landlord API)               │
└─────────────────────────────────────────┘
```

#### Request (desde Tenant → Landlord)
```json
{
  "client_id": "CLT-20251117-001",
  "amount_needed": 150000,
  "tenant_id": "EMPRESA1",
  "tenant_api_key": "sk_live_xxxxxxx",
  "tenant_order_id": "ORD-EMPRESA1-001"
}
```

#### Response (desde Landlord)
```json
{
  "valid": true,
  "client_id": "CLT-20251117-001",
  "available_credit": 500000,
  "requested_amount": 150000,
  "approved": true,
  "message": "Crédito disponible. Puede proceder.",
  "transaction_id": "TXN-20251117-001",
  "expires_in_seconds": 300
}
```

---

### FASE 3: Tenant Confirma Compra

```
┌─────────────────────────────────────────┐
│   Tenant confirma compra exitosa          │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│   POST /api/credits/debit                 │
│   (Llamada a Landlord para descontar)    │
└─────────────────────────────────────────┘
```

#### Request
```json
{
  "client_id": "CLT-20251117-001",
  "transaction_id": "TXN-20251117-001",
  "amount": 150000,
  "tenant_id": "EMPRESA1",
  "tenant_api_key": "sk_live_xxxxxxx",
  "order_id": "ORD-EMPRESA1-001",
  "description": "Compra en EMPRESA1"
}
```

#### Response
```json
{
  "transaction_id": "TXN-20251117-001",
  "success": true,
  "amount_debited": 150000,
  "previous_balance": 500000,
  "new_balance": 350000,
  "timestamp": "2025-11-17T19:15:00Z",
  "receipt_number": "RCP-20251117-001"
}
```

---

### FASE 4: Webhook de Confirmación

```
┌─────────────────────────────────────────┐
│   Landlord notifica a Tenant              │
│   del débito realizado                   │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│   POST /webhooks/credit-transaction       │
│   (Webhook → Tenant API)                 │
└─────────────────────────────────────────┘
```

#### Webhook Payload
```json
{
  "event": "credit.transaction",
  "event_id": "EVT-20251117-002",
  "timestamp": "2025-11-17T19:15:30Z",
  "data": {
    "client_id": "CLT-20251117-001",
    "transaction_id": "TXN-20251117-001",
    "type": "debit",
    "amount": 150000,
    "previous_balance": 500000,
    "new_balance": 350000,
    "tenant_id": "EMPRESA1",
    "tenant_order_id": "ORD-EMPRESA1-001",
    "status": "completed"
  },
  "signature": "hmac-sha256-signature-here"
}
```

---

## 💳 Métodos de Pago en Tenant

### Tipos de Pago Soportados por Tenant

```
1. CRÉDITO (Landlord)
   - Valida con Landlord
   - Descuenta crédito
   - Webhooks de confirmación

2. EFECTIVO
   - Cobro manual
   - Confirmación en punto de venta

3. TARJETA DE CRÉDITO/DÉBITO
   - Integración Stripe, MercadoPago, etc.
   - Procesamiento automatizado

4. TRANSFERENCIA BANCARIA
   - QR o número de cuenta
   - Confirmación manual o automática

5. BILLETERA DIGITAL
   - Integración Nequi, Daviplata, etc.
```

### Flujo de Pago en Tenant

```
Cliente elige método:
  ├─ CRÉDITO → Valida con Landlord → Descuenta → Webhook
  ├─ EFECTIVO → Genera recibo → Confirmación manual
  ├─ TARJETA → Procesa con proveedor → Confirma
  └─ TRANSFERENCIA → Proporciona datos → Espera confirmación
```

---

## 🔌 Endpoints Landlord API

### Gestión de Créditos

#### 1. Solicitar Crédito
```
POST /api/v1/credits/request
Content-Type: application/json
Authorization: Bearer {jwt_token}
```

**Request:**
```json
{
  "email": "cliente@example.com",
  "phone": "+57300123456",
  "document_type": "CC|PA|CE",
  "document_number": "123456789",
  "full_name": "Nombre Completo",
  "address": "Dirección",
  "credit_amount": 500000,
  "credit_plan": "3_months|6_months|12_months"
}
```

**Response:** `201 Created`
```json
{
  "credit_id": "CRD-20251117-001",
  "status": "pending_verification",
  "client_email": "cliente@example.com"
}
```

---

#### 2. Obtener Estado de Solicitud
```
GET /api/v1/credits/{credit_id}
Content-Type: application/json
Authorization: Bearer {jwt_token}
```

**Response:** `200 OK`
```json
{
  "credit_id": "CRD-20251117-001",
  "status": "approved|pending|rejected",
  "approved_amount": 500000,
  "available_balance": 350000,
  "used_amount": 150000
}
```

---

#### 3. Obtener Créditos de Cliente
```
GET /api/v1/clients/{client_id}/credits
Content-Type: application/json
Authorization: Bearer {jwt_token}
```

**Response:** `200 OK`
```json
{
  "client_id": "CLT-20251117-001",
  "credits": [
    {
      "credit_id": "CRD-20251117-001",
      "approved_amount": 500000,
      "available_balance": 350000,
      "status": "active",
      "expiry_date": "2026-05-17"
    }
  ]
}
```

---

#### 4. Validar Crédito (Llamada desde Tenant)
```
POST /api/v1/credits/validate
Content-Type: application/json
Authorization: Bearer {api_key}
X-Tenant-ID: EMPRESA1
```

**Request:**
```json
{
  "client_id": "CLT-20251117-001",
  "amount_needed": 150000,
  "tenant_id": "EMPRESA1"
}
```

**Response:** `200 OK`
```json
{
  "valid": true,
  "client_id": "CLT-20251117-001",
  "available_credit": 500000,
  "approved": true,
  "transaction_id": "TXN-20251117-001"
}
```

---

#### 5. Descontar Crédito
```
POST /api/v1/credits/debit
Content-Type: application/json
Authorization: Bearer {api_key}
X-Tenant-ID: EMPRESA1
```

**Request:**
```json
{
  "client_id": "CLT-20251117-001",
  "transaction_id": "TXN-20251117-001",
  "amount": 150000,
  "tenant_id": "EMPRESA1",
  "order_id": "ORD-EMPRESA1-001"
}
```

**Response:** `200 OK`
```json
{
  "transaction_id": "TXN-20251117-001",
  "success": true,
  "amount_debited": 150000,
  "new_balance": 350000
}
```

---

#### 6. Reembolsar Crédito
```
POST /api/v1/credits/refund
Content-Type: application/json
Authorization: Bearer {api_key}
X-Tenant-ID: EMPRESA1
```

**Request:**
```json
{
  "client_id": "CLT-20251117-001",
  "transaction_id": "TXN-20251117-001",
  "amount": 150000,
  "reason": "cancelled_order"
}
```

**Response:** `200 OK`
```json
{
  "transaction_id": "TXN-20251117-001",
  "refunded_amount": 150000,
  "new_balance": 500000
}
```

---

#### 7. Historial de Transacciones
```
GET /api/v1/clients/{client_id}/transactions
Content-Type: application/json
Authorization: Bearer {jwt_token}
```

**Query Parameters:**
- `limit`: 50
- `offset`: 0
- `type`: debit|credit|all

**Response:** `200 OK`
```json
{
  "transactions": [
    {
      "transaction_id": "TXN-20251117-001",
      "type": "debit",
      "amount": 150000,
      "timestamp": "2025-11-17T19:15:00Z",
      "tenant_id": "EMPRESA1",
      "description": "Compra en EMPRESA1"
    }
  ],
  "total": 150,
  "limit": 50,
  "offset": 0
}
```

---

## 🔌 Endpoints Tenant API

### Consulta de Créditos

#### 1. Obtener Crédito de Cliente (Búsqueda Local)
```
GET /api/v1/clients/{client_email}/credit
Content-Type: application/json
Authorization: Bearer {jwt_token}
```

**Response:** `200 OK`
```json
{
  "client_email": "juan@example.com",
  "client_id": "CLT-20251117-001",
  "available_credit": 350000,
  "status": "active"
}
```

---

#### 2. Crear Orden con Crédito
```
POST /api/v1/orders
Content-Type: application/json
Authorization: Bearer {jwt_token}
```

**Request:**
```json
{
  "client_email": "juan@example.com",
  "items": [
    {
      "product_id": "PROD-001",
      "quantity": 2,
      "unit_price": 75000
    }
  ],
  "total_amount": 150000,
  "payment_method": "credit"
}
```

**Response:** `201 Created`
```json
{
  "order_id": "ORD-EMPRESA1-001",
  "status": "pending_credit_validation",
  "total_amount": 150000
}
```

---

#### 3. Confirmar Orden (Después de validar con Landlord)
```
POST /api/v1/orders/{order_id}/confirm
Content-Type: application/json
Authorization: Bearer {jwt_token}
```

**Request:**
```json
{
  "transaction_id": "TXN-20251117-001",
  "landlord_receipt": "RCP-20251117-001"
}
```

**Response:** `200 OK`
```json
{
  "order_id": "ORD-EMPRESA1-001",
  "status": "completed",
  "total_amount": 150000
}
```

---

#### 4. Cancelar Orden (Solicita Reembolso)
```
POST /api/v1/orders/{order_id}/cancel
Content-Type: application/json
Authorization: Bearer {jwt_token}
```

**Request:**
```json
{
  "reason": "customer_request",
  "transaction_id": "TXN-20251117-001"
}
```

**Response:** `200 OK`
```json
{
  "order_id": "ORD-EMPRESA1-001",
  "status": "cancelled",
  "refund_amount": 150000
}
```

---

## 📨 Webhooks

### Webhooks que Landlord Envía a Tenant

#### 1. Cliente Aprovado
```
POST {tenant_webhook_url}/webhooks/client-approved
Content-Type: application/json
X-Webhook-Signature: sha256={signature}
X-Webhook-Event-ID: EVT-20251117-001
```

**Payload:**
```json
{
  "event": "client.approved",
  "event_id": "EVT-20251117-001",
  "timestamp": "2025-11-17T19:05:00Z",
  "data": {
    "client_id": "CLT-20251117-001",
    "email": "juan@example.com",
    "approved_credit": 500000,
    "available_credit": 500000,
    "status": "active"
  }
}
```

**Response Expected:** `200 OK`
```json
{
  "received": true,
  "event_id": "EVT-20251117-001"
}
```

---

#### 2. Transacción de Crédito Completada
```
POST {tenant_webhook_url}/webhooks/credit-transaction
Content-Type: application/json
X-Webhook-Signature: sha256={signature}
```

**Payload:**
```json
{
  "event": "credit.transaction",
  "event_id": "EVT-20251117-002",
  "timestamp": "2025-11-17T19:15:30Z",
  "data": {
    "client_id": "CLT-20251117-001",
    "transaction_id": "TXN-20251117-001",
    "type": "debit",
    "amount": 150000,
    "new_balance": 350000,
    "tenant_id": "EMPRESA1"
  }
}
```

---

#### 3. Crédito Expirado
```
POST {tenant_webhook_url}/webhooks/credit-expired
Content-Type: application/json
X-Webhook-Signature: sha256={signature}
```

**Payload:**
```json
{
  "event": "credit.expired",
  "event_id": "EVT-20251117-003",
  "timestamp": "2025-11-17T20:00:00Z",
  "data": {
    "client_id": "CLT-20251117-001",
    "email": "juan@example.com",
    "credit_id": "CRD-20251117-001",
    "expired_amount": 350000,
    "expiry_date": "2025-11-17"
  }
}
```

---

### Webhooks que Tenant Envía a Landlord

#### 1. Compra Realizada (Notificación)
```
POST https://admin.credifacilcolombia.com/api/v1/webhooks/purchase-completed
Content-Type: application/json
Authorization: Bearer {api_key}
X-Webhook-Signature: sha256={signature}
```

**Payload:**
```json
{
  "event": "purchase.completed",
  "event_id": "EVT-EMPRESA1-001",
  "timestamp": "2025-11-17T19:20:00Z",
  "data": {
    "client_id": "CLT-20251117-001",
    "transaction_id": "TXN-20251117-001",
    "amount": 150000,
    "tenant_id": "EMPRESA1",
    "order_id": "ORD-EMPRESA1-001",
    "status": "completed"
  }
}
```

---

## ❌ Errores y Validaciones

### Códigos de Error

#### 400 Bad Request
```json
{
  "error": "invalid_request",
  "message": "El email es requerido",
  "code": "MISSING_FIELD"
}
```

#### 401 Unauthorized
```json
{
  "error": "unauthorized",
  "message": "API Key inválida o expirada",
  "code": "INVALID_API_KEY"
}
```

#### 402 Payment Required
```json
{
  "error": "insufficient_credit",
  "message": "Crédito insuficiente para esta transacción",
  "code": "INSUFFICIENT_CREDIT",
  "available": 100000,
  "required": 150000
}
```

#### 403 Forbidden
```json
{
  "error": "forbidden",
  "message": "No tienes permiso para acceder a este recurso",
  "code": "FORBIDDEN"
}
```

#### 404 Not Found
```json
{
  "error": "not_found",
  "message": "Cliente no encontrado",
  "code": "CLIENT_NOT_FOUND"
}
```

#### 409 Conflict
```json
{
  "error": "conflict",
  "message": "La transacción ya fue procesada",
  "code": "DUPLICATE_TRANSACTION"
}
```

#### 429 Too Many Requests
```json
{
  "error": "rate_limited",
  "message": "Demasiadas solicitudes. Intenta más tarde",
  "code": "RATE_LIMIT_EXCEEDED",
  "retry_after": 60
}
```

#### 500 Internal Server Error
```json
{
  "error": "internal_error",
  "message": "Error interno del servidor",
  "code": "INTERNAL_ERROR"
}
```

---

### Validaciones Críticas

#### 1. Validación de Identidad
```
✓ Email válido (RFC 5322)
✓ Teléfono válido (formato E.164)
✓ Documento válido (CC, PA, CE, etc.)
✓ Nombre no vacío
✓ Dirección válida
```

#### 2. Validación de Crédito
```
✓ Monto > 0
✓ Crédito disponible >= Monto
✓ Crédito no expirado
✓ Cliente no bloqueado
✓ Transacción única (no duplicada)
```

#### 3. Validación de Tenant
```
✓ API Key válida
✓ Tenant activo
✓ Tenant no bloqueado
✓ IP en whitelist (opcional)
✓ Rate limit no excedido
```

---

## 🔐 Seguridad

### Autenticación

#### Landlord API
```
Header: Authorization: Bearer {jwt_token}
Validez: 24 horas
Refresh: Via /api/v1/auth/refresh
```

#### Tenant API (Consumidor)
```
Header: Authorization: Bearer {api_key}
Header: X-Tenant-ID: {tenant_id}
Header: X-Signature: HMAC-SHA256(payload, secret)
```

### Validación de Webhooks

```javascript
// En Tenant: validar webhook de Landlord
const crypto = require('crypto');
const signature = req.headers['x-webhook-signature'];
const body = req.rawBody;
const secret = process.env.LANDLORD_WEBHOOK_SECRET;

const hash = crypto
  .createHmac('sha256', secret)
  .update(body)
  .digest('hex');

if (hash !== signature) {
  return res.status(401).json({ error: 'Invalid signature' });
}
```

### Rate Limiting

```
Landlord API:
- 100 requests/minuto por cliente
- 1000 requests/minuto por tenant

Tenant API:
- 50 requests/minuto por cliente
- 500 requests/minuto por IP
```

### Encriptación

```
✓ Todos los endpoints: HTTPS/TLS 1.3
✓ Datos sensibles: Encriptados en DB (AES-256)
✓ API Keys: Hash SHA-256
✓ Transacciones: Signed y Timestamped
```

---

## 📝 Ejemplos Prácticos

### Ejemplo 1: Flujo Completo de Crédito

**Paso 1: Cliente solicita crédito**
```bash
curl -X POST https://admin.credifacilcolombia.com/api/v1/credits/request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGc..." \
  -d '{
    "email": "juan@example.com",
    "phone": "+573001234567",
    "document_type": "CC",
    "document_number": "123456789",
    "full_name": "Juan Pérez García",
    "credit_amount": 500000,
    "credit_plan": "6_months"
  }'
```

**Paso 2: Admin aprueba en Landlord**
```bash
# Admin revisa y aprueba en el dashboard
# Landlord ejecuta internamente:
POST /api/v1/credits/{credit_id}/verify
```

**Paso 3: Webhook a Tenant**
```
Landlord envía:
POST https://empresa1.credifacilcolombia.com/webhooks/client-approved
{
  "event": "client.approved",
  "data": {
    "client_id": "CLT-20251117-001",
    "email": "juan@example.com",
    "approved_credit": 500000,
    "available_credit": 500000
  }
}
```

**Paso 4: Cliente compra en Tenant**
```bash
curl -X POST https://empresa1.credifacilcolombia.com/api/v1/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGc..." \
  -d '{
    "client_email": "juan@example.com",
    "items": [{"product_id": "PROD-001", "quantity": 2, "unit_price": 75000}],
    "total_amount": 150000,
    "payment_method": "credit"
  }'
```

**Paso 5: Tenant valida crédito en Landlord**
```bash
curl -X POST https://admin.credifacilcolombia.com/api/v1/credits/validate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk_live_..." \
  -H "X-Tenant-ID: EMPRESA1" \
  -d '{
    "client_id": "CLT-20251117-001",
    "amount_needed": 150000,
    "tenant_id": "EMPRESA1"
  }'
```

**Paso 6: Tenant descuenta crédito**
```bash
curl -X POST https://admin.credifacilcolombia.com/api/v1/credits/debit \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk_live_..." \
  -H "X-Tenant-ID: EMPRESA1" \
  -d '{
    "client_id": "CLT-20251117-001",
    "transaction_id": "TXN-20251117-001",
    "amount": 150000,
    "tenant_id": "EMPRESA1",
    "order_id": "ORD-EMPRESA1-001"
  }'
```

**Paso 7: Landlord notifica resultado**
```
Webhook a Tenant:
POST https://empresa1.credifacilcolombia.com/webhooks/credit-transaction
{
  "event": "credit.transaction",
  "data": {
    "client_id": "CLT-20251117-001",
    "transaction_id": "TXN-20251117-001",
    "type": "debit",
    "amount": 150000,
    "new_balance": 350000
  }
}
```

---

### Ejemplo 2: Cliente sin Crédito Suficiente

```bash
# Tenant intenta validar crédito insuficiente
POST /api/v1/credits/validate
{
  "client_id": "CLT-20251117-001",
  "amount_needed": 400000,
  "tenant_id": "EMPRESA1"
}

# Respuesta (402 Payment Required)
{
  "error": "insufficient_credit",
  "available": 350000,
  "required": 400000,
  "code": "INSUFFICIENT_CREDIT"
}
```

---

### Ejemplo 3: Reembolso

```bash
# Cliente cancela orden
POST /api/v1/orders/ORD-EMPRESA1-001/cancel
{
  "reason": "customer_request",
  "transaction_id": "TXN-20251117-001"
}

# Tenant solicita reembolso a Landlord
POST /api/v1/credits/refund
{
  "client_id": "CLT-20251117-001",
  "transaction_id": "TXN-20251117-001",
  "amount": 150000,
  "reason": "cancelled_order"
}

# Respuesta
{
  "transaction_id": "TXN-20251117-001",
  "refunded_amount": 150000,
  "new_balance": 500000
}
```

---

## 📊 Diagrama de Secuencia Completo

```
┌─────────┐          ┌──────────────┐          ┌──────────┐
│ Cliente │          │ Landlord API │          │Tenant API│
└────┬────┘          └──────┬───────┘          └────┬─────┘
     │                      │                       │
     │ 1. Solicitar crédito │                       │
     ├─────────────────────>│                       │
     │                      │                       │
     │                 2. Verificar                 │
     │                      │                       │
     │                      │ 3. Webhook (aprobado) │
     │                      ├──────────────────────>│
     │                      │                       │
     │                           4. Comprar        │
     ├───────────────────────────────────────────>│
     │                      │                       │
     │                      │ 5. Validar crédito   │
     │                      │<──────────────────────┤
     │                      │                       │
     │                  6. Validar OK              │
     │                      │                       │
     │                      │ 7. Descontar crédito │
     │                      │<──────────────────────┤
     │                      │                       │
     │                  8. Debitar                 │
     │                      │                       │
     │                      │ 9. Webhook (hecho)   │
     │                      ├──────────────────────>│
     │                      │                       │
     │                      │         10. Confirmar│
     │<──────────────────────────────────────────────┤
     │                      │                       │
```

---

## 🎯 Resumen de Flujos

### Flujo de Aprobación
1. Cliente solicita crédito
2. Landlord verifica identidad
3. Landlord aprueba crédito
4. Landlord notifica a tenants (webhook)

### Flujo de Compra
1. Cliente realiza compra en tenant
2. Tenant valida crédito en landlord
3. Landlord aprueba (si hay saldo)
4. Tenant descuenta crédito
5. Landlord notifica confirmación (webhook)
6. Compra completada

### Flujo de Reembolso
1. Tenant solicita reembolso
2. Landlord restaura crédito
3. Landlord notifica cambio (webhook)

---

## 📚 Documentación Relacionada

- [README.md](./README.md) - Arquitectura general
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Deployment en producción
- [STATUS.md](./STATUS.md) - Estado del proyecto

---

**Última actualización**: 2025-11-17
**Versión**: 1.0
**Autor**: Claude Code
