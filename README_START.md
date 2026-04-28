# 🚀 Credifácil - Inicio Rápido

Scripts para iniciar y detener el proyecto completo de desarrollo.

## 📋 Requisitos Previos

- Docker y Docker Compose instalados
- Dependencias ya instaladas (composer install y npm install ejecutados)

## 🏃‍♂️ Iniciar Proyecto

```bash
# Desde la raíz del proyecto
./start-project.sh
```

Este script:
- ✅ Verifica que los puertos estén disponibles
- ✅ Levanta Landlord Credit API (puerto 8020)
- ✅ Levanta Tenant API (puerto 8021)
- ✅ Inicia Frontend (puerto 5173)
- ✅ Espera a que todos los servicios estén listos
- ✅ Muestra URLs de acceso
- 🔄 Monitorea continuamente el estado de los servicios

## 🛑 Detener Proyecto

```bash
# Desde la raíz del proyecto
./stop-project.sh
```

Este script:
- ✅ Detiene el frontend
- ✅ Detiene contenedores de Tenant API
- ✅ Detiene contenedores de Landlord API
- ✅ Limpia archivos temporales
- ✅ Verifica que no queden contenedores corriendo

## 📊 Servicios Disponibles

Después de ejecutar `./start-project.sh`, tendrás acceso a:

| Servicio | URL | Descripción |
|----------|-----|-------------|
| **Landlord API** | http://localhost:8020 | API central de créditos |
| **Tenant API** | http://localhost:8021 | API multi-tenant |
| **Frontend** | http://localhost:5173 | Interfaz React |
| **Landlord Vite** | http://localhost:5174 | Dev server de Landlord |

## 🔧 Próximos Pasos

1. **Ejecutar migraciones** (una vez que los contenedores estén arriba):
   ```bash
   cd landlord-creditapi && docker-compose exec laravel.test php artisan migrate
   cd ../tenant-api && docker-compose exec laravel.test php artisan migrate
   ```

2. **Crear seeders** si es necesario

3. **Probar endpoints** de las APIs

## 📝 Notas

- Los scripts verifican automáticamente si los servicios ya están corriendo
- Si un puerto está ocupado, el script te lo notificará
- El monitoreo continuo se puede detener con Ctrl+C
- Los logs del frontend se guardan en `frontend.log`

## 🆘 Solución de Problemas

Si algo falla:
1. Verifica que Docker esté corriendo: `docker --version`
2. Revisa logs: `docker-compose logs` en cada directorio
3. Verifica puertos: `lsof -i :8020` (cambia el puerto)
4. Reinicia servicios: `./stop-project.sh && ./start-project.sh`