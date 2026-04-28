# Plan General del Proyecto CrediFácil

**Fecha:** 2026-01-06
**Sistema:** Multi-tenant para gestión de créditos

---

## 📐 Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                    LANDLORD (Puerto 8020)                       │
│  - Gestión centralizada de créditos                            │
│  - Aprobación de solicitudes de crédito                        │
│  - Gestión de aliados/comerciantes                             │
│  - Panel administrativo Livewire + Jetstream                   │
└─────────────────────────────────────────────────────────────────┘
                            ↕ API REST + WebSockets
┌─────────────────────────────────────────────────────────────────┐
│                  TENANT-API (Puerto 8021)                       │
│  - Multi-tenancy (cada comerciante tiene su BD)                │
│  - Registro de comerciantes                                    │
│  - Gestión de cuotas e installments                            │
│  - Webhooks para recibir aprobaciones                          │
│  - Backend Laravel + Stancl Tenancy                            │
└─────────────────────────────────────────────────────────────────┘
                            ↕ API REST
┌─────────────────────────────────────────────────────────────────┐
│                   FRONTEND (Puerto 5176)                        │
│  - Interfaz para comerciantes                                  │
│  - Solicitud de créditos                                       │
│  - Gestión de cuotas y pagos                                   │
│  - React 19 + Vite                                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## ✅ Completado (Sesiones Anteriores)

### Backend - Tenant API
- ✅ Sistema multi-tenant con Stancl Tenancy
- ✅ Registro de comerciantes (TenantRegistrationController)
- ✅ Tabla credit_installments con metadata
- ✅ Sistema de cuotas por transacción (InstallmentParent)
- ✅ WebhookController para recibir aprobaciones de landlord
- ✅ Eventos de broadcasting (TransactionApproved)
- ✅ Configuración de Pusher.com para WebSockets
- ✅ Endpoints de verificación de clientes
- ✅ Endpoints para gestión de compras y cuotas
- ✅ Sistema de pagos con modal interactivo

### Backend - Landlord
- ✅ Sistema de gestión de clientes
- ✅ Sistema de créditos y transacciones
- ✅ Panel LiveWire: PendingCredits (solicitudes pendientes)
- ✅ Panel LiveWire: ActiveCredits (créditos activos)
- ✅ Sistema de aprobación con configuración de términos
- ✅ Webhooks para notificar a tenants
- ✅ Sistema de verificación de clientes (VerificationService)
- ✅ Modelos: Client, Credit, CreditTransaction, VerificationCode, ClientDocument

### Frontend
- ✅ Registro de comerciantes (TenantRegistration)
- ✅ Login y autenticación multi-tenant
- ✅ Lista de transacciones (TransactionsList)
- ✅ Solicitud de compras (PurchaseRequest)
- ✅ Verificación de clientes (ClientVerification)
- ✅ Vista de períodos de pago (PeriodsTable)
- ✅ Modal de pagos (PaymentModal)
- ✅ WebSocket listener con Pusher para notificaciones en tiempo real
- ✅ Estilos Credifacil Design System aplicados

---

## 🚧 En Desarrollo

### 1. Sistema de WebSockets y Notificaciones en Tiempo Real

#### Estado Actual:
- ✅ Frontend: Configurado con Pusher, escuchando eventos
- ✅ Tenant-API: Evento TransactionApproved configurado
- ❌ Landlord: NO tiene broadcasting configurado

#### Tareas Pendientes:
- [ ] **Configurar Pusher en Landlord (.env)**
  - Agregar credenciales de Pusher
  - PUSHER_APP_ID, PUSHER_APP_KEY, PUSHER_APP_SECRET, PUSHER_APP_CLUSTER

- [ ] **Instalar Laravel Reverb o usar Pusher en Landlord**
  - `composer require laravel/reverb` (si no está)
  - Publicar configuración de broadcasting

- [ ] **Crear eventos de broadcasting en Landlord**
  - `CreditApproved` - Cuando se aprueba un crédito
  - `CreditRejected` - Cuando se rechaza un crédito
  - `TenantRegistered` - Cuando se registra un nuevo aliado

- [ ] **Disparar eventos desde PendingCredits**
  - En `approveCredit()` disparar `CreditApproved`
  - En `rejectCredit()` disparar `CreditRejected`

- [ ] **Escuchar eventos en Frontend**
  - Notificaciones de aprobación/rechazo
  - Toast notifications o modals

