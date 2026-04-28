# Plan: Buscador de Comercios + Indicador de Comercio Activo + Aviso en Cambio de Contraseña

## Contexto

Los empleados del aliado necesitan ir a `aliado.dominio.com` para iniciar sesión pero no recuerdan
la URL. La solución es un buscador en la página principal (`dominio.com`) que les permita
encontrar su comercio por nombre y los lleve automáticamente al login correcto.

**Tecnología:** React (frontend) + Laravel con Stancl Tenancy (tenant-api)

**Dónde viven los datos relevantes:**
- `tenant-api` → tabla `tenants` (columna JSON `data` con campos `name`, `status`, etc.)
- `tenant-api` → tabla `domains` (columna `domain` con el dominio del tenant, ej: `tiendajc.localhost`)
- El `Tenant` model en `tenant-api/app/Models/Tenant.php` accede a esos campos con `$tenant->name`
- El `Domain` model viene de `Stancl\Tenancy\Database\Models\Domain`

**No se toca el landlord.** Todo el backend va en `tenant-api`.

---

## Resumen de archivos a modificar

| Archivo | Qué hacer |
|---|---|
| `tenant-api/app/Http/Controllers/TenantRegistrationController.php` | Agregar método `search()` |
| `tenant-api/routes/api.php` (ruta central, NO tenant.php) | Agregar ruta pública `GET /api/tenants/search` |
| `frontend/src/services/api.js` | Agregar método `searchTenants()` |
| `frontend/src/components/LandingPage.jsx` | Reemplazar modal de acceso con buscador |
| `frontend/src/components/Login.jsx` | Mostrar nombre real del comercio |
| `frontend/src/components/Sidebar.jsx` | Mostrar nombre del comercio en el header |
| Futuros componentes de cambio de contraseña | Agregar aviso obligatorio |

---

## Parte 1 — tenant-api: Endpoint público de búsqueda

### Archivo: `tenant-api/app/Http/Controllers/TenantRegistrationController.php`

Agregar el siguiente método al final de la clase, **antes del cierre `}`** de la clase y
**antes del método privado `generateDomainName`**:

```php
/**
 * Buscar comercios por nombre (endpoint público, sin autenticación)
 * GET /api/tenants/search?q=texto
 */
public function search(Request $request)
{
    $query = trim($request->get('q', ''));

    if (strlen($query) < 2) {
        return response()->json([
            'success' => true,
            'data' => []
        ]);
    }

    $tenants = Tenant::with('domains')
        ->get()
        ->filter(function ($tenant) use ($query) {
            $name = $tenant->name ?? '';
            return stripos($name, $query) !== false;
        })
        ->map(function ($tenant) {
            $domain = $tenant->domains->first();
            return [
                'name'   => $tenant->name,
                'domain' => $domain ? $domain->domain : null,
            ];
        })
        ->filter(fn($t) => $t['domain'] !== null) // solo tenants con dominio activo
        ->values()
        ->take(10);

    return response()->json([
        'success' => true,
        'data' => $tenants
    ]);
}
```

**Nota:** El modelo `Tenant` ya tiene el método `with('domains')` usado en `index()`.
No es necesario importar nada nuevo.

---

### Archivo: `tenant-api/routes/api.php`

**IMPORTANTE:** Esta ruta va en `api.php` (rutas centrales), NO en `tenant.php`.
El archivo `tenant.php` solo aplica a subdominios de tenant y no estaría disponible
en `dominio.com`.

Verificar que existe `tenant-api/routes/api.php`. Si no existe, buscar el archivo de
rutas que NO tiene el middleware `InitializeTenancyByDomain`.

Agregar la ruta de búsqueda. Debe ser pública (sin middleware `auth`):

```php
use App\Http\Controllers\TenantRegistrationController;

// Búsqueda pública de comercios (sin autenticación)
Route::get('/tenants/search', [TenantRegistrationController::class, 'search']);
```

