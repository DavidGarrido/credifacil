# Resumen de Sesión — 9 Jun 2026

## Estado General

### PC2 (esta máquina) — 192.168.195.6
| Proyecto | Estado | Último commit |
|---|---|---|
| landlord-creditapi | ✅ Sin cambios | `da7e1cd` — Tabla ally_metrics |
| tenant-api | ⚠️ solo logs (storage/logs/laravel.log) | `0e902eb` — fix Paz y Salvo |
| frontend | ✅ Sin cambios | `9a50483` — merge unificar cambios |

### PC1 (LAN 10.0.0.1)
- ✅ Mismos commits que PC2 en los 3 proyectos
- Sin stashes pendientes

### VPS DigitalOcean (Producción)
- **landlord**: `da7e1cd` ✅ igual que local
- **tenant**: `0e902eb` ✅ igual que local
- Contenedores: Todos Up 6 días (landlord, tenant, MySQL, Redis, Soketi)
- También: conectandotalento, libercol, rifa_db

---

## Diagnóstico de Lentitud — admin.credifacilcolombia.com

### Tiempos de respuesta medidos desde PC2:

| Endpoint | Tiempo | Tipo |
|---|---|---|
| `/favicon.ico` (estático) | **0.50s** ✅ | Nginx directo |
| `/login` (Laravel) | **2.70s** 🔴 | PHP-FPM |
| `/` (raíz, redirect) | **2.90s** 🔴 | PHP-FPM |
| `/health` (404) | **1.15s** 🟡 | PHP-FPM |

### Cuello de botella detectado:
- **2.3s de gap** entre SSL (0.57s) y primer byte (2.90s) → **PHP-FPM / Laravel**

### Configuración actual de PHP-FPM (landlord):
```
pm = dynamic
pm.max_children = 20        ← bajo si hay concurrencia
pm.start_servers = 4        ← muy bajo
pm.min_spare_servers = 2    ← muy bajo
pm.max_spare_servers = 8    ← bajo

memory_limit = 128M         ← bajo para Laravel
max_execution_time = 30

Opcache: JIT=off, sin más tuning
```

### 🔴 PROBLEMA CRÍTICO:
**xdebug está ACTIVO en FPM** (`/etc/php/8.4/fpm/conf.d/20-xdebug.ini`)
- xdebug en producción **mata el rendimiento** (agrega overhead enorme a cada request)
- Debe estar solo en CLI, no en FPM

### Recomendaciones:
1. **Desactivar xdebug en FPM** (quitar symlink de conf.d)
2. **Aumentar opcache**: habilitar JIT, memoria, validate_timestamps=0
3. **Aumentar pm.start_servers** a 8-10, min_spare a 4-6
4. **Aumentar memory_limit** a 256M-512M
5. Correr `php artisan optimize` en contenedor
