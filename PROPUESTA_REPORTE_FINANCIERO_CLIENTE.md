# Propuesta: Panel de Reportes Financieros — CrediFácil

## ¿Qué problema resuelve?

Hoy el administrador de CrediFácil no tiene una forma clara de saber:

- Si el negocio está generando ganancias o pérdidas
- Cuánto capital tiene disponible para seguir aprobando créditos
- Cuánto han vendido y recaudado los comercios aliados cada mes
- Si tiene liquidez suficiente para los próximos meses

Este panel resuelve eso en una sola pantalla.

---

## ¿Qué va a mostrar el panel?

### 1. Resumen de capital

Una vista clara del dinero del negocio:

| Concepto | Descripción |
|----------|-------------|
| **Capital total** | El dinero con el que opera CrediFácil |
| **Capital prestado** | Lo que está actualmente en manos de los clientes |
| **Capital reservado** | Lo que los clientes aún pueden gastar (debe estar siempre disponible en caja) |
| **Capital libre** | Lo que puede prestarse a nuevos clientes hoy |

> Ejemplo: Si CrediFácil tiene $20,000,000 de capital, tiene $8,200,000 comprometidos en créditos activos y $2,120,000 reservados para cupos disponibles, entonces solo puede aprobar créditos nuevos por hasta $11,800,000.

---

### 2. Estado mes a mes por comercio aliado

Por cada comercio, el panel muestra el **resumen del mes en curso**:

| Concepto | Descripción |
|----------|-------------|
| **Ventas generadas** | Total de compras aprobadas con crédito CrediFácil en el mes |
| **Recaudo del mes** | Total de cuotas pagadas por los clientes al comercio en el mes |
| **Cruce de cuentas** | Diferencia entre ventas y recaudo |

**¿Cómo funciona el cruce?**

- Si el recaudo es **menor** que las ventas → el comercio **le debe** esa diferencia a CrediFácil
- Si el recaudo es **mayor** que las ventas → CrediFácil **le debe** esa diferencia al comercio

> Esto se resetea cada mes. El historial de meses anteriores queda guardado para consulta.

---

### 3. Proyección de flujo de caja

El panel permite seleccionar un horizonte de tiempo (1, 3, 6 o 12 meses) y muestra:

| Concepto | Descripción |
|----------|-------------|
| **Cuánto voy a cobrar** | Suma de cuotas programadas que vencen en ese período |
| **Cuánto voy a pagar** | Pagos programados a los comercios en ese período |
| **Flujo neto** | Si el negocio tendrá o no dinero suficiente en ese período |

Esto permite anticipar si se necesita más capital antes de quedarse corto.

---

### 4. Alerta de cuotas máximas

El panel calcula automáticamente:

> *"Con el capital disponible actual, el máximo de cuotas que puedes ofrecer sin riesgo de quedarte sin liquidez es de X meses."*

Si se aprueba un crédito con más cuotas de las recomendadas, el sistema muestra una advertencia.

---

### 5. Estados financieros del negocio

Un resumen ejecutivo mensual con:

| Indicador | Descripción |
|-----------|-------------|
| **Capital vigente** | Lo que está activo en créditos |
| **Intereses generados** | Ganancia real del período |
| **Utilidad neta** | Ingresos menos gastos operativos |
| **Rentabilidad** | % de retorno sobre el capital invertido |

---

### 6. Simulador de riesgo

Permite evaluar, antes de aprobar un crédito, cuánto capital queda expuesto si ese cliente no paga.

---

## ¿Cómo funciona el sistema por detrás?

El panel **no hace consultas lentas** cada vez que se abre. En cambio:

- Los datos se actualizan automáticamente cada vez que ocurre algo (una venta, un pago de cuota, un pago de comercio)
- El panel carga instantáneamente porque lee datos ya calculados
- Una vez al día, en la madrugada, el sistema verifica y actualiza todo de forma completa

Esto garantiza que el panel sea siempre rápido y confiable.

---

## ¿Qué necesita el cliente configurar?

Solo un dato inicial:

> **Capital inicial de operación**: el monto con el que CrediFácil arranca a operar. A partir de ahí, el sistema calcula todo automáticamente.

Opcionalmente:
- **Porcentaje de reserva mínima**: % del capital que no se presta (colchón de seguridad). Por defecto: 20%.

---

## Pantallas que se van a crear o modificar

| Pantalla | Cambio |
|----------|--------|
| **Dashboard (inicio)** | Se reemplaza la pantalla en blanco por el panel financiero completo |
| **Detalle por aliado** | Se agrega la vista mensual de ventas vs recaudo y cruce de cuentas |
| **Configuración** | Nueva pantalla para ingresar capital inicial y reserva mínima |

---

## Lo que NO hace este panel

- No reemplaza la contabilidad formal del negocio
- No conecta con sistemas bancarios externos
- No genera documentos fiscales ni declaraciones de impuestos

---

## Resumen ejecutivo

Con este panel, el administrador de CrediFácil podrá responder en segundos:

✅ ¿Cuánto dinero tengo para prestar hoy?
✅ ¿Qué comercio me debe plata este mes?
✅ ¿Voy a tener liquidez en los próximos 3 meses?
✅ ¿Cuántas cuotas puedo ofrecer sin arriesgar el capital?
✅ ¿El negocio está siendo rentable?
