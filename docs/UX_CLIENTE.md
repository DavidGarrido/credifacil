# Experiencia de Usuario — Portal del Cliente (Deudor)

## 1. Principios de Diseño

- **Sin fricción**: Mínimos pasos para pagar. El cliente viene a pagar, no a navegar.
- **Mobile-first**: La mayoría accede desde celular. Diseño pensado para pulgar.
- **Sin contraseñas**: Autenticación con documento + teléfono + código SMS.
- **Progreso visible**: El cliente siempre sabe cuánto debe, cuánto pagó, y qué sigue.
- **Idioma**: Español 100%. Moneda COP. Fechas en formato colombiano (dd/mm/aaaa).

---

## 2. Mapa de Navegación

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         SPLASH                                           │
│                  Logo Credifácil + loading                               │
│            ¿Token válido? ──Sí──→ Dashboard                              │
│                  │ No                                                    │
│                  ▼                                                       │
│               LOGIN                                                      │
│         Documento + Teléfono                                             │
│                  │                                                       │
│          ┌───────┴──────────┐                                            │
│          ▼                  ▼                                            │
│   ¿Tiene Telegram?   NO → QR + Deep Link                                │
│          │                  │                                            │
│         SÍ                 ▼                                             │
│          │         Abre Telegram Bot                                     │
│          │         @credifacilcolombia_bot                               │
│          │         (vincula chat_id + código)                            │
│          │                  │                                            │
│          ▼                  │                                            │
│   VERIFICAR CÓDIGO ◄───────┘                                            │
│   (código llegó por Telegram)                                            │
│                  │                                                       │
│          ┌───────┴───────┐                                               │
│          ▼               ▼                                               │
│     DASHBOARD        (error → reintentar)                               │
│          │                                                               │
│     ┌────┼────────┬──────────┬───────────┐                               │
│     ▼    ▼        ▼          ▼           ▼                               │
│  Crédito Pagos  Historial  Recibos   Perfil                              │
│  Detalle  WoMPI  Transac.   PDF      ┌────┐                             │
│     │     │        │         │       Datos│                              │
│     │     │        │         │     Soporte│                              │
│     │     │        │         │     Cerrar │                              │
│     │  Confirmación           │     Sesión│                              │
│     ▼  ───────────           ▼           └────┘                          │
│  Amortización  Éxito      Detalle                                        │
│  + Periodos    /Fallo     Transacción                                     │
│                                                                     │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Pantallas — Flujo Completo

---

### 3.1 Splash Screen

```
┌──────────────────────────────┐
│                              │
│                              │
│       [Logo Credifácil]      │
│                              │
│    ┌────────────────────┐    │
│    │                    │    │
│    │   Cargando...      │    │
│    │                    │    │
│    └────────────────────┘    │
│                              │
│   Verificando sesión...      │
│                              │
│   v1.0.0                     │
│                              │
└──────────────────────────────┘

Comportamiento:
- Busca token guardado en almacenamiento seguro
- Si hay token → valida contra /api/client/me
- Si token válido → Dashboard
- Si no hay token o expiró → Login
- Timeout: 3 segundos máx
```

---

### 3.2 Login

```
┌──────────────────────────────┐
│                              │
│       [Logo Credifácil]      │
│                              │
│   Tu portal de pagos         │
│   Consulta y paga tus        │
│   créditos fácil y rápido    │
│                              │
│   ┌──────────────────────┐   │
│   │ Número de documento  │   │
│   │ Ej: 1234567890       │   │
│   └──────────────────────┘   │
│                              │
│   ┌──────────────────────┐   │
│   │ Teléfono celular     │   │
│   │ Ej: 3001234567       │   │
│   └──────────────────────┘   │
│                              │
│   ┌──────────────────────┐   │
│   │   Enviar código      │   │
│   └──────────────────────┘   │
│                              │
│   💬 El código llega por     │
│   Telegram al número que     │
│   ya tienes vinculado        │
│                              │
│   ¿Problemas? Contáctanos    │
│                              │
└──────────────────────────────┘

Validaciones en tiempo real:
- Documento: solo números, 6-10 dígitos
- Teléfono: solo números, 10 dígitos
- Botón "Enviar código" se habilita cuando ambos son válidos

Estados:
- Success con Telegram vinculado → Transición a pantalla de verificación
- Success SIN Telegram vinculado → Muestra QR para vincular (ver abajo)

**Caso especial: Cliente sin Telegram (primer login)**

```
┌──────────────────────────────┐
│                              │
│   📲 Vincula tu Telegram     │
│                              │
│   Para recibir tu código     │
│   de verificación, escanea   │
│   este código QR con tu      │
│   celular:                   │
│                              │
│       ┌──────────────┐       │
│       │   [QR CODE]   │       │
│       │              │       │
│       └──────────────┘       │
│                              │
│   O abre el bot directo:     │
│   @credifacilcolombia_bot    │
│                              │
│   [Abrir Telegram]           │
│                              │
│   Después de vincular,       │
│   vuelve a esta pantalla     │
│   y presiona:                │
│                              │
│   [Ya vincule, verificar]    │
│                              │
│   ¿No tienes Telegram?       │
│   Descárgalo en              │
│   telegram.org               │
│                              │
└──────────────────────────────┘