Si ya hay rutas de tenants en ese archivo, agregar junto a ellas pero asegurándose de
que esta ruta NO tenga `middleware('auth:sanctum')`.

---

## Parte 2 — frontend/src/services/api.js

### Agregar método `searchTenants`

Al final del objeto `api` (antes del cierre `}`), agregar:

```javascript
// Buscar comercios por nombre desde la página principal
// Llama al tenant-api central (VITE_TENANT_API_URL), no a un subdominio
async searchTenants(query) {
  const response = await apiFetch(
    `${TENANT_API_URL}/api/tenants/search?q=${encodeURIComponent(query)}`
  );
  if (!response.ok) {
    throw new Error('Error al buscar comercios');
  }
  return response.json();
},
```

**Nota:** Se usa `TENANT_API_URL` (ya definida al inicio del archivo como
`import.meta.env.VITE_TENANT_API_URL`). No se necesita ninguna variable de entorno nueva.

---

## Parte 3 — frontend/src/components/LandingPage.jsx

### Qué cambiar

El modal "Acceder a mi Comercio" actualmente tiene un input donde el usuario escribe
el slug del dominio manualmente y presiona "Acceder". Reemplazar ese modal por uno con
buscador de texto con resultados en dropdown.

---

### Estados a agregar al componente

Agregar estos estados al inicio del componente `LandingPage`, junto a los existentes:

```javascript
const [searchQuery, setSearchQuery]     = useState('');
const [searchResults, setSearchResults] = useState([]);
const [searching, setSearching]         = useState(false);
const [searchError, setSearchError]     = useState('');
```

Eliminar el estado `tenantDomain` (ya no se usa).

---

### Funciones a agregar

Agregar estas funciones dentro del componente `LandingPage`, antes del `return`.
Eliminar la función `handleAccessSubmit` (ya no se usa).

