import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../realtime/realtime_controller.dart';

class AlertsTab extends StatelessWidget {
  const AlertsTab({super.key});

  bool _isCritical(String severity) {
    return severity == 'critical' || severity == 'emergency';
  }

  @override
  Widget build(BuildContext context) {
    final realtime = context.watch<RealtimeController>();
    final df = DateFormat('yyyy-MM-dd HH:mm:ss');
    final scheme = Theme.of(context).colorScheme;

    final criticalCount = realtime.alerts.where((a) => _isCritical(a.severity)).length;

    return RefreshIndicator(
      onRefresh: () => context.read<RealtimeController>().refreshAlerts(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: Text('Alerts', style: Theme.of(context).textTheme.titleLarge)),
              if (realtime.alerts.isNotEmpty)
                Chip(
                  label: Text('${realtime.alerts.length}'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            criticalCount > 0 ? '$criticalCount critical' : 'No critical alerts',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (realtime.alerts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No alerts.', style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
          else
            for (final a in realtime.alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      _isCritical(a.severity) ? Icons.error_outline : Icons.warning_amber_rounded,
                      color: _isCritical(a.severity) ? scheme.error : scheme.tertiary,
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(a.severity),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${a.category} • ${df.format(a.createdAt.toLocal())}\n${a.message}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: a.acknowledged
                        ? Icon(Icons.check_circle, color: scheme.primary)
                        : TextButton(
                            onPressed: () => context.read<RealtimeController>().acknowledgeAlert(a.id),
                            child: const Text('Ack'),
                          ),
                    isThreeLine: true,
                  ),
                ),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
