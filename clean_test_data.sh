#!/bin/bash
# ============================================================
#  clean_test_data.sh
#  Elimina datos de prueba del sistema Credifácil.
#
#  Modos de uso:
#    bash clean_test_data.sh              # solo reglas 100% seguras
#    bash clean_test_data.sh --dry        # muestra qué borraría sin borrar
#    bash clean_test_data.sh --full       # también aplica reglas agresivas
# ============================================================

set -euo pipefail

# ── Configuración ────────────────────────────────────────────
LOCAL_LANDLORD_CONTAINER="landlord-creditapi-mysql-1"
LOCAL_LANDLORD_DB="landlord_creditapi"
LOCAL_LANDLORD_ROOT_PASS="password"

LOCAL_TENANT_CONTAINER="tenant-api-mysql-1"
LOCAL_TENANT_ROOT_PASS="password"

# ── Lista de clientes a eliminar (aunque parezcan reales) ───
# Agregá emails o IDs separados por espacio
FORCE_DELETE_EMAILS=(
    "alexg.9207@proton.me"       # Alex Garrido (ID 8) + David Garrido (ID 12)
    "caritogarzon0105@gmail.com"  # Alexander Garrrido (ID 2) + Yeimmy Carolina (ID 14)
    "laugarcia.1029@gmail.com"    # Laura Garcia (ID 10)
    "anahernandezc@hotmail.com"   # Ana Hernandez (ID 9)
)
FORCE_DELETE_IDS=(

)

# ── Flags ────────────────────────────────────────────────────
DRY_RUN=false
FULL_MODE=false
for arg in "$@"; do
    case "$arg" in
        --dry) DRY_RUN=true ;;
        --full) FULL_MODE=true ;;
    esac
done

# ── Colores ──────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓ $*${NC}"; }
info() { echo -e "${YELLOW}▶ $*${NC}"; }
warn() { echo -e "${CYAN}  ⚠ $*${NC}"; }
err()  { echo -e "${RED}✗ $*${NC}"; exit 1; }

# ── Helper: ejecuta DELETE solo si no es dry-run ────────────
exec_mysql() {
    local container="$1" db="$2" sql="$3"
    if [ "$DRY_RUN" = true ]; then
        if echo "$sql" | grep -qi "^DELETE"; then
            local table=$(echo "$sql" | sed -n 's/.*FROM \([^ ]*\).*/\1/p')
            local cond=$(echo "$sql" | sed -n 's/.*WHERE \(.*\)/\1/p')
            warn "[DRY-RUN] Se borraría de $table donde $cond"
        fi
        return
    fi
    docker exec "$container" mysql -u root -p"$LOCAL_LANDLORD_ROOT_PASS" "$db" -e "$sql" 2>/dev/null || true
}

run_query() {
    local container="$1" db="$2" sql="$3"
    docker exec "$container" mysql -u root -p"$LOCAL_LANDLORD_ROOT_PASS" "$db" -se "$sql" 2>/dev/null || true
}

echo ""
echo "=============================================="
echo "  Limpieza de datos de prueba"
echo "  Modo: $( [ "$DRY_RUN" = true ] && echo 'DRY-RUN (solo muestra)' || echo 'EJECUCIÓN' )"
echo "  $( [ "$FULL_MODE" = true ] && echo 'Reglas agresivas: ACTIVADAS' || echo 'Reglas agresivas: DESACTIVADAS (usa --full)' )"
echo "  Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="
echo ""

