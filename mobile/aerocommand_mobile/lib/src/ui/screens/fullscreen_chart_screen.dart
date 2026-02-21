import 'package:flutter/material.dart';

import '../widgets/telemetry_charts.dart';

class FullscreenChartScreen extends StatelessWidget {
  const FullscreenChartScreen({
    super.key,
    required this.title,
    required this.chart,
    this.actions,
  });

  final String title;
  final Widget chart;
  final List<Widget>? actions;

  static Route<void> route({required String title, required Widget chart, List<Widget>? actions}) {
    return MaterialPageRoute(
      builder: (_) => FullscreenChartScreen(title: title, chart: chart, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: chart,
        ),
      ),
    );
  }
}

class TelemetryRangeSegmented extends StatelessWidget {
  const TelemetryRangeSegmented({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TelemetryRange value;
  final ValueChanged<TelemetryRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TelemetryRange>(
      segments: [
        for (final r in TelemetryRange.values)
          ButtonSegment<TelemetryRange>(
            value: r,
            label: Text(r.label),
          ),
      ],
      selected: {value},
      onSelectionChanged: (v) {
        if (v.isEmpty) return;
        onChanged(v.first);
      },
    );
  }
}
