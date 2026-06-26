# API Client Endpoints — Portal del Deudor

## Convenciones

- **Base URL (dev):** `http://localhost:8021/api/client`
- **Base URL (prod):** `https://{tenant}.credifacilcolombia.com/api/client`
- **Content-Type:** `application/json`
- **Auth:** `Authorization: Bearer {token_client}` (excepto login/register)
- **Todas las respuestas:** `{ "data": ..., "message": "..." }`

---

## 1. Autenticación del Deudor

### `POST /api/client/auth/login`

Inicia sesión con documento + teléfono. Envía código de verificación por **Telegram**.

**Flujo:**
1. Cliente ingresa documento + teléfono en la app
2. Backend busca el cliente y verifica que tenga `telegram_chat_id`
3. Si **NO tiene Telegram vinculado** → responde con `requires_telegram_link: true` + el deep link del bot
4. Si **SÍ tiene Telegram** → envía código de 4 dígitos al bot y responde ok

**Request:**
```json
{
  "identification": "1234567890",
  "phone": "3001234567"
}
```

**Response (200) — Cliente con Telegram:**
```json
{
  "data": {
    "client_id": 42,
    "phone": "300****567",
    "expires_in": 300,
    "channel": "telegram",
    "requires_telegram_link": false
  },
  "message": "Código enviado por Telegram"
}
```

**Response (200) — Cliente sin Telegram (primer login):**
```json
{
  "data": {
    "client_id": 42,
    "phone": "300****567",
    "requires_telegram_link": true,
    "telegram_bot_username": "credifacilcolombia_bot",
    "telegram_deep_link": "https://t.me/credifacilcolombia_bot?start=42-3001234567",
    "qr_payload": "telegram://start?client=42&phone=3001234567"
  },
  "message": "Vincula tu Telegram para recibir el código"
}
```

**Errores:**
- `404` — Cliente no encontrado
- `429` — Demasiados intentos (esperar 60s)

---

### `POST /api/client/auth/verify`

Verifica el código recibido y devuelve token de acceso.

**Request:**
```json
{
  "client_id": 42,
  "code": "847291"
}
```

**Response (200):**
```json
{
  "data": {
    "token": "1|abc123def456...",
    "token_type": "Bearer",
    "expires_in": 480,
    "client": {
      "id": 42,
      "full_name": "Juan Pérez",
      "identification": "1234567890",
      "email": "juan@email.com",
      "phone": "3001234567"
    }
  },
  "message": "Identidad verificada exitosamente"
}
```

**Errores:**
- `401` — Código inválido o expirado
- `410` — Código expirado, solicitar nuevo

---

### `POST /api/client/auth/resend`

Reenvía el código de verificación por Telegram.

**Request:**
```json
{
  "client_id": 42
}
```

**Response (200):**
```json
{
  "data": { "expires_in": 300 },
  "message": "Código reenviado por Telegram"
}
```

**Errores:**
- `429` — Cooldown 60s entre reenvíos

---

### `POST /api/client/auth/logout`

Invalida el token actual.

**Headers:** `Authorization: Bearer {token_client}`

**Response (200):**
```json
{
  "message": "Sesión cerrada exitosamente"
}
```

---

## 2. Perfil del Deudor

### `GET /api/client/me`

Datos personales del deudor autenticado.

**Response (200):**
```json
{
  "data": {
    "id": 42,
    "full_name": "Juan Pérez",
    "identification": "1234567890",
    "email": "juan@email.com",
    "phone": "3001234567",
    "status": "active",
    "created_at": "2026-01-15T10:30:00Z"
  }
}
```

---

## 3. Créditos

### `GET /api/client/credits`

Lista todos los créditos del deudor autenticado.

**Query params:**
- `status` (opcional) — Filtrar por: `active`, `pagado`, `vencido`, `cancelado`
- `page` (opcional, default 1)

