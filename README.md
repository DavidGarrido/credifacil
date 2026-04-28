# Credifácil - Sistema de Créditos Multi-Tenant

Arquitectura moderna con APIs separadas y frontend desacoplado.

## 📁 Estructura

```
credifacil/
├── landlord-creditapi/       # API 1: Sistema Central de Créditos (Laravel)
│   ├── docker-compose.yml    # Configuración Sail
│   ├── .env.example
│   └── (Proyecto Laravel API)
│
├── tenant-api/               # API 2: Aplicación Multi-Tenant (Laravel)
│   ├── docker-compose.yml    # Configuración Sail
│   ├── .env.example
│   └── (Proyecto Laravel API)
│
├── frontend/                 # Cliente Frontend (React/Vue/Svelte)
│   ├── package.json
│   ├── vite.config.js
│   ├── src/
│   │   ├── pages/
│   │   ├── components/
│   │   └── services/
│   └── .env.example
│
└── README.md
```

## 🚀 Proyectos

### 1. **landlord-creditapi** (Puerto 8000 - Laravel API)
Sistema centralizado de gestión de créditos

**Responsabilidades:**
- ✅ API REST para validación de identidad de clientes
- ✅ Gestión de créditos y límites
- ✅ Webhooks de confirmación
- ✅ Base de datos central de usuarios y créditos
- ✅ Autenticación con API Keys
- ✅ NO tiene UI (solo API)

**Endpoints:**
```
POST /api/verify-client-identity
POST /api/send-confirmation-link
POST /api/confirm-purchase-button
POST /api/validate-purchase
POST /api/notify-payment
POST /webhooks/purchase-confirmed
POST /webhooks/payment-received
GET  /api/clients/{id}/credits
GET  /api/credits/{id}/status
```

### 2. **tenant-api** (Puerto 8001 - Laravel API)
API Multi-Tenant para comerciantes

**Responsabilidades:**
- ✅ Autenticación de usuarios por tenant
- ✅ Gestión de productos/servicios
- ✅ Integración con API de Landlord
- ✅ Consulta de créditos de clientes
- ✅ Procesamiento de pagos
- ✅ NO tiene UI (solo API)

**Características:**
- Cada tenant en subdominio (coindraw.localhost, empresa2.localhost, etc)
- Base de datos separada por tenant (usando Stancl/Tenancy)
- Consumidor de APIs de Landlord
- API Key para comunicación segura

**Endpoints:**
```
POST   /api/auth/login
POST   /api/auth/register
GET    /api/products
POST   /api/orders
GET    /api/orders/{id}
POST   /api/payments
GET    /api/client/{id}/credits
```

### 3. **frontend** (Puerto 3000/5173 - React/Vue/Svelte)
Aplicación cliente desacoplada

**Responsabilidades:**
- ✅ UI para Landlord (Dashboard administrativo)
- ✅ UI para Tenants (Portal de comerciante)
- ✅ UI para Clientes (Solicitar crédito)
- ✅ Integración con ambas APIs
- ✅ Gestión de estado
- ✅ Autenticación con JWT/Tokens

**Características:**
- Framework moderno (React/Vue/Svelte)
- Vite para bundling rápido
- Axios para consumo de APIs
- Responsive Design
- PWA ready

## 🔌 Comunicación Entre Proyectos

```
┌─────────────┐
│   Frontend  │
│  (React)    │
│  :3000      │
└──────┬──────┘
       │
       ├──► [Landlord API]     (8000)
       │    - Verificación identidad
       │    - Gestión créditos
       │
       └──► [Tenant API]        (8001)
            - Autenticación
            - Productos
            - Pedidos
```

**Autenticación:**
- Frontend → APIs: JWT Token en headers
- Tenant API → Landlord API: API Key en headers
- CORS configurado para comunicación segura

## 📋 Setup Inicial

### Prerequisitos
- Docker & Docker Compose
- Node.js 18+ (para frontend)
- Git

### Pasos de Instalación Rápida

#### 1. Crear Proyectos Laravel con Sail

```bash
cd /home/garher/Documentos/credifacil

# Landlord API
cd landlord-creditapi
curl -s "https://laravel.build/landlord-creditapi?with=mysql,redis" | bash
./vendor/bin/sail up -d

# En otra terminal - Tenant API
cd ../tenant-api
curl -s "https://laravel.build/tenant-api?with=mysql,redis" | bash
./vendor/bin/sail up -d
```