El deep link del QR contiene el parámetro /start con los datos del cliente:
https://t.me/credifacilcolombia_bot?start=42-3001234567

Cuando el cliente abre el bot:
1. Bot saluda y vincula el chat_id al cliente
2. Bot envía automáticamente el código de verificación
3. Cliente vuelve a la app y toca "Ya vincule, verificar"
4. App llama al login otra vez → ahora tiene telegram_chat_id
5. Se envía el código sin QR de por medio
```

Estados:
- Error: "No encontramos un cliente con esos datos"
- Error: "Demasiados intentos. Espera 60 segundos"
- Success con Telegram: Transición a pantalla de código

Seguridad:
- Rate limit: 5 intentos por número por hora
- El QR expira a los 5 minutos (el deep link tiene validez)
- El chat_id se vincula automáticamente al número del cliente
```

---

### 3.3 Verificar Código

```
┌──────────────────────────────┐
│                              │
│   ← Atrás                    │
│                              │
│   [Icono Telegram]           │
│                              │
│   Ingresa el código          │
│   que enviamos por           │
│   Telegram al número         │
│   300****567                 │
│                              │
│   💬 Revisa tu Telegram      │
│   @credifacilcolombia_bot    │
│                              │
│   ┌───┐ ┌───┐ ┌───┐ ┌───┐  │
│   │ 8 │ │ 4 │ │ 7 │ │ 2 │  │
│   └───┘ └───┘ └───┘ └───┘  │
│                              │
│   Tiempo restante: 4:32     │
│                              │
│   ┌──────────────────────┐   │
│   │   Reenviar código    │   │
│   └──────────────────────┘   │
│   (habilitado en 4:32)       │
│                              │
│   [Abrir Telegram]           │
│                              │
└──────────────────────────────┘

UX:
- Los inputs son 4 campos individuales (código de 4 dígitos)
- Auto-foco: al escribir un dígito pasa al siguiente
- Botón "Abrir Telegram" → abre la app de Telegram directamente
- El botón "Reenviar" está deshabilitado con countdown 5 minutos
- Si expira el tiempo, muestra "Código expirado. Solicita uno nuevo."
- En el chat de Telegram el código llega así:

```
┌──────────────────────────────┐
│  Credifácil Bot              │
│                              │
│  🔐 Credifácil - Código de   │
│     Verificación             │
│                              │
│  Tu código de verificación   │
│  es: `8472`                  │
│                              │
│  ⏱️ Válido por 10 minutos    │
│  ⚠️ No compartas este        │
│     código con nadie         │
│                              │
└──────────────────────────────┘
```

Estados:
- Loading: "Verificando código..."
- Error: "Código inválido. Te quedan 2 intentos"
- Error: "Código expirado. Solicita uno nuevo"
- Success: Animación de transición al Dashboard

Seguridad:
- Máximo 3 intentos fallidos → bloquea 30 minutos
- Token de verificación expira en 5 minutos
- El código se envía SOLO al chat_id vinculado al cliente
```

---

### 3.4 Dashboard

```
┌──────────────────────────────┐
│  Hola, Juan 👋           🔔 │
│                              │
│  ┌──────────────────────────┐│
│  │  Tus Créditos            ││
│  │                          ││
│  │  ┌────────────────────┐  ││
│  │  │  Crédito Activo     │  ││
│  │  │  CRE-69A364A76A1D9  │  ││
│  │  │                     │  ││
│  │  │  $$$$$$$$$$░░░░░░   │  ││
│  │  │  ████████████░░░░   │  ││
│  │  │  $1.182.000         │  ││
│  │  │  $492.500 pagado    │  ││
│  │  │  42% completado     │  ││
│  │  │                     │  ││
│  │  │  Próximo pago:      │  ││
│  │  │  Jun 15, 2026       │  ││
│  │  │  $98.500            │  ││
│  │  │                     │  ││
│  │  │  [Pagar ahora]      │  ││
│  │  └────────────────────┘  ││
│  │                          ││
│  │  ┌────────────────────┐  ││
│  │  │  Crédito Pagado     │  ││
│  │  │  CRE-69A36A1E572E3  │  ││
│  │  │  ✓ Liquidado        │  ││
│  │  │  [Ver Paz y Salvo]  │  ││
│  │  └────────────────────┘  ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │  Resumen Rápido          ││
│  │                          ││
│  │  💰 Deuda total          ││
│  │     $689.500             ││
│  │                          ││
│  │  📅 Próximo vencimiento  ││
│  │     Jun 15, 2026         ││
│  │     (en 17 días)         ││
│  │                          ││
│  │  ✅ Pagos a tiempo       ││
│  │     5 de 5 (100%)        ││
│  └──────────────────────────┘│
│                              │
│  [Navegación inferior]       │
│  Inicio  Créditos  Pagos  ⚙️  │
└──────────────────────────────┘

Elementos clave:
- Tarjeta de crédito con barra de progreso visual
- Botón "Pagar ahora" siempre visible si hay cuotas pendientes
- Próximo pago destacado con fecha y monto
- Si hay cuotas vencidas: alerta roja "🔴 Tienes cuotas vencidas"
- Si el crédito está al día: badge verde "✅ Al día"
- Pull-to-refresh para actualizar datos

Estados vacíos:
- Sin créditos: "No tienes créditos registrados. Si crees que es un error, contáctanos."
- Todos pagados: "🎉 ¡Felicidades! Todos tus créditos están al día"
```

