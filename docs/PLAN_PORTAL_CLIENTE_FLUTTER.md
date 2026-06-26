# Plan: Portal del Cliente (Deudor) con Flutter

## 1. Visión General

Crear un portal de autogestión para que el **deudor/cliente final** pueda:

- Ver el estado de sus créditos
- Consultar calendario de pagos y cuotas
- Pagar cuotas online (WoMPI)
- Descargar recibos y Paz y Salvo
- Historial de transacciones
- Recibir notificaciones push

## 2. Arquitectura Actual (Cómo funciona hoy)

### 2.1 Proyectos

```
credifacil/
├── landlord-creditapi/      → Laravel 12 + MySQL (central)
│                              Puerto: 8020, DB: 3320
│                              Rol: dueño de clientes, créditos, transacciones
├── tenant-api/               → Laravel 12 + MySQL (multi-tenant)
│                              Puerto: 8021, DB: 3321
│                              Rol: dueño de cuotas, usuarios del comercio
├── frontend/                 → React + Vite (SPA admins/operadores)
│                              Puerto: 5176
└── client-portal/            → Flutter (deudores) ← NUEVO
```

### 2.2 Base de Datos — Landlord (`landlord_creditapi` en puerto 3320)

| Tabla | Descripción | Columnas clave |
|-------|-------------|----------------|
| `clients` | Deudores | `id`, `full_name`, `identification` (UNIQUE), `email`, `phone`, `telegram_chat_id`, `status` (active/suspended/moroso) |
| `credits` | Créditos | `id`, `code`, `client_id`, `amount`, `financed_amount`, `total_limit`, `available_amount`, `status` (pendiente/activo/pagado/vencido), `cutoff_day`, `frequency` |
| `credit_transactions` | Transacciones | `id`, `credit_id`, `type` (purchase/payment/refund), `status`, `amount`, `previous_balance`, `new_balance`, `tenant_id`, `metadata` (JSON con installments_data) |
| `payment_links` | Links de pago | `id`, `credit_id`, `client_id`, `token` (UUID), `installments_data` (JSON), `total_amount`, `status`, `wompi_link_id`, `wompi_response` |
| `ally_payments` | Pagos tenant→landlord | `tenant_id`, `status`, `wompi_reference`, `payment_link_url` |
| `ally_collection_configs` | Config cobro | `tenant_id`, `max_pending_debt`, `current_pending_debt`, `commission_percentage` |
| `credit_plans` | Planes de crédito | `name`, `interest_rate`, `min_amount`, `max_amount`, `frequency` |
| `client_documents` | Documentos | `client_id`, `document_type`, `status` (pending/approved/rejected) |
| `verification_codes` | Códigos verif. | `client_id`, `phone_number`, `code`, `type` (sms/whatsapp/telegram) |
| `tenant_company_infos` | Info comercios | `tenant_id`, `commercial_name`, `billing_type`, `documents_status` |
| `roles` | Roles landlord | `id`, `name`, `permissions` (JSON) |
| `users` | Usuarios landlord | `id`, `name`, `email`, `role_id` |

### 2.3 Base de Datos — Tenant (DB separada por tenant, ej: `tenant_69279ccce227e`)

| Tabla | Descripción | Columnas clave |
|-------|-------------|----------------|
| `credit_installments` | Cuotas del crédito | `id`, `landlord_credit_id` (FK al landlord), `installment_number`, `due_date`, `principal_amount`, `interest_amount`, `insurance_amount`, `total_amount`, `paid_amount`, `remaining_amount`, `status` (pendiente/pagada/vencida/parcial), `client_id`, `payment_date`, `metadata` (JSON) |
| `users` | Usuarios del tenant | `id`, `name`, `email`, `role_id` |
| `roles` | Roles del tenant | `id`, `name`, `permissions` (JSON) — admin, manager, cashier, viewer |

### 2.4 Mapeo de Datos: Deudor vs Tenant

```
LANDLORD (central)
  clients.id  ───────────────────────────────────────┐
  credits.id (code=CRE-XXX)                          │
  credits.client_id → clients.id                     │
  credit_transactions.credit_id → credits.id         │
                                                     │
TENANT DB (tenant_XXXX)                              │
  credit_installments.landlord_credit_id ────────────┘  (mismo ID que credits.id)
  credit_installments.client_id  → clients.id           (mismo ID que clients.id)
```

**Importante:** El `client_id` en `credit_installments` apunta al mismo `clients.id` del landlord. No hay tabla `clients` en la DB del tenant. El deudor como entidad vive exclusivamente en landlord.

### 2.5 Roles Actuales