#### 2. Setup Frontend

```bash
cd ../frontend

# Opción A: React + Vite
npm create vite@latest . -- --template react
# O
npm create vite@latest . -- --template vue
# O
npm create vite@latest . -- --template svelte

npm install
npm run dev  # Puerto 5173
```

#### 3. Configurar Variables de Entorno

**landlord-creditapi/.env:**
```
APP_NAME=CreditAPI
APP_URL=http://localhost:8000
APP_DEBUG=true
DB_CONNECTION=mysql
SANCTUM_STATEFUL_DOMAINS=localhost:3000,localhost:5173
```

**tenant-api/.env:**
```
APP_NAME=TenantApp
APP_URL=http://localhost:8001
DB_CONNECTION=mysql
LANDLORD_API_URL=http://localhost:8000/api
LANDLORD_API_KEY=your-secret-key
SANCTUM_STATEFUL_DOMAINS=localhost:3000,localhost:5173
```

**frontend/.env:**
```
VITE_LANDLORD_API=http://localhost:8000/api
VITE_TENANT_API=http://localhost:8001/api
```

#### 4. Migrations & Seeding

```bash
# Landlord
cd landlord-creditapi
./vendor/bin/sail artisan migrate
./vendor/bin/sail artisan db:seed

# Tenant
cd ../tenant-api
./vendor/bin/sail artisan migrate
./vendor/bin/sail artisan tenant:seed
```

## 🔐 Seguridad

- ✅ CORS configurado para desarrollo local
- ✅ API Keys para comunicación entre servidores
- ✅ JWT/Sanctum para autenticación de usuarios
- ✅ Rate limiting en endpoints críticos
- ✅ Validación de datos en todas las APIs
- ✅ HTTPS en producción

## 📊 Base de Datos

### Landlord (Base de datos centralizada)
```
users              → Admins de Landlord
clients            → Clientes finales
credits            → Créditos otorgados
credit_plans       → Planes disponibles
payments           → Pagos registrados
api_keys           → Keys para Tenants
```

### Tenant (Base de datos por tenant con Stancl/Tenancy)
```
users              → Usuarios del comerciante
products           → Productos/servicios
orders             → Órdenes/compras
payments           → Pagos procesados
client_credits     → Cache de créditos
```

## 🧪 Testing

```bash
# APIs - Laravel
cd landlord-creditapi
./vendor/bin/sail artisan test

cd ../tenant-api
./vendor/bin/sail artisan test

# Frontend
cd ../frontend
npm run test
```

## 📚 Documentación API

### Landlord API Docs
```
GET    /api/docs              → Documentación interactiva
POST   /api/verify-client-identity
POST   /api/validate-purchase
GET    /api/clients/{id}/credits
```

### Tenant API Docs
```
GET    /api/docs              → Documentación interactiva
POST   /api/auth/login
GET    /api/products
POST   /api/orders
GET    /api/client/{id}/credits
```

## 🚀 Deploy

Ver archivo **DEPLOYMENT.md** para instrucciones completas de deployment a DigitalOcean.

Resumen:
- **Landlord** - DigitalOcean Droplet (docker)
- **Tenant** - DigitalOcean Droplet (docker)
- **Frontend** - Vercel, Netlify, o mismo Droplet

## 📝 Estructura de Carpetas del Frontend

```
frontend/
├── src/
│   ├── pages/
│   │   ├── LandlordDashboard.jsx
│   │   ├── TenantPortal.jsx
│   │   └── ClientApp.jsx
│   ├── components/
│   │   ├── Auth/
│   │   ├── Credits/
│   │   └── shared/
│   ├── services/
│   │   ├── landlordApi.js
│   │   ├── tenantApi.js
│   │   └── auth.js
│   ├── store/
│   │   ├── authStore.js
│   │   └── creditsStore.js
│   └── App.jsx
├── .env
└── package.json
```

## 🤝 Contribución

- Cada API es independiente
- Frontend consume ambas APIs
- Las migraciones están versionadas
- Usar convenciones de commits

## 📄 License

MIT
