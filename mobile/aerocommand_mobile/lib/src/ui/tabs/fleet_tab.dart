import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../config/endpoint_controller.dart';
import '../../models/vehicle_model.dart';
import '../../realtime/realtime_controller.dart';
import '../../realtime/telemetry_summary.dart';
import '../screens/drone_details_screen.dart';
import '../screens/fleet_map_fullscreen_screen.dart';
import '../widgets/drone_logo.dart';

class FleetTab extends StatefulWidget {
  const FleetTab({super.key});

  @override
  State<FleetTab> createState() => _FleetTabState();
}

class _FleetTabState extends State<FleetTab> {
  bool _loading = true;
  String? _error;
  List<VehicleModel> _vehicles = const [];

  static const _defaultCenter = LatLng(36.8065, 10.1815);
  static const _defaultZoom = 13.0;
  static const _tileUrlTemplate = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const _tileSubdomains = ['a', 'b', 'c', 'd'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final res = await api.getJson('/fleet/vehicles', query: {'page': '1', 'page_size': '200'});
      if (res is Map && res['items'] is List) {
        final items = (res['items'] as List)
            .whereType<Map>()
            .map((e) => VehicleModel.fromJson(e.cast<String, dynamic>()))
            .toList();
        setState(() => _vehicles = items);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final realtime = context.watch<RealtimeController>();
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthController>();
    final endpoints = context.watch<EndpointController>();

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: _FleetMapCard(
              vehicles: _vehicles,
              realtime: realtime,
              defaultCenter: _defaultCenter,
              defaultZoom: _defaultZoom,
              tileUrlTemplate: _tileUrlTemplate,
              tileSubdomains: _tileSubdomains,
            ),
          ),

          if (_vehicles.isEmpty)
            _FleetEmptyState(
              onRefresh: _load,
              backendDisplay: endpoints.display,
              role: auth.role,
              isDemo: auth.isDemo,
            )
          else ...[
            const SizedBox(height: 10),
            for (final v in _vehicles)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: _VehicleAtAGlanceCard(
                  vehicle: v,
                  telemetry: realtime.latestTelemetry[v.id],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DroneDetailsScreen(vehicleId: v.id, initialName: v.name),
                      ),
                    );
                  },
                ),
              ),
          ],
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Realtime cache: ${realtime.latestTelemetry.length} vehicles'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FleetMapCard extends StatefulWidget {
  const _FleetMapCard({
    required this.vehicles,
    required this.realtime,
    required this.defaultCenter,
    required this.defaultZoom,
    required this.tileUrlTemplate,
    required this.tileSubdomains,
  });

  final List<VehicleModel> vehicles;
  final RealtimeController realtime;
  final LatLng defaultCenter;
  final double defaultZoom;
  final String tileUrlTemplate;
  final List<String> tileSubdomains;

  @override
  State<_FleetMapCard> createState() => _FleetMapCardState();
}

class _FleetMapCardState extends State<_FleetMapCard> {
  final MapController _mapController = MapController();

  List<_VehicleMarker> _markers() {
    final markers = <_VehicleMarker>[];
    for (final v in widget.vehicles) {
      final t = widget.realtime.latestTelemetry[v.id];
      if (t == null) continue;
      if (t.lat == 0 || t.lng == 0) continue;
      markers.add(
        _VehicleMarker(
          vehicleId: v.id,
          name: v.name,
          status: v.status,
          armed: t.armed,
          headingDeg: t.heading,
          point: LatLng(t.lat, t.lng),
        ),
      );
    }
    return markers;
  }