# ═════════════════════════════════════════════════════════════
#  0. FUERZA BRUTA — Clientes marcados manualmente
# ═════════════════════════════════════════════════════════════
if [ ${#FORCE_DELETE_EMAILS[@]} -gt 0 ] || [ ${#FORCE_DELETE_IDS[@]} -gt 0 ]; then
    info "0. Eliminando clientes marcados manualmente..."

    for EMAIL in "${FORCE_DELETE_EMAILS[@]}"; do
        # Obtener TODOS los IDs que matcheen este email (pueden ser varios)
        CLIENTS=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "SELECT id, full_name FROM clients WHERE email = '$EMAIL';")
        if [ -z "$CLIENTS" ]; then
            warn "Email '$EMAIL' no encontrado (ya fue eliminado?)"
            continue
        fi
        while IFS=$'\t' read -r CID CNAME; do
            [ -z "$CID" ] && continue
            warn "'$CNAME' (ID $CID, email: $EMAIL)"
            for CRID in $(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "SELECT id FROM credits WHERE client_id = $CID;"); do
                [ -z "$CRID" ] && continue
                # Borrar enlaces de pago asociados al crédito
                exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                    "DELETE FROM payment_links WHERE credit_id = $CRID;"
                # Borrar cuotas en tenant DBs
                for DB in $(run_query "$LOCAL_TENANT_CONTAINER" "" "SHOW DATABASES;" | grep '^tenanttenant_' || true); do
                    HAS_TABLE=$(run_query "$LOCAL_TENANT_CONTAINER" "$DB" \
                        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB' AND table_name='credit_installments';")
                    [ "$HAS_TABLE" = "1" ] && exec_mysql "$LOCAL_TENANT_CONTAINER" "$DB" \
                        "DELETE FROM credit_installments WHERE landlord_credit_id = $CRID;"
                done
                exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                    "DELETE FROM credit_transactions WHERE credit_id = $CRID;"
                exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                    "DELETE FROM credits WHERE id = $CRID;"
            done
            # Borrar datos relacionados al cliente antes de eliminar el cliente
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM payment_links WHERE client_id = $CID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM client_documents WHERE client_id = $CID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM verification_codes WHERE client_id = $CID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM clients WHERE id = $CID;"
            [ "$DRY_RUN" = false ] && ok "Cliente '$CNAME' (ID $CID) eliminado por fuerza bruta"
        done <<< "$CLIENTS"
    done

    for CID in "${FORCE_DELETE_IDS[@]}"; do
        CNAME=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "SELECT full_name FROM clients WHERE id = $CID;" 2>/dev/null || true)
        if [ -n "$CNAME" ]; then
            warn "'$CNAME' (ID $CID, forzado)"
            for CRID in $(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "SELECT id FROM credits WHERE client_id = $CID;"); do
                exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                    "DELETE FROM payment_links WHERE credit_id = $CRID;"
                for DB in $(run_query "$LOCAL_TENANT_CONTAINER" "" "SHOW DATABASES;" | grep '^tenanttenant_' || true); do
                    HAS_TABLE=$(run_query "$LOCAL_TENANT_CONTAINER" "$DB" \
                        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB' AND table_name='credit_installments';")
                    [ "$HAS_TABLE" = "1" ] && exec_mysql "$LOCAL_TENANT_CONTAINER" "$DB" \
                        "DELETE FROM credit_installments WHERE landlord_credit_id = $CRID;"
                done
                exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                    "DELETE FROM credit_transactions WHERE credit_id = $CRID;"
                exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                    "DELETE FROM credits WHERE id = $CRID;"
            done
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM payment_links WHERE client_id = $CID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM client_documents WHERE client_id = $CID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM verification_codes WHERE client_id = $CID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM clients WHERE id = $CID;"
            [ "$DRY_RUN" = false ] && ok "Cliente '$CNAME' (ID $CID) eliminado por fuerza bruta"
        else
            warn "ID $CID no encontrado (ya fue eliminado?)"
        fi
    done
fi

# ═════════════════════════════════════════════════════════════
#  REGLAS 100% SEGURAS (siempre se ejecutan)
# ═════════════════════════════════════════════════════════════

# ── 1. Clientes con documento TEST* ──────────────────────────
info "1. Clientes con documento de prueba (TEST*)..."

TEST_CLIENTS=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
    "SELECT id, full_name FROM clients WHERE identification LIKE 'TEST%';")

if [ -n "$TEST_CLIENTS" ]; then
    while IFS=$'\t' read -r CID CNAME; do
        [ -z "$CID" ] && continue
        warn "'$CNAME' (ID $CID) — documento de prueba"
        for CRID in $(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "SELECT id FROM credits WHERE client_id = $CID;"); do
            [ -z "$CRID" ] && continue
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM payment_links WHERE credit_id = $CRID;"
            for DB in $(run_query "$LOCAL_TENANT_CONTAINER" "" "SHOW DATABASES;" | grep '^tenanttenant_' || true); do
                HAS_TABLE=$(run_query "$LOCAL_TENANT_CONTAINER" "$DB" \
                    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB' AND table_name='credit_installments';")
                [ "$HAS_TABLE" = "1" ] && exec_mysql "$LOCAL_TENANT_CONTAINER" "$DB" \
                    "DELETE FROM credit_installments WHERE landlord_credit_id = $CRID;"
            done
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM credit_transactions WHERE credit_id = $CRID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM credits WHERE id = $CRID;"
        done
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM payment_links WHERE client_id = $CID;"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM client_documents WHERE client_id = $CID;"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM verification_codes WHERE client_id = $CID;"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM clients WHERE id = $CID;"
        [ "$DRY_RUN" = false ] && ok "Cliente '$CNAME' (ID $CID) eliminado"
    done <<< "$TEST_CLIENTS"
else
    ok "Sin clientes con documento TEST"
fi

# ── 2. Clientes sin ningún crédito ───────────────────────────
info "2. Clientes sin créditos asociados..."

NO_CREDIT_IDS=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
    "SELECT c.id, c.full_name FROM clients c LEFT JOIN credits cr ON cr.client_id = c.id WHERE cr.id IS NULL;")

if [ -n "$NO_CREDIT_IDS" ]; then
    while IFS=$'\t' read -r CID CNAME; do
        [ -z "$CID" ] && continue
        warn "'$CNAME' (ID $CID) — sin créditos"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM payment_links WHERE client_id = $CID;"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM client_documents WHERE client_id = $CID;"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM verification_codes WHERE client_id = $CID;"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM clients WHERE id = $CID;"
        [ "$DRY_RUN" = false ] && ok "Cliente '$CNAME' (ID $CID) eliminado — sin créditos"
    done <<< "$NO_CREDIT_IDS"
else
    ok "Sin clientes huérfanos"
fi

# ── 3. Créditos activos sin transacciones ────────────────────
info "3. Créditos activos sin transacciones..."

GHOST_CREDITS=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
    "SELECT cr.id, cr.client_id FROM credits cr LEFT JOIN credit_transactions tx ON tx.credit_id = cr.id WHERE cr.status = 'active' AND tx.id IS NULL;")

