# Flutter Architecture — Portal del Cliente

## 1. Stack Tecnológico

| Capa | Tecnología | Versión |
|------|-----------|---------|
| Lenguaje | Dart | 3.x |
| Framework | Flutter | 3.x |
| Estado | Riverpod o Provider | - |
| HTTP | Dio | 5.x |
| WebView | webview_flutter | - |
| PDF | flutter_pdfview + path_provider | - |
| Almacén local | flutter_secure_storage | - |
| Notificaciones | firebase_messaging | - |
| Build targets | Web (PWA) + Android (APK) + iOS (IPA) | - |

## 2. Estructura del Proyecto

```
client-portal/
├── pubspec.yaml
├── lib/
│   ├── main.dart                          ← Entry point, setup providers
│   ├── app.dart                           ← MaterialApp, router config
│   │
│   ├── core/
│   │   ├── config/
│   │   │   └── app_config.dart            ← URLs, WoMPI keys, timeouts
│   │   ├── theme/
│   │   │   └── app_theme.dart             ← Tema matoxi (colores, tipografía)
│   │   ├── constants/
│   │   │   ├── api_constants.dart         ← Endpoints como constantes
│   │   │   └── app_constants.dart         ← Strings, valores fijos
│   │   ├── network/
│   │   │   ├── api_client.dart            ← Instancia Dio singleton
│   │   │   ├── auth_interceptor.dart      ← Inyecta token en headers
│   │   │   └── api_exceptions.dart        ← Manejo centralizado de errores
│   │   ├── storage/
│   │   │   └── secure_storage.dart        ← Token storage encriptado
│   │   └── utils/
│   │       ├── currency_formatter.dart    ← Formato COP ($1.234.567)
│   │       ├── date_formatter.dart        ← Fechas en español
│   │       ├── validators.dart            ← Validación documento, teléfono
│   │       └── url_launcher.dart          ← Abrir links externos
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── client_model.dart
│   │   │   ├── credit_model.dart
│   │   │   ├── credit_summary_model.dart
│   │   │   ├── period_model.dart
│   │   │   ├── installment_model.dart
│   │   │   ├── transaction_model.dart
│   │   │   ├── payment_link_model.dart
│   │   │   ├── payment_confirm_model.dart
│   │   │   └── api_response_model.dart    ← Envoltorio genérico
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart       ← Login, verify, logout
│   │   │   ├── credit_repository.dart     ← CRUD créditos
│   │   │   ├── payment_repository.dart    ← Pagos WoMPI
│   │   │   └── transaction_repository.dart← Historial
│   │   └── datasources/
│   │       └── remote_datasource.dart     ← Llamadas HTTP directas
│   │
│   ├── providers/
│   │   ├── auth_provider.dart             ← Estado de autenticación
│   │   ├── credit_provider.dart           ← Lista/detalle créditos
│   │   ├── payment_provider.dart          ← Estado de pago en curso
│   │   └── notification_provider.dart     ← Push notifications
│   │
│   ├── features/
│   │   ├── splash/
│   │   │   └── splash_screen.dart         ← Logo + verificar token
│   │   ├── auth/
│   │   │   ├── login_screen.dart          ← Documento + teléfono
│   │   │   └── verify_screen.dart         ← Código SMS
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart      ← Resumen tarjetas
│   │   ├── credits/
│   │   │   ├── credit_list_screen.dart    ← Lista créditos
│   │   │   ├── credit_detail_screen.dart  ← Detalle + resumen
│   │   │   ├── amortization_screen.dart   ← Tabla amortización
│   │   │   └── period_detail_screen.dart  ← Cuotas por periodo
│   │   ├── payments/
│   │   │   ├── payment_select_screen.dart ← Seleccionar cuotas
│   │   │   ├── wompi_webview_screen.dart  ← Checkout WoMPI
│   │   │   └── payment_result_screen.dart ← Éxito/fallo
│   │   ├── transactions/
│   │   │   ├── transaction_list_screen.dart
│   │   │   └── transaction_detail_screen.dart
│   │   ├── receipts/
│   │   │   └── receipt_screen.dart        ← Visor PDF
│   │   └── profile/
│   │       ├── profile_screen.dart        ← Datos personales
│   │       ├── notifications_screen.dart  ← Config notificaciones
│   │       └── support_screen.dart        ← Contacto/soporte
│   │
│   └── widgets/
│       ├── credit_card.dart               ← Tarjeta resumen crédito
│       ├── installment_tile.dart          ← Fila de cuota individual
│       ├── period_card.dart               ← Periodo expandible
│       ├── status_badge.dart              ← Badge de estado (colores)
│       ├── amount_display.dart            ← Monto con formato COP
│       ├── progress_chart.dart            ← Barra de progreso de pago
│       ├── payment_method_selector.dart   ← Selección método pago
│       ├── empty_state.dart               ← Estado sin datos
│       ├── error_state.dart               ← Estado error con retry
│       ├── loading_overlay.dart           ← Loader overlay
│       └── app_bottom_nav.dart            ← Bottom navigation bar
│
├── web/
│   └── manifest.json                      ← PWA manifest
├── android/
│   └── app/src/main/AndroidManifest.xml
└── ios/
    └── Runner/Info.plist
```

