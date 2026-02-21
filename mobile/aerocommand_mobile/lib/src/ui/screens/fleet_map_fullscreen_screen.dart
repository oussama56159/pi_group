import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/vehicle_model.dart';
import '../../realtime/realtime_controller.dart';
import '../screens/drone_details_screen.dart';
import '../widgets/drone_logo.dart';

class FleetMapFullscreenScreen extends StatefulWidget {
  const FleetMapFullscreenScreen({
    super.key,
    required this.vehicles,
    required this.defaultCenter,
    required this.defaultZoom,
    required this.tileUrlTemplate,
    required this.tileSubdomains,
  });

  final List<VehicleModel> vehicles;
  final LatLng defaultCenter;
  final double defaultZoom;
  final String tileUrlTemplate;
  final List<String> tileSubdomains;

  @override
  State<FleetMapFullscreenScreen> createState() => _FleetMapFullscreenScreenState();
}

class _FleetMapFullscreenScreenState extends State<FleetMapFullscreenScreen> {
  final MapController _mapController = MapController();
  int _lastMarkerCount = -1;
  bool _userInteracted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToMarkers());
  }

  List<_VehicleMarker> _markers(RealtimeController realtime) {
    final markers = <_VehicleMarker>[];
    for (final v in widget.vehicles) {
      final t = realtime.latestTelemetry[v.id];
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

  void _fitToMarkers() {
    if (!mounted) return;
    final realtime = context.read<RealtimeController>();
    final markers = _markers(realtime);
    if (markers.isEmpty) return;

    _fitToMarkersList(markers);
  }

  void _fitToMarkersList(List<_VehicleMarker> markers) {
    if (markers.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(markers.map((m) => m.point).toList());
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
        maxZoom: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final realtime = context.watch<RealtimeController>();
    final scheme = Theme.of(context).colorScheme;

    final markers = _markers(realtime);

    if (markers.isNotEmpty && markers.length != _lastMarkerCount) {
      _lastMarkerCount = markers.length;
      if (!_userInteracted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _fitToMarkersList(markers);
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.defaultCenter,
              initialZoom: widget.defaultZoom,
              minZoom: 3,
              maxZoom: 22,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture) {
                  _userInteracted = true;
                }
              },
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
                      width: 40,
                      height: 40,
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
                            size: 34,
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
                color: scheme.surface.withValues(alpha: 0.92),
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
        ],
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
