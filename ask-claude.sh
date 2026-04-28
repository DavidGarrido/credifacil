#!/bin/bash
# Script para que Cline consulte a Claude cuando no puede resolver algo.
# Uso: ./ask-claude.sh "descripcion del problema"

if [ -z "$1" ]; then
  echo "Uso: $0 \"descripcion del problema\""
  exit 1
fi

PREGUNTA="$1"

CONTEXTO="Proyecto Credifacil - sistema de creditos multi-tenant:
- landlord-creditapi/ : API central de creditos (Laravel 11)
- tenant-api/         : API multi-tenant (Laravel 11)
- frontend/           : Cliente (React + Vite + Tailwind)

CONSULTA:
$PREGUNTA"

env -u CLAUDECODE claude -p "$CONTEXTO"
