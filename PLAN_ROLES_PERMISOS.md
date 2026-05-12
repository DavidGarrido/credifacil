# Plan: Roles y Permisos en Tenants

**Fecha**: 2026-05-12  
**Estado**: Diseño  
**Alcance**: Tenant API + Frontend (no landlord)

---

## Objetivo

Que cada comercio (tenant) pueda tener múltiples usuarios con distintos niveles de acceso:
- El **Admin** crea usuarios y les asigna roles
- Cada **rol** define qué puede hacer el usuario en la plataforma
- El **frontend** oculta/muestra secciones según permisos

---

## Roles predefinidos

| Rol | Permisos |
|---|---|
| **admin** | Todo: compras, clientes, reportes, usuarios, configuración, cobros |
| **manager** | Compras, clientes, reportes, ver cobros |
| **cashier** | Solo crear compras, ver sus propias transacciones |
| **viewer** | Solo ver reportes y transacciones (sin crear ni modificar) |

Cada tenant arranca con su usuario inicial como `admin`.

---

## Diseño técnico

### 1. Migración — tabla `roles` (en cada tenant DB)

```php
Schema::create('roles', function (Blueprint $table) {
    $table->id();
    $table->string('name');        // admin, manager, cashier, viewer
    $table->json('permissions');   // ["purchases.create", "clients.manage", ...]
    $table->timestamps();
});
```

### 2. Migración — agregar `role_id` a `users`

```php
Schema::table('users', function (Blueprint $table) {
    $table->foreignId('role_id')->nullable()->constrained('roles');
});
```

### 3. Seeder de roles

Al crear la BD del tenant, insertar los 4 roles con sus permisos:

```php
// admin
['name' => 'admin', 'permissions' => ['*']]

// manager  
['name' => 'manager', 'permissions' => [
    'purchases.create',
    'purchases.view',
    'clients.view',
    'clients.register',
    'reports.view',
    'payments.view',
]]

// cashier
['name' => 'cashier', 'permissions' => [
    'purchases.create',
    'purchases.view_own',
]]

// viewer
['name' => 'viewer', 'permissions' => [
    'purchases.view',
    'reports.view',
]]
```

### 4. Modelo `Role`

```php
class Role extends Model
{
    protected $fillable = ['name', 'permissions'];
    protected $casts = ['permissions' => 'array'];
    
    public function users() { return $this->hasMany(User::class); }
    
    public function hasPermission(string $permission): bool
    {
        return in_array('*', $this->permissions) 
            || in_array($permission, $this->permissions);
    }
}
```

### 5. Método en `User`

```php
public function role() { return $this->belongsTo(Role::class); }

public function can(string $permission): bool
{
    return $this->role && $this->role->hasPermission($permission);
}

public function isAdmin(): bool
{
    return $this->role?->name === 'admin';
}
```

### 6. Middleware `CheckPermission`

```php
// app/Http/Middleware/CheckPermission.php
class CheckPermission
{
    public function handle(Request $request, Closure $next, string $permission)
    {
        if (!auth()->user()?->can($permission)) {
            return response()->json(['message' => 'No autorizado'], 403);
        }
        return $next($request);
    }
}
```

Registrar en `bootstrap/app.php` como alias `permission`.

### 7. Middleware `EnsureHasRole`

```php
// Para endpoints que requieren admin
Route::middleware('permission:users.manage')->group(...)
```

### 8. Endpoints de gestión de usuarios (solo admin)

```
GET    /api/users              → listar usuarios con roles
POST   /api/users              → crear usuario + asignar rol
PUT    /api/users/{id}/role    → cambiar rol
DELETE /api/users/{id}         → eliminar usuario
GET    /api/roles              → listar roles disponibles
```

### 9. Endpoint `/api/user` ampliado

El endpoint actual `GET /api/user` debe incluir `role` y `permissions`:

```json
{
  "id": 1,
  "name": "María",
  "email": "maria@comercio.com",
  "role": {
    "name": "cashier",
    "permissions": ["purchases.create", "purchases.view_own"]
  }
}
```

### 10. Frontend — adaptaciones

- `api.getCurrentUser()` ya devuelve `user.role.permissions`
- `AuthContext` guarda los permisos del usuario
- Componente `<Can permission="purchases.create">` wrapper condicional
- Sidebar filtra items según permisos
- Botones de acción (Crear Compra, Registrar Cliente, etc.) visibles solo con permiso

```jsx
// Ejemplo de uso
<Can permission="purchases.create">
  <button onClick={...}>Nueva Compra</button>
</Can>
```

### 11. Seed de usuarios

Al crear tenant nuevo, el primer usuario es admin:

```php
$adminRole = Role::where('name', 'admin')->first();
User::create([
    'name' => $request->name,
    'email' => $request->email,
    'password' => bcrypt($request->password),
    'role_id' => $adminRole->id,
]);
```

---

## Plan de implementación (7 pasos)

| # | Paso | Archivos |
|---|---|---|
| 1 | Migración: tabla `roles` + `role_id` en `users` | `database/migrations/` |
| 2 | Seeder de roles | `database/seeders/RoleSeeder.php` |
| 3 | Modelo `Role` + métodos en `User` | `app/Models/Role.php`, `app/Models/User.php` |
| 4 | Middleware `CheckPermission` | `app/Http/Middleware/CheckPermission.php` |
| 5 | Endpoints CRUD de usuarios + roles | `app/Http/Controllers/Api/UserController.php`, `routes/tenant.php` |
| 6 | Proteger rutas existentes con middleware | `routes/tenant.php` |
| 7 | Frontend: `Can` component, sidebar dinámico, ocultar botones | `frontend/src/` |

---

## Notas

- Los roles son **por tenant**, no globales. Cada comercio gestiona sus propios usuarios.
- El landlord **no** ve ni gestiona roles de tenants (solo ve la lista de usuarios como ya está implementado).
- El admin del tenant **no puede** crear nuevos roles personalizados (solo usar los 4 predefinidos), por simplicidad inicial.
- Si en el futuro se necesita personalización, se puede migrar a Spatie/laravel-permission.