if [ -n "$GHOST_CREDITS" ]; then
    while IFS=$'\t' read -r GID GCID; do
        [ -z "$GID" ] && continue
        warn "Crédito ID $GID — activo sin transacciones"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM payment_links WHERE credit_id = $GID;"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM credits WHERE id = $GID;"
        [ "$DRY_RUN" = false ] && ok "Crédito ID $GID eliminado — activo sin transacciones"

        REMAINING=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "SELECT COUNT(*) FROM credits WHERE client_id = $GCID;")
        if [ "$REMAINING" = "0" ]; then
            CNAME=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "SELECT full_name FROM clients WHERE id = $GCID;")
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM payment_links WHERE client_id = $GCID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM client_documents WHERE client_id = $GCID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM verification_codes WHERE client_id = $GCID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM clients WHERE id = $GCID;"
            [ "$DRY_RUN" = false ] && ok "Cliente '$CNAME' (ID $GCID) eliminado — ya sin créditos"
        fi
    done <<< "$GHOST_CREDITS"
else
    ok "Sin créditos fantasma"
fi

# ── 4. Tenants sin actividad (landlord) ──────────────────────
info "4. Tenants de prueba en landlord..."

REAL_TENANTS=(
    "tenant_69a3586fb69ee"  # ARTE Y CONFORD
    "tenant_69a3541bc406a"  # Libercol
    "tenant_69dc307ae7cf1"  # HABITARE
    "tenant_69a5026342e84"  # Blockers
)

for TID in $(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
    "SELECT tenant_id FROM tenant_company_infos;"); do
    KEEP=false
    for RT in "${REAL_TENANTS[@]}"; do
        [ "$TID" = "$RT" ] && KEEP=true && break
    done
    if [ "$KEEP" = false ]; then
        TNAME=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "SELECT commercial_name FROM tenant_company_infos WHERE tenant_id='$TID';")
        warn "'$TNAME' ($TID)"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM ally_payments WHERE tenant_id='$TID';"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM ally_collection_configs WHERE tenant_id='$TID';"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM tenant_company_infos WHERE tenant_id='$TID';"
        [ "$DRY_RUN" = false ] && ok "Tenant landlord '$TNAME' ($TID) eliminado"
    fi
done

# ── 5. Tenants de prueba (tenant-api) ────────────────────────
info "5. Tenants de prueba en tenant-api..."

for TID in $(run_query "$LOCAL_TENANT_CONTAINER" "tenant_api" \
    "SELECT id FROM tenants;"); do
    KEEP=false
    for RT in "${REAL_TENANTS[@]}"; do
        [ "$TID" = "$RT" ] && KEEP=true && break
    done
    if [ "$KEEP" = false ]; then
        TNAME=$(run_query "$LOCAL_TENANT_CONTAINER" "tenant_api" \
            "SELECT JSON_UNQUOTE(JSON_EXTRACT(data, '$.name')) FROM tenants WHERE id='$TID';")
        warn "'${TNAME:-sin_nombre}' ($TID)"
        exec_mysql "$LOCAL_TENANT_CONTAINER" "" \
            "DROP DATABASE IF EXISTS \`tenanttenant_${TID#tenant_}\`;"
        exec_mysql "$LOCAL_TENANT_CONTAINER" "tenant_api" \
            "DELETE FROM tenants WHERE id='$TID';"
        [ "$DRY_RUN" = false ] && ok "Tenant-api '${TNAME:-sin_nombre}' ($TID) eliminado"
    fi