#### Landlord (central)
| Rol | Permisos |
|-----|----------|
| **superadmin** | `['*']` — acceso total |
| **admin** | `users.view`, `users.manage`, `credits.view`, `credits.approve`, `clients.view`, `clients.manage`, `allies.view`, `allies.config`, `collections.view`, `collections.manage`, `reports.view` |
| **manager** | `credits.view`, `credits.approve`, `clients.view`, `allies.view`, `collections.view`, `collections.manage`, `reports.view` |
| **viewer** | `credits.view`, `clients.view`, `allies.view`, `reports.view` |

#### Tenant (por comercio)
| Rol | Permisos |
|-----|----------|
| **admin** | `['*']` |
| **manager** | `purchases.create`, `purchases.view`, `clients.view`, `clients.register`, `reports.view`, `payments.view` |
| **cashier** | `purchases.create`, `purchases.view_own` |
| **viewer** | `purchases.view`, `reports.view` |

## 3. API Routes Existentes Relevantes para el Portal

### 3.1 Landlord API (`/api`)

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/clients/{identification}/credit` | No | Consultar crédito por identificación |
| POST | `/clients/register` | No | Registrar cliente |
| GET | `/verification/status/{clientId}` | No | Estado de verificación |
| POST | `/webhooks/wompi` | Checksum | Webhook de WoMPI |

### 3.2 Tenant API (rutas públicas y protegidas)

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/api/login` | No | Login empleado → token Sanctum |
| POST | `/api/register` | No | Registrar empleado |
| POST | `/api/logout` | Sanctum | Logout |
| GET | `/api/user` | Sanctum | Usuario actual |
| GET | `/api/clients/{identification}/credit` | Sanctum | Consultar crédito |
| POST | `/api/clients/register` | Sanctum | Registrar cliente |
| GET | `/api/credits/{landlordCreditId}/periods` | Sanctum | Periodos de un crédito |
| GET | `/api/credits/{landlordCreditId}/payment-options` | Sanctum | Opciones de pago |
| POST | `/api/payments/period` | Sanctum | Pagar periodo |
| POST | `/api/payments/pending` | Sanctum | Pagar cuotas pendientes |
| POST | `/api/payments/liquidation` | Sanctum | Liquidar crédito |
| POST | `/api/payments/single` | Sanctum | Pagar cuota individual |
| GET | `/api/purchase-requests/transactions` | Sanctum | Historial transacciones |
| GET | `/api/purchase-requests/transactions/{id}/receipt` | Sanctum | Descargar recibo PDF |
| GET | `/api/purchase-requests/transactions/{id}/status` | No | Estado transacción |
| GET | `/api/credits/{creditId}/paz-y-salvo` | Sanctum | Descargar Paz y Salvo |
| GET | `/api/installments/amortization/{landlordCreditId}` | Sanctum | Tabla de amortización |

### 3.3 Rutas Web Landlord

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/payment/{token}` | No | Página pública link de pago (solo informativa) |

## 4. Flujo de Datos Actual

### 4.1 Creación de crédito (hoy)
```
Frontend → POST /api/purchase-requests (tenant-api)
         → tenant-api consulta landlord (proxy)
         → landlord crea credit + credit_transaction
         → landlord responde OK
         → tenant-api genera installments en su DB
         → tenant-api responde al frontend
```

### 4.2 Pago presencial (hoy)
```
Cajero en Frontend → POST /api/payments/period (tenant-api)
                   → tenant-api procesa pago:
                     1. Actualiza installment(s) en su DB
                     2. Encola evento InstallmentPaid
                   → Queue worker envía webhook a landlord
                   → Landlord registra credit_transaction
                   → Landlord actualiza available_amount
                   → Landlord envía notificación Telegram al deudor
```

### 4.3 WoMPI (hoy - solo para deuda del tenant)
```
Tenant debe dinero → POST /api/debt/generate-payment-link (tenant-api)
                   → tenant-api proxyea a landlord
                   → landlord crea PaymentLink + llama WoMPI
                   → WoMPI devuelve URL de checkout
                   → Tenant paga en checkout.wompi.co
                   → WoMPI webhook → landlord-creditapi POST /api/webhooks/wompi
                   → landlord marca deuda como pagada
```

## 5. Lo Nuevo: Portal Cliente

### 5.1 Nuevos Endpoints en Tenant-API

```php
// Autenticación del deudor (NUEVO guard: client)
POST /api/client/auth/login          → {identification, phone} → token_client
POST /api/client/auth/verify         → {code} → confirmar identidad
POST /api/client/auth/logout

// Datos del deudor
GET  /api/client/me                  → Datos personales + créditos
GET  /api/client/credits             → Lista de créditos activos
GET  /api/client/credits/{id}        → Detalle + amortización
GET  /api/client/credits/{id}/periods → Periodos y cuotas
GET  /api/client/transactions        → Historial de pagos
GET  /api/client/transactions/{id}/receipt → Descargar PDF