```javascript
let searchTimeout = null;

const handleSearchChange = (value) => {
  setSearchQuery(value);
  setSearchResults([]);
  setSearchError('');

  if (searchTimeout) clearTimeout(searchTimeout);

  if (value.length < 2) {
    setSearching(false);
    return;
  }

  setSearching(true);
  searchTimeout = setTimeout(async () => {
    try {
      const result = await api.searchTenants(value);
      if (result.success) {
        setSearchResults(result.data);
      }
    } catch (err) {
      setSearchError('Error al buscar. Intenta de nuevo.');
    } finally {
      setSearching(false);
    }
  }, 300);
};

const handleTenantSelect = (tenant) => {
  // El dominio guardado es ej: "tiendajc.localhost" → extraer solo "tiendajc"
  // Luego construir la URL usando el hostname actual de la ventana
  // Así funciona igual en dev (localhost) y en producción (dominio.com)
  const subdomain = tenant.domain.split('.')[0];
  const port = window.location.port ? `:${window.location.port}` : '';
  window.location.href = `${window.location.protocol}//${subdomain}.${window.location.hostname}${port}/login`;
};
```

---

### Reemplazar el modal completo

Buscar el bloque que empieza con `{showLoginModal && (` y termina con el cierre `)}` del modal.
Reemplazarlo por:

```jsx
{showLoginModal && (
  <div
    className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4"
    onClick={() => { setShowLoginModal(false); setSearchQuery(''); setSearchResults([]); setSearchError(''); }}
  >
    <div
      className="bg-white rounded-3xl p-8 max-w-md w-full relative shadow-2xl"
      onClick={(e) => e.stopPropagation()}
    >
      <button
        className="absolute top-4 right-4 text-gray-500 hover:text-gray-700 hover:bg-gray-100 w-10 h-10 rounded-full flex items-center justify-center text-xl transition-all duration-200"
        onClick={() => { setShowLoginModal(false); setSearchQuery(''); setSearchResults([]); setSearchError(''); }}
      >
        ×
      </button>

      <h3 className="text-2xl font-bold text-gray-900 mb-2">Acceder a mi Comercio</h3>
      <p className="text-gray-500 mb-6">Escribe el nombre de tu comercio para buscarlo</p>

      <div className="relative">
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => handleSearchChange(e.target.value)}
          placeholder="Ej: Tienda JC, Cafetería..."
          className="w-full px-4 py-3 border-2 border-gray-300 rounded-xl text-base outline-none focus:border-emerald-500 transition-all duration-200"
          autoFocus
        />

        {/* Spinner mientras busca */}
        {searching && (
          <div className="absolute right-4 top-1/2 -translate-y-1/2">
            <div className="w-5 h-5 border-2 border-gray-300 border-t-emerald-500 rounded-full animate-spin"></div>
          </div>
        )}

        {/* Lista de resultados */}
        {searchResults.length > 0 && (
          <div className="absolute top-full left-0 right-0 mt-1 bg-white border-2 border-gray-200 rounded-xl shadow-lg z-10 overflow-hidden">
            {searchResults.map((tenant) => (
              <button
                key={tenant.domain}
                onClick={() => handleTenantSelect(tenant)}
                className="w-full text-left px-4 py-3 hover:bg-emerald-50 hover:text-emerald-700 transition-colors duration-150 border-b border-gray-100 last:border-0"
              >
                <span className="font-medium">{tenant.name}</span>
              </button>
            ))}
          </div>
        )}

        {/* Sin resultados */}
        {!searching && searchQuery.length >= 2 && searchResults.length === 0 && !searchError && (
          <div className="absolute top-full left-0 right-0 mt-1 bg-white border-2 border-gray-200 rounded-xl shadow-lg p-4 text-center text-gray-500 text-sm">
            No se encontró ningún comercio con ese nombre
          </div>
        )}

        {/* Error de red */}
        {searchError && (
          <div className="absolute top-full left-0 right-0 mt-1 bg-red-50 border-2 border-red-200 rounded-xl p-4 text-center text-red-600 text-sm">
            {searchError}
          </div>
        )}
      </div>

      <p className="text-xs text-gray-400 mt-6 text-center">
        Si no encuentras tu comercio, contacta a tu administrador
      </p>
    </div>
  </div>
)}
```

---

## Parte 4 — frontend/src/components/Login.jsx

### Qué cambiar

Actualmente muestra `Panel de {api.getCurrentTenant()}` que devuelve el slug crudo
(ej: `tiendajc`). Debe mostrar el nombre real del comercio (ej: `Tienda JC`).

---

### Agregar estado y efecto al componente Login

Agregar al inicio del componente `Login`, junto a los estados existentes:

```javascript
const [commerceName, setCommerceName] = useState('');

useEffect(() => {
  if (api.getCurrentTenant()) {
    api.getCompanyInfo()
      .then(res => {
        if (res?.success && res?.data?.commercial_name) {
          setCommerceName(res.data.commercial_name);
        }
      })
      .catch(() => {}); // silencioso, el fallback es el slug del subdominio
  }
}, []);
```

Agregar `useEffect` a los imports de React si no está ya:
```javascript
import { useState, useEffect } from 'react';
```

---

### Reemplazar el subtítulo del formulario

**Buscar:**
```jsx
<p className="text-sm text-gray-500">
  {api.getCurrentTenant() ? (
    <>Panel de {api.getCurrentTenant()}</>
  ) : (
    <>Acceso al sistema</>
  )}
</p>
```

**Reemplazar por:**
```jsx
<p className="text-sm text-gray-500">
  {api.getCurrentTenant() ? (
    <>Acceso al panel de{' '}
      <strong className="text-gray-800">
        {commerceName || api.getCurrentTenant()}
      </strong>
    </>
  ) : (
    <>Acceso al sistema</>
  )}
</p>
```

---

## Parte 5 — frontend/src/components/Sidebar.jsx

### Qué cambiar

El Sidebar muestra el logo "CF" y el texto "CrediFácil" pero no indica en qué comercio
está el usuario. Se debe mostrar el nombre del comercio de forma notoria.

---

### Agregar estado y efecto al componente Sidebar

Agregar al inicio del componente `Sidebar`, junto a los estados existentes:

```javascript
const [commerceName, setCommerceName] = useState('');