done

# ── 6. Bases de datos huérfanas ──────────────────────────────
info "6. Bases de datos de tenant huérfanas..."

EXISTING_TENANTS=$(run_query "$LOCAL_TENANT_CONTAINER" "tenant_api" \
    "SELECT id FROM tenants;")
ALL_DBS=$(run_query "$LOCAL_TENANT_CONTAINER" "" \
    "SHOW DATABASES;" | grep '^tenanttenant_' || true)

for DB in $ALL_DBS; do
    SUFFIX="${DB#tenanttenant_}"
    FOUND=false
    for TID in $EXISTING_TENANTS; do
        [ "${TID#tenant_}" = "$SUFFIX" ] && FOUND=true && break
    done
    if [ "$FOUND" = false ]; then
        warn "DB huérfana '$DB'"
        exec_mysql "$LOCAL_TENANT_CONTAINER" "" \
            "DROP DATABASE IF EXISTS \`$DB\`;"
        [ "$DRY_RUN" = false ] && ok "DB '$DB' eliminada"
    fi
done

# ── 7. Cuotas huérfanas en tenant DBs ────────────────────────
info "7. Cuotas huérfanas en tenant DBs..."

ACTIVE_CREDIT_IDS=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
    "SELECT id FROM credits;" | tr '\n' ',' | sed 's/,$//' || true)
TENANT_DBS=$(run_query "$LOCAL_TENANT_CONTAINER" "" \
    "SHOW DATABASES;" | grep '^tenanttenant_' || true)

for DB in $TENANT_DBS; do
    HAS_TABLE=$(run_query "$LOCAL_TENANT_CONTAINER" "$DB" \
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB' AND table_name='credit_installments';")
    [ "$HAS_TABLE" != "1" ] && continue

    ORPHAN_CREDITS=$(run_query "$LOCAL_TENANT_CONTAINER" "$DB" \
        "SELECT DISTINCT landlord_credit_id FROM credit_installments WHERE landlord_credit_id NOT IN ($ACTIVE_CREDIT_IDS);")
    for OC in $ORPHAN_CREDITS; do
        warn "$DB: cuotas de credit_id=$OC"
        exec_mysql "$LOCAL_TENANT_CONTAINER" "$DB" \
            "DELETE FROM credit_installments WHERE landlord_credit_id = $OC;"
        [ "$DRY_RUN" = false ] && ok "$DB: cuotas huérfanas de credit_id=$OC eliminadas"
    done
done

# ═════════════════════════════════════════════════════════════
#  REGLAS AGRESIVAS (solo con --full)
# ═════════════════════════════════════════════════════════════

if [ "$FULL_MODE" = true ]; then

echo ""
info "══════ REGLAS AGRESIVAS (--full) ══════"
echo ""

# ── 8. Clientes con solo créditos pending en $0 ────────────
info "8. Clientes con créditos pending en \$0 (posiblemente prueba)..."

PENDING_CLIENTS=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
    "SELECT DISTINCT c.id, c.full_name FROM clients c JOIN credits cr ON cr.client_id = c.id WHERE cr.status = 'pending' AND (cr.financed_amount IS NULL OR cr.financed_amount = 0) AND c.identification NOT LIKE 'TEST%';")

if [ -n "$PENDING_CLIENTS" ]; then
    while IFS=$'\t' read -r CID CNAME; do
        [ -z "$CID" ] && continue
        warn "'$CNAME' (ID $CID) — créditos pending en \$0"
        for CRID in $(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "SELECT id FROM credits WHERE client_id = $CID AND status = 'pending';"); do
            [ -z "$CRID" ] && continue
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM payment_links WHERE credit_id = $CRID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM credit_transactions WHERE credit_id = $CRID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM credits WHERE id = $CRID;"
        done
        # Solo borrar cliente si no le quedan créditos
        REMAINING=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "SELECT COUNT(*) FROM credits WHERE client_id = $CID;")
        if [ "$REMAINING" = "0" ]; then
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM payment_links WHERE client_id = $CID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM client_documents WHERE client_id = $CID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM verification_codes WHERE client_id = $CID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM clients WHERE id = $CID;"
            [ "$DRY_RUN" = false ] && ok "Cliente '$CNAME' (ID $CID) eliminado"
        else
            warn "  → Conservado: tiene créditos activos"
        fi
    done <<< "$PENDING_CLIENTS"