// Pago online con WoMPI
POST /api/client/payments/generate-link → Crea link de pago WoMPI
POST /api/client/payments/confirm       → Confirmación post-pago (polling)
```

### 5.2 Flujo de Autenticación del Deudor

```
1. Deudor abre la app Flutter
2. Ingresa: número de documento + teléfono
3. Tenant-api valida contra landlord que exista el cliente
4. Si el cliente tiene telegram_chat_id vinculado:
   a. Tenant-api envía código de 4 dígitos vía Telegram Bot
   b. Cliente recibe el código en @credifacilcolombia_bot
   c. Cliente ingresa el código en la app
5. Si el cliente NO tiene telegram_chat_id (primer ingreso):
   a. La app muestra QR + deep link de Telegram
   b. Cliente escanea QR → abre Telegram Bot
   c. Bot vincula chat_id automáticamente (deep link /start)
   d. Bot envía el código de verificación al chat
   e. Cliente vuelve a la app y presiona "Ya vincule, verificar"
   f. Se completa el flujo normal (paso 4)
6. Código verificado → se genera token_client (Sanctum)
7. Token se almacena en flutter_secure_storage

El token_client tiene scope limitado:
  - Solo lectura de sus propios créditos (scope: client.credits:read)
  - Solo pago de sus propias cuotas (scope: client.payments:write)
  - No puede ver datos de otros deudores
  - No puede modificar datos del perfil

Reuso del sistema existente:
  - VerificationService::sendVerificationCode() ya soporta canal 'telegram'
  - TelegramWebhookController::handleStart() ya vincula chat_id + envía código
  - VerificationService::verifyCode() ya valida el código
  - Solo hay que exponer los endpoints correctos en tenant-api
```

**Deep link de Telegram (actual):**
```
https://t.me/credifacilcolombia_bot?start=42-3001234567
                bot_username          cliente_id-teléfono
```

### 5.3 Flujo de Pago con WoMPI

```
Deudor en Flutter app
  → Ve cuotas pendientes, selecciona cuáles pagar
  → Toca "Pagar con tarjeta/Nequi/PSE"
  → POST /api/client/payments/generate-link
     → tenant-api recibe: {credit_id, installment_ids[], amount}
     → tenant-api guarda intento de pago en landlord
     → landlord crea PaymentLink con installments_data
     → landlord llama WoMPI (WompiService::createPaymentLink)
     → landlord devuelve URL de checkout
     → tenant-api devuelve URL + token al Flutter
  → Flutter abre WebView con checkout.wompi.co
  → Deudor paga en WoMPI
  → WoMPI envía webhook: POST /api/webhooks/wompi (landlord)
     → landlord verifica checksum
     → landlord busca PaymentLink por wompi_link_id
     → landlord marca PaymentLink como pagado
     → landlord crea credit_transaction (type: payment)
     → landlord notifica a tenant-api vía webhook
        POST /api/webhooks/client-payment-received (tenant)
     → tenant-api marca cuotas como pagadas
  → Flutter recibe confirmación vía polling o Reverb WebSocket
  → Muestra recibo, opción de descargar PDF