---

### 3.5 Detalle de Crédito

```
┌──────────────────────────────┐
│  ← Crédito                   │
│                              │
│  CRE-69A364A76A1D9           │
│                              │
│  ┌──────────────────────────┐│
│  │  Información General     ││
│  │                          ││
│  │  Monto:     $1.000.000   ││
│  │  Cuotas:   12 mensuales  ││
│  │  Interés:  3.5% mensual  ││
│  │  Inicio:   15 Ene 2026   ││
│  │  Fin:      15 Ene 2027   ││
│  │  Estado:   ✅ Activo      ││
│  │  Cupo disp: $658.122     ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │  Resumen de Pagos        ││
│  │                          ││
│  │  Pagadas:  5 de 12       ││
│  │  Pendientes: 6           ││
│  │  Vencidas:  1 🔴          ││
│  │  Total pagado: $492.500  ││
│  │  Total pendiente:$689.500││
│  │                          ││
│  │  ████████████░░░░░░░░░░  ││
│  │       42% completado     ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │  Cuotas del Mes          ││
│  │  Junio 2026              ││
│  │                          ││
│  │  ┌─────┬────────┬─────┐  ││
│  │  │ #6  │ Jun 15 │$98.5│  ││
│  │  │     │ Pend.  │     │  ││
│  │  └─────┴────────┴─────┘  ││
│  │                          ││
│  │  Ver calendario completo ││
│  │  [Ver amortización]      ││
│  └──────────────────────────┘│
│                              │
│  [Pagar cuotas pendientes]   │
│                              │
└──────────────────────────────┘

Acciones:
- Tap en cuota → opciones de pago
- "Ver amortización" → tabla completa
- "Pagar cuotas pendientes" → Payment Selection
- Si hay cuota vencida: alerta + opción "Pagar vencidas primero"

Nota: La cuota vencida se muestra al inicio de la lista con color rojo.
```

---

### 3.6 Tabla de Amortización

```
┌──────────────────────────────┐
│  ← Amortización              │
│                              │
│  CRE-69A364A76A1D9           │
│                              │
│  Resumen: Capital $1.000.000 │
│           Interés  $170.000  │
│           Seguro  $12.000    │
│           Total   $1.182.000 │
│                              │
│  ┌──────────────────────────┐│
│  │  #1  Ene 15   $98.500  ✅││
│  │     Capital  $80.000     ││
│  │     Interés  $17.000     ││
│  │     Seguro   $1.500      ││
│  │     Saldo:   $920.000    ││
│  ├──────────────────────────┤│
│  │  #2  Feb 15   $98.500  ✅││
│  │     Saldo:   $840.000    ││
│  ├──────────────────────────┤│
│  │  #3  Mar 15   $98.500  ✅││
│  ├──────────────────────────┤│
│  │  #6  Jun 15   $98.500  🔴││
│  │     VENCIDA (3 días)     ││
│  │     [Pagar ahora]        ││
│  ├──────────────────────────┤│
│  │  #7  Jul 15   $98.500  ⏳││
│  ├──────────────────────────┤│
│  │  #8  Ago 15   $98.500  ⏳││
│  └──────────────────────────┘│
│                              │
│  [Pagar todo lo pendiente]   │
│                              │
└──────────────────────────────┘

UX:
- Scroll vertical con todas las cuotas
- Cada cuota expandible: tap para ver detalle (capital, interés, seguro)
- Colores de status:
  - ✅ Pagada (verde)
  - 🔴 Vencida (rojo) con días de retraso
  - ⏳ Pendiente (gris/azul)
  - 🟡 Parcial (amarillo)
- Al final: totales acumulados
- Filtro: "Todas" | "Pendientes" | "Pagadas" | "Vencidas"
```

---

### 3.7 Selección de Pago

