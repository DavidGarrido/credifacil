# Plan de Implementación: Documentación de Tenants (Aliados)

## Objetivo
Implementar un sistema para almacenar y gestionar la documentación requerida de cada tenant (aliado comercial) durante el proceso de registro y configuración.

## Información y Documentos Requeridos

### Información Básica
- Nombre comercial
- Canal para usar Credifácil: tienda física, e-commerce, redes sociales (multicheck) - extensible
- Plan de pagos: 7 días 9%, 30 días 6.5%, 60 días 5.5% (mismo que configuración existente)

### Información de Facturación
- Tipo: Natural o Jurídica
- Nombre del dueño/comercio
- NIT
- Dígito de verificación
- Celular
- Email de facturación electrónica

### Dirección
- Dirección de la tienda (apto, local, etc.)
- Departamento
- Ciudad

### Información Bancaria
- Banco
- Tipo de cuenta
- Número de cuenta

### Representante Legal
- Tipo de identificación (CC)
- Número de identificación
- ¿Más del 5% de la empresa?

### Documentos
- Cámara de Comercio (inferior a 60 días)
- RUT
- Certificado Bancario (inferior a 180 días)
- Fotocopia cédula representante legal (ambos lados, PDF)

## Opciones de Almacenamiento

### Opción 1: Archivo JSON por Tenant
**Descripción:** Cada tenant tiene un archivo JSON dedicado que contiene toda su información y documentación.

**Ventajas:**
- ✅ Simplicidad de implementación inicial
- ✅ Fácil de versionar con Git
- ✅ No requiere cambios en la base de datos
- ✅ Lectura/escritura rápida para datos estructurados
- ✅ Portabilidad - fácil de migrar o respaldar
- ✅ Ideal para configuraciones estáticas que cambian raramente

**Desventajas:**
- ❌ No escalable para búsquedas complejas o consultas frecuentes
- ❌ Dificulta la auditoría y el historial de cambios
- ❌ Riesgo de corrupción de archivos
- ❌ No soporta transacciones ACID
- ❌ Difícil de integrar con sistemas externos que requieren SQL
- ❌ Problemas de concurrencia si múltiples procesos escriben simultáneamente
- ❌ Pérdida de información al eliminar tenant

### Opción 2: Tabla de Empresa en Base de Datos del Tenant
**Descripción:** Crear una tabla `company_info` en cada base de datos de tenant con un solo registro que contenga la información de la empresa y referencias a documentos.

**Ventajas:**
- ✅ Alto rendimiento para consultas y búsquedas
- ✅ Soporte completo para transacciones ACID
- ✅ Fácil auditoría y historial de cambios
- ✅ Integración nativa con el resto del sistema
- ✅ Soporte para concurrencia y bloqueos
- ✅ Escalabilidad para consultas complejas
- ✅ Fácil backup y restauración con herramientas de BD

**Desventajas:**
- ❌ Mayor complejidad de implementación
- ❌ Requiere migraciones de base de datos
- ❌ Dependencia de la estructura de BD
- ❌ Más overhead para datos que cambian raramente
- ❌ Necesidad de gestionar esquemas en múltiples tenants
- ❌ **Pérdida de información al eliminar tenant** - riesgo crítico

### Opción 3: Tabla Central en Base de Datos de Landlord (Recomendada)
**Descripción:** Crear una tabla `tenant_company_info` en la base de datos central de landlord que almacene la información de empresa y documentación de todos los tenants.

**Ventajas:**
- ✅ Preserva información incluso si se elimina un tenant
- ✅ Centralización de datos para gestión administrativa
- ✅ Alto rendimiento para consultas y búsquedas
- ✅ Soporte completo para transacciones ACID
- ✅ Fácil auditoría y historial de cambios
- ✅ Integración con sistema de gestión de aliados
- ✅ Soporte para concurrencia y bloqueos
- ✅ Escalabilidad para consultas complejas
- ✅ Fácil backup y restauración centralizada

**Desventajas:**
- ❌ Mayor complejidad de implementación inicial
- ❌ Requiere migraciones en BD central
- ❌ Dependencia de estructura de BD central
- ❌ Necesidad de gestionar acceso multi-tenant

## Recomendación
**Usar Opción 3 (Tabla Central en Landlord)** para la información de empresa y documentos, ya que:

