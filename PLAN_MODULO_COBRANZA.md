# Plan de Implementación: Módulo de Gestión de Cobranza

## Resumen Ejecutivo

Crear un módulo de cobranza en **landlord-creditapi** que unifique la vista de todos los clientes, clasifique cuáles están en mora o próximos a vencer, y genere enlaces de pago únicos para compartir.

## Requisitos Funcionales

1. **Vista unificada en landlord** (vista global de todos los tenants)
2. **Clasificación de clientes:**
   - **Para Cobranza**: Cuotas vencidas O próximas a vencer en el período
   - **Al Día**: Sin cuotas vencidas ni próximas a vencer
3. **Generación de enlaces de pago:**
   - Solo incluye cuotas del período (vencidas + próximas a vencer)
   - Token/UUID único para compartir vía WhatsApp/SMS
   - Sin integración con pasarela (solo información, pago manual)
4. **Agregar opción al sidebar**

---

## Arquitectura de la Solución

### 1. Nuevo Modelo: PaymentLink

**Archivo:** `landlord-creditapi/app/Models/PaymentLink.php`

**Propósito:** Almacenar enlaces de pago generados con snapshot de cuotas

**Campos:**
- `credit_id` (FK a credits)
- `client_id` (FK a clients)
- `token` (UUID único)
- `installments_data` (JSON con snapshot de cuotas incluidas)
- `total_amount` (monto total calculado)
- `status` (active, paid, expired, cancelled)
- `expires_at` (fecha de expiración)
- `paid_at` (fecha de pago, nullable)
- `notes` (notas adicionales, nullable)

**Métodos:**
- `isExpired()`: Verifica si el enlace está expirado
- `isActive()`: Verifica si está activo y no expirado

---

### 2. Componente Livewire: CollectionManagement

**Archivo:** `landlord-creditapi/app/Livewire/CollectionManagement.php`

**Propósito:** Componente principal del módulo de cobranza

**Propiedades:**
- `$activeTab` (for_collection | up_to_date)
- `$search` (búsqueda por nombre o identificación)
- `$daysAhead` (días para considerar "próximas a vencer", default: 5)
- `$showLinkModal` (mostrar modal de enlace generado)
- `$generatedLink` (URL del enlace generado)
- `$linkExpirationDays` (días de validez del enlace, default: 7)

**Métodos principales:**

1. **`getClientsData()`**
   - Obtiene todos los créditos activos
   - Consulta cuotas de cada crédito desde tenant-api
   - Clasifica clientes según estado de cuotas
   - Retorna array con clientes "para cobranza" y "al día"

2. **`classifyClient($installmentsData)`**
   - Analiza cuotas de un crédito
   - Identifica cuotas vencidas (due_date < hoy)
   - Identifica cuotas próximas a vencer (hoy <= due_date <= hoy + N días)
   - Calcula totales y conteos
   - Retorna clasificación completa

3. **`fetchInstallmentsFromTenant($credit)`**
   - Consulta endpoint `/api/installments/amortization/{landlordCreditId}` del tenant
   - Usa HTTP con header `Host: {tenant_domain}`
   - Maneja errores y timeouts
   - Retorna array de cuotas

4. **`generatePaymentLink($creditId)`**
   - Obtiene cuotas relevantes del período
   - Calcula monto total
   - Crea registro en `payment_links` con token UUID
   - Genera URL pública
   - Muestra modal con enlace para copiar

**Flujo de datos:**
```
Credit (landlord)
    → HTTP request a tenant-api
    → Obtiene cuotas (CreditInstallment)
    → Clasifica según fechas y estado
    → Muestra en UI
    → Genera enlace con snapshot
```

---

### 3. Vista Blade: collection-management.blade.php

**Archivo:** `landlord-creditapi/resources/views/livewire/collection-management.blade.php`

**Estructura:**

1. **Header**
   - Título "Gestión de Cobranza"
   - Input para configurar días adelantados

2. **Barra de búsqueda**
   - Búsqueda por nombre o identificación

3. **Tabs**
   - Tab "Para Cobranza" con contador
   - Tab "Al Día" con contador

4. **Tabla "Para Cobranza"**
   - Columnas: Cliente, Identificación, Cuotas Vencidas, Próximas a Vencer, Total a Cobrar, Acciones
   - Botón "Generar Enlace" por cliente
   - Badges de colores: rojo (vencidas), amarillo (próximas)

5. **Tabla "Al Día"**
   - Columnas: Cliente, Identificación, Próxima Cuota, Estado
   - Badge verde "Al día"

6. **Modal de Enlace Generado**
   - Header con gradiente verde (estilo CrediFácil)
   - Input readonly con URL del enlace
   - Botón "Copiar" para copiar al portapapeles
   - Información de validez (7 días)