```
┌──────────────────────────────┐
│  ← Pagar                     │
│                              │
│  CRE-69A364A76A1D9           │
│                              │
│  Selecciona las cuotas       │
│  que deseas pagar:           │
│                              │
│  ☐ Cuota #6   Jun 15  $98.5K│
│    Vencida (3 días) 🔴       │
│                              │
│  ☐ Cuota #7   Jul 15  $98.5K│
│                              │
│  ☐ Cuota #8   Ago 15  $98.5K│
│                              │
│  ☐ Cuota #9   Sep 15  $98.5K│
│                              │
│  ☐ Cuota #10  Oct 15  $98.5K│
│                              │
│  ☐ Cuota #11  Nov 15  $98.5K│
│                              │
│  ☐ Cuota #12  Dic 15  $98.5K│
│                              │
│  ──────────────────────────  │
│  Seleccionadas: 2 cuotas     │
│  Total: $197.000             │
│                              │
│  [Pagar $197.000 con WoMPI]  │
│                              │
│  También puedes:             │
│  [Pagar todo] $689.500       │
│                              │
└──────────────────────────────┘

UX:
- Checkboxes para selección múltiple
- Tap en cuota → muestra detalle rápido en modal
- Las vencidas tienen indicador rojo
- Selector rápido: "Pagar vencidas" | "Pagar todo"
- El total se actualiza en tiempo real al seleccionar
- Botón de pago muestra el monto exacto
- Doble confirmación: "¿Estás seguro de pagar $197.000?"

Touch targets grandes para selección con el pulgar.
```

---

### 3.8 WebView WoMPI — Checkout

```
┌──────────────────────────────┐
│  ← Pago seguro               │
│                              │
│  ┌──────────────────────────┐│
│  │                          ││
│  │   [CHECKOUT WOMPI]       ││
│  │                          ││
│  │   Total: $197.000        ││
│  │                          ││
│  │   Opciones de pago:      ││
│  │   ┌──────────────────┐   ││
│  │   │ 💳 Tarjeta débito│   ││
│  │   ├──────────────────┤   ││
│  │   │ 💳 Tarjeta       │   ││
│  │   │    crédito       │   ││
│  │   ├──────────────────┤   ││
│  │   │ 🟣 Nequi         │   ││
│  │   ├──────────────────┤   ││
│  │   │ 🟡 Daviplata     │   ││
│  │   ├──────────────────┤   ││
│  │   │ 🏦 PSE           │   ││
│  │   └──────────────────┘   ││
│  │                          ││
│  │   [Continuar al pago]    ││
│  │                          ││
│  └──────────────────────────┘│
│                              │
│  Pago 100% seguro por WoMPI  │
│  No guardamos tus datos      │
│  bancarios                   │
│                              │
└──────────────────────────────┘

UX:
- WebView embebido dentro de la app
- Barra superior con título "Pago seguro" + botón cerrar
- NO se puede navegar hacia atrás fuera del checkout
- Al completar el pago:
  - WoMPI redirige a nuestra URL de callback
  - La app detecta la redirección
  - Inicia polling de confirmación
- Si el usuario cierra el WebView sin completar:
  - Modal: "¿Estás seguro? El pago no se ha completado"
  - Opciones: "Seguir pagando" | "Cancelar"
- Loading state mientras carga el checkout

Seguridad:
- El WebView NO ejecuta JavaScript del sitio padre
- Sin caché de credenciales
- Timeout: 15 minutos máx en el checkout
```

---

### 3.9 Confirmación de Pago

```
┌──────────────────────────────┐
│                              │
│                              │
│          🎉                  │
│                              │
│   ¡Pago exitoso!             │
│                              │
│   $197.000                   │
│   CRE-69A364A76A1D9          │
│   Cuotas pagadas: #6 y #7    │
│                              │
│   ┌──────────────────────┐   │
│   │  Fecha: Jun 15, 2026 │   │
│   │  Método: Tarjeta     │   │
│   │  Ref: WOMPI-XXXXXX   │   │
│   └──────────────────────┘   │
│                              │
│   ┌──────────────────────┐   │
│   │  Descargar recibo    │   │
│   └──────────────────────┘   │
│                              │
│   ┌──────────────────────┐   │
│   │  Ir al dashboard     │   │
│   └──────────────────────┘   │
│                              │
│   💡 Sabías que...           │
│   Puedes pagar varias cuotas │
│   a la vez para ahorrar      │
│   tiempo                     │
│                              │
└──────────────────────────────┘

Animación:
- Confetti o check animado al cargar
- La tarjeta de crédito en el dashboard se actualiza visualmente

Errores:
```
┌──────────────────────────────┐
│                              │
│          😕                  │
│                              │
│   Pago no completado         │
│                              │
│   El pago fue rechazado      │
│   o cancelado.               │
│                              │
│   Motivo: Tarjeta sin fondos │
│                              │
│   ┌──────────────────────┐   │
│   │  Intentar de nuevo   │   │
│   └──────────────────────┘   │
│                              │
│   ┌──────────────────────┐   │
│   │  Otro método de pago │   │
│   └──────────────────────┘   │
│                              │
│   ┌──────────────────────┐   │
│   │  Ir al dashboard     │   │
│   └──────────────────────┘   │
│                              │
│   ¿Problemas persistentes?   │
│   Contáctanos                 │
│                              │
└──────────────────────────────┘
```

---

### 3.10 Historial de Transacciones

```
┌──────────────────────────────┐
│  ← Historial                 │
│                              │
│  🔍 Buscar...               │
│                              │
│  [Todos ▼] [Fecha ▼]        │
│                              │
│  ┌──────────────────────────┐│
│  │  Hoy                     ││
│  ├──────────────────────────┤│
│  │💳 Pago       $197.000 ✅ ││
│  │  CRE-69A364A76A1D9      ││
│  │  10:30 AM  Ver recibo →  ││
│  ├──────────────────────────┤│
│  │  Jun 10, 2026            ││
│  ├──────────────────────────┤│
│  │💳 Pago       $98.500  ✅ ││
│  │  CRE-69A364A76A1D9      ││
│  │  Cuota #5    Ver recibo →││
│  ├──────────────────────────┤│
│  │  Ene 15, 2026            ││
│  ├──────────────────────────┤│
│  │🛒 Compra    $1.000.000✅ ││
│  │  Desembolso inicial      ││
│  │  Ver detalle →           ││
│  └──────────────────────────┘│
│                              │
│  Cargar más...              │
│                              │
└──────────────────────────────┘

