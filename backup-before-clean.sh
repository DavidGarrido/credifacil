#!/bin/bash

# Script para hacer respaldo antes de limpiar datos
# Crea backups de las tablas importantes

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuración
LANDLORD_CONTAINER="landlord-creditapi-mysql-1"
TENANT_CONTAINER="tenant-api-mysql-1"
MYSQL_ROOT_PASSWORD="password"
BACKUP_DIR="/home/garher/Documentos/credifacil/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  CrediFácil - Backup de Datos${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Crear directorio de backups
mkdir -p "$BACKUP_DIR/$TIMESTAMP"

echo -e "${GREEN}Respaldando datos en: $BACKUP_DIR/$TIMESTAMP${NC}"
echo ""

# Backup de LANDLORD
echo -e "${GREEN}[1/2] Respaldando base de datos de LANDLORD...${NC}"
docker exec $LANDLORD_CONTAINER mysqldump -uroot -p${MYSQL_ROOT_PASSWORD} \
    landlord_creditapi \
    clients credits credit_transactions client_documents verification_codes payment_links \
    > "$BACKUP_DIR/$TIMESTAMP/landlord_backup.sql" 2>/dev/null

echo -e "${GREEN}✓ Backup de landlord completado${NC}"

# Backup de TENANTS
echo -e "${GREEN}[2/2] Respaldando cuotas de tenants...${NC}"

tenant_dbs=$(docker exec $TENANT_CONTAINER mysql -uroot -p${MYSQL_ROOT_PASSWORD} -N -e "
SELECT TABLE_SCHEMA
FROM information_schema.TABLES
WHERE TABLE_NAME = 'credit_installments'
  AND TABLE_SCHEMA LIKE 'tenant%'
GROUP BY TABLE_SCHEMA;
" 2>&1 | grep -v "Warning")

for db in $tenant_dbs; do
    echo -e "${YELLOW}  Respaldando $db...${NC}"
    docker exec $TENANT_CONTAINER mysqldump -uroot -p${MYSQL_ROOT_PASSWORD} \
        $db credit_installments \
        > "$BACKUP_DIR/$TIMESTAMP/tenant_${db}_installments.sql" 2>/dev/null
done

echo -e "${GREEN}✓ Backup de tenants completado${NC}"
echo ""

# Resumen
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Backup Completado${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Ubicación: $BACKUP_DIR/$TIMESTAMP"
echo ""
echo "Archivos creados:"
ls -lh "$BACKUP_DIR/$TIMESTAMP/" | tail -n +2 | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo -e "${GREEN}Ahora puedes ejecutar clean-test-data.sh de forma segura${NC}"
echo ""
