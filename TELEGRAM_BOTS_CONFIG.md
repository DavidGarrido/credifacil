# 🤖 Configuración de Bots de Telegram - Credifácil

El sistema utiliza una arquitectura de bots dual para separar el entorno de desarrollo/pruebas del entorno de producción.

---

## 1. Bots Registrados

| Entorno | Username | Propósito |
| :--- | :--- | :--- |
| **Producción** | `@credifacilcolombia_bot` | Uso oficial por clientes reales. |
| **Pruebas / Local** | `@pruebascredifacilbot` | Pruebas de desarrollo, flujo de cuotas y depuración. |

---

## 2. Variables de Entorno (.env)

Cada entorno debe tener configuradas las siguientes variables en el archivo `.env` del **Landlord**:

```env
# Ejemplo para LOCAL
TELEGRAM_BOT_TOKEN=8510714367:AAH76vOAYBT2X-0iyliCc_ekQJSkeBe6WQA
TELEGRAM_BOT_USERNAME=pruebascredifacilbot

# Ejemplo para PRODUCCIÓN
TELEGRAM_BOT_TOKEN=8755939774:AAFwWgsXimY-vkzP23p19Co-UdeHktQQI5s
TELEGRAM_BOT_USERNAME=credifacilcolombia_bot
```

---

## 3. Dinamismo Frontend (Deep Links)

El frontend detecta automáticamente qué bot usar basándose en la respuesta del Landlord.

- **Endpoint:** `/api/status/{clientId}` (Landlord).
- **Lógica:** El controlador `VerificationController` incluye la variable `telegram_bot_username` en la respuesta JSON.
- **Implementación:** El componente `ClientVerification.jsx` usa este valor para construir los enlaces `t.me/{username}?start=...` y el código QR.

---

## 4. Gestión del Webhook

Se utiliza el script `setup_telegram_webhook.sh` (ubicado en la raíz del proyecto) para configurar los webhooks de forma rápida.

### Modo Local (Desarrollo)
Usa **ngrok** para crear un túnel hacia tu puerto local 8020.
```bash
./setup_telegram_webhook.sh local
```
*Requiere tener ngrok instalado y autenticado.*

### Modo Producción
Configura el webhook directamente hacia la URL oficial del servidor.
```bash
./setup_telegram_webhook.sh prod
```
*URL resultante:* `https://admin.credifacilcolombia.com/api/telegram/webhook`

---

## 5. Funcionamiento del Webhook (Lógica Interna)

El controlador encargado de recibir los mensajes es:
`landlord-creditapi/app/Http/Controllers/Api/TelegramWebhookController.php`

### Estados de Verificación
El bot "sabe" qué acción esperar de un usuario mediante el Cache de Laravel:
- **Llave:** `telegram_doc_step:{chatId}`
- **Valores:** `identification_front`, `identification_back`.
- **Expiración:** 24 horas.

### Comandos Soportados
- `/start {param}`: Inicia el proceso de vinculación y verificación de identidad.
- `SI`: Acepta una propuesta de crédito.
- `{número}`: Selecciona el número de cuotas para una compra.
- `Fotos/Documentos`: Sube automáticamente imágenes a la carpeta de documentos del cliente.

---

## 6. Resolución de Problemas (Troubleshooting)

1. **El bot no responde en local:**
   - Verifica que ngrok esté corriendo: `ps aux | grep ngrok`.
   - Re-ejecuta el script: `./setup_telegram_webhook.sh local`.
   - Verifica los logs: `tail -f landlord-creditapi/storage/logs/laravel.log`.

2. **Error 404 en el Webhook Info:**
   - Si `getWebhookInfo` de Telegram muestra 404, la URL de ngrok ha cambiado o el servidor local no está escuchando en el puerto 8020.

3. **Cambio de Bot:**
   - Si cambias el token en el `.env`, recuerda limpiar la caché de Laravel:
     `php artisan config:clear && php artisan cache:clear`