UX:
- Agrupado por fecha (Hoy, Ayer, Esta semana, Fecha específica)
- Iconos por tipo: 🛒 Compra, 💳 Pago, ↩️ Reembolso
- Badge de estado: ✅ Aprobado, ⏳ Pendiente, ❌ Rechazado
- Swipe left en item → "Descargar recibo" (acción rápida)
- Tap en item → Detalle completo de la transacción
- Búsqueda por referencia o monto
- Filtro por tipo de transacción
- Pull-to-refresh

Detalle de transacción:
```
┌──────────────────────────────┐
│  ← Transacción               │
│                              │
│  💳 Pago                     │
│                              │
│  Estado: ✅ Aprobado         │
│  Monto:  $98.500             │
│  Fecha:  Jun 10, 2026        │
│  Métd:   Tarjeta débito      │
│  Ref:    WOMPI-A1B2C3        │
│                              │
│  Crédito: CRE-69A364A76A1D9  │
│  Cuota:  #5                  │
│  Periodo: Mayo 2026          │
│                              │
│  Saldo anterior: $787.500    │
│  Saldo actual:  $689.000     │
│                              │
│  ┌──────────────────────┐    │
│  │  Descargar recibo    │    │
│  └──────────────────────┘    │
│                              │
│  ┌──────────────────────┐    │
│  │  Compartir recibo    │    │
│  └──────────────────────┘    │
│                              │
└──────────────────────────────┘
```

---

### 3.11 Recibo PDF

```
┌──────────────────────────────┐
│  ← Recibo                    │
│                              │
│  ┌──────────────────────────┐│
│  │                          ││
│  │    [VISOR PDF NATIVO]    ││
│  │                          ││
│  │   CREDIFÁCIL SAS         ││
│  │   NIT 901.XXX.XXX- X     ││
│  │                          ││
│  │   RECIBO DE PAGO         ││
│  │   No. WOMPI-A1B2C3       ││
│  │                          ││
│  │   Cliente: Juan Pérez    ││
│  │   CC: 1234567890         ││
│  │                          ││
│  │   Crédito: CRE-XXXX      ││
│  │   Cuota: #5              ││
│  │   Fecha: Jun 10, 2026    ││
│  │                          ││
│  │   Capital:   $80.000     ││
│  │   Interés:   $17.000     ││
│  │   Seguro:    $1.500      ││
│  │   Total:     $98.500     ││
│  │                          ││
│  │   Método: WoMPI           ││
│  │   (Tarjeta débito)       ││
│  │                          ││
│  │   ───────────────        ││
│  │   Este es un comprobante ││
│  │   de pago válido         ││
│  │                          ││
│  │   [FIRMA DIGITAL]        ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────┐    │
│  │  Compartir           │    │
│  └──────────────────────┘    │
│                              │
│  ┌──────────────────────┐    │
│  │  Guardar en el       │    │
│  │  dispositivo         │    │
│  └──────────────────────┘    │
│                              │
└──────────────────────────────┘

UX:
- Visor PDF nativo con scroll y zoom por pellizco
- Botón "Compartir" → nativo de iOS/Android
- Botón "Guardar" → descarga al dispositivo
- En Web: descarga directa
- El PDF se genera en tenant-api (ya existe el endpoint)
```

---

### 3.12 Perfil

