import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../realtime/realtime_controller.dart';
import '../../realtime/telemetry_summary.dart';
import '../screens/fullscreen_chart_screen.dart';
import '../widgets/telemetry_charts.dart';

class TelemetryMetricDetailScreen extends StatefulWidget {
  const TelemetryMetricDetailScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
    required this.metric,
    this.initialRange = TelemetryRange.min5,
  });

  final String vehicleId;
  final String vehicleName;
  final TelemetryMetric metric;
  final TelemetryRange initialRange;

  @override
  State<TelemetryMetricDetailScreen> createState() => _TelemetryMetricDetailScreenState();
}

class _TelemetryMetricDetailScreenState extends State<TelemetryMetricDetailScreen> {
  late TelemetryRange _range;

  bool _loadingFull = false;
  String? _fullError;
  List<TelemetrySummary>? _fullHistory;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_range == TelemetryRange.full) {
        _ensureFullHistory();
      }
    });
  }

  Future<void> _ensureFullHistory() async {
    if (!mounted) return;

    final realtime = context.read<RealtimeController>();
    if (realtime.isDemo) {
      return;
    }

    if (_fullHistory != null || _loadingFull) return;

    setState(() {
      _loadingFull = true;
      _fullError = null;
    });

    try {
      final api = context.read<ApiClient>();
      final end = DateTime.now().toUtc();
      final start = end.subtract(const Duration(minutes: 60));

      final res = await api.getJson(
        '/telemetry/vehicles/${widget.vehicleId}/history',
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
          out.add(TelemetrySummary.fromFrameJson(widget.vehicleId, p.cast<String, dynamic>()));
        } else if (p is String) {
          final decoded = jsonDecode(p);
          if (decoded is Map) {
            out.add(TelemetrySummary.fromFrameJson(widget.vehicleId, decoded.cast<String, dynamic>()));
          }
        }
      }
      out.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (!mounted) return;
      setState(() {
        _fullHistory = out;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingFull = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final realtime = context.watch<RealtimeController>();
    final scheme = Theme.of(context).colorScheme;

    final latest = realtime.latestTelemetry[widget.vehicleId];

    List<TelemetrySummary> raw;
    if (_range == TelemetryRange.full && _fullHistory != null) {
      raw = _fullHistory!;
    } else {
      raw = realtime.telemetryHistory[widget.vehicleId] ?? const [];
      raw = filterByRange(raw, _range);
    }

    raw = downsample(raw, maxPoints: 900);

    double? extract(TelemetrySummary s) {
      return switch (widget.metric) {
        TelemetryMetric.altitude => s.alt,
        TelemetryMetric.speed => s.groundspeed,
        TelemetryMetric.battery => s.batteryRemaining,
        TelemetryMetric.signal => s.signalStrength?.toDouble(),
        TelemetryMetric.temperature => s.temperatureC,
      };
    }

    final filtered = raw.where((s) => extract(s) != null).toList(growable: false);
    final series = filtered.isEmpty
        ? const <TelemetryPoint>[]
        : buildSeries(filtered, (s) => extract(s)!.toDouble());

    final subtitle = latest == null
        ? 'Waiting for telemetry…'
        : 'Latest: ${extract(latest)?.toStringAsFixed(widget.metric == TelemetryMetric.battery ? 0 : 1) ?? '—'} ${widget.metric.unit}';

    final line = TelemetryLineChartCard(
      title: widget.metric.title,
      unit: widget.metric.unit,
      series: series,
      height: 360,
    );

    final rangeSelector = TelemetryRangeSegmented(
      value: _range,
      onChanged: (r) {
        setState(() {
          _range = r;
        });
        if (r == TelemetryRange.full) {
          _ensureFullHistory();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicleName} • ${widget.metric.title}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            rangeSelector,
            const SizedBox(height: 12),
            if (_range == TelemetryRange.full && !realtime.isDemo) ...[
              if (_loadingFull)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Loading history…', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                )
              else if (_fullError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('History failed: $_fullError', style: TextStyle(color: scheme.error)),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Showing last 60 minutes.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ),
            ],
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            line,
          ],
        ),
      ),
    );
  }
}
