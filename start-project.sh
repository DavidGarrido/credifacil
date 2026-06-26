#!/bin/bash

# Credifácil - Script para levantar el proyecto completo
# Levanta landlord-api, tenant-api y frontend

set -e  # Salir si hay error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================================"
echo "  Credifácil - Sistema de Créditos Multi-Tenant"
echo -e "========================================================${NC}"
echo ""

# Función para verificar si un puerto está en uso
check_port() {
    local port=$1
    local name=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}  Puerto $port ($name) ya está en uso${NC}"
        return 1
    else
        echo -e "${GREEN}  Puerto $port ($name) disponible${NC}"
        return 0
    fi
}

# Función para esperar a que un servicio esté listo
# Uso: wait_for_service <url> <name> [max_attempts]
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=${3:-30}
    local attempt=1

    echo -n "  Esperando $service_name"

    while [ $attempt -le $max_attempts ]; do
        if curl -s --max-time 5 "$url" > /dev/null 2>&1; then
            echo -e " ${GREEN}OK${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done

    echo -e " ${RED}TIMEOUT${NC}"
    return 1
}

# Función para esperar a que MySQL esté listo
wait_for_mysql() {
    local container=$1
    local max_attempts=30
    local attempt=1

    echo -n "  Esperando MySQL ($container)"

    while [ $attempt -le $max_attempts ]; do
        if docker exec $container mysqladmin ping -h localhost -u root -ppassword --silent 2>/dev/null; then
            echo -e " ${GREEN}OK${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done

    echo -e " ${RED}TIMEOUT${NC}"
    return 1
}

# Función para configurar un proyecto Laravel
setup_laravel_project() {
    local project_dir=$1
    local project_name=$2
    local api_port=$3
    local mysql_container=$4

    echo -e "${BLUE}[$project_name]${NC} Configurando..."

    cd "$PROJECT_DIR/$project_dir"

    # 1. Crear .env si no existe
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            echo -e "  ${GREEN}Archivo .env creado desde .env.example${NC}"
        else
            echo -e "  ${RED}Error: No existe .env.example${NC}"
            return 1
        fi
    else
        echo -e "  ${GREEN}Archivo .env existe${NC}"
    fi

    # 2. Asegurar variables críticas en .env
    if ! grep -q "^CACHE_STORE=" .env; then
        echo "CACHE_STORE=redis" >> .env
        echo -e "  ${YELLOW}CACHE_STORE=redis agregado al .env${NC}"
    fi

    # 3. Levantar contenedores
    echo -e "  Levantando contenedores..."
    docker compose up -d 2>/dev/null || docker-compose up -d

    # 4. Esperar a que MySQL esté listo
    wait_for_mysql "$mysql_container"

    # 5. Obtener nombre del contenedor Laravel
    local laravel_container="${project_dir}-laravel.test-1"

    # 5. Instalar dependencias de Composer si no existen
    if ! docker exec $laravel_container test -f vendor/autoload.php 2>/dev/null; then
        echo -e "  Instalando dependencias de Composer..."
        docker exec $laravel_container composer install --no-interaction --quiet
        echo -e "  ${GREEN}Dependencias instaladas${NC}"
    else
        echo -e "  ${GREEN}Dependencias de Composer OK${NC}"
    fi

    # 6. Arreglar permisos de storage y bootstrap/cache
    echo -e "  Configurando permisos..."
    docker exec $laravel_container chmod -R 777 storage bootstrap/cache 2>/dev/null || true

    # 7. Ejecutar migraciones si es necesario
    echo -e "  Verificando migraciones..."
    if docker exec $laravel_container php artisan migrate:status 2>&1 | grep -q "Migration table not found\|No migrations found"; then
        echo -e "  Ejecutando migraciones..."
        docker exec $laravel_container php artisan migrate --force --quiet
        echo -e "  ${GREEN}Migraciones ejecutadas${NC}"
    else
        echo -e "  ${GREEN}Migraciones OK${NC}"
    fi

    # 8. Esperar a que el servicio HTTP responda
    wait_for_service "http://localhost:$api_port" "$project_name"

    cd "$PROJECT_DIR"
    echo ""
}