else
    ok "Sin clientes con créditos pending"
fi

# ── 9. Créditos cuyas transacciones solo apuntan a tenants eliminados ──
info "9. Créditos atados a tenants que ya no existen..."

REAL_IDS=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
    "SELECT GROUP_CONCAT(CONCAT('\"', tenant_id, '\"')) FROM tenant_company_infos;" || echo '""')

ORPHAN_CREDITS=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
    "SELECT cr.id, cr.client_id FROM credits cr WHERE cr.status = 'active'
     AND EXISTS (SELECT 1 FROM credit_transactions tx WHERE tx.credit_id = cr.id AND tx.tenant_id IS NOT NULL AND tx.tenant_id != 'landlord' AND tx.tenant_id NOT IN (SELECT tenant_id FROM tenant_company_infos))
     AND NOT EXISTS (SELECT 1 FROM credit_transactions tx2 WHERE tx2.credit_id = cr.id AND tx2.tenant_id IN (SELECT tenant_id FROM tenant_company_infos));")

if [ -n "$ORPHAN_CREDITS" ]; then
    while IFS=$'\t' read -r GID GCID; do
        [ -z "$GID" ] && continue
        CNAME=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "SELECT full_name FROM clients WHERE id = $GCID;")
        warn "'$CNAME' (ID $GCID) — crédito $GID solo tiene transacciones de tenants eliminados"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM payment_links WHERE credit_id = $GID;"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM credit_transactions WHERE credit_id = $GID;"
        exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "DELETE FROM credits WHERE id = $GID;"
        [ "$DRY_RUN" = false ] && ok "Crédito ID $GID eliminado"
        REMAINING=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
            "SELECT COUNT(*) FROM credits WHERE client_id = $GCID;")
        if [ "$REMAINING" = "0" ]; then
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM payment_links WHERE client_id = $GCID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM client_documents WHERE client_id = $GCID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM verification_codes WHERE client_id = $GCID;"
            exec_mysql "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
                "DELETE FROM clients WHERE id = $GCID;"
            [ "$DRY_RUN" = false ] && ok "Cliente '$CNAME' (ID $GCID) eliminado"
        fi
    done <<< "$ORPHAN_CREDITS"
else
    ok "Sin créditos atados a tenants eliminados"
fi

fi # FIN FULL_MODE

# ═════════════════════════════════════════════════════════════
#  VERIFICACIÓN FINAL
# ═════════════════════════════════════════════════════════════

echo ""
if [ "$DRY_RUN" = false ]; then
    info "Verificando resultado..."
    CREDITS=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
        "SELECT COUNT(*) FROM credits WHERE status='active';")
    CLIENTS=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
        "SELECT COUNT(*) FROM clients;")
    TENANTS_L=$(run_query "$LOCAL_LANDLORD_CONTAINER" "$LOCAL_LANDLORD_DB" \
        "SELECT COUNT(*) FROM tenant_company_infos;")
    TENANTS_A=$(run_query "$LOCAL_TENANT_CONTAINER" "tenant_api" \
        "SELECT COUNT(*) FROM tenants;")
    DBS=$(run_query "$LOCAL_TENANT_CONTAINER" "" \
        "SHOW DATABASES;" | grep -c '^tenanttenant_' || true)

    echo ""
    echo "=============================================="
    echo "  LIMPIEZA COMPLETADA"
    echo "=============================================="
    ok "Créditos activos:       $CREDITS"
    ok "Clientes:                $CLIENTS"
    ok "Tenants (landlord):      $TENANTS_L"
    ok "Tenants (tenant-api):    $TENANTS_A"
    ok "Bases de datos tenants:  $DBS"
    echo ""
    echo "  Recarga: http://localhost:8020/collections/manage"
    echo "=============================================="

    # Invalidar caché
    info "Invalidando caché del landlord..."
    docker exec landlord-creditapi-laravel.test-1 \
        php artisan cache:forget report_global_summary 2>/dev/null || true
    ok "Caché invalidado"
else
    ok "Modo DRY-RUN — no se borró nada. Para ejecutar: bash $0"
    ok "Para incluir reglas agresivas: bash $0 --full"
fi
