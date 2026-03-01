import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../realtime/telemetry_summary.dart';

enum TelemetryRange {
  min1,
  min5,
  min15,
  full,
}

extension TelemetryRangeX on TelemetryRange {
  String get label => switch (this) {
        TelemetryRange.min1 => '1 min',
        TelemetryRange.min5 => '5 min',
        TelemetryRange.min15 => '15 min',
        TelemetryRange.full => 'Full',
      };

  Duration? get duration => switch (this) {
        TelemetryRange.min1 => const Duration(minutes: 1),
        TelemetryRange.min5 => const Duration(minutes: 5),
        TelemetryRange.min15 => const Duration(minutes: 15),
        TelemetryRange.full => null,
      };
}

enum TelemetryMetric {
  altitude,
  speed,
  battery,
  signal,
  temperature,
}

extension TelemetryMetricX on TelemetryMetric {
  String get title => switch (this) {
        TelemetryMetric.altitude => 'Altitude',
        TelemetryMetric.speed => 'Speed',
        TelemetryMetric.battery => 'Battery',
        TelemetryMetric.signal => 'Signal',
        TelemetryMetric.temperature => 'Temperature',
      };

  String get unit => switch (this) {
        TelemetryMetric.altitude => 'm',
        TelemetryMetric.speed => 'm/s',
        TelemetryMetric.battery => '%',
        TelemetryMetric.signal => '%',
        TelemetryMetric.temperature => '°C',
      };
}

class RadialGaugeCard extends StatelessWidget {
  const RadialGaugeCard({
    super.key,
    required this.title,
    required this.value01,
    required this.valueLabel,
    this.subtitle,
    this.color,
    this.onTap,
  });

  final String title;
  final double value01;
  final String valueLabel;
  final String? subtitle;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = value01.clamp(0.0, 1.0);

    final gauge = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: clamped),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 86,
              height: 86,
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 8,
                backgroundColor: scheme.outlineVariant,
                valueColor: AlwaysStoppedAnimation(color ?? scheme.primary),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(valueLabel, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ],
        );
      },
    );

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              Center(child: gauge),
            ],
          ),
        ),
      ),
    );
  }
}

class TelemetryLineChartCard extends StatelessWidget {
  const TelemetryLineChartCard({
    super.key,
    required this.title,
    required this.unit,
    required this.series,
    this.color,
    this.onTap,
    this.height = 160,
  });

  final String title;
  final String unit;
  final List<TelemetryPoint> series;
  final Color? color;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final c = color ?? scheme.primary;

    final spots = series.map((p) => FlSpot(p.x, p.y)).toList(growable: false);

    final yValues = series.map((e) => e.y).toList();
    final yMin = yValues.isEmpty ? 0.0 : yValues.reduce(min);
    final yMax = yValues.isEmpty ? 1.0 : yValues.reduce(max);
    final pad = (yMax - yMin).abs() * 0.15;

    final xMin = series.isEmpty ? 0.0 : series.first.x;
    final xMax = series.isEmpty ? 1.0 : series.last.x;
    final xInterval = _niceTimeInterval(xMin, xMax);
    final yInterval = _niceInterval(yMin, yMax);
    final ySpan = (yMax - yMin).abs();

