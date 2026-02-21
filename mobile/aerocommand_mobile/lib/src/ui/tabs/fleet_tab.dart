import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../models/vehicle_model.dart';
import '../../realtime/realtime_controller.dart';
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
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No vehicles found.'),
            ),
          for (final v in _vehicles)
            ListTile(
              leading: DroneLogo(size: 26, color: Theme.of(context).colorScheme.onSurface),
              title: Text(v.name),
              subtitle: Text('${v.callsign} • ${v.status}'),
              trailing: _VehicleTelemetryChip(vehicleId: v.id),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DroneDetailsScreen(vehicleId: v.id, initialName: v.name),
                  ),
                );
              },
            ),
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

class _VehicleTelemetryChip extends StatelessWidget {
  const _VehicleTelemetryChip({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final realtime = context.watch<RealtimeController>();
    final t = realtime.latestTelemetry[vehicleId];
    if (t == null) {
      return const Text('—');
    }
    final bat = t.batteryRemaining.toStringAsFixed(0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$bat%'),
        Text(
          t.mode,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
