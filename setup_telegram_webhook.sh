#!/bin/bash

# Determinar el modo (local o prod)
MODE=${1:-local}

# Ruta al archivo .env para obtener el token
ENV_FILE="/mnt/almacenamiento/garher/Documentos/credifacil/landlord-creditapi/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: No se encontró el archivo .env en $ENV_FILE"
    exit 1
fi

# Extraer el token de Telegram del .env basado en el modo
if [ "$MODE" == "prod" ]; then
    TOKEN_VAR="TELEGRAM_BOT_TOKEN_PROD"
else
    TOKEN_VAR="TELEGRAM_BOT_TOKEN_TEST"
fi

TOKEN=$(grep "$TOKEN_VAR" "$ENV_FILE" | cut -d '=' -f2 | tr -d '"' | tr -d "'")

if [ -z "$TOKEN" ]; then
    echo "Error: TELEGRAM_BOT_TOKEN no encontrado en el archivo .env"
    exit 1
fi

if [ "$MODE" == "prod" ]; then
    WEBHOOK_URL="https://admin.credifacilcolombia.com/api/telegram/webhook"
    echo "Modo PRODUCCIÓN detectado."
    echo "Configurando webhook en la URL oficial: $WEBHOOK_URL"
else
    echo "Modo LOCAL detectado."
    echo "Iniciando ngrok en el puerto 8020..."
    # Iniciar ngrok en segundo plano
    ngrok http 8020 > /dev/null 2>&1 &
    NGROK_PID=$!

    # Esperar a que ngrok se inicie y la API local esté disponible
    echo "Esperando a que ngrok genere la URL pública..."
    MAX_RETRIES=10
    COUNT=0
    URL=""

    while [ $COUNT -lt $MAX_RETRIES ]; do
        # Consultar la API local de ngrok para obtener la URL pública
        URL=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^"]*')
        
        if [ ! -z "$URL" ]; then
            break
        fi
        
        sleep 2
        COUNT=$((COUNT + 1))
    done

    if [ -z "$URL" ]; then
        echo "Error: No se pudo obtener la URL de ngrok."
        kill $NGROK_PID
        exit 1
    fi

    echo "URL de ngrok obtenida: $URL"
    WEBHOOK_URL="${URL}/api/telegram/webhook"
fi

# Establecer el webhook de Telegram
echo "Enviando solicitud a Telegram..."
RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${TOKEN}/setWebhook?url=${WEBHOOK_URL}")

echo "Respuesta de Telegram: $RESPONSE"

if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "------------------------------------------------------------"
    echo "ÉXITO: Webhook configurado correctamente para $MODE."
    if [ "$MODE" == "local" ]; then
        echo "ngrok está corriendo en segundo plano (PID: $NGROK_PID)."
        echo "Recuerda no cerrar esta sesión o matar el proceso de ngrok."
    fi
    echo "------------------------------------------------------------"
else
    echo "Error al configurar el webhook."
    if [ "$MODE" == "local" ]; then
        kill $NGROK_PID
    fi
    exit 1
fi