1. Preserva la información crítica incluso si se elimina un tenant
2. Centraliza la gestión administrativa de aliados
3. La documentación empresarial requiere integridad y auditabilidad
4. Facilita consultas desde el sistema de gestión de aliados
5. Permite validaciones y relaciones con otras entidades
6. Es más robusto para un sistema multi-tenant con respaldo centralizado

## Arquitectura Propuesta

### Frontend (Registro de Tenant)
1. Mantener `TenantRegistration.jsx` sin cambios - registro básico
2. Crear nuevo módulo `CompanyDocumentation.jsx` para gestión de documentos
3. Agregar botón "Cargar Documentación" en sidebar si documentos están pendientes
4. Mostrar módulo "Info Empresa" en sidebar si documentos están completos
5. Implementar flujo interactivo paso a paso para subida de documentos
6. Actualizar `api.js` para endpoints de gestión de documentos

### Backend (Landlord)
1. Modificar endpoint `/api/tenants/register` para crear registro básico en `tenant_company_info` (sin archivos)
2. Crear configuración inicial de cobranza en `ally_collection_configs` con permisos de venta y recaudo **desactivados**
3. Crear endpoint `/api/tenants/{tenantId}/documents` para subida de documentos por tenants
4. Validar y procesar documentos subidos, crear registros en `tenant_documents`
5. Crear endpoints para gestión administrativa de documentos (aprobar, rechazar, descargar)
6. Crear endpoint `/api/tenants/{tenantId}/permissions` para consulta de permisos
7. Implementar lógica para activar permisos cuando documentos estén aprobados

### Base de Datos
```sql
-- En base de datos central de landlord
CREATE TABLE tenant_company_info (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id VARCHAR(50) NOT NULL,

    -- Información básica
    commercial_name VARCHAR(255) NOT NULL,
    credifacil_channel ENUM('tienda_fisica', 'ecommerce', 'redes_sociales', 'otro') NOT NULL,
    payment_plan VARCHAR(100) DEFAULT '7_dias_9%,30_dias_6.5%,60_dias_5.5%',

    -- Facturación
    billing_type ENUM('natural', 'juridica') NOT NULL,
    owner_name VARCHAR(255) NOT NULL,
    nit VARCHAR(50) NOT NULL,
    nit_verification_digit VARCHAR(5),
    billing_phone VARCHAR(50) NOT NULL,
    billing_email VARCHAR(255) NOT NULL,

    -- Dirección
    store_address TEXT NOT NULL,
    department VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,

    -- Información bancaria
    bank_name VARCHAR(255) NOT NULL,
    account_type ENUM('ahorros', 'corriente') NOT NULL,
    account_number VARCHAR(50) NOT NULL,

    -- Representante legal
    legal_rep_id_type VARCHAR(10) DEFAULT 'CC',
    legal_rep_id_number VARCHAR(50) NOT NULL,
    legal_rep_owns_more_than_5_percent BOOLEAN DEFAULT FALSE,

    -- Estado y administración
    documents_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    admin_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY unique_tenant (tenant_id),
    INDEX idx_status (documents_status),
    INDEX idx_created_at (created_at),
    INDEX idx_channel (credifacil_channel),
    INDEX idx_department_city (department, city)
);

CREATE TABLE tenant_documents (
    id INT PRIMARY KEY AUTO_INCREMENT,
    tenant_id VARCHAR(50) NOT NULL,
    document_type ENUM('camara_comercio', 'rut', 'certificado_bancario', 'cedula_representante') NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    mime_type VARCHAR(100),
    file_size INT,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    status_reason TEXT,
    expiry_date DATE,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP NULL,
    reviewed_by INT,
    FOREIGN KEY (tenant_id) REFERENCES tenant_company_info(tenant_id) ON DELETE CASCADE,
    INDEX idx_tenant_status (tenant_id, status),
    INDEX idx_expiry (expiry_date),
    INDEX idx_type (document_type)
);
```