#### Archivos a Modificar:
```
landlord-creditapi/
├── .env (agregar PUSHER_*)
├── config/broadcasting.php (verificar)
├── app/Events/CreditApproved.php (crear)
├── app/Events/CreditRejected.php (crear)
└── app/Livewire/PendingCredits.php (modificar approveCredit)
```

---

### 2. Gestión de Aliados/Comerciantes ✅ (95% Completado)

#### Objetivo:
Panel en Landlord para gestionar los comerciantes que se registran en el sistema.

#### Estado: EN PRODUCCIÓN
- ✅ API de métricas implementada
- ✅ Panel de gestión funcional
- ⚠️ Falta: Cambio de estado de aliados (updateStatus)

---

##### FASE 1: API en Tenant-API (8021) - Endpoints de Métricas ✅
- ✅ **AlliesController creado** (/app/Http/Controllers/Api/AlliesController.php)

- ✅ **Endpoint GET /api/allies/summary**
  - Calcula métricas en tiempo real desde credit_installments
  - `total_collected`: Suma de paid_amount
  - `total_credits_generated`: Suma de montos de installment_number = 0
  - `active_credits`: Count de créditos con cuotas pendientes
  - `total_clients`: Count de client_id únicos
  - `pending_installments`: Cuotas en estado pendiente/parcial/vencida
  - `total_pending_amount`: Monto total pendiente de cobro

- ✅ **Endpoint GET /api/allies/credits**
  - Lista paginada de créditos agrupados por landlord_credit_id
  - Incluye: monto total, pagado, pendiente, progreso %
  - Paginación: per_page, page

- ✅ **Endpoint GET /api/allies/credits/{landlordCreditId}**
  - Detalles completos de un crédito
  - Lista todas las cuotas con estado y pagos
  - Resumen del crédito

- ✅ **Rutas agregadas en routes/tenant.php**
  ```php
  Route::prefix('allies')->group(function () {
      Route::get('/summary', [AlliesController::class, 'summary']);
      Route::get('/credits', [AlliesController::class, 'credits']);
      Route::get('/credits/{landlordCreditId}', [AlliesController::class, 'creditDetails']);
  });
  ```

- ✅ **Endpoint GET /api/tenants** (TenantRegistrationController::index)
  - Lista todos los tenants registrados
  - Incluye: id, name, email, phone, domain, status, created_at

- ⚠️ **Autenticación deshabilitada temporalmente**
  - Rutas sin `auth:sanctum` para facilitar desarrollo
  - **IMPORTANTE**: Agregar auth antes de producción

##### FASE 2: Panel en Landlord (8020) ✅
- ✅ **Componente Livewire AlliesManagement creado**
  - Archivo: `/app/Livewire/AlliesManagement.php`
  - Consulta `/api/tenants` para lista de aliados
  - Para cada tenant consulta `/api/allies/summary` con header Host
  - Usa `host.docker.internal:8021` para comunicación desde Docker
  - Métodos implementados:
    - `loadAllies()`: Carga lista completa con métricas
    - `selectAlly()`: Ver detalles de un aliado
    - `fetchTenantMetrics()`: Obtiene métricas de un tenant
    - `fetchTenantCredits()`: Obtiene créditos de un tenant
  - Búsqueda por nombre/dominio funcional
  - Manejo robusto de errores

- ✅ **Vista allies-management.blade.php creada**
  - Tabla con columnas implementadas:
    - ✅ Nombre del Aliado
    - ✅ Estado (badge con colores)
    - ✅ Total Recolectado ($ de cuotas pagadas)
    - ✅ Créditos Generados ($ total de créditos)
    - ✅ Créditos Activos (cantidad)
    - ✅ Total Clientes (cantidad)
    - ✅ Última Actualización
    - ✅ Acciones (Ver detalles)
  - ✅ Buscador por nombre/dominio funcional
  - ✅ Botón de actualizar (refresh)
  - ✅ Estados de loading y error
  - ✅ Diseño Tailwind CSS profesional

- ✅ **Ruta /allies/manage agregada**
  - Archivo: `routes/web.php`
  ```php
  Route::get('/allies/manage', AlliesManagement::class)->name('allies.manage');
  ```

- ✅ **Opción en menú de navegación agregada**
  - Archivo: `resources/views/navigation-menu.blade.php`
  - Enlace a "Aliados" visible en menú responsive

