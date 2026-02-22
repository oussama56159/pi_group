import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/api/api_client.dart';
import 'src/api/mock_api_client.dart';
import 'src/auth/auth_controller.dart';
import 'src/config/endpoint_controller.dart';
import 'src/realtime/realtime_controller.dart';
import 'src/theme/theme_controller.dart';
import 'src/ui/screens/login_screen.dart';
import 'src/ui/screens/home_screen.dart';
import 'src/ui/widgets/loading_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AeroCommandApp());
}

class AeroCommandApp extends StatelessWidget {
  const AeroCommandApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.blueGrey,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHighest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
        ChangeNotifierProvider(create: (_) => EndpointController()..load()),
        ChangeNotifierProvider(
          create: (context) => AuthController(
            baseUrlProvider: () => context.read<EndpointController>().apiBaseUrl,
          ),
        ),
        ProxyProvider2<AuthController, EndpointController, ApiClient>(
          update: (context, auth, endpoints, previous) {
            if (auth.isDemo) {
              return (previous is MockApiClient) ? previous : MockApiClient();
            }
            return HttpApiClient(
              tokenProvider: () => auth.accessToken,
              baseUrlProvider: () => endpoints.apiBaseUrl,
            );
          },
        ),
        ChangeNotifierProxyProvider3<AuthController, ApiClient, EndpointController, RealtimeController>(
          create: (context) => RealtimeController(
            auth: context.read<AuthController>(),
            api: context.read<ApiClient>(),
            endpoints: context.read<EndpointController>(),
          ),
          update: (_, auth, api, endpoints, previous) {
            if (previous == null) {
              return RealtimeController(auth: auth, api: api, endpoints: endpoints);
            }
            if (!identical(previous.auth, auth) || !identical(previous.api, api) || !identical(previous.endpoints, endpoints)) {
              return RealtimeController(auth: auth, api: api, endpoints: endpoints);
            }
            return previous;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final theme = context.watch<ThemeController>();
          return MaterialApp(
            title: 'AeroCommand Mobile',
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: theme.mode,
            home: const _Root(),
          );
        },
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthController>().restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (auth.isRestoring) {
      return const LoadingView(message: 'Starting…');
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    return const HomeScreen();
  }
}
