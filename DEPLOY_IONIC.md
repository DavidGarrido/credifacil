# 📱 Despliegue de la App Cliente (client-portal-ionic)

Análisis de opciones para desplegar la app Ionic del portal del cliente.

---

## Comparativa de Opciones

| Opción | Plataforma | Costo | Actualización | Instalación | Esfuerzo |
|---|---|---|---|---|---|
| **PWA** | Web (Android/iOS) | $0 | Instantánea | Visitando URL + "Agregar a pantalla inicio" | Bajo |
| **APK directo** | Android | $0 | Manual (descargar nuevo APK) | Desde archivo .apk | Bajo |
| **Google Play** | Android | $25 (una vez) | Automática vía Play Store | Play Store | Alto |
| **Firebase Dist.** | Android | $0 | Notificación al tester | Link de descarga | Medio |
| **Apple App Store** | iOS | $99/año | Automática vía App Store | App Store | Muy alto |

---

## ✅ Opción Recomendada: PWA (Progressive Web App)

### Ventajas
- **Ya tenemos la infraestructura**: Nginx + SSL + dominio en producción
- **Sin costo adicional**: No requiere Google Play ($25) ni Apple ($99/año)
- **Actualización instantánea**: Los usuarios siempre ven la última versión
- **Multi-plataforma**: Funciona en Android, iOS, Windows, Mac
- **Instalable**: El usuario puede "Agregar a pantalla de inicio" como una app nativa
- **Notificaciones push**: Se pueden agregar con service workers

### Desventajas
- No aparece en tiendas de apps (menos descubrimiento)
- Funcionalidades nativas limitadas (pero Capacitor soporta muchas vía web)

### Cómo implementarlo

#### 1. Configurar Ionic como PWA

En `capacitor.config.ts`:
```ts
const config: CapacitorConfig = {
  appId: 'com.credifacil.cliente',
  appName: 'Credifácil',
  webDir: 'www',
  server: {
    // En producción, apuntar a la URL real
    url: 'https://app.credifacilcolombia.com',
    cleartext: false,
  },
};
```

#### 2. Habilitar PWA en Angular

```bash
# Agregar soporte PWA (service worker + manifest)
ng add @angular/pwa
```

Esto genera:
- `ngsw-config.json` — Config del service worker (cacheo de assets)
- `manifest.webmanifest` — Config de la PWA (nombre, iconos, tema)
- `src/icons/` — Iconos en distintos tamaños

#### 3. Compilar para producción

```bash
npm run build
```

Se genera en `www/` con service worker incluido.

#### 4. Subir al servidor (VPS)

```bash
rsync -az --delete \
  -e "ssh -i ~/.ssh/do_credifacil" \
  www/ \
  root@137.184.163.131:/opt/credifacil/client-portal-dist/
```

#### 5. Configurar Nginx

Agregar al server block de `credifacilcolombia.com`:
```nginx
server_name credifacilcolombia.com www.credifacilcolombia.com app.credifacilcolombia.com;

root /opt/credifacil/client-portal-dist;

# Service worker needs special handling
location /ngsw.json {
    add_header Cache-Control "no-cache";
}

location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

#### 6. Actualizar URL del API en el environment

Para producción, cambiar `src/environments/environment.prod.ts`:
```ts
export const environment = {
  production: true,
  tenantApiUrl: 'https://admin.credifacilcolombia.com/api/client',
};
```

---

## 📦 Opción 2: APK + Distribución Manual

### Ventajas
- Experiencia 100% nativa
- Acceso a todas las APIs de Capacitor (cámara, notificaciones, etc.)
- Se puede instalar en cualquier dispositivo Android sin Play Store

### Desventajas
- Solo Android (para iOS se necesita Mac + Apple Developer)
- El usuario debe habilitar "instalar apps de orígenes desconocidos"
- Actualización manual (descargar nuevo APK cada vez)

### Cómo implementarlo

Ya lo hicimos:
```bash
# 1. Compilar web
npm run build

# 2. Sincronizar con Android
npx cap sync android

# 3. Generar APK
cd android && ./gradlew assembleDebug
```

El APK se genera en:
```
android/app/build/outputs/apk/debug/app-debug.apk
```

#### Para cambiar la URL del API en el APK

Editar `src/environments/environment.ts`:
```ts
export const environment = {
  production: false,
  tenantApiUrl: 'https://admin.credifacilcolombia.com/api/client', // URL de producción
};
```

Luego recompilar.

#### Para distribución a testers

Se puede firmar el APK con una keystore de release:
```bash
# Generar keystore (solo una vez)
keytool -genkey -v -keystore credifacil.keystore -alias credifacil -keyalg RSA -keysize 2048 -validity 10000

# Compilar en release
cd android && ./gradlew assembleRelease
```

El APK release firmado está en:
```
android/app/build/outputs/apk/release/app-release.apk
```

---

## 🚀 Opción 3: Google Play Store

### Ventajas
- Visibilidad en la tienda oficial de Android
- Actualizaciones automáticas
- Mayor confianza del usuario

### Desventajas
- $25 USD único por cuenta de desarrollador
- Proceso de revisión (24-48 hrs)
- Necesita AAB (Android App Bundle) en vez de APK

### Requisitos
1. Cuenta de Google Play Developer ($25)
2. Generar AAB firmado:
   ```bash
   cd android && ./gradlew bundleRelease
   ```
   Archivo: `android/app/build/outputs/bundle/release/app-release.aab`
3. Completar la ficha de Play Store (descripciones, capturas, categoría)
4. Subir el AAB a Google Play Console
5. Esperar revisión (~24 hrs)

---

## 📋 Plan de Acción Recomendado

### Fase 1 — PWA (inmediato, 1-2 días)
1. Agregar `@angular/pwa` al proyecto Ionic
2. Configurar environment de producción
3. Compilar y subir al servidor
4. Configurar Nginx para servir la PWA
5. Probar en celular: `https://app.credifacilcolombia.com`

### Fase 2 — APK release (paralelo, 2-3 días)
1. Crear keystore de firma
2. Compilar AAB y APK release
3. Distribuir a testers internos vía Firebase App Distribution
4. Probar funcionalidad completa

### Fase 3 — Google Play (cuando esté estable, 1 semana)
1. Pagar cuenta de desarrollador ($25)
2. Preparar assets de Play Store (iconos, capturas, descripción)
3. Subir AAB firmado
4. Publicar

---
