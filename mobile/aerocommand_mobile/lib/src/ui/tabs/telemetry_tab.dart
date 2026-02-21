import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:convert';

import '../../api/api_client.dart';
import '../../models/vehicle_model.dart';
import '../../realtime/realtime_controller.dart';
import '../../realtime/telemetry_summary.dart';
import '../screens/fullscreen_chart_screen.dart';
import '../screens/telemetry_metric_detail_screen.dart';
import '../widgets/telemetry_charts.dart';

class TelemetryTab extends StatefulWidget {
  const TelemetryTab({super.key});

  @override
  State<TelemetryTab> createState() => _TelemetryTabState();
}

class _TelemetryTabState extends State<TelemetryTab> {
  bool _loadingVehicles = true;
  List<VehicleModel> _vehicles = const [];
  String? _selectedVehicleId;

  TelemetryRange _range = TelemetryRange.min5;
  bool _loadingFullHistory = false;
  String? _fullHistoryError;
  List<TelemetrySummary>? _fullHistory;

  Map<String, dynamic>? _latestSnapshot;
  bool _loadingSnapshot = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVehicles());
  }

  Future<void> _loadVehicles() async {
    setState(() => _loadingVehicles = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.getJson('/fleet/vehicles', query: {'page': '1', 'page_size': '200'});
      if (res is Map && res['items'] is List) {
        final items = (res['items'] as List)
            .whereType<Map>()
            .map((e) => VehicleModel.fromJson(e.cast<String, dynamic>()))
            .toList();
        setState(() {
          _vehicles = items;
          _selectedVehicleId ??= items.isNotEmpty ? items.first.id : null;
        });
        if (_selectedVehicleId != null) {
          await _loadLatestSnapshot(_selectedVehicleId!);
        }
      }
    } finally {
      setState(() => _loadingVehicles = false);
    }
  }

  Future<void> _loadLatestSnapshot(String vehicleId) async {
    setState(() => _loadingSnapshot = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.getJson('/telemetry/vehicles/$vehicleId/latest');
      if (res is Map) {
        setState(() => _latestSnapshot = res.cast<String, dynamic>());
      } else {
        setState(() => _latestSnapshot = null);
      }
    } catch (_) {
      setState(() => _latestSnapshot = null);
    } finally {
      setState(() => _loadingSnapshot = false);
    }
  }

  Future<void> _ensureFullHistory(String vehicleId) async {
    final realtime = context.read<RealtimeController>();
    if (realtime.isDemo) return;

    if (_fullHistory != null || _loadingFullHistory) return;

    setState(() {
      _loadingFullHistory = true;
      _fullHistoryError = null;
    });

    try {
      final api = context.read<ApiClient>();
      final end = DateTime.now().toUtc();
      final start = end.subtract(const Duration(minutes: 60));
      final res = await api.getJson(
        '/telemetry/vehicles/$vehicleId/history',
        query: {
          'start_time': start.toIso8601String(),
          'end_time': end.toIso8601String(),
          'resolution': '1s',
        },
      );

      final points = (res is Map && res['points'] is List) ? (res['points'] as List) : const [];
      final out = <TelemetrySummary>[];
      for (final p in points) {
        if (p is Map) {
          out.add(TelemetrySummary.fromFrameJson(vehicleId, p.cast<String, dynamic>()));
        }
      }
      out.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (!mounted) return;
      setState(() => _fullHistory = out);
    } catch (e) {
      if (mounted) {
        setState(() => _fullHistoryError = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loadingFullHistory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final realtime = context.watch<RealtimeController>();
    final scheme = Theme.of(context).colorScheme;

    if (_loadingVehicles) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vehicles.isEmpty) {
      return const Center(child: Text('No vehicles available.'));
    }

    final selected = _selectedVehicleId;
    final t = selected != null ? realtime.latestTelemetry[selected] : null;

    final historyRaw = selected == null
        ? const <TelemetrySummary>[]
        : (_range == TelemetryRange.full && _fullHistory != null)
            ? _fullHistory!
            : realtime.telemetryHistory[selected] ?? const <TelemetrySummary>[];

    final history = downsample(
      filterByRange(historyRaw, _range),
      maxPoints: 700,
    );

    final snapshotPretty = (_latestSnapshot == null)
      ? null
      : const JsonEncoder.withIndent('  ').convert(_latestSnapshot);

    return RefreshIndicator(
      onRefresh: () async {
        await _loadVehicles();
        if (_selectedVehicleId != null) {
          await _loadLatestSnapshot(_selectedVehicleId!);
        }
        if (_selectedVehicleId != null && _range == TelemetryRange.full) {
          setState(() => _fullHistory = null);
          await _ensureFullHistory(_selectedVehicleId!);
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Telemetry', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<String>(
                key: ValueKey(selected ?? 'none'),
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Vehicle',
                ),
                items: _vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList(),
                onChanged: (id) async {
                  if (id == null) return;
                  setState(() => _selectedVehicleId = id);
                  await _loadLatestSnapshot(id);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Realtime', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (t == null)
                    Text('Waiting for telemetry…', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))
                  else
                    Column(
                      children: [
                        _kv(context, 'Battery', '${t.batteryRemaining.toStringAsFixed(0)}%'),
                        _kv(context, 'Mode', '${t.mode} • ${t.armed ? 'armed' : 'disarmed'}'),
                        _kv(context, 'Position', '${t.lat.toStringAsFixed(5)}, ${t.lng.toStringAsFixed(5)}'),
                        _kv(context, 'Altitude', '${t.alt.toStringAsFixed(1)} m'),
                        _kv(context, 'Speed', '${t.groundspeed.toStringAsFixed(1)} m/s'),
                        _kv(context, 'Heading', '${t.heading.toStringAsFixed(0)}°'),
                        if (t.signalStrength != null) _kv(context, 'Signal', '${t.signalStrength}%'),
                        if (t.temperatureC != null) _kv(context, 'Temp', '${t.temperatureC!.toStringAsFixed(1)}°C'),
                        _kv(context, 'GPS', 'sats ${t.satellites} • fix ${t.gpsFix}'),
                        _kv(context, 'Time', t.timestamp.toLocal().toIso8601String()),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text('Charts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TelemetryRangeSegmented(
                    value: _range,
                    onChanged: (r) async {
                      setState(() {
                        _range = r;
                        if (r != TelemetryRange.full) {
                          _fullHistory = null;
                          _fullHistoryError = null;
                          _loadingFullHistory = false;
                        }
                      });
                      if (r == TelemetryRange.full && selected != null) {
                        await _ensureFullHistory(selected);
                      }
                    },
                  ),
                  if (_range == TelemetryRange.full && !realtime.isDemo) ...[
                    const SizedBox(height: 10),
                    if (_loadingFullHistory)
                      Text('Loading last 60 minutes…', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))
                    else if (_fullHistoryError != null)
                      Text('History failed: $_fullHistoryError', style: TextStyle(color: scheme.error))
                    else
                      Text('Showing last 60 minutes.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: RadialGaugeCard(
                  title: 'Battery',
                  value01: (t?.batteryRemaining ?? 0) / 100.0,
                  valueLabel: t == null ? '—' : '${t.batteryRemaining.toStringAsFixed(0)}%',
                  subtitle: t?.mode,
                  onTap: selected == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TelemetryMetricDetailScreen(
                                vehicleId: selected,
                                vehicleName: _vehicles.firstWhere((v) => v.id == selected).name,
                                metric: TelemetryMetric.battery,
                                initialRange: _range,
                              ),
                            ),
                          );
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RadialGaugeCard(
                  title: 'Signal',
                  value01: (t?.signalStrength ?? 0) / 100.0,
                  valueLabel: t?.signalStrength == null ? '—' : '${t!.signalStrength}%',
                  subtitle: t?.signalStrength == null ? 'n/a' : 'RSSI',
                  onTap: selected == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TelemetryMetricDetailScreen(
                                vehicleId: selected,
                                vehicleName: _vehicles.firstWhere((v) => v.id == selected).name,
                                metric: TelemetryMetric.signal,
                                initialRange: _range,
                              ),
                            ),
                          );
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TelemetryLineChartCard(
            title: 'Altitude',
            unit: TelemetryMetric.altitude.unit,
            series: buildSeries(history, (s) => s.alt),
            onTap: selected == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TelemetryMetricDetailScreen(
                          vehicleId: selected,
                          vehicleName: _vehicles.firstWhere((v) => v.id == selected).name,
                          metric: TelemetryMetric.altitude,
                          initialRange: _range,
                        ),
                      ),
                    );
                  },
          ),
          const SizedBox(height: 12),
          TelemetryLineChartCard(
            title: 'Speed',
            unit: TelemetryMetric.speed.unit,
            series: buildSeries(history, (s) => s.groundspeed),
            onTap: selected == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TelemetryMetricDetailScreen(
                          vehicleId: selected,
                          vehicleName: _vehicles.firstWhere((v) => v.id == selected).name,
                          metric: TelemetryMetric.speed,
                          initialRange: _range,
                        ),
                      ),
                    );
                  },
          ),
          const SizedBox(height: 12),
          TelemetryLineChartCard(
            title: 'Battery',
            unit: TelemetryMetric.battery.unit,
            series: buildSeries(history, (s) => s.batteryRemaining),
            onTap: selected == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TelemetryMetricDetailScreen(
                          vehicleId: selected,
                          vehicleName: _vehicles.firstWhere((v) => v.id == selected).name,
                          metric: TelemetryMetric.battery,
                          initialRange: _range,
                        ),
                      ),
                    );
                  },
          ),
          if (history.any((s) => s.temperatureC != null)) ...[
            const SizedBox(height: 12),
            TelemetryLineChartCard(
              title: 'Temperature',
              unit: TelemetryMetric.temperature.unit,
              series: buildSeries(
                history.where((s) => s.temperatureC != null).toList(growable: false),
                (s) => s.temperatureC!,
              ),
              onTap: selected == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TelemetryMetricDetailScreen(
                            vehicleId: selected,
                            vehicleName: _vehicles.firstWhere((v) => v.id == selected).name,
                            metric: TelemetryMetric.temperature,
                            initialRange: _range,
                          ),
                        ),
                      );
                    },
            ),
          ],

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Latest Snapshot', style: Theme.of(context).textTheme.titleMedium),
                      TextButton(
                        onPressed: (_selectedVehicleId == null || _loadingSnapshot)
                            ? null
                            : () => _loadLatestSnapshot(_selectedVehicleId!),
                        child: _loadingSnapshot ? const Text('Loading…') : const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_latestSnapshot == null)
                    Text('No snapshot available yet.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))
                  else
                    SelectableText(snapshotPretty ?? ''),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String key, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              key,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
