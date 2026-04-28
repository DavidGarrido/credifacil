# 🎨 Guía de Estilos - Credifácil Colombia

Esta guía define los estilos visuales de la plataforma Credifácil, basados en un diseño limpio, moderno y profesional.

---

## 🎨 Paleta de Colores

### Colores Principales

```css
/* Verde Esmeralda (Principal) */
--emerald-50: #ecfdf5
--emerald-100: #d1fae5
--emerald-500: #10b981  /* Color principal de marca */
--emerald-600: #059669  /* Hover states */

/* Verde Turquesa (Secundario) */
--teal-400: #2dd4bf
--teal-500: #14b8a6

/* Azul Eléctrico (Acentos) */
--blue-600: #2563eb
--blue-700: #1d4ed8

/* Grises (Neutros) */
--gray-50: #f9fafb   /* Fondos suaves */
--gray-100: #f3f4f6  /* Fondos de tarjetas */
--gray-200: #e5e7eb  /* Bordes */
--gray-500: #6b7280  /* Texto secundario */
--gray-700: #374151  /* Texto principal */
--gray-800: #1f2937  /* Títulos */
--gray-900: #111827  /* Texto muy oscuro */

/* Estados */
--red-600: #dc2626   /* Errores, rechazos */
--amber-600: #d97706 /* Advertencias */
--green-600: #16a34a /* Éxito */
```

### Uso de Colores

| Elemento | Color | Uso |
|----------|-------|-----|
| **Botones principales** | `bg-emerald-500` | Acciones primarias (Aprobar, Guardar, Continuar) |
| **Botones secundarios** | `bg-gray-100` | Cancelar, Volver |
| **Headers/Encabezados** | `bg-gradient-to-r from-emerald-500 to-teal-400` | Headers de modales y secciones |
| **Iconos activos** | `text-emerald-600` | Iconos dentro de tarjetas |
| **Texto principal** | `text-gray-900` | Títulos y contenido importante |
| **Texto secundario** | `text-gray-500` | Labels, descripciones |
| **Fondos** | `bg-gray-50` | Fondos de página |
| **Tarjetas** | `bg-white` con `border-gray-100` | Contenedores de información |

---

## 📐 Espaciado y Tamaños

### Sistema de Espaciado

```javascript
// Padding interno de contenedores
px-6 py-5    // Contenedores principales
px-5 py-3    // Headers de secciones
px-4 py-3    // Elementos medianos
px-3 py-2    // Elementos pequeños

// Gaps entre elementos
gap-6        // Entre secciones grandes
gap-4        // Entre elementos medianos
gap-3        // Entre elementos pequeños
space-x-4    // Horizontal entre elementos relacionados
```

### Tamaños de Elementos

| Elemento | Clase | Tamaño |
|----------|-------|--------|
| **Iconos grandes** | `w-16 h-16` | Headers de modal |
| **Iconos medianos** | `w-12 h-12` | Tarjetas de documentos |
| **Iconos pequeños** | `w-5 h-5` | Dentro de botones |
| **Botones grandes** | `px-10 py-3.5` | Botones principales |
| **Botones medianos** | `px-6 py-2.5` | Botones secundarios |
| **Inputs** | `px-4 py-3` | Campos de formulario |

---

## 🔤 Tipografía

### Jerarquía de Texto

```html
<!-- Títulos de Modal/Página -->
<h1 class="text-2xl font-bold tracking-tight leading-tight text-gray-900">
    Título Principal
</h1>

<!-- Subtítulos -->
<p class="text-base font-medium text-emerald-50">
    Subtítulo o descripción
</p>

<!-- Headers de Sección -->
<h4 class="text-base font-bold text-gray-800">
    Información del Cliente
</h4>

<!-- Labels de Formulario -->
<label class="block text-sm font-semibold text-gray-700 mb-2">
    Campo de Formulario
</label>

<!-- Texto Normal -->
<p class="text-sm font-semibold text-gray-900">
    Contenido principal
</p>

<!-- Texto Secundario -->
<p class="text-xs text-gray-500">
    Información adicional
</p>
```

### Pesos de Fuente

- **font-bold**: Títulos principales
- **font-semibold**: Labels, botones, texto importante
- **font-medium**: Subtítulos, texto secundario
- **font-normal**: Texto regular (no se especifica)

