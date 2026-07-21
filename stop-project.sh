#!/bin/bash

# Credifácil - Script para detener el proyecto completo
# Detiene landlord-api, tenant-api y frontend

echo "🛑 Deteniendo Credifácil - Sistema de Créditos Multi-Tenant"
echo "========================================================"

# Función para detener contenedores docker-compose
stop_docker_service() {
    local service_name=$1
    local service_dir=$2

    echo "🔽 Deteniendo $service_name..."
    cd $service_dir

    if docker-compose ps | grep -q "Up"; then
        docker-compose down
        echo "✅ $service_name detenido"
    else
        echo "ℹ️  $service_name ya estaba detenido"
    fi

    cd ..
    echo ""
}

# 1. Detener Queue Workers
echo "Deteniendo Queue Workers..."
for pidfile in tenant-queue.pid landlord-queue.pid; do
    if [ -f "$pidfile" ]; then
        PID=$(cat $pidfile)
        if kill -0 $PID 2>/dev/null; then
            kill $PID
            echo "  Worker detenido (PID: $PID)"
        fi
        rm -f $pidfile
    fi
done
pkill -f "queue:work" 2>/dev/null || true
rm -f tenant-queue.log landlord-queue.log 2>/dev/null
echo ""

# 2. Detener Frontend
echo "🌐 Deteniendo Frontend..."
if [ -f "frontend.pid" ]; then
    FRONTEND_PID=$(cat frontend.pid)
    if kill -0 $FRONTEND_PID 2>/dev/null; then
        echo "🔽 Matando proceso frontend (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID
        echo "✅ Frontend detenido"
    else
        echo "ℹ️  Proceso frontend ya terminó"
    fi
    rm -f frontend.pid
else
    # Buscar procesos de Vite
    VITE_PIDS=$(pgrep -f "vite")
    if [ ! -z "$VITE_PIDS" ]; then
        echo "🔽 Matando procesos Vite..."
        kill $VITE_PIDS 2>/dev/null
        echo "✅ Procesos Vite detenidos"
    else
        echo "ℹ️  No se encontraron procesos de Vite corriendo"
    fi
fi
echo ""

# 3. Detener Microservicio Telegram
echo "📱 Deteniendo Microservicio Telegram..."
if [ -f "telegram-httpd.pid" ]; then
    TG_PID=$(cat telegram-httpd.pid)
    if kill -0 $TG_PID 2>/dev/null; then
        kill $TG_PID
        echo "  Telegram detenido (PID: $TG_PID)"
    fi
    rm -f telegram-httpd.pid
fi
/opt/credifacil/stop.sh 2>/dev/null || true
pkill -f "telegram_httpd.py 8099" 2>/dev/null || true
echo "✅ Microservicio Telegram detenido"
echo ""

# 4. Detener Tenant API
stop_docker_service "Tenant API" "tenant-api"

# 5. Detener Landlord Credit API
stop_docker_service "Landlord Credit API" "landlord-creditapi"

# 6. Limpiar archivos temporales
echo "🧹 Limpiando archivos temporales..."
rm -f frontend.log 2>/dev/null
echo "✅ Limpieza completada"
echo ""

# 5. Mostrar estado final
echo "✋ ¡Proyecto Credifácil detenido completamente!"
echo ""
echo "💡 Para volver a iniciar: ./start-project.sh"
echo ""

# Mostrar contenedores que podrían quedar
echo "🔍 Verificando contenedores restantes..."
REMAINING=$(docker ps --filter "name=credifacil\|landlord\|tenant" --format "table {{.Names}}\t{{.Status}}")

if [ ! -z "$REMAINING" ] && [ "$REMAINING" != "NAMES" ]; then
    echo "⚠️  Contenedores que podrían seguir corriendo:"
    echo "$REMAINING"
    echo ""
    echo "💡 Para detener manualmente: docker stop <container_name>"
else
    echo "✅ No quedan contenedores relacionados corriendo"
fi