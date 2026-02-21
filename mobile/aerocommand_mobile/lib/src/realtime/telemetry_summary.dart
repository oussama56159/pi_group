class TelemetrySummary {
  TelemetrySummary({
    required this.vehicleId,
    required this.timestamp,
    required this.batteryRemaining,
    required this.mode,
    required this.armed,
    required this.lat,
    required this.lng,
    required this.alt,
    required this.groundspeed,
    required this.heading,
    required this.satellites,
    required this.gpsFix,
    this.signalStrength,
    this.temperatureC,
  });

  final String vehicleId;
  final DateTime timestamp;
  final double batteryRemaining;
  final String mode;
  final bool armed;
  final double lat;
  final double lng;
  final double alt;
  final double groundspeed;
  final double heading;
  final int satellites;
  final int gpsFix;
  final int? signalStrength; // 0..100
  final double? temperatureC;

  factory TelemetrySummary.fromFrameJson(String vehicleId, Map<String, dynamic> frame) {
    final gps = (frame['gps'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final position = (frame['position'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final battery = (frame['battery'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final system = (frame['system'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    final signal = (frame['signal'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    final tsRaw = frame['timestamp']?.toString();
    final ts = tsRaw != null ? DateTime.tryParse(tsRaw) ?? DateTime.now() : DateTime.now();

    return TelemetrySummary(
      vehicleId: vehicleId,
      timestamp: ts,
      batteryRemaining: (battery['remaining'] as num?)?.toDouble() ?? 0,
      mode: system['mode']?.toString() ?? 'unknown',
      armed: system['armed'] == true,
      lat: (position['lat'] as num?)?.toDouble() ?? (gps['lat'] as num?)?.toDouble() ?? 0,
      lng: (position['lng'] as num?)?.toDouble() ?? (gps['lng'] as num?)?.toDouble() ?? 0,
      alt: (position['alt'] as num?)?.toDouble() ?? (gps['alt'] as num?)?.toDouble() ?? 0,
      groundspeed: (frame['groundspeed'] as num?)?.toDouble() ?? 0,
      heading: (frame['heading'] as num?)?.toDouble() ?? 0,
      satellites: (gps['satellites_visible'] as num?)?.toInt() ?? 0,
      gpsFix: (gps['fix_type'] as num?)?.toInt() ?? 0,
      signalStrength: (frame['signal_strength'] as num?)?.toInt() ?? (signal['strength'] as num?)?.toInt(),
      temperatureC: (frame['temperature_c'] as num?)?.toDouble() ?? (frame['temperature'] as num?)?.toDouble(),
    );
  }
}