### Gestión de Archivos
- Estructura organizada de directorios:
  ```
  storage/app/landlord/tenant_documents/
  ├── {tenant_id}/
  │   ├── info/                          # Información básica y formularios
  │   ├── documents/                     # Documentos oficiales
  │   │   ├── camara_comercio/
  │   │   ├── rut/
  │   │   ├── certificado_bancario/
  │   │   └── cedula_representante/
  │   └── temp/                          # Archivos temporales durante subida
  └── archives/                          # Documentos archivados por fecha
      └── YYYY-MM/
  ```
- Nombres de archivo: Renombrar archivos subidos con nombres descriptivos:
  - `camara_comercio_{tenant_id}_{fecha_subida}.{extension}`
  - `rut_{tenant_id}_{fecha_subida}.{extension}`
  - `certificado_bancario_{tenant_id}_{fecha_subida}.{extension}`
  - `cedula_representante_{tenant_id}_{fecha_subida}.{extension}`
  - No usar el nombre original del archivo del cliente
- Validaciones: tamaño máximo 5MB, tipos permitidos PDF/JPG/PNG
- Validaciones específicas por documento:
  - Cámara de Comercio: expiry_date <= 60 días desde hoy
  - Certificado Bancario: expiry_date <= 180 días desde hoy
  - RUT y Cédula: sin fecha de caducidad específica
- Limpieza automática de directorio temp después de 24 horas
- Acceso controlado por middleware de autenticación

## Implementación por Fases

### Fase 1: Infraestructura
- [ ] Crear tabla `tenant_company_info` en base de datos central de landlord
- [ ] Crear tabla `tenant_documents` en base de datos central de landlord
- [ ] Configurar estructura de directorios organizada para documentos de tenants
- [ ] Crear migración para migrar datos existentes si los hay
- [ ] Implementar comandos de mantenimiento para limpieza de archivos temporales

### Fase 2: Backend
- [ ] Modificar/crear controlador `TenantController` y `TenantDocumentController`
- [ ] Implementar validaciones de archivos y gestión de tabla `tenant_documents`
- [ ] Crear servicios de procesamiento y almacenamiento de documentos
- [ ] Actualizar endpoint de registro con creación de registros en ambas tablas y configuración inicial (ventas y recaudo desactivados)
- [ ] Implementar endpoints para aprobar/rechazar documentos y actualizar estados
- [ ] Crear endpoint /api/tenants/{tenantId}/permissions para consulta de permisos
- [ ] Implementar lógica para activar permisos cuando todos los documentos estén aprobados

### Fase 3: Frontend
- [ ] Crear módulo `CompanyDocumentation.jsx` para gestión de documentos
- [ ] Agregar botón dinámico en sidebar: "Cargar Documentación" si pendiente, "Info Empresa" si completo
- [ ] Implementar flujo interactivo paso a paso para recopilar información y subir documentos
- [ ] Incluir vista de resumen con toda la información antes del envío
- [ ] Botón "Enviar" para submit final de la documentación
- [ ] Actualizar api.js con endpoints para gestión de documentos
- [ ] Implementar verificación de permisos en tenant frontend (purchase y payments)
- [ ] Bloquear acceso a /dashboard/purchase si sales_enabled = false
- [ ] Bloquear acceso a /dashboard/payments si payments_enabled = false
- [ ] Mostrar mensajes informativos cuando permisos estén desactivados

### Fase 4: Gestión
- [ ] Actualizar vista `AllyDetails` (http://localhost:8020/allies/{tenantId}/details) para mostrar datos completos del aliado desde `tenant_company_info`
- [ ] Crear tabla de documentos en `AllyDetails` con campos: nombre archivo, tipo, estado, motivo estado, fecha caducidad
- [ ] Implementar acciones de aprobar/rechazar documentos individuales con motivos en la vista
- [ ] Implementar descarga de documentos desde landlord en la vista
- [ ] Al aprobar todos los documentos requeridos, activar automáticamente permisos de venta y recaudo
- [ ] Notificaciones a tenants sobre cambios en estado de documentos
- [ ] Dashboard administrativo para gestión completa de aliados y documentación

## Consideraciones de Seguridad
- Validar tipos MIME del lado servidor
- Escanear archivos en busca de malware
- Control de acceso basado en roles
- Encriptación de documentos sensibles
- Logs de auditoría para accesos

## Testing
- Pruebas de subida de archivos grandes
- Validación de tipos de archivo
- Concurrencia en registro de tenants
- Integración con sistema de gestión de aliados