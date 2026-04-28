# Plan de Implementación: Gestión de Aliados (Tenants)

**Fecha:** 2026-01-06
**Objetivo:** Crear un panel en el landlord para gestionar los aliados/comerciantes que se registran en el sistema

---

## 📋 Estado Actual

### Tenant-API (Puerto 8021)
- ✅ Tiene sistema de registro de tenants en `TenantRegistrationController`
- ✅ Tabla `tenants` con campos: id, name, email, phone, address, status, data (JSON)
- ✅ Tabla `domains` para subdominios de cada tenant
- ✅ Frontend de registro en http://localhost:5176/
- ✅ Endpoint: `POST /api/tenants/register` - Registra nuevos tenants

### Landlord (Puerto 8020)
- ✅ Panel de créditos pendientes (`PendingCredits`)
- ✅ Panel de créditos activos (`ActiveCredits`)
- ❌ **NO tiene** panel de gestión de aliados
- ❌ **NO tiene** endpoint para consultar tenants

---

## 🎯 Requerimientos del Cliente

El cliente quiere en **Gestión de Créditos** lo siguiente:
1. **Solicitudes de ingreso** - Lo que está como "pendiente"
2. **Créditos activos** - Lo que está como "activo"
3. **Gestión de Aliados** - Panel para ver y gestionar comerciantes/tenants (NUEVO)

---

## 📝 Plan de Implementación

### FASE 1: API en Tenant-API (8021) ⚡ PRIORIDAD

#### 1.1 Crear endpoint para listar tenants
**Archivo:** `/tenant-api/app/Http/Controllers/TenantRegistrationController.php`

```php
/**
 * Listar todos los tenants
 * GET /api/tenants
 */
public function index()
{
    $tenants = Tenant::with('domains')->get();

    return response()->json([
        'success' => true,
        'data' => $tenants->map(function ($tenant) {
            return [
                'tenant_id' => $tenant->id,
                'name' => $tenant->name,
                'email' => $tenant->email,
                'phone' => $tenant->phone,
                'address' => $tenant->address,
                'status' => $tenant->status ?? 'active',
                'domain' => $tenant->domains->first()?->domain,
                'created_at' => $tenant->created_at,
                'updated_at' => $tenant->updated_at,
            ];
        }),
        'total' => $tenants->count(),
    ]);
}
```

#### 1.2 Agregar ruta en routes/api.php
**Archivo:** `/tenant-api/routes/api.php`

```php
// Rutas de tenants (sin autenticación para que landlord pueda consultar)
Route::prefix('tenants')->group(function () {
    Route::post('/register', [TenantRegistrationController::class, 'register']);
    Route::get('/', [TenantRegistrationController::class, 'index']); // NUEVO
    Route::get('/{tenantId}/status', [TenantRegistrationController::class, 'status']);
});
```

#### 1.3 Crear endpoint para actualizar estado de tenant
**Archivo:** `/tenant-api/app/Http/Controllers/TenantRegistrationController.php`

```php
/**
 * Actualizar estado de un tenant
 * PUT /api/tenants/{tenantId}/status
 */
public function updateStatus(Request $request, $tenantId)
{
    $validator = Validator::make($request->all(), [
        'status' => 'required|in:pending,active,inactive,suspended',
    ]);

    if ($validator->fails()) {
        return response()->json([
            'success' => false,
            'errors' => $validator->errors()
        ], 422);
    }

    $tenant = Tenant::find($tenantId);

    if (!$tenant) {
        return response()->json([
            'success' => false,
            'message' => 'Tenant no encontrado'
        ], 404);
    }

    $tenant->status = $request->status;
    $tenant->save();

    return response()->json([
        'success' => true,
        'message' => 'Estado actualizado',
        'data' => [
            'tenant_id' => $tenant->id,
            'status' => $tenant->status,
        ]
    ]);
}
```

---

### FASE 2: Panel en Landlord (8020)

#### 2.1 Crear componente Livewire ManageTenants
**Comando:**
```bash
cd /home/garher/Documentos/credifacil/landlord-creditapi
docker exec landlord-creditapi-laravel.test-1 php artisan make:livewire ManageTenants
```

**Archivo:** `/landlord/app/Livewire/ManageTenants.php`

```php
<?php

namespace App\Livewire;

use Illuminate\Support\Facades\Http;
use Livewire\Component;
use Livewire\WithPagination;

class ManageTenants extends Component
{
    use WithPagination;

    public $tenants = [];
    public $search = '';
    public $statusFilter = 'all';
    public $loading = false;

    public function mount()
    {
        $this->loadTenants();
    }

    public function loadTenants()
    {
        $this->loading = true;

        try {
            // Consultar API de tenant-api
            $response = Http::get('http://host.docker.internal:8021/api/tenants');

            if ($response->successful()) {
                $data = $response->json();
                $this->tenants = $data['data'];
            }
        } catch (\Exception $e) {
            session()->flash('error', 'Error al cargar aliados: ' . $e->getMessage());
        }

        $this->loading = false;
    }

    public function updateTenantStatus($tenantId, $newStatus)
    {
        try {
            $response = Http::put("http://host.docker.internal:8021/api/tenants/{$tenantId}/status", [
                'status' => $newStatus
            ]);

            if ($response->successful()) {
                session()->flash('success', 'Estado actualizado correctamente');
                $this->loadTenants();
            }
        } catch (\Exception $e) {
            session()->flash('error', 'Error al actualizar estado');
        }
    }

    public function render()
    {
        return view('livewire.manage-tenants');
    }
}
```