```
┌──────────────────────────────┐
│  ← Perfil                    │
│                              │
│  👤 Juan Pérez               │
│  CC 1234567890               │
│                              │
│  ┌──────────────────────────┐│
│  │  📱 300****567           │
│  │  📧 juan****@email.com   │
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │  🔔 Notificaciones     > ││
│  ├──────────────────────────┤│
│  │  📄 Mis documentos     > ││
│  ├──────────────────────────┤│
│  │  ❓ Ayuda / Soporte    > ││
│  ├──────────────────────────┤│
│  │  📋 Términos y        > ││
│  │     condiciones          ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │  Cerrar sesión           ││
│  └──────────────────────────┘│
│                              │
│  Versión 1.0.0               │
│                              │
└──────────────────────────────┘

Notificaciones:
```
┌──────────────────────────────┐
│  ← Notificaciones            │
│                              │
│  🔔 Recordatorios de pago   │
│  ┌────────────────────────┐  │
│  │ ●  Activar recordatorio│  │
│  │    de pago (3 días     │  │
│  │    antes del vencim.)  │  │
│  └────────────────────────┘  │
│                              │
│  Canal de notificación       │
│  ┌────────────────────────┐  │
│  │ ☑️ Push (app)          │  │
│  │ ☐ SMS                  │  │
│  │ ☐ Email                │  │
│  └────────────────────────┘  │
│                              │
│  Últimas notificaciones:     │
│  ┌────────────────────────┐  │
│  │ ✅ Pago recibido       │  │
│  │   $98.500 - CRE-XXX    │  │
│  │   Hoy 10:30 AM         │  │
│  ├────────────────────────┤  │
│  │ 🔴 Cuota #6 vencida    │  │
│  │   CRE-XXX - $98.500    │  │
│  │   Ayer                 │  │
│  └────────────────────────┘  │
│                              │
└──────────────────────────────┘
```

Soporte:
```
┌──────────────────────────────┐
│  ← Ayuda                      │
│                              │
│  📞 Línea de atención        │
│  01 8000 123 456             │
│                              │
│  💬 WhatsApp                 │
│  +57 300 123 4567            │
│                              │
│  📧 Email                    │
│  soporte@credifacil.com.co   │
│                              │
│  Preguntas frecuentes:       │
│                              │
│  ▶ ¿Cómo pago mis cuotas?   │
│  ▶ ¿Qué métodos de pago     │
│     tengo disponibles?       │
│  ▶ ¿Qué pasa si no pago     │
│     a tiempo?               │
│  ▶ ¿Cómo descargo mi Paz    │
│     y Salvo?                │
│  ▶ ¿Puedo pagar antes del   │
│     vencimiento?            │
│                              │
└──────────────────────────────┘
```

---

## 4. Notificaciones Push

### 4.1 Tipos de Notificación

| Tipo | Timing | Contenido |
|------|--------|-----------|
| Recordatorio pago | 3 días antes del vencimiento | "🔔 Tu cuota #6 vence el 15 Jun. Paga a tiempo" |
| Vencimiento hoy | El día del vencimiento | "⚠️ Hoy vence tu cuota #6 ($98.500)" |
| Mora | 1 día después de vencido | "🔴 Tienes una cuota vencida. Evita intereses" |
| Pago exitoso | Inmediato después del pago | "✅ Recibimos tu pago de $98.500" |
| Paz y Salvo | Cuando se liquida el crédito | "🎉 ¡Crédito CRE-XXX liquidado! Descarga tu Paz y Salvo" |
| Bienvenida | Primer login | "👋 Bienvenido a Credifácil. Aquí puedes gestionar tus pagos" |

### 4.2 Acciones desde Notificación

```dart
// Al tocar la notificación, la app navega a la pantalla correspondiente
onTapNotification(RemoteMessage message) {
  final type = message.data['type'];
  switch (type) {
    case 'payment_reminder':
    case 'overdue':
      router.go('/credits/${message.data['credit_id']}');
      break;
    case 'payment_success':
      router.go('/transactions/${message.data['transaction_id']}');
      break;
    case 'paz_y_salvo':
      router.go('/credits/${message.data['credit_id']}/paz-y-salvo');
      break;
    default:
      router.go('/dashboard');
  }
}
```

---

## 5. Estados de Carga y Transiciones

### 5.1 Loading States

```
┌──────────────────────────────┐
│  Cargando créditos...        │
│                              │
│  ┌────────────────────────┐  │
│  │  ░░░░░░░░░░░░░░░░░░░░  │  │  ← Shimmer animation
│  │  ░░░░░░░░░░            │  │
│  │  ░░░░░░░░░░░░░░░░░░░░  │  │
│  │  ░░░░░░                │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │  ░░░░░░░░░░░░░░░░░░░░  │  │
│  │  ░░░░░░░░░░            │  │
│  └────────────────────────┘  │
│                              │
└──────────────────────────────┘
```

### 5.2 Empty States

```
┌──────────────────────────────┐
│                              │
│          📭                  │
│                              │
│   No tienes créditos         │
│   activos                    │
│                              │
│   Si crees que esto es un    │
│   error, contáctanos         │
│                              │
│   [Contactar soporte]        │
│                              │
└──────────────────────────────┘
```

### 5.3 Error States

```
┌──────────────────────────────┐
│                              │
│          ⚠️                  │
│                              │
│   No pudimos cargar          │
│   tus créditos               │
│                              │
│   Revisa tu conexión a       │
│   internet e intenta de      │
│   nuevo                      │
│                              │
│   [Intentar de nuevo]        │
│                              │
└──────────────────────────────┘
```

### 5.4 Offline State

```
┌──────────────────────────────┐
│  ┌────────────────────────┐  │
│  │ 📡 Sin conexión        │  │
│  │ Los datos mostrados    │  │
│  │ pueden no estar        │  │
│  │ actualizados           │  │
│  └────────────────────────┘  │
│                              │
│  (Última actualización:      │
│   10:30 AM - cache local)    │
│                              │
└──────────────────────────────┘

