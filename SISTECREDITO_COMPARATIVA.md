# Estudio Sistecredito → Implementación CrediFácil

> **Fecha:** 24 de junio de 2026
> **Propósito:** Documentar el análisis comparativo con Sistecredito Personas y el plan de implementación de features faltantes en CrediFácil, tanto en el portal de administración (React) como en el portal del cliente (Ionic).

---

## 1. Metodología

Se analizó el dashboard de Sistecredito Personas (`personas.sistecredito.com`) mediante:
- Extracción de cookies del navegador (perfil "laura")
- Fetch del HTML, CSS y JS del dashboard
- Mapeo de rutas y componentes de la SPA (Angular + Azure AD B2C)
- Extracción de endpoints de API desde el código JS

Paralelamente se exploraron los repositorios de CrediFácil con `git`:
- `landlord-creditapi` — API central (Laravel 11)
- `tenant-api` — API multi-tenant (Laravel 11)
- `frontend/` — Portal administración comercios (React + Vite)
- `client-portal-ionic/` — Portal del cliente (Ionic/Angular)

---

## 2. Comparativa de Features

### 2.1 Portal Administración (React) — comercios

| Feature | Sistecredito Comercios | CrediFácil React | Backend listo |
|---|---|---|---|
| Login con email+password | ✅ | ✅ | ✅ |
| Dashboard con tarjetas de resumen | ✅ | ❌ No hay landing | ⚠️ Parcial |
| Nueva solicitud de compra | ✅ | `PurchaseRequest.jsx` ✅ | ✅ |
| Simulador de crédito | ❌ No aplica | `CreditSimulator.jsx` ✅ | ✅ `POST /simulate-amortization` |
| Transacciones / historial | ✅ | `TransactionsList.jsx` ✅ | ✅ |
| Tabla de amortización | ✅ | `AmortizationPage.jsx` ✅ | ✅ |
| Periodos y pagos | ✅ | `PeriodsPage.jsx`, `PaymentsPage.jsx` ✅ | ✅ |
| Comprobante PDF compra | ✅ | `downloadReceipt()` ✅ | ✅ `GET /transactions/{id}/receipt` |
| Cargar documentación empresa | ✅ | `CompanyDocumentation.jsx` ✅ | ✅ |
| Gestión de usuarios/roles | ✅ | `UserManagement.jsx` ✅ | ✅ |
| Pagos programados (aliados) | ❌ No aplica | `ScheduledPaymentsPage.jsx` ✅ | ✅ |
| **Paz y Salvo PDF** | ✅ | ❌ No expuesto en UI | ✅ `GET /credits/{creditId}/paz-y-salvo` |
| **Perfil de usuario** (cambiar password) | ✅ | ❌ No existe | ✅ `PUT /users/{id}/reset-password` |
| **Dashboard resumen** (cards) | ✅ | ❌ No existe | ⚠️ No hay endpoint dedicado |

### 2.2 Portal Cliente (Ionic) — deudores

| Feature | Sistecredito Personas | CrediFácil Ionic | Backend listo |
|---|---|---|---|
| Login con cédula + teléfono | ✅ | `LoginComponent` ✅ | `ClientAuthController` ✅ |
| Verificación por código SMS/Telegram | ✅ | `VerifyComponent` ✅ | `VerificationController` ✅ |
| Dashboard con resumen de créditos | ✅ | `DashboardComponent` ✅ | `ClientCreditController@index` ✅ |
| Detalle de crédito | ✅ | `DetailComponent` ✅ | `ClientCreditController@show` ✅ |
| Tabla de amortización | ✅ | `AmortizationComponent` ✅ | `ClientCreditController@amortization` ✅ |
| Periodos (cuotas agrupadas) | ✅ | `PeriodsComponent` ✅ | `ClientCreditController@periods` ✅ |
| Pago de cuotas | ✅ | `PayComponent` (en proceso) | `ClientCreditController@payPeriod` ✅ |
| Historial de transacciones | ✅ | `TransactionsComponent` ✅ | `ClientCreditController@transactions` ✅ |
| Perfil + cerrar sesión | ✅ | `ProfileComponent` ✅ | `ClientAuthController@me` ✅ |
| **Simulador de crédito** | ✅ | ❌ No existe | ✅ `POST /simulate-amortization` |
| **Paz y Salvo PDF** | ✅ | ❌ No hay botón | ✅ `GET /credits/{creditId}/paz-y-salvo` |
| **Solicitar crédito / ampliar cupo** | ✅ | ❌ No existe | ❌ No existe (hay que crearlo) |
| **Notificaciones in-app** | ✅ | ❌ No existe | ❌ Solo Telegram webhook |
| **Registro autónomo** (crearse cuenta) | ✅ | ❌ No existe | ❌ No existe |