---

## 🎯 Componentes Principales

### 1. Botones

#### Botón Principal (Verde)
```html
<button class="px-10 py-3.5 bg-emerald-500 text-white rounded-xl hover:bg-emerald-600 text-base font-semibold shadow-lg shadow-emerald-500/30 transition-all duration-200 hover:shadow-xl hover:shadow-emerald-500/40">
    Aprobar Crédito
</button>
```

#### Botón Secundario (Gris)
```html
<button class="px-8 py-3.5 bg-gray-100 text-gray-700 rounded-xl border border-gray-200 hover:bg-gray-200 text-base font-semibold transition-all duration-200">
    Cancelar
</button>
```

#### Botón de Acción (Verde Pequeño)
```html
<a href="#" class="inline-flex items-center px-6 py-2.5 bg-emerald-500 text-white text-sm font-bold rounded-xl hover:bg-emerald-600 transition-all duration-200 shadow-sm hover:shadow-md">
    <svg class="w-4 h-4 mr-2">...</svg>
    Ver
</a>
```

### 2. Inputs y Formularios

#### Input de Texto
```html
<input
    type="text"
    class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent text-base"
    placeholder="Ingrese el valor"
>
```

#### Input con Ícono (Moneda)
```html
<div class="relative">
    <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 text-base font-medium">$</span>
    <input
        type="number"
        class="w-full pl-8 pr-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent text-base font-semibold"
        placeholder="0.00"
    >
</div>
```

#### Select
```html
<select class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent text-base bg-white">
    <option value="mensual">Mensual</option>
    <option value="quincenal">Quincenal</option>
</select>
```

#### Label de Formulario
```html
<label class="block text-sm font-semibold text-gray-700 mb-2">
    Cupo a habilitar *
</label>
```

#### Mensaje de Error
```html
<p class="mt-1.5 text-xs text-red-600 font-medium">
    Este campo es requerido
</p>
```

### 3. Tarjetas y Contenedores

#### Tarjeta Principal (Sección)
```html
<div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
    <!-- Header de Sección -->
    <div class="bg-gray-50 px-5 py-3 border-b border-gray-200">
        <h4 class="text-base font-bold text-gray-800">Título de Sección</h4>
    </div>

    <!-- Contenido -->
    <div class="p-5">
        <!-- Contenido aquí -->
    </div>
</div>
```

#### Tarjeta de Información (Campo de Datos)
```html
<div class="bg-gray-50 rounded-xl p-4 border border-gray-100">
    <p class="text-xs text-gray-500 font-medium mb-1.5">Label</p>
    <p class="text-base font-bold text-gray-900">Valor</p>
</div>
```

#### Tarjeta de Documento/Elemento de Lista
```html
<div class="bg-gray-50 rounded-xl p-4 border border-gray-200 flex items-center justify-between hover:border-emerald-300 hover:bg-emerald-50/30 transition-all duration-200">
    <div class="flex items-center space-x-3 flex-1">
        <div class="w-12 h-12 bg-emerald-100 rounded-xl flex items-center justify-center flex-shrink-0">
            <svg class="w-6 h-6 text-emerald-600">...</svg>
        </div>
        <div class="flex-1">
            <p class="text-sm font-bold text-gray-900">Título</p>
            <p class="text-xs text-gray-500 mt-0.5">Subtítulo</p>
        </div>
    </div>
    <button class="ml-4 flex-shrink-0">Acción</button>
</div>
```

### 4. Modales

