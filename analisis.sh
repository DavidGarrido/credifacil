#!/bin/bash

# ============================================================
# inspect_project.sh - Credifácil / landlord-creditapi
# Uso: bash inspect_project.sh [ruta_del_proyecto]
# Ejemplo: bash inspect_project.sh /home/garher/Documentos/credifacil/landlord-creditapi
# ============================================================

PROJECT_PATH="${1:-$(pwd)}"

echo "============================================================"
echo "  CREDIFÁCIL - Inspección landlord-creditapi"
echo "  Ruta: $PROJECT_PATH"
echo "  Fecha: $(date)"
echo "============================================================"

cd "$PROJECT_PATH" || { echo "❌ No se pudo acceder a: $PROJECT_PATH"; exit 1; }

# ── 1. VERSION DE LARAVEL Y PHP ──────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  1. VERSIONES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▶ PHP:"
php -v 2>/dev/null || echo "  (php no encontrado en PATH)"
echo ""
echo "▶ Laravel (composer.json):"
grep -E '"laravel/framework"' composer.json 2>/dev/null || echo "  No encontrado"
echo ""
echo "▶ Composer packages relevantes:"
grep -E '"stancl/tenancy|tymon/jwt|laravel/sanctum|spatie/|maatwebsite/|barryvdh/"' composer.json 2>/dev/null || echo "  Ninguno relevante encontrado"

# ── 2. MODELOS ───────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  2. MODELOS (app/Models)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d "app/Models" ]; then
  for model in app/Models/*.php; do
    echo ""
    echo "📄 $model"
    echo "   fillable / casts / relations:"
    grep -E 'fillable|casts|hasMany|belongsTo|hasOne|belongsToMany|protected \$table' "$model" | sed 's/^/   /'
  done
else
  echo "  Carpeta app/Models no encontrada"
fi

# ── 3. MIGRACIONES ───────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  3. MIGRACIONES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d "database/migrations" ]; then
  ls database/migrations/*.php 2>/dev/null | while read f; do
    echo ""
    echo "📄 $(basename $f)"
    grep -E 'Schema::create|->string|->integer|->decimal|->boolean|->timestamp|->enum|->foreignId|->unsignedBigInteger' "$f" | head -30 | sed 's/^/   /'
  done
else
  echo "  No se encontró carpeta database/migrations"
fi

# ── 4. RUTAS API ─────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  4. RUTAS API (routes/api.php)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "routes/api.php" ]; then
  cat routes/api.php
else
  echo "  routes/api.php no encontrado"
fi

# ── 5. CONTROLLERS ───────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  5. CONTROLLERS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
find app/Http/Controllers -name "*.php" 2>/dev/null | while read f; do
  echo ""
  echo "📄 $f"
  grep -E 'public function ' "$f" | sed 's/^/   /'
done

# ── 6. ESTRUCTURA DE CARPETAS ────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  6. ESTRUCTURA GENERAL DEL PROYECTO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
find . -not -path '*/vendor/*' \
       -not -path '*/.git/*' \
       -not -path '*/node_modules/*' \
       -not -path '*/storage/*' \
       -not -path '*/.sail/*' \
       -maxdepth 4 \
       -type f -name "*.php" | sort | sed 's/^/  /'

# ── 7. .ENV (sin secrets) ─────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  7. .ENV (claves ocultas)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f ".env" ]; then
  sed -E 's/(KEY|SECRET|PASSWORD|TOKEN|PWD)=.*/\1=***/' .env
else
  echo "  .env no encontrado"
fi

echo ""
echo "============================================================"
echo "  ✅ Inspección completada"
echo "============================================================"