---

## 3. Arquitectura: Landlord vs Tenant

```
                    ┌─────────────────────────────────────────┐
                    │              LANDLORD                   │
                    │  (API central - DigitalOcean VPS)       │
                    │                                         │
                    │  Clients, Credits, CreditTransactions    │
                    │  TenantCompanyInfo, TenantDocument       │
                    │  AllyPayments, VerificationCodes         │
                    └──────────────┬──────────────────────────┘
                                   │ HTTP
          ┌────────────────────────┼────────────────────────┐
          │                        │                        │
          ▼                        ▼                        ▼
   ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
   │   TENANT A   │       │   TENANT B   │       │   TENANT C   │
   │  (Comercio)  │       │  (Comercio)  │       │  (Comercio)  │
   │              │       │              │       │              │
   │ CreditInst-  │       │ CreditInst-  │       │ CreditInst-  │
   │ allments     │       │ allments     │       │ allments     │
   │ Periods      │       │ Periods      │       │ Periods      │
   │ Payments     │       │ Payments     │       │ Payments     │
   │ Users, Roles │       │ Users, Roles │       │ Users, Roles │
   └──────┬───────┘       └──────┬───────┘       └──────┬───────┘
          │                      │                      │
          ▼                      ▼                      ▼
   ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
   │   IONIC      │       │   REACT      │       │   REACT      │
   │ (Cliente)    │       │ (Admin       │       │ (Admin       │
   │              │       │  comercio)   │       │  comercio)   │
   └──────────────┘       └──────────────┘       └──────────────┘
```

### Regla de ruteo

| Si modifica... | Va a... | DB |
|---|---|---|
| `Clients`, `Credits`, `CreditTransactions` | **Landlord** (proxy desde Tenant) | Central |
| `CreditInstallments`, pagos, periodos | **Tenant** directo | Local del comercio |

### Flujo de autenticación

| Portal | Tipo | Backend |
|---|---|---|
| **React** (admin comercio) | Email + password → Sanctum token | `AuthController@login` en Tenant |
| **Ionic** (cliente/deudor) | Cédula + teléfono → código Telegram → token | `ClientAuthController` en Tenant → Landlord |

---

## 4. Plan de Implementación

### Fase 1: Funcionalidades con backend listo (solo frontend)

Estas features ya tienen endpoints, solo falta la UI:

| # | Feature | Frontend | Prioridad |
|---|---|---|---|
| 1 | **Paz y Salvo PDF** en Ionic (botón "Descargar certificado" en detalle de crédito) | `client-portal-ionic` | Alta |
| 2 | **Simulador de crédito** en Ionic (pasar `CreditSimulator.jsx` del React a Ionic) | `client-portal-ionic` | Alta |
| 3 | **Perfil admin** en React (cambio de contraseña desde el sidebar) | `frontend/` | Media |
| 4 | **Dashboard resumen** en React (tarjetas con balance, cupo, deuda) | `frontend/` | Media |

### Fase 2: Solicitar crédito / ampliar cupo (backend + frontend)

Flujo completo: **Ionic (cliente) → Tenant → Landlord → aprobación manual**

| # | Capa | Lo que hay que crear |
|---|---|---|
| 5a | **Landlord** | `POST /credit-requests/request-credit` — crear crédito `pending` (sin compra) |
| 5b | **Landlord** | `POST /credit-requests/{id}/request-increase` — solicitar aumento de cupo |
| 5c | **Landlord** | `GET /credit-requests/pending` — listar solicitudes pendientes de aprobación |
| 5d | **Landlord** | `POST /credit-requests/{id}/approve` — aprobar solicitud (asigna cupo) |
| 5e | **Landlord** | `POST /credit-requests/{id}/reject` — rechazar solicitud |
| 5f | **Tenant** | `POST /client/credits/request` — proxy al landlord |
| 5g | **Tenant** | `POST /client/credits/{id}/request-increase` — proxy al landlord |
| 5h | **Ionic** | Botón "Solicitar crédito" en dashboard vacío + formulario |
| 5i | **Ionic** | Modal/opción "Ampliar cupo" en detalle de crédito |
| 5j | **React (Landlord)** | Panel de revisión de solicitudes pendientes |