#### Estructura de Modal
```html
<!-- Overlay -->
<div class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-start justify-center z-50 p-2 overflow-y-auto" style="padding-top: 1rem; padding-bottom: 1rem;">

    <!-- Contenedor del Modal -->
    <div class="bg-white rounded-3xl shadow-2xl w-full max-w-4xl flex flex-col transform transition-all duration-300 scale-100 my-auto" style="max-height: calc(100vh - 2rem);">

        <!-- Header -->
        <div class="bg-gradient-to-r from-emerald-500 to-teal-400 px-8 py-6 text-white relative overflow-hidden flex-shrink-0 rounded-t-3xl">
            <div class="relative z-10 flex items-center justify-between">
                <div class="flex items-center space-x-4">
                    <div class="w-16 h-16 bg-white rounded-full flex items-center justify-center shadow-lg flex-shrink-0">
                        <svg class="w-9 h-9 text-emerald-500">...</svg>
                    </div>
                    <div>
                        <h3 class="text-2xl font-bold tracking-tight leading-tight">Título del Modal</h3>
                        <p class="text-emerald-50 text-base font-medium mt-1.5">Descripción</p>
                    </div>
                </div>
                <button class="text-white/90 hover:text-white transition-all duration-200 p-2.5 hover:bg-white/10 rounded-full flex-shrink-0">
                    <svg class="w-6 h-6">...</svg>
                </button>
            </div>
        </div>

        <!-- Contenido con Scroll -->
        <div class="flex-1 overflow-y-auto bg-gray-50" style="min-height: 0;">
            <div class="p-6 space-y-6">
                <!-- Contenido aquí -->
            </div>
        </div>

        <!-- Footer -->
        <div class="border-t border-gray-200 px-6 py-5 bg-white rounded-b-3xl flex-shrink-0">
            <div class="flex gap-4 justify-end items-center">
                <button class="px-8 py-3.5 bg-gray-100 text-gray-700 rounded-xl border border-gray-200 hover:bg-gray-200 text-base font-semibold transition-all duration-200">
                    Cancelar
                </button>
                <button class="px-10 py-3.5 bg-emerald-500 text-white rounded-xl hover:bg-emerald-600 text-base font-semibold shadow-lg shadow-emerald-500/30 transition-all duration-200 hover:shadow-xl hover:shadow-emerald-500/40">
                    Confirmar
                </button>
            </div>
        </div>

    </div>
</div>
```

### 5. Alertas e Información

#### Alerta Informativa (Verde)
```html
<div class="bg-emerald-50 border border-emerald-200 rounded-xl p-4">
    <div class="flex items-start space-x-3">
        <svg class="w-5 h-5 text-emerald-600 flex-shrink-0 mt-0.5">...</svg>
        <p class="text-sm text-emerald-800">
            Mensaje informativo aquí
        </p>
    </div>
</div>
```

#### Estado Vacío
```html
<div class="text-center py-8 bg-gray-50 rounded-xl border border-gray-200">
    <svg class="w-16 h-16 text-gray-300 mx-auto mb-3">...</svg>
    <p class="text-sm font-semibold text-gray-500">Título del estado vacío</p>
    <p class="text-xs text-gray-400 mt-1">Descripción adicional</p>
</div>
```

### 6. Iconos

#### Contenedor de Icono Grande (Circular)
```html
<div class="w-16 h-16 bg-white rounded-full flex items-center justify-center shadow-lg flex-shrink-0">
    <svg class="w-9 h-9 text-emerald-500">...</svg>
</div>
```

#### Contenedor de Icono Mediano (Redondeado)
```html
<div class="w-12 h-12 bg-emerald-100 rounded-xl flex items-center justify-center flex-shrink-0">
    <svg class="w-6 h-6 text-emerald-600">...</svg>
</div>
```

---

## 🎭 Efectos y Transiciones

### Bordes Redondeados

```css
rounded-xl    /* 0.75rem - Default para la mayoría de elementos */
rounded-2xl   /* 1rem - Tarjetas grandes */
rounded-3xl   /* 1.5rem - Modales y contenedores principales */
rounded-full  /* 100% - Iconos circulares, badges */
```

### Sombras

```css
/* Sombra suave (tarjetas) */
shadow-sm

/* Sombra media (elementos elevados) */
shadow-md

/* Sombra grande (botones principales) */
shadow-lg

/* Sombra con color (botones principales) */
shadow-lg shadow-emerald-500/30
hover:shadow-xl hover:shadow-emerald-500/40
```

### Transiciones

```css
/* Transición estándar */
transition-all duration-200

/* Transición de colores */
transition-colors duration-200
```

### Estados Hover

```html
<!-- Tarjetas interactivas -->
hover:border-emerald-300 hover:bg-emerald-50/30

<!-- Botones -->
hover:bg-emerald-600

<!-- Fondos de fondo -->
hover:bg-gray-200

<!-- Sombras -->
hover:shadow-xl hover:shadow-emerald-500/40
```

---

## 📱 Responsividad

### Breakpoints

