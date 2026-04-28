#!/bin/bash

# Script para limpiar datos de prueba de CrediFácil
# Limpia créditos, transacciones en landlord y cuotas en todos los tenants

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuración
LANDLORD_CONTAINER="landlord-creditapi-mysql-1"
TENANT_CONTAINER="tenant-api-mysql-1"
MYSQL_ROOT_PASSWORD="password"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  CrediFácil - Limpieza de Datos${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Verificar que los contenedores estén corriendo
echo -e "${GREEN}Verificando contenedores...${NC}"
if ! docker ps | grep -q "$LANDLORD_CONTAINER"; then
    echo -e "${RED}Error: El contenedor $LANDLORD_CONTAINER no está corriendo${NC}"
    exit 1
fi

if ! docker ps | grep -q "$TENANT_CONTAINER"; then
    echo -e "${RED}Error: El contenedor $TENANT_CONTAINER no está corriendo${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Contenedores activos${NC}"
echo ""

# Advertencia
echo -e "${RED}⚠️  ADVERTENCIA ⚠️${NC}"
echo -e "${RED}Este script eliminará TODOS los siguientes datos:${NC}"
echo ""
echo "  En LANDLORD:"
echo "    - Enlaces de pago (payment_links)"
echo "    - Transacciones de crédito (credit_transactions)"
echo "    - Créditos (credits)"
echo "    - Documentos de clientes (client_documents)"
echo "    - Códigos de verificación (verification_codes)"
echo "    - Clientes (clients)"
echo ""
echo "  En TODOS LOS TENANTS:"
echo "    - Cuotas de crédito (credit_installments)"
echo ""

# Confirmación
read -p "¿Estás seguro de continuar? (escribe 'SI' para confirmar): " confirm

if [ "$confirm" != "SI" ]; then
    echo -e "${YELLOW}Operación cancelada${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}Iniciando limpieza...${NC}"
echo ""

# ============================================
# LIMPIAR LANDLORD
# ============================================
echo -e "${GREEN}[1/3] Limpiando base de datos de LANDLORD...${NC}"

docker exec $LANDLORD_CONTAINER mysql -uroot -p${MYSQL_ROOT_PASSWORD} landlord_creditapi -e "
SET FOREIGN_KEY_CHECKS = 0;

-- Limpiar payment links
DELETE FROM payment_links;
ALTER TABLE payment_links AUTO_INCREMENT = 1;
SELECT CONCAT('✓ Eliminados ', ROW_COUNT(), ' enlaces de pago') as resultado;

-- Limpiar transacciones
DELETE FROM credit_transactions;
ALTER TABLE credit_transactions AUTO_INCREMENT = 1;
SELECT CONCAT('✓ Eliminadas ', ROW_COUNT(), ' transacciones') as resultado;

-- Limpiar créditos
DELETE FROM credits;
ALTER TABLE credits AUTO_INCREMENT = 1;
SELECT CONCAT('✓ Eliminados ', ROW_COUNT(), ' créditos') as resultado;

-- Limpiar documentos de clientes
DELETE FROM client_documents;
ALTER TABLE client_documents AUTO_INCREMENT = 1;
SELECT CONCAT('✓ Eliminados ', ROW_COUNT(), ' documentos') as resultado;

-- Limpiar códigos de verificación
DELETE FROM verification_codes;
ALTER TABLE verification_codes AUTO_INCREMENT = 1;
SELECT CONCAT('✓ Eliminados ', ROW_COUNT(), ' códigos de verificación') as resultado;

-- Limpiar clientes
DELETE FROM clients;
ALTER TABLE clients AUTO_INCREMENT = 1;
SELECT CONCAT('✓ Eliminados ', ROW_COUNT(), ' clientes') as resultado;

SET FOREIGN_KEY_CHECKS = 1;

SELECT '---' as '---';
SELECT 'LANDLORD limpiado exitosamente' as 'Estado';
" 2>&1 | grep -v "Warning"

echo ""

# ============================================
# LIMPIAR TENANTS
# ============================================
echo -e "${GREEN}[2/3] Obteniendo lista de bases de datos de tenants...${NC}"

# Obtener lista de bases de datos de tenants
tenant_dbs=$(docker exec $TENANT_CONTAINER mysql -uroot -p${MYSQL_ROOT_PASSWORD} -N -e "
SELECT TABLE_SCHEMA
FROM information_schema.TABLES
WHERE TABLE_NAME = 'credit_installments'
  AND TABLE_SCHEMA LIKE 'tenant%'
GROUP BY TABLE_SCHEMA;
" 2>&1 | grep -v "Warning")

# Contar bases de datos
db_count=$(echo "$tenant_dbs" | grep -c "tenant" || true)

echo -e "${GREEN}Encontradas $db_count base(s) de datos de tenants${NC}"
echo ""

echo -e "${GREEN}[3/3] Limpiando cuotas en cada tenant...${NC}"

# Limpiar cada base de datos de tenant
counter=1
for db in $tenant_dbs; do
    echo -e "${YELLOW}  [$counter/$db_count] Limpiando $db...${NC}"

    result=$(docker exec $TENANT_CONTAINER mysql -uroot -p${MYSQL_ROOT_PASSWORD} $db -N -e "
    DELETE FROM credit_installments;
    ALTER TABLE credit_installments AUTO_INCREMENT = 1;
    SELECT ROW_COUNT();
    " 2>&1 | grep -v "Warning" | tail -1)

    echo -e "${GREEN}    ✓ Eliminadas $result cuotas${NC}"
    ((counter++))
done

echo ""

# ============================================
# RESUMEN
# ============================================
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Limpieza Completada Exitosamente${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Mostrar estadísticas finales
echo -e "${YELLOW}Estadísticas finales:${NC}"
echo ""

echo "LANDLORD:"
docker exec $LANDLORD_CONTAINER mysql -uroot -p${MYSQL_ROOT_PASSWORD} landlord_creditapi -e "
SELECT 'Clientes' as Tabla, COUNT(*) as Total FROM clients
UNION ALL
SELECT 'Créditos', COUNT(*) FROM credits
UNION ALL
SELECT 'Transacciones', COUNT(*) FROM credit_transactions
UNION ALL
SELECT 'Documentos', COUNT(*) FROM client_documents
UNION ALL
SELECT 'Enlaces de pago', COUNT(*) FROM payment_links;
" 2>&1 | grep -v "Warning"

echo ""
echo "TENANTS:"
for db in $tenant_dbs; do
    count=$(docker exec $TENANT_CONTAINER mysql -uroot -p${MYSQL_ROOT_PASSWORD} $db -N -e "
    SELECT COUNT(*) FROM credit_installments;
    " 2>&1 | grep -v "Warning")
    echo "  $db: $count cuotas"
done

echo ""
echo -e "${GREEN}✓ Todas las tablas han sido limpiadas${NC}"
echo -e "${GREEN}✓ Los AUTO_INCREMENT han sido reiniciados${NC}"
echo -e "${GREEN}✓ El sistema está listo para nuevas pruebas${NC}"
echo ""
