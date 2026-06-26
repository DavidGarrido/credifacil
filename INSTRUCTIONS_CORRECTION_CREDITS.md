# 🛠️ Procedimiento de Corrección Manual de Créditos en Producción

Este documento detalla los pasos para conectarse al servidor y corregir manualmente datos de créditos (ej. seguros mal calculados) tanto en el Landlord como en los Tenants.

---

## 1. Acceso al Servidor (Hostinger)

Para realizar cualquier cambio, primero debes conectarte al servidor principal vía SSH:

```bash
# Servidor Producción (Hostinger)
ssh root@187.124.232.145
```
*Nota: Asegúrate de tener tu llave pública autorizada o la llave `do_credifacil` configurada.*

---

## 2. Acceso a las Bases de Datos

El sistema corre sobre Docker. Para ejecutar SQL, debes entrar a los contenedores de base de datos.

### A. Base de Datos LANDLORD
Ubicación: `/opt/credifacil/landlord-creditapi`

```bash
cd /opt/credifacil/landlord-creditapi
docker compose exec mysql mysql -u landlord_user -pLandlordProd2026 landlord_creditapi
```

### B. Base de Datos TENANT
Ubicación: `/opt/credifacil/tenant-api-credifacil`

Para el tenant, primero identifica el nombre de la base de datos (ej: `tenanttenant_69dc307ae7cf1`):
```bash
cd /opt/credifacil/tenant-api-credifacil
# Entrar a MySQL general para ver bases de datos
docker compose exec mysql mysql -u root -pTenantProd2026 -e "SHOW DATABASES;"
# Entrar a la base de datos específica
docker compose exec mysql mysql -u root -pTenantProd2026 [NOMBRE_DB_TENANT]
```

---

## 3. Guía de Corrección: Seguros

### Paso 1: Corregir en el Landlord
Ajusta el porcentaje, el monto total del seguro y el total a pagar del crédito.

```sql
-- Reemplazar los valores en [ ]
UPDATE credits 
SET 
    insurance_percentage = 15.00, 
    insurance_amount = [MONTO_CORRECTO_TOTAL], 
    total_payable = amount + [MONTO_CORRECTO_TOTAL] + [INTERESES_TOTALES]
WHERE id = [ID_CREDITO];
```

### Paso 2: Corregir en el Tenant
Ajusta el valor del seguro en cada cuota y recalcula el total de la cuota.

```sql
-- Reemplazar los valores en [ ]
UPDATE credit_installments 
SET 
    insurance_amount = [NUEVO_SEGURO_POR_CUOTA], 
    total_amount = principal_amount + interest_amount + [NUEVO_SEGURO_POR_CUOTA]
WHERE landlord_credit_id = [ID_CREDITO_LANDLORD] 
  AND installment_number > 0;
```

---

## 4. Integridad de Datos: La "Cuota 0" (Metadata)

Si al intentar ver un crédito en el frontend recibes un **Error 500** en los endpoints `/periods` o `/payment-options`, es muy probable que falte el registro de control `installment_number = 0` en el Tenant.

Este registro es vital porque almacena en su columna `metadata` la configuración que el frontend necesita.

### Cómo verificar si falta:
```sql
SELECT id FROM credit_installments 
WHERE landlord_credit_id = [ID_CREDITO] AND installment_number = 0;
```

### Cómo restaurar la Cuota 0:
Si no existe, debes insertarla manualmente con el JSON de metadata correcto:

```sql
INSERT INTO credit_installments (
    landlord_credit_id, installment_number, principal_amount, 
    interest_amount, insurance_amount, total_amount, 
    remaining_amount, status, client_id, creator_id, metadata, 
    created_at, updated_at
) VALUES (
    [ID_CREDITO_LANDLORD], 
    0, 
    [MONTO_BASE], 
    0, 0, [MONTO_BASE], [MONTO_BASE], 
    'pendiente', [ID_CLIENTE], 1,
    '{"client_name": "NOMBRE", "client_identification": "123", "landlord_transaction_id": [ID_TRANSACCION], "credit_config": {"term": [PLAZO], "interest_rate": [TASA], "insurance_percentage": 15.0}, "created_automatically": true}',
    NOW(), NOW()
);
```

---

## 5. Finalización
Después de los cambios manuales, limpia la caché del Landlord para que los cambios se reflejen en el panel web:

```bash
cd /opt/credifacil/landlord-creditapi
docker compose exec laravel.test php artisan config:clear
docker compose exec laravel.test php artisan cache:clear
```

---

## ⚠️ Precauciones
- **NUNCA elimines el registro `installment_number = 0`**. Si vas a regenerar cuotas, borra solo las que sean `> 0`.
- Realiza un `SELECT` antes del `UPDATE` para confirmar que estás afectando al crédito correcto.
- Verifica siempre que el `landlord_transaction_id` en la metadata coincida con el ID de la transacción en el Landlord.