# Función para levantar queue workers dentro de los contenedores
setup_queue_workers() {
    echo -e "${BLUE}[Queue Workers]${NC} Iniciando workers de cola..."

    # Matar workers previos si existen
    docker exec tenant-api-laravel.test-1 pkill -f "queue:work" 2>/dev/null || true
    docker exec landlord-creditapi-laravel.test-1 pkill -f "queue:work" 2>/dev/null || true

    # Tenant: procesa eventos InstallmentPaid → NotifyLandlordOfPayment
    nohup docker exec tenant-api-laravel.test-1 php artisan queue:work redis \
        --sleep=3 --tries=3 --timeout=60 --queue=default \
        > "$PROJECT_DIR/tenant-queue.log" 2>&1 &
    TENANT_QUEUE_PID=$!
    disown $TENANT_QUEUE_PID 2>/dev/null || true
    echo $TENANT_QUEUE_PID > "$PROJECT_DIR/tenant-queue.pid"
    echo -e "  ${GREEN}Tenant queue worker iniciado (PID: $TENANT_QUEUE_PID)${NC}"

    # Landlord: por si tiene jobs propios encolados
    nohup docker exec landlord-creditapi-laravel.test-1 php artisan queue:work redis \
        --sleep=3 --tries=3 --timeout=60 --queue=default \
        > "$PROJECT_DIR/landlord-queue.log" 2>&1 &
    LANDLORD_QUEUE_PID=$!
    disown $LANDLORD_QUEUE_PID 2>/dev/null || true
    echo $LANDLORD_QUEUE_PID > "$PROJECT_DIR/landlord-queue.pid"
    echo -e "  ${GREEN}Landlord queue worker iniciado (PID: $LANDLORD_QUEUE_PID)${NC}"

    echo ""
}

# Función para otorgar permisos MySQL para tenants
setup_mysql_permissions() {
    local mysql_container=$1

    echo -e "${BLUE}[MySQL Tenant]${NC} Configurando permisos para crear bases de datos..."

    docker exec $mysql_container mysql -u root -ppassword -e \
        "GRANT ALL PRIVILEGES ON *.* TO 'sail'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;" 2>/dev/null

    echo -e "  ${GREEN}Permisos de MySQL configurados${NC}"
    echo ""
}

# Función para configurar el portal cliente (Ionic)
setup_ionic_portal() {
    echo -e "${BLUE}[Ionic Portal]${NC} Configurando..."

    cd "$PROJECT_DIR/client-portal-ionic"

    # 1. Instalar dependencias npm si no existen
    if [ ! -d node_modules ]; then
        echo -e "  Instalando dependencias npm..."
        npm install --silent 2>/dev/null
        echo -e "  ${GREEN}Dependencias npm instaladas${NC}"
    else
        echo -e "  ${GREEN}Dependencias npm OK${NC}"
    fi

    # 2. Verificar si ya está corriendo en puerto 5177
    if lsof -Pi :5177 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "  ${GREEN}Ionic Portal ya está corriendo en :5177${NC}"
    else
        # Matar procesos ng anteriores
        pkill -f "ng serve" 2>/dev/null || true

        echo -e "  Iniciando servidor de desarrollo..."
        nohup npm start -- --host 0.0.0.0 --port 5177 > "$PROJECT_DIR/ionic-portal.log" 2>&1 &
        IONIC_PID=$!
        disown $IONIC_PID 2>/dev/null || true
        echo $IONIC_PID > "$PROJECT_DIR/ionic-portal.pid"
        echo -e "  ${GREEN}Ionic Portal iniciado (PID: $IONIC_PID)${NC}"
    fi

    # 3. Esperar a que esté listo (Angular compila lento, timeout ~90s)
    wait_for_service "http://localhost:5177" "Ionic Portal" 45

    cd "$PROJECT_DIR"
    echo ""
}

# Función para configurar el frontend
setup_frontend() {
    echo -e "${BLUE}[Frontend]${NC} Configurando..."

    cd "$PROJECT_DIR/frontend"

    # 1. Instalar dependencias npm si no existen
    if [ ! -d node_modules ]; then
        echo -e "  Instalando dependencias npm..."
        npm install --silent 2>/dev/null
        echo -e "  ${GREEN}Dependencias npm instaladas${NC}"
    else
        echo -e "  ${GREEN}Dependencias npm OK${NC}"
    fi

    # 2. Verificar si ya está corriendo
    if pgrep -f "vite.*5176" > /dev/null 2>&1; then
        echo -e "  ${GREEN}Frontend ya está corriendo${NC}"
    else
        # Matar procesos vite anteriores si existen
        pkill -f "vite" 2>/dev/null || true

        echo -e "  Iniciando servidor de desarrollo..."
        nohup npm run dev > "$PROJECT_DIR/frontend.log" 2>&1 &
        FRONTEND_PID=$!
        disown $FRONTEND_PID 2>/dev/null || true
        echo $FRONTEND_PID > "$PROJECT_DIR/frontend.pid"
        echo -e "  ${GREEN}Frontend iniciado (PID: $FRONTEND_PID)${NC}"
    fi

    # 3. Esperar a que esté listo
    wait_for_service "http://localhost:5176" "Frontend"

    cd "$PROJECT_DIR"
    echo ""
}