useEffect(() => {
  if (user) {
    api.getCompanyInfo()
      .then(res => {
        if (res?.success && res?.data?.commercial_name) {
          setCommerceName(res.data.commercial_name);
        }
      })
      .catch(() => {});
  }
}, [user]);
```

---

### Reemplazar el Logo Section

**Buscar este bloque completo:**
```jsx
{/* Logo Section */}
<div className="p-6 border-b border-gray-200 relative">
  <div className={`flex items-center ${isCollapsed ? 'justify-center' : 'space-x-3'}`}>
    <div className="w-10 h-10 bg-emerald-500 text-white rounded-lg flex items-center justify-center font-bold text-lg">CF</div>
    {!isCollapsed && <span className="text-xl font-bold text-gray-900">CrediFácil</span>}
  </div>
  {!isCollapsed && (
    <button onClick={toggleCollapse} className="absolute top-2 right-2 text-gray-600 hover:text-gray-900 text-xl">
      ✕
    </button>
  )}
</div>
```

**Reemplazar por:**
```jsx
{/* Logo Section */}
<div className="p-6 border-b border-gray-200 relative">
  <div className={`flex items-center ${isCollapsed ? 'justify-center' : 'space-x-3'}`}>
    <div className="w-10 h-10 bg-emerald-500 text-white rounded-lg flex items-center justify-center font-bold text-lg flex-shrink-0">CF</div>
    {!isCollapsed && (
      <div className="flex flex-col min-w-0">
        <span className="text-sm font-bold text-gray-900 truncate leading-tight">
          {commerceName || api.getCurrentTenant() || 'CrediFácil'}
        </span>
        <span className="text-xs text-gray-400 leading-tight">CrediFácil</span>
      </div>
    )}
  </div>
  {!isCollapsed && (
    <button onClick={toggleCollapse} className="absolute top-2 right-2 text-gray-600 hover:text-gray-900 text-xl">
      ✕
    </button>
  )}
</div>
```

---

## Parte 6 — Aviso en cambio de contraseña (para cuando se implemente)

Cuando se cree un componente de cambio de contraseña, agregar el siguiente aviso
**justo encima del botón de guardar**. Es obligatorio, no omitir.

El componente debe obtener `commerceName` llamando a `api.getCompanyInfo()` igual
que se hace en Login.jsx y Sidebar.jsx.

```jsx
{/* AVISO OBLIGATORIO - no remover */}
<div className="bg-amber-50 border-2 border-amber-400 rounded-xl p-4 flex items-start space-x-3">
  <span className="text-amber-500 text-xl flex-shrink-0">⚠️</span>
  <div>
    <p className="text-sm font-bold text-amber-800">
      Esta contraseña es exclusiva de {commerceName || 'este comercio'}
    </p>
    <p className="text-sm text-amber-700 mt-1">
      Si trabajas en otros comercios, sus contraseñas no se verán afectadas.
      Cada comercio maneja sus propias credenciales de forma independiente.
    </p>
  </div>
</div>
```

---

## Notas importantes

- **No se modifica el landlord.** Todo el backend va en `tenant-api`.
- **No se agregan variables de entorno.** Se reutiliza `VITE_TENANT_API_URL`.
- **La autenticación no cambia.** Cada tenant sigue manejando sus propios usuarios.
  El buscador solo ayuda al usuario a encontrar la URL de su comercio.
- **`api.getCompanyInfo()`**: verificar que este método exista en `api.js` y que
  llame a `GET /api/company-info` o similar. Si tiene un nombre diferente, usar
  el nombre correcto.
- **Rutas centrales vs rutas de tenant:** La ruta de búsqueda debe ir en las rutas
  centrales (accesibles desde `dominio.com`), no en `tenant.php` (que solo aplica
  a subdominios). Verificar que el archivo donde se agrega la ruta no tenga el
  middleware `InitializeTenancyByDomain`.
