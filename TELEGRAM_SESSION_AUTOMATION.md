/home/garher/Documentos compartidos
# Telegram Session Automation (Telethon)

## ¿Qué es?

Usamos **Telethon** (cliente MTProto) para controlar una cuenta de Telegram real (no un bot) desde el servidor. Esto permite enviar mensajes a cualquier número, incluso si no ha iniciado conversación con un bot.

## Archivos en el VPS

| Archivo | Descripción |
|---------|-------------|
| `/opt/rifaloop/tg_send_persist.py` | Script para enviar mensajes. Si no hay sesión, genera QR. |
| `/opt/rifaloop/algarher_session.session` | Archivo de sesión (se crea automáticamente al escanear QR). |
| `/opt/rifaloop/tg_qr.png` | Último QR generado (por si quieres verlo como imagen). |

## Cómo usar

### Enviar un mensaje

```bash
cd /opt/rifaloop
source /ruta/a/tu/venv/bin/activate  # si usas venv

python3 tg_send_persist.py <numero> "mensaje"
```

Ejemplos:

```bash
python3 tg_send_persist.py 573006284920 "Hola, buen día!"
python3 tg_send_persist.py 573208923626 "Te invito a participar en RifaLoop"
```

### Primera vez (sesión nueva)

Si el archivo `.session` no existe, el script mostrará un QR en la terminal. **Escanea con Telegram: Ajustes > Dispositivos > Vincular Dispositivo**. Una vez escaneado, la sesión queda guardada y no vuelve a pedir QR.

### La sesión expiró

Si el QR aparece de nuevo, simplemente escanea otra vez.

## Cómo funciona

- **Telethon** conecta vía MTProto (protocolo nativo de Telegram), no via Bot API.
- La sesión se guarda en un archivo SQLite (`.session`) en el servidor.
- El script `tg_send_persist.py` verifica si hay sesión válida al iniciar; si no, pide QR.
- **Importante:** No se debe llamar `client.disconnect()` para que la sesión persista entre ejecuciones.

## Riesgos y límites

- **Telegram puede banear la cuenta** si detecta automatización no oficial. Es el mismo riesgo que con WhatsApp + Evolution API.
- Para minimizar riesgos:
  - No enviar más de ~30-50 mensajes/día desde la cuenta.
  - Espaciar los envíos (varios minutos entre cada uno).
  - No enviar a números que puedan reportarte como spam.
  - Usar la cuenta con moderación también para uso normal (chats, grupos).
- No hay servicio pago de Telegram para automatizar cuentas de usuario. Solo existe la Bot API (gratuita, pero limitada a quien inicia conversación).

## Alternativa sin riesgo

**Usar el Bot de RifaLoop** (API oficial de bots) para enviar mensajes solo a usuarios registrados (los que ya iniciaron el bot). Cero riesgo de ban. Los telegram_id de usuarios registrados están en la DB (`users.telegram_id`).

## Scripts útiles

### Verificar sesión

```python
python3 -c "
import asyncio
from telethon import TelegramClient
c = TelegramClient('/opt/rifaloop/algarher_session.session', API_ID, API_HASH)
async def t():
    await c.connect()
    me = await c.get_me()
    print('Sesion activa:', me.first_name if me else 'NO')
    await c.disconnect()
asyncio.run(t())
"
```

### Enviar desde código Python

```python
from telethon import TelegramClient
import asyncio

API_ID = 38349422
API_HASH = "3ba5c3ce7eba516450e05912ecf099df"

async def send(numero, mensaje):
    client = TelegramClient("/opt/rifaloop/algarher_session.session", API_ID, API_HASH)
    await client.connect()
    if await client.is_user_authorized():
        await client.send_message("+" + numero, mensaje)
        print("OK", numero)
    await client.disconnect()

asyncio.run(send("573006284920", "Hola!"))
```

## API_ID y API_HASH

- **API_ID:** 38349422
- **API_HASH:** 3ba5c3ce7eba516450e05912ecf099df
- Obtenidos de https://my.telegram.org (cuenta de Alex Garrido).