# ============================================================
# INICIO DEL SCRIPT PRINCIPAL
# ============================================================

echo -e "${YELLOW}[1/7]${NC} Verificando puertos..."
check_port 8020 "Landlord API" || true
check_port 8021 "Tenant API" || true
check_port 5176 "Frontend" || true
check_port 5177 "Ionic Portal" || true
check_port 3320 "Landlord DB" || true
check_port 3321 "Tenant DB" || true
echo ""

echo -e "${YELLOW}[2/7]${NC} Configurando Landlord Credit API..."
setup_laravel_project "landlord-creditapi" "Landlord API" "8020" "landlord-creditapi-mysql-1"

echo -e "${YELLOW}[3/7]${NC} Configurando Tenant API..."
setup_laravel_project "tenant-api" "Tenant API" "8021" "tenant-api-mysql-1"

echo -e "${YELLOW}[4/7]${NC} Configurando permisos de base de datos..."
setup_mysql_permissions "tenant-api-mysql-1"

echo -e "${YELLOW}[5/7]${NC} Iniciando queue workers..."
setup_queue_workers

echo -e "${YELLOW}[6/7]${NC} Configurando Frontend..."
setup_frontend

echo -e "${YELLOW}[7/7]${NC} Configurando Ionic Portal..."
setup_ionic_portal

# ============================================================
# RESUMEN FINAL
# ============================================================

echo -e "${GREEN}========================================================"
echo "  Proyecto Credifácil iniciado exitosamente!"
echo -e "========================================================${NC}"
echo ""
echo -e "${BLUE}Servicios disponibles:${NC}"
echo "  Landlord API:     http://localhost:8020"
echo "  Tenant API:       http://localhost:8021"
echo "  Frontend (React): http://localhost:5176"
echo "  Portal Cliente:   http://localhost:5177"
echo ""
echo -e "${BLUE}Bases de datos:${NC}"
echo "  Landlord DB:      localhost:3320 (user: sail, pass: password)"
echo "  Tenant DB:        localhost:3321 (user: sail, pass: password)"
echo ""
echo -e "${BLUE}Comandos utiles:${NC}"
echo "  Detener proyecto:     ./stop-project.sh"
echo "  Ver logs landlord:    docker logs -f landlord-creditapi-laravel.test-1"
echo "  Ver logs tenant:      docker logs -f tenant-api-laravel.test-1"
echo "  Ver logs frontend:    tail -f frontend.log"
echo "  Ver logs ionic:       tail -f ionic-portal.log"
echo "  Ver queue tenant:     tail -f tenant-queue.log"
echo "  Ver queue landlord:   tail -f landlord-queue.log"
echo ""

# Preguntar si quiere monitorear
read -p "Iniciar monitoreo de servicios? (s/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo -e "${BLUE}Monitoreando servicios... (Ctrl+C para salir)${NC}"
    echo ""

    # Función de cleanup
    cleanup() {
        echo ""
        echo -e "${YELLOW}Monitoreo detenido.${NC}"
        echo -e "Usa ${BLUE}./stop-project.sh${NC} para detener todos los servicios"
        exit 0
    }

    trap cleanup SIGINT

    # Monitoreo continuo
    while true; do
        status=""

        if curl -s --max-time 3 "http://localhost:8020" > /dev/null 2>&1; then
            status+="${GREEN}Landlord:OK${NC} "
        else
            status+="${RED}Landlord:DOWN${NC} "
        fi

        if curl -s --max-time 3 "http://localhost:8021" > /dev/null 2>&1; then
            status+="${GREEN}Tenant:OK${NC} "
        else
            status+="${RED}Tenant:DOWN${NC} "
        fi

        if curl -s --max-time 3 "http://localhost:5176" > /dev/null 2>&1; then
            status+="${GREEN}Frontend:OK${NC} "
        else
            status+="${RED}Frontend:DOWN${NC} "
        fi

        if curl -s --max-time 3 "http://localhost:5177" > /dev/null 2>&1; then
            status+="${GREEN}Ionic:OK${NC}"
        else
            status+="${RED}Ionic:DOWN${NC}"
        fi

        echo -e "  [$(date '+%H:%M:%S')] $status"
        sleep 10
    done
fi

echo ""
echo -e "${GREEN}Listo para usar!${NC}"