Comportamiento offline:
- Muestra datos cacheados localmente
- Botón de pago deshabilitado ("Disponible cuando tengas conexión")
- Badge persistente "Sin conexión" en la barra superior
- Cuando vuelve la conexión, refresca automáticamente
```

---

## 6. Micro-interacciones

| Acción | Feedback |
|--------|----------|
| Tap en botón | Scale down 0.95 → bounce back |
| Pull-to-refresh | Indicador nativo + última actualización |
| Pago exitoso | Checkmark animado + confetti |
| Pago fallido | Shake en el botón + glow rojo |
| Login exitoso | Transición slide hacia la derecha |
| Seleccionar cuota | Checkmark con animación circular |
| Scroll en tabla | Sticky header con el mes |
| Cerrar sesión | Fade out + redirect a login |

---

## 7. Arquitectura de Pantallas (Widget Tree Flutter)

```
MaterialApp
└── GoRouter
    ├── SplashScreen
    ├── LoginScreen
    │   └── DocumentInput + PhoneInput + SubmitButton
    ├── VerifyScreen
    │   └── CodeInput (4 campos) + Timer + ResendButton
    ├── DashboardScreen
    │   ├── AppBar (Saludo + Notificaciones)
    │   ├── CreditCard (Barra progreso + Próximo pago + PayButton)
    │   ├── QuickSummary (Deuda + Próximo vencimiento + Pagos a tiempo)
    │   └── BottomNav (Inicio, Créditos, Pagos, Perfil)
    ├── CreditDetailScreen
    │   ├── InfoCard (Monto, Cuotas, Interés)
    │   ├── ProgressCard (Pagadas/Pendientes/Vencidas + Barra)
    │   └── PeriodList + AmortizationButton + PayButton
    ├── AmortizationScreen
    │   ├── SummaryHeader
    │   └── InstallmentList (expandible, filtrable)
    ├── PaymentSelectScreen
    │   ├── InstallmentChecklist
    │   ├── TotalDisplay
    │   └── PayButton (WoMPI)
    ├── WompiWebviewScreen
    │   └── WebView + LoadingOverlay + CloseConfirmDialog
    ├── PaymentResultScreen
    │   ├── SuccessAnimation / ErrorAnimation
    │   ├── TransactionInfo
    │   └── DownloadButton + DashboardButton
    ├── TransactionListScreen
    │   ├── SearchBar + Filters
    │   └── TransactionList (agrupado por fecha)
    ├── TransactionDetailScreen
    │   ├── StatusBadge + InfoCard
    │   └── DownloadButton + ShareButton
    ├── ReceiptScreen
    │   └── PDFViewer + ShareButton + SaveButton
    ├── ProfileScreen
    │   ├── UserInfo
    │   ├── MenuList (Notificaciones, Documentos, Soporte, Términos)
    │   └── LogoutButton
    ├── NotificationsScreen
    │   ├── ToggleChannels
    │   └── NotificationHistory
    └── SupportScreen
        ├── ContactInfo (Teléfono, WhatsApp, Email)
        └── FAQList
```

---

## 8. Flujo de Pago Completo (Paso a Paso)

```
1. Cliente recibe notificación push:
   "🔔 Tu cuota #6 vence el 15 Jun"

2. Tap en notificación → abre la app en Detalle del Crédito

3. Ve cuota #6 vencida (rojo) y cuotas #7-12 pendientes

4. Tap "Pagar cuotas pendientes"

5. Selecciona cuotas #6 y #7 (checkbox)
   → Total: $197.000

6. Tap "Pagar $197.000 con WoMPI"

7. Modal de confirmación:
   "¿Estás seguro de pagar $197.000 correspondiente a las cuotas #6 y #7?"

8. Tap "Sí, pagar"

9. Se abre WebView con checkout WoMPI
   - Elige "Tarjeta débito"
   - Ingresa datos de tarjeta
   - Tap "Pagar $197.000"

10. WoMPI procesa:

    10a. ✅ Éxito:
        - WebView cierra automáticamente
        - Pantalla de éxito con confetti
        - "¡Pago exitoso! $197.000 - Cuotas #6 y #7"
        - Opción: Descargar recibo
        - Opción: Ir al dashboard
        - Llega notificación push: "✅ Recibimos tu pago de $197.000"

    10b. ❌ Fallo:
        - WebView muestra error
        - "Pago no completado. Motivo: Fondos insuficientes"
        - Opción: Intentar de nuevo
        - Opción: Otro método de pago
        - Opción: Ir al dashboard

11. (Opcional) Tap "Descargar recibo" → visor PDF

