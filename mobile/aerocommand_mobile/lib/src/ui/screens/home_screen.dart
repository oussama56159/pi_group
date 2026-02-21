import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_controller.dart';
import '../../realtime/realtime_controller.dart';
import '../../theme/theme_controller.dart';
import '../tabs/alerts_tab.dart';
import '../tabs/dashboard_tab.dart';
import '../tabs/fleet_tab.dart';
import '../tabs/missions_tab.dart';
import '../tabs/telemetry_tab.dart';
import '../widgets/drone_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  String? _startedRealtimeMode; // 'live' | 'demo'

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthController>();

    if (!auth.isAuthenticated) {
      _startedRealtimeMode = null;
      return;
    }

    if (auth.isDemo) {
      if (_startedRealtimeMode != 'demo') {
        _startedRealtimeMode = 'demo';
        context.read<RealtimeController>().startDemo();
      }
      return;
    }

    if (_startedRealtimeMode != 'live') {
      _startedRealtimeMode = 'live';
      context.read<RealtimeController>().connectOrgStream();
      context.read<RealtimeController>().refreshAlerts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final realtime = context.watch<RealtimeController>();
    final theme = context.watch<ThemeController>();

    final pages = const [
      DashboardTab(),
      FleetTab(),
      TelemetryTab(),
      AlertsTab(),
      MissionsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('AeroCommand (${auth.user?.name ?? ''})'),
        actions: [
          if (auth.isDemo)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Demo Mode',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Text(
              realtime.connectionState,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          IconButton(
            tooltip: theme.isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: theme.toggle,
            icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              final realtime = context.read<RealtimeController>();
              final auth = context.read<AuthController>();
              await realtime.disconnect();
              await auth.logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: DroneLogo(size: 22), label: 'Fleet'),
          NavigationDestination(icon: Icon(Icons.sensors), label: 'Telemetry'),
          NavigationDestination(icon: Icon(Icons.warning_amber), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Missions'),
        ],
      ),
    );
  }
}