#### 2.2 Crear vista del componente
**Archivo:** `/landlord/resources/views/livewire/manage-tenants.blade.php`

Vista con:
- Tabla de aliados con columnas: Nombre, Email, Teléfono, Dominio, Estado, Fecha registro, Acciones
- Filtros por estado: Todos, Pendientes, Activos, Inactivos
- Buscador por nombre/email
- Botones para cambiar estado: Aprobar, Suspender, Activar
- Diseño consistente con PendingCredits y ActiveCredits

#### 2.3 Agregar ruta en routes/web.php
**Archivo:** `/landlord/routes/web.php`

```php
Route::middleware(['auth:sanctum', config('jetstream.auth_session'), 'verified'])->group(function () {
    Route::get('/dashboard', function () {
        return view('dashboard');
    })->name('dashboard');

    Route::get('/credits/pending', PendingCredits::class)->name('credits.pending');
    Route::get('/credits/active', ActiveCredits::class)->name('credits.active');
    Route::get('/tenants/manage', ManageTenants::class)->name('tenants.manage'); // NUEVO
});
```

#### 2.4 Agregar opción en el menú de navegación
**Archivo:** `/landlord/resources/views/navigation-menu.blade.php`

Agregar opción "Gestión de Aliados" en el menú principal

---

## 🔄 Flujo Completo

```
┌─────────────────────────────────────────────────────────────┐
│  1. Comerciante se registra en http://localhost:5176/      │
│     (Frontend → Tenant-API:8021)                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  2. Tenant-API crea tenant en su tabla                      │
│     - Crea DB para el tenant                                │
│     - Crea usuario admin                                    │
│     - Status: 'pending' por defecto                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  3. Admin del Landlord accede a "Gestión de Aliados"       │
│     (Landlord:8020 → GET http://8021/api/tenants)          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  4. Admin ve lista de comerciantes y puede:                │
│     - Aprobar (status: active)                              │
│     - Rechazar (status: inactive)                           │
│     - Suspender (status: suspended)                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  5. Cambio de estado se guarda en Tenant-API                │
│     (Landlord:8020 → PUT http://8021/api/tenants/{id})     │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ Checklist de Implementación

### Tenant-API (8021)
- [ ] Agregar método `index()` en TenantRegistrationController
- [ ] Agregar método `updateStatus()` en TenantRegistrationController
- [ ] Agregar rutas GET /api/tenants y PUT /api/tenants/{id}/status
- [ ] Probar endpoints con Postman/curl
- [ ] Commitear cambios

### Landlord (8020)
- [ ] Crear componente Livewire ManageTenants
- [ ] Crear vista manage-tenants.blade.php
- [ ] Agregar ruta /tenants/manage
- [ ] Agregar opción en menú de navegación
- [ ] Aplicar estilos Credifacil Design System
- [ ] Probar flujo completo
- [ ] Commitear cambios

---

## 🎨 Diseño Visual

El panel debe seguir el mismo diseño que PendingCredits y ActiveCredits:
- Header con título "Gestión de Aliados"
- Filtros y búsqueda
- Tabla responsive con Tailwind CSS
- Badges de estado con colores:
  - 🟡 Pending: yellow
  - 🟢 Active: green
  - 🔴 Inactive: red
  - ⚫ Suspended: gray
- Botones de acción con confirmación

---

## 🚀 Próximos Pasos (Futuro)

- [ ] Integrar WebSockets para notificar cuando se registra un nuevo tenant
- [ ] Dashboard con estadísticas de aliados
- [ ] Historial de cambios de estado
- [ ] Exportar listado de aliados a Excel/PDF
- [ ] Sistema de aprobación por niveles

---

## 📌 Notas Importantes

1. **Seguridad:** Los endpoints de tenant-api están sin autenticación actualmente. Considerar agregar API key compartida entre landlord y tenant-api.

2. **CORS:** Verificar que tenant-api permita peticiones desde landlord (puerto 8020).

3. **Docker:** Usar `host.docker.internal` en lugar de `localhost` cuando el landlord haga peticiones desde Docker al tenant-api.

4. **Consistencia:** Mantener el mismo estilo de código y diseño que los paneles existentes (PendingCredits, ActiveCredits).

---

**Última actualización:** 2026-01-06
**Responsable:** Claude Code + Usuario
