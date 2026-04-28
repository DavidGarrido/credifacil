#!/bin/bash
# ============================================================
#  backup_vps_hostinger.sh
#  Trae los dumps de producción (DigitalOcean) y los restaura
#  en los contenedores Docker locales.
# ============================================================

set -euo pipefail

# ── Configuración ────────────────────────────────────────────
VPS_HOST="137.184.163.131"
VPS_USER="root"
SSH_KEY="$HOME/.ssh/do_credifacil"
DUMP_DIR="/tmp/credifacil_dumps"

# Producción – landlord
LANDLORD_COMPOSE="/opt/credifacil/landlord-creditapi/compose.yaml"
LANDLORD_DB="landlord_creditapi"
LANDLORD_USER="landlord_user"
LANDLORD_PASS="LandlordProd2026"

# Producción – tenant
TENANT_COMPOSE="/opt/credifacil/tenant-api-credifacil/compose.yaml"
TENANT_ROOT_PASS="TenantProd2026"

# Local – contenedores
LOCAL_LANDLORD_CONTAINER="landlord-creditapi-mysql-1"
LOCAL_LANDLORD_DB="landlord_creditapi"
LOCAL_LANDLORD_ROOT_PASS="password"

LOCAL_TENANT_CONTAINER="tenant-api-mysql-1"
LOCAL_TENANT_ROOT_PASS="password"

SSH="ssh -i $SSH_KEY $VPS_USER@$VPS_HOST"

# ── Colores ──────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓ $*${NC}"; }
info() { echo -e "${YELLOW}▶ $*${NC}"; }
err()  { echo -e "${RED}✗ $*${NC}"; exit 1; }

# ── Inicio ───────────────────────────────────────────────────
mkdir -p "$DUMP_DIR"
echo ""
echo "=============================================="
echo "  Backup VPS → Local  |  $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="
echo ""

# ── 1. Dump landlord ─────────────────────────────────────────
info "Descargando dump del landlord..."
$SSH "docker compose -f $LANDLORD_COMPOSE exec -T mysql \
    mysqldump -u $LANDLORD_USER -p$LANDLORD_PASS $LANDLORD_DB 2>/dev/null" \
    > "$DUMP_DIR/landlord.sql" \
    || err "Fallo al descargar dump del landlord"
ok "landlord.sql  ($(wc -l < "$DUMP_DIR/landlord.sql") líneas)"

# ── 2. Listar bases de datos del tenant ──────────────────────
info "Listando bases de datos de tenant en producción..."
TENANT_DBS=$($SSH "docker compose -f $TENANT_COMPOSE exec -T mysql \
    mysql -u root -p$TENANT_ROOT_PASS -e 'SHOW DATABASES;' 2>/dev/null" \
    | grep -E '^(tenant_api|tenanttenant_)' | tr '\n' ' ')

if [ -z "$TENANT_DBS" ]; then
    err "No se encontraron bases de datos de tenant en producción"
fi
ok "DBs encontradas: $TENANT_DBS"

# ── 3. Dump de todas las DBs de tenant ───────────────────────
info "Descargando dump de tenant (todas las DBs)..."
$SSH "docker compose -f $TENANT_COMPOSE exec -T mysql \
    mysqldump -u root -p$TENANT_ROOT_PASS --databases $TENANT_DBS 2>/dev/null" \
    > "$DUMP_DIR/tenant_all.sql" \
    || err "Fallo al descargar dump del tenant"
ok "tenant_all.sql  ($(wc -l < "$DUMP_DIR/tenant_all.sql") líneas)"

# ── 4. Restaurar landlord local ──────────────────────────────
info "Restaurando landlord en contenedor local ($LOCAL_LANDLORD_CONTAINER)..."
docker exec -i "$LOCAL_LANDLORD_CONTAINER" \
    mysql -u root -p"$LOCAL_LANDLORD_ROOT_PASS" "$LOCAL_LANDLORD_DB" \
    < "$DUMP_DIR/landlord.sql" 2>/dev/null \
    || err "Fallo al restaurar landlord local"
ok "Landlord restaurado en $LOCAL_LANDLORD_DB"

# ── 5. Restaurar tenant local ────────────────────────────────
info "Restaurando tenant en contenedor local ($LOCAL_TENANT_CONTAINER)..."
docker exec -i "$LOCAL_TENANT_CONTAINER" \
    mysql -u root -p"$LOCAL_TENANT_ROOT_PASS" \
    < "$DUMP_DIR/tenant_all.sql" 2>/dev/null \
    || err "Fallo al restaurar tenant local"
ok "Tenant restaurado (todas las DBs)"

# ── 6. Verificación rápida ───────────────────────────────────
echo ""
info "Verificando datos locales..."

CREDITS=$(docker exec "$LOCAL_LANDLORD_CONTAINER" \
    mysql -u root -p"$LOCAL_LANDLORD_ROOT_PASS" "$LOCAL_LANDLORD_DB" \
    -se "SELECT COUNT(*) FROM credits WHERE status='active';" 2>/dev/null)
ok "Créditos activos en landlord local: $CREDITS"

LOCAL_TENANT_DBS=$(docker exec "$LOCAL_TENANT_CONTAINER" \
    mysql -u root -p"$LOCAL_TENANT_ROOT_PASS" \
    -se "SHOW DATABASES;" 2>/dev/null \
    | grep -c '^tenanttenant_' || true)
ok "Bases de datos de tenant locales: $LOCAL_TENANT_DBS"

# ── Resumen ──────────────────────────────────────────────────
echo ""
echo "=============================================="
ok "Backup completado — dumps en $DUMP_DIR"
echo "  landlord:  $DUMP_DIR/landlord.sql"
echo "  tenant:    $DUMP_DIR/tenant_all.sql"
echo ""
echo "  Recarga http://localhost:8020/collections/manage"
echo "=============================================="
echo ""