**Estilos:** Tailwind CSS con colores CrediFácil (#009161, #183D4A)

---

### 4. Controlador: PaymentLinkController

**Archivo:** `landlord-creditapi/app/Http/Controllers/PaymentLinkController.php`

**Método: `show($token)`**
- Busca el enlace por token
- Valida que esté activo y no expirado
- Si está expirado → vista de enlace expirado
- Si está activo → vista con detalle de cuotas

---

### 5. Vistas Públicas de Enlace

#### Vista Principal: payment-link/show.blade.php

**Archivo:** `landlord-creditapi/resources/views/payment-link/show.blade.php`

**Contenido:**
- Header con logo y título "Resumen de Pago"
- Información del cliente (nombre, identificación)
- Lista de cuotas pendientes con:
  - Número de cuota
  - Fecha de vencimiento
  - Monto pendiente
  - Badge: VENCIDA (rojo) o PRÓXIMA A VENCER (amarillo)
- Total a pagar destacado
- Instrucciones de pago
- Información de validez del enlace

#### Vista Expirada: payment-link/expired.blade.php

**Archivo:** `landlord-creditapi/resources/views/payment-link/expired.blade.php`

**Contenido:**
- Ícono de error
- Mensaje "Enlace Expirado"
- Instrucciones para contactar asesor

---

### 6. Rutas

**Archivo:** `landlord-creditapi/routes/web.php`

**Rutas protegidas (con auth):**
```php
Route::get('/collections/manage', CollectionManagement::class)->name('collections.manage');
```

**Rutas públicas (sin auth):**
```php
Route::get('/payment/{token}', [PaymentLinkController::class, 'show'])->name('payment.link');
```

---

### 7. Modificación del Sidebar

**Archivo:** `landlord-creditapi/resources/views/components/sidebar-menu.blade.php`

**Agregar después de la sección "Créditos":**
```blade
<!-- Cobranza -->
<a href="{{ route('collections.manage') }}"
   class="sidebar-nav-link {{ request()->routeIs('collections.manage') ? 'sidebar-nav-link-active' : '' }}">
    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path>
    </svg>
    <span>Gestión de Cobranza</span>
</a>
```

---

## Base de Datos

### Migración: create_payment_links_table.php

**Archivo:** `landlord-creditapi/database/migrations/2026_01_14_000001_create_payment_links_table.php`

```php
Schema::create('payment_links', function (Blueprint $table) {
    $table->id();
    $table->foreignId('credit_id')->constrained()->onDelete('cascade');
    $table->foreignId('client_id')->constrained()->onDelete('cascade');
    $table->string('token')->unique();
    $table->json('installments_data');
    $table->decimal('total_amount', 12, 2);
    $table->enum('status', ['active', 'paid', 'expired', 'cancelled'])->default('active');
    $table->timestamp('expires_at');
    $table->timestamp('paid_at')->nullable();
    $table->text('notes')->nullable();
    $table->timestamps();

    $table->index(['token', 'status']);
    $table->index('credit_id');
});
```

---

## Lógica de Clasificación

### Criterios "Para Cobranza"

Un cliente está **para cobranza** si tiene al menos una de estas condiciones:

1. **Cuotas vencidas:**
   - `due_date < hoy`
   - `status IN ('pendiente', 'parcial')`
   - `remaining_amount > 0`

2. **Cuotas próximas a vencer:**
   - `hoy <= due_date <= hoy + N días` (N configurable, default: 5)
   - `status IN ('pendiente', 'parcial')`
   - `remaining_amount > 0`

### Criterios "Al Día"

Un cliente está **al día** si:
- NO tiene cuotas vencidas
- NO tiene cuotas próximas a vencer en el período configurado

### Información Mostrada

**Para Cobranza:**
- Número de cuotas vencidas
- Monto total vencido
- Número de cuotas próximas a vencer
- Monto total próximo a vencer
- Total a cobrar (suma de ambos)

**Al Día:**
- Próxima fecha de vencimiento
- Estado "Al día"

---

## Generación de Enlaces

### Estructura del Token

- **Tipo:** UUID v4 generado con `Str::uuid()`
- **Formato:** `550e8400-e29b-41d4-a716-446655440000`
- **Único:** Garantizado por base de datos (unique index)

### URL del Enlace

```
https://credifacil.com/payment/550e8400-e29b-41d4-a716-446655440000
```

### Expiración

- **Por defecto:** 7 días desde la generación
- **Configurable:** Variable `$linkExpirationDays` en el componente
- **Validación:** Se verifica en cada acceso al enlace

### Datos del Snapshot

El campo `installments_data` almacena JSON con:
```json
[
  {
    "installment_number": 1,
    "due_date": "2026-01-10",
    "total_amount": 150.00,
    "remaining_amount": 150.00,
    "status": "vencida"
  },
  {
    "installment_number": 2,
    "due_date": "2026-01-18",
    "total_amount": 150.00,
    "remaining_amount": 150.00,
    "status": "pendiente"
  }
]
```

**Nota:** Es un snapshot al momento de generación, NO se actualiza dinámicamente.

---

## Integración con Tenant-API

### Endpoint Utilizado

**URL:** `/api/installments/amortization/{landlordCreditId}`

**Método:** GET

**Headers:**
```
Host: {tenant_domain}
Accept: application/json
```

**Respuesta esperada:**
```json
{
  "success": true,
  "data": {
    "installments": [
      {
        "id": 123,
        "installment_number": 1,
        "due_date": "2026-01-10",
        "principal_amount": 100.00,
        "interest_amount": 45.00,
        "insurance_amount": 5.00,
        "total_amount": 150.00,
        "paid_amount": 0.00,
        "remaining_amount": 150.00,
        "status": "vencida",
        "payment_date": null
      }
    ],
    "summary": { ... }
  }
}
```

**Endpoint verificado:** Existe en `tenant-api/routes/tenant.php:81`

**Nota:** El endpoint ya existe y devuelve todos los campos necesarios (verificado en línea 607-645 de PurchaseRequestController.php)

---

## Flujo Completo del Sistema

### Flujo de Usuario (Admin)

1. Admin accede a **"Gestión de Cobranza"** desde sidebar
2. Sistema carga todos los créditos activos del landlord
3. Para cada crédito:
   - Consulta cuotas desde tenant-api
   - Clasifica según fechas de vencimiento
4. Muestra dos tabs con clientes clasificados
5. Admin selecciona cliente y hace clic en "Generar Enlace"
6. Sistema:
   - Crea registro en `payment_links`
   - Genera token UUID
   - Calcula monto total del período
   - Guarda snapshot de cuotas
7. Muestra modal con URL para copiar
8. Admin comparte enlace vía WhatsApp/SMS

### Flujo del Cliente

1. Cliente recibe enlace vía WhatsApp/SMS
2. Accede a la URL pública
3. Sistema valida token y expiración
4. Si válido: Muestra página con:
   - Sus datos personales
   - Lista de cuotas pendientes
   - Total a pagar
   - Instrucciones para pagar
5. Cliente contacta asesor o va a oficina para pagar
6. Pago se registra manualmente en el sistema

---

## Pasos de Implementación

### Paso 1: Base de Datos (5 min)
1. Crear migración `2026_01_14_000001_create_payment_links_table.php`
2. Ejecutar `php artisan migrate`

### Paso 2: Modelo PaymentLink (5 min)
1. Crear `app/Models/PaymentLink.php`
2. Definir fillable, casts, relaciones y métodos

### Paso 3: Componente Livewire (30 min)
1. Crear `app/Livewire/CollectionManagement.php`
2. Implementar métodos:
   - `getClientsData()`
   - `classifyClient()`
   - `fetchInstallmentsFromTenant()`
   - `generatePaymentLink()`

### Paso 4: Vista del Componente (20 min)
1. Crear `resources/views/livewire/collection-management.blade.php`
2. Implementar tabs, tablas y modal

### Paso 5: Controlador Público (10 min)
1. Crear `app/Http/Controllers/PaymentLinkController.php`
2. Implementar método `show($token)`

### Paso 6: Vistas Públicas (15 min)
1. Crear `resources/views/payment-link/show.blade.php`
2. Crear `resources/views/payment-link/expired.blade.php`

### Paso 7: Rutas (5 min)
1. Modificar `routes/web.php`
2. Agregar ruta protegida y ruta pública

### Paso 8: Sidebar (5 min)
1. Modificar `resources/views/components/sidebar-menu.blade.php`
2. Agregar enlace con ícono

### Paso 9: Testing (15 min)
1. Verificar clasificación de clientes
2. Probar generación de enlaces
3. Probar vista pública
4. Probar expiración de enlaces

**Tiempo total estimado:** ~2 horas

---

## Consideraciones Técnicas

### Rendimiento

**Problema:** Cada crédito activo = 1 llamada HTTP a tenant-api

**Soluciones futuras:**
- Implementar caché de cuotas (5-15 minutos)
- Crear endpoint batch en tenant-api
- Procesar en background con jobs

**Para MVP:** Aceptable con < 100 créditos activos

### Seguridad

- Enlaces públicos solo muestran información (no procesan pagos)
- Token UUID no es predecible
- Validación de expiración en cada acceso
- No se requiere autenticación para ver enlace (por diseño)

### Escalabilidad

**Para futuro:**
- Paginación si hay muchos clientes
- Filtros adicionales (por tenant, por rango de fechas)
- Búsqueda avanzada
- Exportación a Excel/PDF

### Comunicación HTTP

- Timeout: 10 segundos
- Manejo de errores con try-catch
- Logs para debug
- URL base: `http://host.docker.internal:8021` (desarrollo)

---

## Archivos a Crear/Modificar

### Archivos Nuevos (8 archivos)

1. `landlord-creditapi/database/migrations/2026_01_14_000001_create_payment_links_table.php`
2. `landlord-creditapi/app/Models/PaymentLink.php`
3. `landlord-creditapi/app/Livewire/CollectionManagement.php`
4. `landlord-creditapi/resources/views/livewire/collection-management.blade.php`
5. `landlord-creditapi/app/Http/Controllers/PaymentLinkController.php`
6. `landlord-creditapi/resources/views/payment-link/show.blade.php`
7. `landlord-creditapi/resources/views/payment-link/expired.blade.php`
8. `landlord-creditapi/resources/views/layouts/public.blade.php` (opcional, layout para vistas públicas)

### Archivos a Modificar (2 archivos)

1. `landlord-creditapi/routes/web.php` - Agregar rutas
2. `landlord-creditapi/resources/views/components/sidebar-menu.blade.php` - Agregar enlace

---

## Archivos Críticos

Los 3 archivos más críticos para el funcionamiento:

1. **`app/Livewire/CollectionManagement.php`**
   - Lógica central de clasificación
   - Consultas a tenant-api
   - Generación de enlaces

2. **`resources/views/livewire/collection-management.blade.php`**
   - Interfaz principal del módulo
   - Tabs, tablas, búsqueda, modal

3. **`app/Models/PaymentLink.php`**
   - Estructura de datos
   - Validaciones y métodos

---

## Casos de Uso

### Caso 1: Cliente con Cuotas Vencidas

**Escenario:**
- Cliente Juan tiene 2 cuotas vencidas (hace 5 días)
- Próxima cuota vence en 10 días

**Resultado:**
- Aparece en tab "Para Cobranza"
- Muestra: 2 cuotas vencidas, 0 próximas a vencer
- Enlace incluye solo las 2 cuotas vencidas

### Caso 2: Cliente con Cuotas Próximas

**Escenario:**
- Cliente María no tiene cuotas vencidas
- Tiene 1 cuota que vence en 3 días
- Días configurados: 5

**Resultado:**
- Aparece en tab "Para Cobranza"
- Muestra: 0 cuotas vencidas, 1 próxima a vencer
- Enlace incluye la cuota próxima

### Caso 3: Cliente al Día

**Escenario:**
- Cliente Pedro no tiene cuotas vencidas
- Su próxima cuota vence en 15 días
- Días configurados: 5

**Resultado:**
- Aparece en tab "Al Día"
- Muestra próxima fecha de vencimiento
- No se puede generar enlace (no tiene cuotas en el período)

---

## Funcionalidades Futuras (Fuera del Alcance Actual)

1. **Integración con pasarela de pagos** (MercadoPago, PayU, Wompi)
2. **Notificaciones automáticas** (SMS, WhatsApp, Email)
3. **Dashboard de cobranza** con KPIs y métricas
4. **Historial de enlaces** generados por cliente
5. **Registro de pagos** desde el enlace público
6. **Reportes de cobranza** exportables
7. **Recordatorios automáticos** de cuotas próximas a vencer
8. **Integración con CRM** para seguimiento de cobranza

---

## Validación del Plan

### Requisitos Cumplidos ✓

- [x] Vista unificada en landlord
- [x] Clasificación en "Para Cobranza" y "Al Día"
- [x] Criterio: cuotas vencidas + próximas a vencer en período
- [x] Generación de enlaces únicos (UUID)
- [x] Enlace incluye solo cuotas del período
- [x] Sin integración con pasarela (solo información)
- [x] Agregar al sidebar
- [x] Seguir patrones existentes (Livewire, HTTP, estilos)

### Endpoints Verificados ✓

- [x] `/api/installments/amortization/{landlordCreditId}` existe en tenant-api
- [x] Devuelve todos los campos necesarios
- [x] Formato de respuesta compatible

---

## Resumen Técnico

**Tecnologías:**
- Laravel 11
- Livewire (componentes reactivos)
- Tailwind CSS (estilos)
- HTTP Client (comunicación con tenant-api)

**Patrones:**
- MVC + Livewire
- Repository pattern (implícito en modelos)
- Service layer (métodos privados en componente)

**Arquitectura:**
- Landlord (central) consulta datos de Tenants vía HTTP
- Snapshot de datos para enlaces (no tiempo real)
- Validación en múltiples capas

**Estimación:** 2 horas de desarrollo + 30 minutos de testing = **2.5 horas total**