#### Archivos Creados/Modificados: ✅
```
tenant-api/
├── app/Http/Controllers/TenantRegistrationController.php ✅ (modificado - index())
├── app/Http/Controllers/Api/AlliesController.php ✅ (creado - 3 endpoints)
└── routes/
    ├── api.php ✅ (modificado - GET /api/tenants)
    └── tenant.php ✅ (modificado - rutas /allies/*)

landlord-creditapi/
├── app/Livewire/AlliesManagement.php ✅ (creado)
├── resources/views/livewire/allies-management.blade.php ✅ (creado)
├── routes/web.php ✅ (modificado - ruta allies.manage)
└── resources/views/navigation-menu.blade.php ✅ (modificado - enlace menú)
```

#### Tareas Pendientes:
- [ ] **Endpoint PUT /api/tenants/{id}/status**
  - Para cambiar estado de aliados (pending → active → inactive → suspended)
  - TenantRegistrationController::updateStatus()

- [ ] **Botones de acción en panel**
  - Aprobar aliado (pending → active)
  - Suspender aliado (active → suspended)
  - Reactivar aliado (suspended → active)

- [ ] **Agregar autenticación a rutas /api/allies/***
  - Middleware auth:sanctum
  - Sistema de API tokens por tenant

- [ ] **Dashboard de métricas agregadas**
  - Total recaudado de todos los aliados
  - Total de aliados activos/pendientes/suspendidos
  - Gráfica de tendencias

---

### 3. Sistema de Verificación de Clientes (Integración Completa)

#### Estado Actual:
- ✅ Backend completo en Landlord (VerificationService)
- ✅ Modelos y migraciones creados
- ✅ Endpoints API creados
- ❌ NO probado end-to-end
- ❌ NO integrado servicio de SMS/WhatsApp real

#### Tareas Pendientes:
- [ ] **Probar flujo completo de verificación**
  - Cliente solicita código
  - Se envía SMS/WhatsApp
  - Cliente ingresa código
  - Sistema valida

- [ ] **Integrar servicio de mensajería real**
  - Opciones: Twilio, MessageBird, Vonage
  - Configurar credenciales
  - Actualizar `VerificationService::dispatchCode()`

- [ ] **Commitear cambios pendientes en Landlord**
  - VerificationService
  - VerificationController
  - Modelos: VerificationCode, ClientDocument
  - Migraciones

#### Archivos Pendientes de Commit:
```
landlord-creditapi/
├── app/Services/VerificationService.php
├── app/Http/Controllers/Api/VerificationController.php
├── app/Models/VerificationCode.php
├── app/Models/ClientDocument.php
├── database/migrations/2025_12_02_000001_create_verification_codes_table.php
├── database/migrations/2025_12_02_000002_create_client_documents_table.php
└── database/migrations/2025_12_02_000003_add_phone_verified_at_to_clients_table.php
```

---

## 📋 Backlog de Características

### Prioridad Alta
1. **Dashboard con métricas**
   - Total de aliados activos
   - Total de créditos aprobados/pendientes
   - Monto total financiado
   - Gráficas de tendencias

2. **Sistema de reportes**
   - Exportar listado de aliados a Excel/PDF
   - Reporte de créditos por período
   - Reporte de pagos

3. **Historial de cambios**
   - Log de aprobaciones/rechazos
   - Log de cambios de estado de tenants
   - Auditoría de transacciones

### Prioridad Media
4. **Mejoras de seguridad**
   - API Key compartida entre Landlord y Tenant-API
   - Rate limiting en endpoints públicos
   - Validación de firma en webhooks (ya existe parcialmente)

5. **Sistema de roles y permisos**
   - Super admin
   - Analista de crédito
   - Operador

6. **Notificaciones por email**
   - Al aprobar/rechazar crédito
   - Al registrar nuevo aliado
   - Recordatorios de pago

### Prioridad Baja
7. **Configuración de términos de crédito**
   - Planes de crédito predefinidos
   - Tasas de interés por tipo de comercio
   - Límites de crédito automatizados

8. **Chat de soporte**
   - Entre landlord y tenant
   - Sistema de tickets

9. **App móvil**
   - Para comerciantes
   - Para clientes finales

---

## 🔧 Tareas Técnicas Pendientes

### Optimizaciones
- [ ] Implementar caché para consultas frecuentes
- [ ] Optimizar queries N+1 con eager loading
- [ ] Configurar queue workers para jobs pesados
- [ ] Implementar rate limiting

### Testing
- [ ] Tests unitarios para servicios críticos
- [ ] Tests de integración para flujo de crédito
- [ ] Tests E2E con Playwright/Cypress

### DevOps
- [ ] Configurar CI/CD
- [ ] Scripts de backup automático
- [ ] Monitoreo con Sentry o similar
- [ ] Logging estructurado

### Documentación
- [ ] API documentation con Swagger/OpenAPI
- [ ] Manual de usuario para comerciantes
- [ ] Manual de administración para landlord
- [ ] Guía de despliegue

---

## 📅 Cronograma Sugerido

### Semana 1 (Actual) - ✅ 100% Completada
- [x] Implementar WebSockets con Pusher (Frontend + Tenant-API)
- [x] Sistema de verificación de clientes (Backend)
- [x] **Gestión de Aliados - FASE 1** (API en Tenant-API)
- [x] **Gestión de Aliados - FASE 2** (Panel en Landlord)

### Semana 2
- [ ] Completar broadcasting en Landlord
- [ ] Probar flujo completo de WebSockets
- [ ] Dashboard con métricas básicas
- [ ] Sistema de reportes básico

### Semana 3
- [ ] Integración de SMS/WhatsApp
- [ ] Historial de cambios y auditoría
- [ ] Mejoras de seguridad (API Keys)
- [ ] Testing básico

### Semana 4
- [ ] Sistema de roles y permisos
- [ ] Notificaciones por email
- [ ] Optimizaciones de rendimiento
- [ ] Documentación completa

---

## 🎯 Próximos Pasos Inmediatos

### ✅ Completado Hoy (2026-01-06)
1. ✅ Crear documento de planificación
2. ✅ **Gestión de Aliados - FASE 1 Completada**
   - ✅ AlliesController con 3 endpoints de métricas
   - ✅ Endpoint GET /api/tenants
   - ✅ Rutas configuradas
3. ✅ **Gestión de Aliados - FASE 2 Completada**
   - ✅ Componente Livewire AlliesManagement
   - ✅ Vista allies-management.blade.php
   - ✅ Integración con API funcionando
   - ✅ Buscador y métricas en tiempo real

### Hoy - Siguiente (Prioridad 1)
4. [ ] **Probar flujo completo del panel de aliados**
   - Verificar que carga lista de tenants
   - Verificar que muestra métricas correctas
   - Probar búsqueda
5. [ ] **Commitear cambios**
   - Tenant-API: AlliesController + routes
   - Landlord: AlliesManagement + vista + routes

### Esta Semana (Prioridad 2)
6. [ ] Implementar cambio de estado de aliados (updateStatus)
7. [ ] Configurar Broadcasting completo en Landlord
8. [ ] Probar flujo end-to-end de notificaciones WebSocket
9. [ ] Crear dashboard básico con métricas agregadas

---

## 📝 Notas Importantes

### Decisiones Técnicas
- **WebSockets:** Pusher.com (free tier suficiente para desarrollo)
- **Arquitectura:** Multi-tenant con bases de datos separadas (Stancl Tenancy)
- **Comunicación:** REST API + WebSockets + Webhooks
- **Frontend:** React 19 (sin router, multitenancy por dominio)
- **Backend:** Laravel 12 + Livewire + Jetstream

### URLs del Sistema
- **Landlord Admin:** http://localhost:8020
- **Tenant API:** http://localhost:8021
- **Frontend:** http://localhost:5176 (registro) + {tenant}.localhost:5176 (app)

### Entorno Docker
- Usar `host.docker.internal` para comunicación entre contenedores
- Tenant-API corre en Docker Sail
- Landlord corre en Docker Sail
- Frontend corre en host (npm run dev)

---

## 🐛 Problemas Conocidos

1. **Laravel Reverb v1.6.3 tiene bugs**
   - Solución: Usar Pusher.com directamente
   - Issue: #329, #212 en GitHub

2. **Soketi tuvo problemas de conexión**
   - Solución: Migrado a Pusher.com
   - Soketi container detenido

3. **Permisos en migraciones**
   - Problema: Permission denied en archivos de migración
   - Solución: `chmod -R 755 database/migrations/`

---

**Última actualización:** 2026-01-06
**Responsables:** Claude Code + Usuario
**Estado:** En Desarrollo Activo