12. En el dashboard, la tarjeta de crédito se actualiza:
    - Barra de progreso: 58% (antes 42%)
    - Próximo pago: Cuota #8 - Ago 15 - $98.500

Tiempo estimado total: 2-3 minutos
```

---

## 9. Copy y Microcopy

### 9.1 Botones

| Contexto | Texto |
|----------|-------|
| Login | "Enviar código" |
| Verificación | "Ingresa el código" |
| Reenviar código | "Reenviar código" |
| Dashboard - Pendiente | "Pagar ahora" |
| Dashboard - Sin cuotas | "Ver crédito" |
| Dashboard - Liquidado | "Ver Paz y Salvo" |
| Detalle crédito | "Pagar cuotas pendientes" |
| Amortización vencida | "Pagar ahora" |
| Amortización pagada | "Ver recibo" |
| Selección pago | "Pagar $XXX con WoMPI" |
| Selección pago (todo) | "Pagar todo" |
| Confirmación pago | "Sí, pagar" |
| Éxito | "Descargar recibo" |
| Éxito | "Ir al dashboard" |
| Error | "Intentar de nuevo" |
| Error | "Otro método de pago" |
| Recibo | "Compartir" |
| Recibo | "Guardar en dispositivo" |
| Perfil | "Cerrar sesión" |
| Offline | "Disponible cuando tengas conexión" |

### 9.2 Mensajes de Error

| Situación | Mensaje |
|-----------|---------|
| Documento inválido | "Ingresa un documento válido (6-10 dígitos)" |
| Teléfono inválido | "Ingresa un teléfono válido (10 dígitos)" |
| Credenciales incorrectas | "No encontramos un cliente con esos datos" |
| Código incorrecto | "Código inválido. Te quedan N intentos" |
| Código expirado | "Código expirado. Solicita uno nuevo" |
| Demasiados intentos | "Demasiados intentos. Espera 60 segundos" |
| Sin conexión | "Revisa tu conexión a internet e intenta de nuevo" |
| Error de servidor | "Algo salió mal. Intenta de nuevo en unos minutos" |
| Pago rechazado | "El pago fue rechazado por el banco. Intenta con otro método" |
| Crédito no encontrado | "No encontramos ese crédito. Si el problema persiste, contáctanos" |
| Sesión expirada | "Tu sesión expiró. Ingresa nuevamente" |

### 9.3 Estados Vacíos

| Pantalla | Mensaje |
|----------|---------|
| Dashboard sin créditos | "No tienes créditos registrados. Si crees que es un error, contáctanos" |
| Dashboard todo pagado | "🎉 ¡Felicidades! Todos tus créditos están al día" |
| Sin transacciones | "Aún no tienes movimientos" |
| Sin notificaciones | "No tienes notificaciones nuevas" |

---

## 10. Diseño Responsivo

### 10.1 Mobile (< 480px) — Primario
- Layout de 1 columna
- Bottom navigation
- Touch targets >= 48px
- Fuente: 14-16px base

### 10.2 Tablet (480-1024px)
- Layout de 2 columnas en dashboard
- Sidebar opcional
- Más espacio en tablas

### 10.3 Web/PWA (> 1024px)
- Layout adaptativo con sidebar
- Tablas más densas
- Split view en detalle de crédito
- Máximo ancho: 1200px centrado

---

## 11. Paleta de Colores

```dart
// Basado en tema matoxi existente
class AppColors {
  static const primary = Color(0xFF1A56DB);     // Azul corporativo
  static const primaryLight = Color(0xFF3B82F6);
  static const secondary = Color(0xFF10B981);   // Verde éxito
  static const danger = Color(0xFFEF4444);      // Rojo vencido/error
  static const warning = Color(0xFFF59E0B);     // Amarillo advertencia
  static const info = Color(0xFF3B82F6);       // Azul info
  static const success = Color(0xFF10B981);     // Verde pagado
  static const background = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
}
```

### Mapa de colores por estado

| Estado | Color | HEX |
|--------|-------|-----|
| Pagada / Al día | Verde éxito | `#10B981` |
| Pendiente | Azul info | `#3B82F6` |
| Vencida | Rojo peligro | `#EF4444` |
| Parcial | Amarillo advertencia | `#F59E0B` |
| Cancelado | Gris | `#9CA3AF` |
| Activo | Verde éxito | `#10B981` |
| Próximo pago | Azul primario | `#1A56DB` |

---

## 12. Animaciones y Transiciones

| Transición | Animación | Duración |
|------------|-----------|----------|
| Splash → Login | Fade in logo + slide up inputs | 400ms |
| Login → Verify | Slide left | 300ms |
| Verify → Dashboard | Scale + fade | 500ms |
| Dashboard → Detalle | Slide right | 300ms |
| Pago exitoso | Confetti + checkmark bounce | 800ms |
| Pago fallido | Shake | 300ms |
| Cerrar sesión | Fade out | 200ms |
| Pull-to-refresh | Native spinner | - |
| Error → retry | Pulsing retry button | 1s loop |
| Nuevo item en lista | Animated insert | 300ms |