## 3. Gestión de Estado (Riverpod)

### Provider Tree

```dart
// Auth
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// Credits
final creditListProvider = FutureProvider.family<List<CreditModel>, int>((ref, clientId) {
  return ref.read(creditRepositoryProvider).getCredits(clientId);
});

final creditDetailProvider = FutureProvider.family<CreditModel, int>((ref, creditId) {
  return ref.read(creditRepositoryProvider).getCreditDetail(creditId);
});

// Payment
final paymentStateProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(ref.read(paymentRepositoryProvider));
});

// Notifications
final notificationProvider = StreamProvider<RemoteMessage>((ref) {
  return ref.read(firebaseMessagingProvider).onMessage;
});
```

### AuthState

```dart
enum AuthStatus { unknown, authenticated, unauthenticated, verifying }

class AuthState {
  final AuthStatus status;
  final ClientModel? client;
  final String? token;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.client,
    this.token,
    this.error,
  });
}
```

### PaymentState

```dart
enum PaymentStatus { idle, generating, ready, processing, success, failed }

class PaymentState {
  final PaymentStatus status;
  final PaymentLinkModel? paymentLink;
  final PaymentConfirmModel? confirmation;
  final String? error;
  final bool isLoading;

  const PaymentState({
    this.status = PaymentStatus.idle,
    this.paymentLink,
    this.confirmation,
    this.error,
    this.isLoading = false,
  });
}
```

## 4. Navegación (GoRouter)

```dart
final router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final auth = ref.read(authProvider);
    final isLoggedIn = auth.status == AuthStatus.authenticated;
    final isAuthRoute = state.matchedLocation.startsWith('/auth');

    if (!isLoggedIn && !isAuthRoute) return '/auth/login';
    if (isLoggedIn && isAuthRoute) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/auth/verify', builder: (_, state) => VerifyScreen(clientId: state.extra as int)),
    GoRoute(
      path: '/dashboard',
      builder: (_, __) => const DashboardScreen(),
      routes: [
        GoRoute(path: 'credits', builder: (_, __) => const CreditListScreen()),
        GoRoute(path: 'credits/:id', builder: (_, state) => CreditDetailScreen(creditId: int.parse(state.pathParameters['id']!))),
        GoRoute(path: 'credits/:id/amortization', builder: (_, state) => AmortizationScreen(creditId: int.parse(state.pathParameters['id']!))),
        GoRoute(path: 'credits/:id/periods', builder: (_, state) => PeriodDetailScreen(creditId: int.parse(state.pathParameters['id']!))),
        GoRoute(path: 'payments', builder: (_, __) => const PaymentSelectScreen()),
        GoRoute(path: 'payments/wompi', builder: (_, state) => WompiWebviewScreen(url: state.extra as String)),
        GoRoute(path: 'payments/result', builder: (_, state) => PaymentResultScreen(result: state.extra as PaymentResult)),
        GoRoute(path: 'transactions', builder: (_, __) => const TransactionListScreen()),
        GoRoute(path: 'transactions/:id', builder: (_, state) => TransactionDetailScreen(transactionId: int.parse(state.pathParameters['id']!))),
        GoRoute(path: 'receipts/:id', builder: (_, state) => ReceiptScreen(transactionId: int.parse(state.pathParameters['id']!))),
        GoRoute(path: 'profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: 'profile/notifications', builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: 'profile/support', builder: (_, __) => const SupportScreen()),
      ],
    ),
  ],
);
```