  @override
  void didUpdateWidget(covariant _FleetMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.realtime.latestTelemetry.length != widget.realtime.latestTelemetry.length) {
      _fitToMarkers();
    }
  }

  void _fitToMarkers() {
    final markers = _markers();
    if (markers.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(markers.map((m) => m.point).toList());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(32),
          maxZoom: 16,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final markers = _markers();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 280,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.defaultCenter,
                initialZoom: widget.defaultZoom,
                minZoom: 3,
                maxZoom: 22,
              ),
              children: [
                TileLayer(
                  urlTemplate: widget.tileUrlTemplate,
                  subdomains: widget.tileSubdomains,
                  userAgentPackageName: 'aerocommand_mobile',
                ),
                MarkerLayer(
                  markers: [
                    for (final m in markers)
                      Marker(
                        point: m.point,
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DroneDetailsScreen(vehicleId: m.vehicleId, initialName: m.name),
                              ),
                            );
                          },
                          child: Transform.rotate(
                            angle: (m.headingDeg) * 3.141592653589793 / 180.0,
                            child: DroneLogo(
                              size: 30,
                              color: _statusColor(scheme, m.status, m.armed),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (markers.isNotEmpty)
                  RichAttributionWidget(
                    alignment: AttributionAlignment.bottomRight,
                    attributions: [
                      TextSourceAttribution('© OpenStreetMap contributors'),
                      TextSourceAttribution('© CARTO'),
                    ],
                  ),
              ],
            ),
            Positioned(
              left: 12,
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(
                    markers.isEmpty ? 'Waiting for live GPS…' : 'Live positions: ${markers.length}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton.filledTonal(
                tooltip: 'Full screen map',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FleetMapFullscreenScreen(
                        vehicles: widget.vehicles,
                        defaultCenter: widget.defaultCenter,
                        defaultZoom: widget.defaultZoom,
                        tileUrlTemplate: widget.tileUrlTemplate,
                        tileSubdomains: widget.tileSubdomains,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_full),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ColorScheme scheme, String status, bool armed) {
    if (armed) return scheme.error;
    if (status == 'in_flight') return scheme.primary;
    if (status == 'online') return scheme.tertiary;
    return scheme.outline;
  }
}

class _VehicleMarker {
  _VehicleMarker({
    required this.vehicleId,
    required this.name,
    required this.status,
    required this.armed,
    required this.headingDeg,
    required this.point,
  });

  final String vehicleId;
  final String name;
  final String status;
  final bool armed;
  final double headingDeg;
  final LatLng point;
}

class _FleetEmptyState extends StatelessWidget {
  const _FleetEmptyState({
    required this.onRefresh,
    required this.backendDisplay,
    required this.role,
    required this.isDemo,
  });

  final VoidCallback onRefresh;
  final String backendDisplay;
  final String role;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.air, size: 44, color: scheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text('No vehicles found', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            isDemo
                ? 'Demo mode is on, but no demo vehicles are loaded.'
                : 'This can happen if you are pointing at a different backend than the web app, or if your account is not assigned to any fleet (non-admin users only see vehicles in their fleets).',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Text(
            'Backend: $backendDisplay\nRole: $role',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _VehicleAtAGlanceCard extends StatelessWidget {
  const _VehicleAtAGlanceCard({
    required this.vehicle,
    required this.telemetry,
    required this.onTap,
  });

  final VehicleModel vehicle;
  final TelemetrySummary? telemetry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final age = telemetry == null ? null : DateTime.now().difference(telemetry!.timestamp);
    final isFresh = age != null && age < const Duration(seconds: 15);
    final dotColor = isFresh ? scheme.tertiary : scheme.outline;

    final batteryPct = telemetry == null ? null : _formatBatteryPct(telemetry!);
    final lastSeen = telemetry == null ? 'No telemetry yet' : '${_formatAge(age!)} ago';
    final statusLabel = vehicle.status.trim().isEmpty ? 'unknown' : vehicle.status;
    final showArmed = telemetry?.armed == true;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  DroneLogo(size: 34, color: scheme.onSurface),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vehicle.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.callsign,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusPill(label: statusLabel, kind: _StatusPillKind.status),
                        if (showArmed) _StatusPill(label: 'armed', kind: _StatusPillKind.armed),
                        Text(
                          lastSeen,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    batteryPct == null ? '—' : '$batteryPct%',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    telemetry?.mode ?? '—',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StatusPillKind { status, armed }

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.kind});

  final String label;
  final _StatusPillKind kind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = label.toLowerCase();

    Color background;
    Color foreground;
    if (kind == _StatusPillKind.armed) {
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
    } else if (normalized.contains('online') || normalized.contains('in_flight')) {
      background = scheme.tertiaryContainer;
      foreground = scheme.onTertiaryContainer;
    } else if (normalized.contains('offline')) {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurface;
    } else {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurface;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

int _formatBatteryPct(TelemetrySummary t) {
  // Backend frames may report 0..1 or 0..100; normalize to 0..100.
  final raw = t.batteryRemaining;
  final pct = raw <= 1.0 ? (raw * 100.0) : raw;
  final clamped = pct.clamp(0.0, 100.0);
  return clamped.round();
}

String _formatAge(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds}s';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  return '${d.inHours}h';
}