**Response (200):**
```json
{
  "data": [
    {
      "id": 1,
      "code": "CRE-69A364A76A1D9",
      "amount": 1000000.00,
      "financed_amount": 1000000.00,
      "total_limit": 2000000.00,
      "available_amount": 658122.00,
      "interest_rate": 3.50,
      "term": 12,
      "installment_amount": 98500.00,
      "frequency": "mensual",
      "cutoff_day": 15,
      "status": "active",
      "start_date": "2026-01-15",
      "end_date": "2027-01-15",
      "next_payment_date": "2026-06-15",
      "next_payment_amount": 98500.00,
      "pending_installments": 7,
      "total_paid": 492500.00,
      "total_pending": 689500.00
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 15,
    "total": 2,
    "last_page": 1
  }
}
```

---

### `GET /api/client/credits/{creditId}`

Detalle completo de un crédito.

**Response (200):**
```json
{
  "data": {
    "id": 1,
    "code": "CRE-69A364A76A1D9",
    "credit_plan": {
      "name": "Crédito Libre Inversión",
      "interest_rate": 3.50,
      "frequency": "mensual"
    },
    "amount": 1000000.00,
    "initial_fee": 0.00,
    "financed_amount": 1000000.00,
    "interest_rate": 3.50,
    "term": 12,
    "installment_amount": 98500.00,
    "insurance_percentage": 0.15,
    "insurance_amount": 1500.00,
    "total_payable": 1182000.00,
    "frequency": "mensual",
    "cutoff_day": 15,
    "total_limit": 2000000.00,
    "available_amount": 658122.00,
    "status": "active",
    "start_date": "2026-01-15",
    "end_date": "2027-01-15",
    "activation_date": "2026-01-15",
    "summary": {
      "total_installments": 12,
      "paid_installments": 5,
      "pending_installments": 7,
      "overdue_installments": 0,
      "total_paid": 492500.00,
      "total_pending": 689500.00,
      "on_time_payment_rate": "100%"
    }
  }
}
```

---

### `GET /api/client/credits/{creditId}/periods`

Periodos y cuotas del crédito, agrupados por mes/periodo.

**Response (200):**
```json
{
  "data": [
    {
      "period_number": 6,
      "period_label": "Junio 2026",
      "due_date": "2026-06-15",
      "status": "pending",
      "total": 98500.00,
      "paid": 0.00,
      "remaining": 98500.00,
      "installments": [
        {
          "id": 66,
          "installment_number": 6,
          "due_date": "2026-06-15",
          "principal_amount": 80000.00,
          "interest_amount": 17000.00,
          "insurance_amount": 1500.00,
          "total_amount": 98500.00,
          "paid_amount": 0.00,
          "remaining_amount": 98500.00,
          "status": "pendiente",
          "days_overdue": 0
        }
      ]
    }
  ]
}
```

---

### `GET /api/client/credits/{creditId}/amortization`

Tabla de amortización completa.

**Response (200):**
```json
{
  "data": {
    "summary": {
      "total_principal": 1000000.00,
      "total_interest": 170000.00,
      "total_insurance": 18000.00,
      "total_payable": 1182000.00
    },
    "installments": [
      {
        "number": 1,
        "due_date": "2026-01-15",
        "initial_balance": 1000000.00,
        "principal": 80000.00,
        "interest": 17000.00,
        "insurance": 1500.00,
        "total": 98500.00,
        "final_balance": 920000.00,
        "status": "pagada",
        "paid_date": "2026-01-15"
      }
    ]
  }
}
```

---

## 4. Transacciones

### `GET /api/client/transactions`

Historial de transacciones del deudor.

**Query params:**
- `type` (opcional) — `purchase`, `payment`, `refund`
- `page` (opcional)

