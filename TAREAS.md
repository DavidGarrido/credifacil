# Tareas Pendientes - Credifacil

Fuente: Notion - "Tareas Credifacil" (actualizado 2026-03-02)

## Prioridad Alta

### 1. Implementar sistema de niveles para clientes
- **Categoria:** Nuevo Feature
- **Estado:** Pendiente
- Crear un sistema de niveles (ej: Bronce, Plata, Oro, Platino) para segmentar clientes según comportamiento de pago, antigüedad, monto de crédito, etc.
- **Componentes:**
  - Migración: tabla `client_levels` (config de niveles: nombre, color, icono, requisitos) + columna `level_id`/`current_level` en `clients`
  - Backend (landlord): CRUD de niveles, endpoint para consultar nivel del cliente, lógica de ascenso/descenso automático basado en reglas
  - Backend (tenant): proxy para consultar nivel del cliente, aplicar tasas/beneficios según nivel
  - Frontend (Ionic): mostrar nivel del cliente (badge, tarjeta) en dashboard, perfil y detalle de crédito
  - Frontend (React admin): visualización de nivel en listado de clientes, edición manual de nivel
- **Reglas sugeridas:**
  - Puntualidad en pagos (% de cuotas pagadas a tiempo)
  - Antigüedad como cliente
  - Monto total de créditos otorgados
  - Historial de morosidad

### 2. Solucionar error en el boton de pago en cobranza de aliados
- **Categoria:** Correcciones Tecnicas
- **Estado:** Pendiente
- El boton de pago en el modulo de cobranza de aliados no funciona correctamente.

### 2. Ajustar el descuento en el cruce de cuentas (% + 19% IVA)
- **Categoria:** Cruce de Cuentas
- **Estado:** Pendiente
- El calculo del descuento en cruce de cuentas debe incluir el porcentaje mas el 19% de IVA.

## Prioridad Media

### 3. No cobrar intereses durante los primeros 5 dias del periodo anterior
- **Categoria:** Intereses y Cobros
- **Estado:** Pendiente
- Durante los primeros 5 dias del periodo anterior no se deben generar intereses.

### 4. Mostrar los abonos realizados por el aliado en el desglose de movimientos de credito
- **Categoria:** Desglose de Movimientos
- **Estado:** Pendiente
- En el detalle de movimientos de un credito deben verse los abonos hechos por el aliado.