## 5. Manejo de Token y Seguridad

```dart
class SecureStorage {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'client_token', value: token);
    await _storage.write(key: 'token_saved_at', value: DateTime.now().toIso8601String());
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: 'client_token');
    final savedAt = await _storage.read(key: 'token_saved_at');
    if (token == null || savedAt == null) return null;

    // Validar expiración (8 horas = 480 min)
    final saved = DateTime.parse(savedAt);
    if (DateTime.now().difference(saved).inMinutes > 480) {
      await clearToken();
      return null;
    }
    return token;
  }

  Future<void> clearToken() async {
    await _storage.deleteAll();
  }
}
```

## 6. Configuración Multi-Entorno

```dart
class AppConfig {
  // Dev
  static const String tenantApiUrl = 'http://localhost:8021/api/client';

  // Producción (se define por build flavor)
  static const String tenantApiUrlProd = 'https://{tenant}.credifacilcolombia.com/api/client';
  static const String wompiPublicKeyProd = 'pub_prod_xxx';
  static const String wompiPublicKeySandbox = 'pub_test_xxx';

  static const bool isSandbox = true;
  static String get wompiPublicKey => isSandbox ? wompiPublicKeySandbox : wompiPublicKeyProd;
}
```

## 7. WebView WoMPI — Flujo de Pago

```dart
class WompiWebviewScreen extends StatefulWidget {
  final String url;
  const WompiWebviewScreen({required this.url});

  @override
  State<WompiWebviewScreen> createState() => _WompiWebviewScreenState();
}

class _WompiWebviewScreenState extends State<WompiWebviewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          // Detectar redirección de éxito/fallo
          if (url.contains('payment/success')) {
            // Polling a confirm endpoint
            _confirmPayment();
          } else if (url.contains('payment/error')) {
            Navigator.pushReplacementNamed(context, '/payments/result',
              extra: PaymentResult.success());
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _confirmPayment() async {
    // Polling cada 2s por 30s máximo
    // GET /api/client/payments/{id}/status
    // Al recibir status=approved, navegar a resultado
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago seguro')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
```

## 8. Manejo de Estados en UI

Cada pantalla sigue el patrón:

```dart
class CreditListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(creditListProvider(clientId));

    return creditsAsync.when(
      loading: () => const LoadingOverlay(),
      error: (error, stack) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.refresh(creditListProvider(clientId)),
      ),
      data: (credits) => credits.isEmpty
        ? const EmptyState(message: 'No tienes créditos activos')
        : ListView.builder(
            itemCount: credits.length,
            itemBuilder: (_, i) => CreditCard(credit: credits[i]),
          ),
    );
  }
}
```

## 9. Targets de Build

```yaml
# pubspec.yaml
flutter:
  web:
    title: CrediFácil Cliente
    manifest: web/manifest.json
    service_worker: web/service_worker.js

flutter build web        # PWA (desplegable en Netlify/Vercel)
flutter build apk        # Android APK
flutter build ios        # iOS IPA
flutter build appbundle  # Android Play Store
```

## 10. Dependencias Clave (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  webview_flutter: ^4.7.0
  flutter_pdfview: ^1.3.0
  path_provider: ^2.1.0
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
  intl: ^0.19.0
  flutter_local_notifications: ^17.0.0
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  url_launcher: ^6.2.0
  share_plus: ^9.0.0
  package_info_plus: ^8.0.0
  flutter_svg: ^2.0.0
```