```html
<!-- Mobile First -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
    <!-- Contenido -->
</div>

<!-- Espaciado responsivo -->
<div class="p-4 md:p-6">
    <!-- Contenido -->
</div>
```

### Columnas Comunes

```html
<!-- Dos columnas en desktop -->
<div class="grid grid-cols-1 md:grid-cols-2 gap-4">

<!-- Tres columnas en desktop -->
<div class="grid grid-cols-1 md:grid-cols-3 gap-4">

<!-- Campo que ocupa todo el ancho -->
<div class="md:col-span-3">
```

---

## ✅ Checklist de Implementación

Al crear un nuevo componente, asegúrate de:

- [ ] Usar la paleta de colores correcta (verde esmeralda como principal)
- [ ] Bordes redondeados consistentes (`rounded-xl` o `rounded-2xl`)
- [ ] Espaciado adecuado (`p-5`, `gap-4`, etc.)
- [ ] Tipografía correcta (font-bold para títulos, font-semibold para labels)
- [ ] Transiciones suaves (`transition-all duration-200`)
- [ ] Estados hover definidos
- [ ] Responsive design (mobile first)
- [ ] Sombras apropiadas para elementos elevados
- [ ] Iconos con tamaños consistentes
- [ ] Mensajes de error en rojo con `text-xs`

---

## 🎨 Ejemplos de Uso Completo

### Ejemplo 1: Formulario de Crédito

```html
<div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
    <div class="bg-gray-50 px-5 py-3 border-b border-gray-200">
        <h4 class="text-base font-bold text-gray-800">Configuración del Crédito</h4>
    </div>
    <div class="p-5">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <!-- Campo de Cupo -->
            <div class="md:col-span-3">
                <label class="block text-sm font-semibold text-gray-700 mb-2">
                    Cupo a habilitar *
                </label>
                <div class="relative">
                    <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 text-base font-medium">$</span>
                    <input
                        type="number"
                        class="w-full pl-8 pr-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent text-base font-semibold"
                        placeholder="0.00"
                    >
                </div>
            </div>

            <!-- Campo de Cuotas -->
            <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">Cuotas máx. *</label>
                <input
                    type="number"
                    class="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent text-base"
                    placeholder="12"
                >
            </div>
        </div>
    </div>
</div>
```

### Ejemplo 2: Lista de Documentos

```html
<div class="space-y-3">
    <div class="bg-gray-50 rounded-xl p-4 border border-gray-200 flex items-center justify-between hover:border-emerald-300 hover:bg-emerald-50/30 transition-all duration-200">
        <div class="flex items-center space-x-3 flex-1">
            <div class="w-12 h-12 bg-emerald-100 rounded-xl flex items-center justify-center flex-shrink-0">
                <svg class="w-6 h-6 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                </svg>
            </div>
            <div class="flex-1">
                <p class="text-sm font-bold text-gray-900">Cédula (Frente)</p>
                <p class="text-xs text-gray-500 mt-0.5">Subido el 02/12/2025</p>
            </div>
        </div>
        <a href="#" class="inline-flex items-center px-6 py-2.5 bg-emerald-500 text-white text-sm font-bold rounded-xl hover:bg-emerald-600 transition-all duration-200 shadow-sm hover:shadow-md ml-4 flex-shrink-0">
            <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
            </svg>
            Ver
        </a>
    </div>
</div>
```

---

## 🚀 Recursos Adicionales

### Librerías Usadas
- **Tailwind CSS 3.x**: Framework de utilidades CSS
- **Livewire 3.x**: Framework de Laravel para componentes reactivos
- **Heroicons**: Librería de iconos SVG

### Herramientas Recomendadas
- **Tailwind CSS IntelliSense**: Extensión de VS Code para autocompletado
- **Prettier**: Para formateo automático de código

---

## 📝 Notas Finales

1. **Consistencia es clave**: Usa siempre las mismas clases para elementos similares
2. **Mobile First**: Diseña primero para móvil y luego escala a desktop
3. **Accesibilidad**: Asegúrate de que los contrastes sean suficientes
4. **Performance**: Evita clases innecesarias, mantén el código limpio
5. **Documentación**: Comenta código complejo para facilitar mantenimiento

---

**Última actualización**: Diciembre 2025
**Versión**: 1.0
**Autor**: Equipo Credifácil Colombia
