# Scripts de Mantenimiento - CrediFácil

Scripts para gestionar datos de prueba en el entorno de desarrollo.

## Scripts Disponibles

### 1. `backup-before-clean.sh` (Recomendado ejecutar primero)
Crea un backup completo de todos los datos antes de limpiar.

**Ubicación de backups:** `/home/garher/Documentos/credifacil/backups/`

**Uso:**
```bash
./backup-before-clean.sh
```

**Qué respalda:**
- **Landlord:** clients, credits, credit_transactions, client_documents, verification_codes, payment_links
- **Tenants:** credit_installments de todas las bases de datos de tenants

---

### 2. `clean-test-data.sh`
Limpia todos los datos de prueba del sistema.

**Uso:**
```bash
./clean-test-data.sh
```

**¡IMPORTANTE!** El script pedirá confirmación. Debes escribir **`SI`** (mayúsculas) para continuar.

**Qué elimina:**

**En LANDLORD:**
- Enlaces de pago (payment_links)
- Transacciones de crédito (credit_transactions)
- Créditos (credits)
- Documentos de clientes (client_documents)
- Códigos de verificación (verification_codes)
- Clientes (clients)

**En TODOS LOS TENANTS:**
- Cuotas de crédito (credit_installments)

**El script también:**
- Reinicia los AUTO_INCREMENT a 1
- Respeta las foreign keys (desactiva temporalmente las restricciones)
- Muestra estadísticas antes y después de la limpieza

---

## Flujo Recomendado

### Para limpiar datos de prueba de forma segura:

```bash
# 1. Hacer backup (opcional pero recomendado)
./backup-before-clean.sh

# 2. Limpiar datos
./clean-test-data.sh

# 3. Confirmar escribiendo: SI
```

---

## Ejemplo de Uso

```bash
garher@pc:~/Documentos/credifacil$ ./backup-before-clean.sh
========================================
  CrediFácil - Backup de Datos
========================================

Respaldando datos en: /home/garher/Documentos/credifacil/backups/20260114_172530

[1/2] Respaldando base de datos de LANDLORD...
✓ Backup de landlord completado
[2/2] Respaldando cuotas de tenants...
  Respaldando tenanttenant_69208a3194d34...
  Respaldando tenanttenant_692858bce7b16...
✓ Backup de tenants completado

========================================
  Backup Completado
========================================

Ubicación: /home/garher/Documentos/credifacil/backups/20260114_172530

Archivos creados:
  landlord_backup.sql (15K)
  tenant_tenanttenant_69208a3194d34_installments.sql (8.2K)
  tenant_tenanttenant_692858bce7b16_installments.sql (12K)

Ahora puedes ejecutar clean-test-data.sh de forma segura
```

```bash
garher@pc:~/Documentos/credifacil$ ./clean-test-data.sh
========================================
  CrediFácil - Limpieza de Datos
========================================

Verificando contenedores...
✓ Contenedores activos

⚠️  ADVERTENCIA ⚠️
Este script eliminará TODOS los siguientes datos:

  En LANDLORD:
    - Enlaces de pago (payment_links)
    - Transacciones de crédito (credit_transactions)
    - Créditos (credits)
    - Documentos de clientes (client_documents)
    - Códigos de verificación (verification_codes)
    - Clientes (clients)

  En TODOS LOS TENANTS:
    - Cuotas de crédito (credit_installments)

¿Estás seguro de continuar? (escribe 'SI' para confirmar): SI

Iniciando limpieza...

[1/3] Limpiando base de datos de LANDLORD...
✓ Eliminados 3 enlaces de pago
✓ Eliminadas 18 transacciones
✓ Eliminados 8 créditos
✓ Eliminados 12 documentos
✓ Eliminados 5 códigos de verificación
✓ Eliminados 7 clientes
LANDLORD limpiado exitosamente

[2/3] Obteniendo lista de bases de datos de tenants...
Encontradas 11 base(s) de datos de tenants

[3/3] Limpiando cuotas en cada tenant...
  [1/11] Limpiando tenanttenant_69208a3194d34...
    ✓ Eliminadas 21 cuotas
  [2/11] Limpiando tenanttenant_692858bce7b16...
    ✓ Eliminadas 31 cuotas
  ...

========================================
  Limpieza Completada Exitosamente
========================================

Estadísticas finales:

LANDLORD:
Tabla              Total
Clientes          0
Créditos          0
Transacciones     0
Documentos        0
Enlaces de pago   0

TENANTS:
  tenanttenant_69208a3194d34: 0 cuotas
  tenanttenant_692858bce7b16: 0 cuotas
  ...

✓ Todas las tablas han sido limpiadas
✓ Los AUTO_INCREMENT han sido reiniciados
✓ El sistema está listo para nuevas pruebas
```

---

## Notas Importantes

1. **Los scripts requieren que los contenedores Docker estén corriendo**
   - landlord-creditapi-mysql-1
   - tenant-api-mysql-1

2. **Password de MySQL:** Los scripts usan `password` como password de root
   - Si tu password es diferente, edita la variable `MYSQL_ROOT_PASSWORD` en los scripts

3. **Backups automáticos:** El script de limpieza NO hace backups automáticos
   - Siempre ejecuta `backup-before-clean.sh` primero si quieres guardar los datos

4. **Los backups NO se eliminan automáticamente**
   - Revisa periódicamente la carpeta `backups/` y elimina backups antiguos

5. **Restaurar desde backup:**
   ```bash
   # Para restaurar landlord
   docker exec -i landlord-creditapi-mysql-1 mysql -uroot -ppassword landlord_creditapi < backups/TIMESTAMP/landlord_backup.sql

   # Para restaurar un tenant específico
   docker exec -i tenant-api-mysql-1 mysql -uroot -ppassword DB_NAME < backups/TIMESTAMP/tenant_DB_NAME_installments.sql
   ```

---

## Solución de Problemas

### Error: "Contenedor no está corriendo"
```bash
# Verificar contenedores activos
docker ps

# Iniciar contenedores si están detenidos
cd landlord-creditapi && docker compose up -d
cd tenant-api && docker compose up -d
```

### Error: "Access denied for user 'root'"
- Verifica que el password en los scripts sea correcto
- Edita `MYSQL_ROOT_PASSWORD` en ambos scripts

### Los scripts no tienen permisos de ejecución
```bash
chmod +x backup-before-clean.sh
chmod +x clean-test-data.sh
```

---

## Contacto

Para reportar problemas o sugerencias, contacta al equipo de desarrollo.