    final chart = SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: xMin,
          maxX: xMax,
          minY: yMin - (pad == 0 ? 1 : pad),
          maxY: yMax + (pad == 0 ? 1 : pad),
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: yInterval),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: yInterval,
                getTitlesWidget: (v, meta) {
                  final label = _formatYAxisValue(v, unit: unit, span: ySpan);
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 6,
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: xInterval,
                getTitlesWidget: (v, meta) {
                  final label = _formatElapsedTime(v);
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => scheme.inverseSurface,
              tooltipRoundedRadius: 12,
              getTooltipItems: (spots) {
                return spots
                    .map(
                      (s) => LineTooltipItem(
                        '${s.y.toStringAsFixed(1)} $unit',
                        TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w700),
                      ),
                    )
                    .toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.22,
              barWidth: 3,
              color: c,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: c.withValues(alpha: 0.18)),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
    );

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Text(unit, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 10),
              if (series.length < 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Waiting for data…', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                )
              else
                chart,
            ],
          ),
        ),
      ),
    );
  }

  double _niceInterval(double minY, double maxY) {
    final span = (maxY - minY).abs();
    if (span <= 0) return 1;
    if (span < 5) return 1;
    if (span < 20) return 5;
    if (span < 50) return 10;
    return 20;
  }

  double _niceTimeInterval(double minX, double maxX) {
    final span = (maxX - minX).abs();
    if (span <= 0) return 1;
    if (span <= 60) return 10; // seconds
    if (span <= 5 * 60) return 60; // 1 minute
    if (span <= 15 * 60) return 3 * 60; // 3 minutes
    if (span <= 60 * 60) return 10 * 60; // 10 minutes
    return 15 * 60; // 15 minutes
  }

  String _formatElapsedTime(double seconds) {
    final s = seconds.round().clamp(0, 1 << 31);
    if (s >= 3600) {
      final h = s ~/ 3600;
      final m = (s % 3600) ~/ 60;
      return '$h:${m.toString().padLeft(2, '0')}';
    }
    final m = s ~/ 60;
    final ss = s % 60;
    return '$m:${ss.toString().padLeft(2, '0')}';
  }

  String _formatYAxisValue(double v, {required String unit, required double span}) {
    final lowerUnit = unit.toLowerCase();
    final isPercentLike = lowerUnit.contains('%');

    if (isPercentLike) {
      if (span < 2) return v.toStringAsFixed(1);
      return v.toStringAsFixed(0);
    }

    if (span >= 100) return v.toStringAsFixed(0);
    if (span >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }
}

class TelemetryBarChartCard extends StatelessWidget {
  const TelemetryBarChartCard({
    super.key,
    required this.title,
    required this.items,
    required this.unit,
    this.color,
    this.onTap,
    this.height = 220,
  });

  final String title;
  final List<TelemetryBarItem> items;
  final String unit;
  final Color? color;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;

    final chart = SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: 100,
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, meta) {
                  if (v % 20 != 0) return const SizedBox.shrink();
                  return Text(v.toInt().toString(), style: Theme.of(context).textTheme.labelSmall);
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= items.length) return const SizedBox.shrink();
                  final label = items[idx].label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(label, style: Theme.of(context).textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              tooltipRoundedRadius: 12,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final it = items[group.x.toInt()];
                return BarTooltipItem(
                  '${it.value.toStringAsFixed(0)} $unit',
                  TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w700),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < items.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: items[i].value,
                    width: 14,
                    borderRadius: BorderRadius.circular(6),
                    color: c,
                    backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: scheme.surfaceContainerHighest),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      ),
    );

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                  Text(unit, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                Text('No active drones.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))
              else
                chart,
            ],
          ),
        ),
      ),
    );
  }
}

class TelemetryPoint {
  const TelemetryPoint(this.x, this.y);

  final double x;
  final double y;
}

class TelemetryBarItem {
  const TelemetryBarItem({required this.label, required this.value});

  final String label;
  final double value;
}

List<TelemetryPoint> buildSeries(
  List<TelemetrySummary> samples,
  double Function(TelemetrySummary s) value,
) {
  if (samples.isEmpty) return const [];
  final x0 = samples.first.timestamp.millisecondsSinceEpoch.toDouble();
  return samples
      .map(
        (s) => TelemetryPoint(
          (s.timestamp.millisecondsSinceEpoch.toDouble() - x0) / 1000.0,
          value(s),
        ),
      )
      .toList(growable: false);
}

List<TelemetrySummary> filterByRange(List<TelemetrySummary> samples, TelemetryRange range) {
  if (samples.isEmpty) return const [];
  final d = range.duration;
  if (d == null) return samples;
  final cutoff = DateTime.now().toUtc().subtract(d);
  final idx = samples.indexWhere((s) => !s.timestamp.isBefore(cutoff));
  if (idx < 0) return const [];
  return samples.sublist(idx);
}

List<TelemetrySummary> downsample(List<TelemetrySummary> samples, {int maxPoints = 600}) {
  if (samples.length <= maxPoints) return samples;
  final step = (samples.length / maxPoints).ceil();
  final out = <TelemetrySummary>[];
  for (var i = 0; i < samples.length; i += step) {
    out.add(samples[i]);
  }
  return out;
}

List<TelemetryBarItem> buildBarItems(Map<String, double> values, {int maxItems = 8}) {
  final entries = values.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top = entries.take(maxItems);
  return top.map((e) => TelemetryBarItem(label: e.key, value: e.value)).toList(growable: false);
}