```

### 5.4 Estructura del Proyecto Flutter

```
client-portal/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── config/
│   │   │   └── env.dart                ← URLs tenant-api, WoMPI public key
│   │   ├── theme/
│   │   │   └── app_theme.dart          ← Colores corporativos (matoxi)
│   │   ├── network/
│   │   │   ├── api_client.dart         ← Dio HTTP client
│   │   │   ├── api_interceptor.dart    ← Token interceptor + refresh
│   │   │   └── api_endpoints.dart      ← Constantes de rutas
│   │   └── utils/
│   │       ├── currency_formatter.dart ← Formato COP
│   │       └── date_formatter.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── client.dart
│   │   │   ├── credit.dart
│   │   │   ├── installment.dart
│   │   │   ├── period.dart
│   │   │   ├── transaction.dart
│   │   │   └── payment_link.dart
│   │   └── repositories/
│   │       ├── auth_repository.dart
│   │       ├── credit_repository.dart
│   │       ├── payment_repository.dart
│   │       └── transaction_repository.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── credit_provider.dart
│   │   └── payment_provider.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── verify_code_screen.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart       ← Resumen: saldo, próx cuota
│   │   ├── credits/
│   │   │   ├── credit_list_screen.dart
│   │   │   ├── credit_detail_screen.dart   ← Amortización completa
│   │   │   └── period_detail_screen.dart   ← Cuotas de un periodo
│   │   ├── payments/
│   │   │   ├── payment_select_screen.dart  ← Seleccionar cuotas a pagar
│   │   │   ├── wompi_webview_screen.dart   ← WebView checkout WoMPI
│   │   │   └── payment_confirmation_screen.dart
│   │   ├── transactions/
│   │   │   └── transaction_history_screen.dart
│   │   ├── receipts/
│   │   │   └── receipt_viewer_screen.dart  ← Ver/descargar PDF
│   │   └── profile/
│   │       └── profile_screen.dart         ← Datos, soporte, cerrar sesión
│   └── widgets/
│       ├── credit_card.dart
│       ├── installment_tile.dart
│       ├── status_badge.dart
│       ├── payment_method_selector.dart
│       └── loading_overlay.dart
├── web/                         ← PWA (mismo código)
├── android/                     ← APK (mismo código)
└── ios/                         ← IPA (mismo código)
```

### 5.5 Estados de la App (State Machine)

```
                  ┌──────────────┐
                  │   Splash     │
                  └──────┬───────┘
                         │
                  ┌──────▼───────┐
           ┌──────│  ¿Token?     │──────┐
           │      └──────┬───────┘      │
           │ NO          │ SI           │
     ┌─────▼─────┐ ┌─────▼──────┐      │
     │  Login    │ │ Validar    │      │
     │ (doc+tel) │ │ Token      │      │
     └─────┬─────┘ └─────┬──────┘      │
           │ SI          │ Válido      │
     ┌─────▼─────┐       │             │
     │ Verificar │       │             │
     │ (código)  │       │             │
     └─────┬─────┘       │             │
           │ OK          │             │
           └──────┬──────┘             │
                  │                    │
           ┌──────▼────────────────────┘
           │      Dashboard
           │  ┌──────────────────┐
           │ │  Resumen crédito  │
           │ │  Próximo pago     │
           │ │  Estado cuenta    │
           │  └──────────────────┘
           │         │
           │    ┌────┴────┐
           │    ▼         ▼
           │ Créditos   Pagos
           │    │         │
           │    ▼         ▼
           │ Detalle   WoMPI
           │    │      WebView
           │    ▼
           │ Recibos
           │ PDF
           │
           └───── Cerrar sesión ───→ Login
```

## 6. Modificaciones Necesarias en el Backend

### 6.1 Tenant-API (nuevos archivos)

```
app/Http/Controllers/Api/ClientAuthController.php   ← Auth para deudores
app/Http/Controllers/Api/ClientCreditController.php ← Consultas del deudor
app/Http/Controllers/Api/ClientPaymentController.php← Pago online
app/Services/ClientAuthService.php                  ← Lógica de auth
app/Services/ClientPaymentService.php               ← Lógica de pago WoMPI
routes/client.php                                   ← Rutas para deudores
```

### 6.2 Landlord-CreditAPI

```
app/Http/Controllers/Api/ClientPaymentLinkController.php ← Crear link WoMPI
```

No se requieren nuevas tablas. Se reusan:
- `clients` (ya existe)
- `credits` (ya existe)
- `credit_transactions` (ya existe)
- `payment_links` (ya existe, actualmente informativo)
- `credit_installments` (ya existe en tenant DB)

### 6.3 CORS

Agregar origen del portal Flutter web en `config/cors.php` del tenant-api:

```php
'allowed_origins' => [
    env('CLIENT_PORTAL_URL', 'http://localhost:5177'),
    // ...
],
```

## 7. Plan de Implementación

| Fase | Tareas | Dependencias |
|------|--------|-------------|
| **Fase 1: Auth** | Endpoint login deudor, verificación SMS, token scoped | Ninguna |
| **Fase 2: Consultas** | Endpoints: mis créditos, detalle, amortización, periodos | Fase 1 |
| **Fase 3: Flutter** | Proyecto Flutter: auth, dashboard, créditos, transacciones | Fase 1, 2 |
| **Fase 4: Pagos WoMPI** | Endpoint generar link, WebView, webhook, confirmación | Fase 2 |
| **Fase 5: Recibos PDF** | Endpoints descarga, visor PDF en Flutter | Fase 3 |
| **Fase 6: Notificaciones** | Push notifications (Firebase) | Fase 5 |
| **Fase 7: PWA + APK** | Build web, Android, iOS | Fase 6 |

## 8. Riesgos y Consideraciones

- **WoMPI requiere HTTPS** en producción. El webhook debe apuntar a URL pública.
- **SMS verification** requiere servicio de SMS (Twilio, etc.) o reforzar vía WhatsApp/Telegram.
- **Seguridad**: El token del deudor debe tener alcance limitado (no puede ver otros clientes).
- **Multi-tenancy abstracto**: El deudor puede pertenecer a un tenant, pero los endpoints del portal cliente deben funcionar sin exponer la estructura multi-tenant. El `tenant_id` se resuelve automáticamente desde el landlord.
