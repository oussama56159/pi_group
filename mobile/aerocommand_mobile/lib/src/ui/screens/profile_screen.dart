import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_controller.dart';
import '../../config/endpoint_controller.dart';
import '../../realtime/realtime_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final endpoints = context.watch<EndpointController>();
    final scheme = Theme.of(context).colorScheme;

    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _kv(
                    context,
                    'Name',
                    (user != null && user.name.trim().isNotEmpty) ? user.name.trim() : '—',
                  ),
                  _kv(context, 'Email', user?.email ?? '—'),
                  _kv(context, 'Role', user?.role ?? '—'),
                  _kv(context, 'Mode', auth.isDemo ? 'Demo' : 'Live'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Backend', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    endpoints.apiBaseUrl,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final realtime = context.read<RealtimeController>();
              final auth = context.read<AuthController>();
              await realtime.disconnect();
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              k,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(v, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
