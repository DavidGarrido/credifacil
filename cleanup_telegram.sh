#!/bin/bash

echo "Limpiando verificaciones de Telegram y datos de teléfono de los clientes..."

docker exec landlord-creditapi-laravel.test-1 php artisan tinker --execute="
    App\Models\VerificationCode::where('type', 'telegram')->delete();
    App\Models\Client::query()->update([
        'phone_verified_at' => null,
        'telegram_chat_id' => null,
        'telegram_username' => null
    ]);
    echo 'OK';
"

if [ $? -eq 0 ]; then
    echo "------------------------------------------------------------"
    echo "ÉXITO: Limpieza completada correctamente."
    echo "------------------------------------------------------------"
else
    echo "Error al ejecutar la limpieza."
    exit 1
fi