**Response (200):**
```json
{
  "data": [
    {
      "id": 128,
      "credit_id": 1,
      "type": "payment",
      "status": "approved",
      "amount": 98500.00,
      "previous_balance": 1000000.00,
      "new_balance": 901500.00,
      "description": "Pago cuota #6",
      "payment_method": "wompi",
      "installments_affected": [66],
      "created_at": "2026-06-15T10:30:00Z",
      "receipt_url": "/api/client/transactions/128/receipt"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 15,
    "total": 5,
    "last_page": 1
  }
}
```

---

### `GET /api/client/transactions/{id}/receipt`

Descarga el comprobante PDF de la transacción.

**Headers:** `Authorization: Bearer {token_client}`

**Response (200):**
- Content-Type: `application/pdf`
- El PDF se descarga directamente

**Errores:**
- `403` — La transacción no pertenece al deudor autenticado
- `404` — Transacción no encontrada

---

### `GET /api/client/credits/{creditId}/paz-y-salvo`

Descarga el Paz y Salvo PDF del crédito (solo si está liquidado).

**Response (200):**
- Content-Type: `application/pdf`

**Errores:**
- `400` — El crédito no está liquidado
- `403` — No pertenece al deudor

---

## 5. Pagos Online (WoMPI)

### `POST /api/client/payments/generate-link`

Genera un link de pago WoMPI para las cuotas seleccionadas.

**Request:**
```json
{
  "credit_id": 1,
  "installment_ids": [66, 67, 68],
  "amount": 295500.00,
  "description": "Pago de cuotas 6, 7 y 8",
  "callback_url": "myapp://payment/callback",
  "redirect_url": "https://micliente.credifacilcolombia.com/payment/success"
}
```

**Response (200):**
```json
{
  "data": {
    "payment_id": 42,
    "wompi_checkout_url": "https://checkout.wompi.co/l/link_abc123",
    "amount": 295500.00,
    "reference": "credifacil_42_1717000000",
    "expires_at": "2026-06-15T11:30:00Z",
    "installments": [
      {"id": 66, "number": 6, "amount": 98500.00},
      {"id": 67, "number": 7, "amount": 98500.00},
      {"id": 68, "number": 8, "amount": 98500.00}
    ]
  }
}
```

**Nota:** El `wompi_checkout_url` se abre en un WebView dentro de la app Flutter.

---

### `POST /api/client/payments/confirm`

Confirma el estado del pago después del retorno de WoMPI (polling).

**Request:**
```json
{
  "payment_id": 42,
  "wompi_transaction_id": "txn_abc123"
}
```

**Response (200):**
```json
{
  "data": {
    "payment_id": 42,
    "status": "approved",
    "amount": 295500.00,
    "credit_id": 1,
    "new_available_amount": 361622.00,
    "installments_paid": [
      {"id": 66, "status": "pagada"},
      {"id": 67, "status": "pagada"},
      {"id": 68, "status": "pagada"}
    ],
    "receipt_url": "/api/client/transactions/129/receipt",
    "created_at": "2026-06-15T10:35:00Z"
  },
  "message": "Pago aprobado exitosamente"
}
```

---

## 6. Manejo de Errores (Estándar)

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Los datos enviados son inválidos",
    "details": {
      "identification": ["El documento es requerido"],
      "phone": ["El teléfono debe tener 10 dígitos"]
    }
  }
}
```

| Código HTTP | Error | Descripción |
|-------------|-------|-------------|
| 400 | `BAD_REQUEST` | Parámetros inválidos |
| 401 | `UNAUTHORIZED` | Token inválido o expirado |
| 403 | `FORBIDDEN` | No tiene permiso para este recurso |
| 404 | `NOT_FOUND` | Recurso no encontrado |
| 409 | `CONFLICT` | Conflicto de estado (ej: crédito ya pagado) |
| 422 | `VALIDATION_ERROR` | Datos de entrada inválidos |
| 429 | `TOO_MANY_ATTEMPTS` | Demasiadas solicitudes |
| 500 | `INTERNAL_ERROR` | Error interno del servidor |
