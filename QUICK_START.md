# 🚀 Credifácil - Quick Start Guide

Guía rápida para empezar con Credifácil en 5 minutos.

## ✅ Pre-requisitos Instalados

Los dos proyectos Laravel ya están siendo creados con `laravel.build` y Sail:

```
✓ landlord-creditapi/   → Proyecto Laravel 12 con MySQL + Redis
✓ tenant-api/           → Proyecto Laravel 12 con MySQL + Redis
```

Espera a que terminen las instalaciones automáticas (5-10 minutos).

## 🔥 Una Vez Completada la Instalación

### 1️⃣ Iniciar Landlord API (Puerto 8000)

```bash
cd /home/garher/Documentos/credifacil/landlord-creditapi

# Levantar contenedores
./vendor/bin/sail up -d

# Generar APP_KEY si falta
./vendor/bin/sail artisan key:generate

# Ejecutar migraciones
./vendor/bin/sail artisan migrate

# Verificar que funciona
curl http://localhost:8000
```

### 2️⃣ Iniciar Tenant API (Puerto 8001)

En otra terminal:

```bash
cd /home/garher/Documentos/credifacil/tenant-api

# Levantar contenedores
./vendor/bin/sail up -d

# Generar APP_KEY si falta
./vendor/bin/sail artisan key:generate

# Ejecutar migraciones
./vendor/bin/sail artisan migrate

# Verificar que funciona
curl http://localhost:8001
```

### 3️⃣ Crear Frontend (Puerto 5173)

En otra terminal:

```bash
cd /home/garher/Documentos/credifacil/frontend

# Crear proyecto React con Vite
npm create vite@latest . -- --template react

# Instalar dependencias
npm install

# Instalar cliente HTTP
npm install axios

# Iniciar dev server
npm run dev
```

## 📊 Verificar que Todo Funciona

### Landlord API
```bash
./vendor/bin/sail artisan tinker
# En tinker:
> \Illuminate\Support\Facades\Route::getRoutes()->get()
# Deberías ver las rutas API
```

### Tenant API
```bash
./vendor/bin/sail artisan tinker
# En tinker:
> \Illuminate\Support\Facades\Route::getRoutes()->get()
# Deberías ver las rutas API
```

### Frontend
Abre http://localhost:5173 en el navegador

## 📚 Estructura Final

```
credifacil/
├── landlord-creditapi/    ✓ API Central (8000)
├── tenant-api/            ✓ API Multi-Tenant (8001)
├── frontend/              ✓ Cliente React (5173)
└── README.md              ✓ Documentación completa
```

## 🧪 Testing Rápido

### Test 1: Crear tabla de usuarios en Landlord
```bash
cd landlord-creditapi
./vendor/bin/sail artisan migrate
./vendor/bin/sail artisan tinker
> DB::table('users')->insert(['name' => 'Admin', 'email' => 'admin@example.com', 'password' => bcrypt('password')])
```

### Test 2: API Health Check
```bash
# Landlord
curl -X GET http://localhost:8000/api/health

# Tenant
curl -X GET http://localhost:8001/api/health
```

## 🔌 Próximos Pasos

1. **Crear controladores API** en ambos proyectos
2. **Configurar rutas API** (`routes/api.php`)
3. **Conectar Frontend** a ambas APIs con Axios
4. **Implementar autenticación** con Sanctum/JWT
5. **Deploy** a producción

## 📝 Notas Importantes

- Cada proyecto tiene su propia base de datos MySQL
- Redis está disponible para cache y queues
- Sail maneja automáticamente Docker Compose
- Las migraciones están en `database/migrations/`
- Los seeders están en `database/seeders/`

## ❓ Troubleshooting

Si los contenedores no inician:
```bash
# Eliminar contenedores previos
./vendor/bin/sail down -v

# Reconstruir
./vendor/bin/sail build --no-cache

# Levantar nuevamente
./vendor/bin/sail up -d
```

Si hay problema de permisos:
```bash
sudo chown -R $USER:$USER /home/garher/Documentos/credifacil
```

## 📞 Soporte

Documentación completa en `/home/garher/Documentos/credifacil/README.md`

¡Que disfrutes desarrollando Credifácil! 🎉