### Fase 3: Mejoras post-MVP (backend + frontend)

| # | Feature | Capas |
|---|---|---|
| 6 | **Notificaciones push** | Backend (canal de notificaciones) + Ionic (badge + lista) |
| 7 | **Registro autónomo de clientes** | Landlord (registro sin comercio) + Ionic (onboarding) |
| 8 | **Pago en línea** (con pasarela) | Tenant + Landlord + Wompi/Daviplata |

---

## 5. Detalle de endpoints a crear

### 5.1 Landlord — Solicitud de crédito

```php
POST /api/credit-requests/request-credit
Body: {
    "client_identification": "1022978178",
    "client_name": "Juan Pérez",
    "client_email": "juan@email.com",
    "client_phone": "3205731318",
    "client_address": "Calle 123",
    "requested_amount": 5000000,
    "tenant_id": "comercio-x"
}
Response 201: {
    "success": true,
    "data": {
        "credit_request_id": 1,
        "status": "pending",
        "requested_amount": 5000000,
        "message": "Solicitud creada. Pendiente de aprobación."
    }
}
```

### 5.2 Landlord — Ampliación de cupo

```php
POST /api/credit-requests/{creditId}/request-increase
Body: {
    "requested_increase": 2000000,
    "reason": "Para comprar más mercancía",
    "tenant_id": "comercio-x"
}
```

### 5.3 Landlord — Aprobación/Rechazo (admin)

```php
POST /api/admin/credit-requests/{id}/approve
Body: { "approved_amount": 3000000 }
// Asigna el cupo al crédito, cambia status a "active"

POST /api/admin/credit-requests/{id}/reject  
Body: { "reason": "Documentación insuficiente" }
```

### 5.4 Tenant — Proxys para cliente

```php
POST /api/client/credits/request  → proxy a Landlord POST /credit-requests/request-credit
POST /api/client/credits/{id}/request-increase → proxy a Landlord POST /credit-requests/{id}/request-increase
```

---

## 6. Estado Actual del Código

### Backend — cambios sin commit en tenant-api

| Archivo | Estado |
|---|---|
| `app/Http/Controllers/Api/ClientAuthController.php` | ✅ Nuevo, sin commit |
| `app/Http/Controllers/Api/ClientCreditController.php` | ✅ Nuevo, sin commit |
| `app/Http/Middleware/ClientAuth.php` | ✅ Nuevo, sin commit |
| `app/Http/Middleware/InitializeClientTenancy.php` | ✅ Nuevo, sin commit |
| `app/Models/ClientToken.php` | ✅ Nuevo, sin commit |
| `database/migrations/*_create_client_tokens_table.php` | ✅ Nuevo, sin commit |
| `routes/api.php` (client routes) | ✅ Modificado, sin commit |
| `routes/tenant.php` (import) | ✅ Modificado, sin commit |

### Backend — landlord

Sin cambios detectados. Todo lo de clientes se maneja vía los endpoints existentes (`getCreditByIdentification`, `registerClient`, `requestPurchase`).

### Frontend Ionic

Todas las páginas base existen (login, verify, dashboard, credits detail, periods, amortization, pay, transactions, profile, splash). El tema está migrado a light.

---

## 7. Orden de implementación propuesto

```
Fase 1a: Paz y Salvo en Ionic (solo frontend, backend listo)
    └── Botón en detalle de crédito → descarga PDF
    
Fase 1b: Simulador en Ionic (pasar de React a Ionic)
    └── Nueva página /tabs/dashboard/simulator
    
Fase 2a: Backend Landlord (solicitud/ampliación)
    └── request-credit, request-increase, approve, reject, pending list

Fase 2b: Backend Tenant (proxy)
    └── POST /client/credits/request
    └── POST /client/credits/{id}/request-increase
    
Fase 2c: Ionic (solicitar crédito desde dashboard)
    └── Botón + formulario + estado de la solicitud

Fase 2d: React (panel de aprobación para landlord) — opcional
    └── Lista de solicitudes pendientes + aprobar/rechazar
```

---

## 8. Referencias

- **Sistecredito Personas:** `https://personas.sistecredito.com/dashboard`
- **CrediFácil React (admin comercios):** `frontend/`
- **CrediFácil Ionic (portal cliente):** `client-portal-ionic/`
- **API Landlord:** `landlord-creditapi/`
- **API Tenant:** `tenant-api/`
- **Doc flujo de créditos:** `CREDIT_FLOW.md`
- **Doc estructura BD:** `DATABASE_STRUCTURE.md`
