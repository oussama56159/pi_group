import 'package:flutter/material.dart';

enum DroneOperationalState {
  armed,
  disarmed,
  inflight,
}

class DroneMapStyle {
  // Palette (per product request): red / blue / violet.
  static const Color armedColor = Color(0xFFFF3B30); // red
  static const Color disarmedColor = Color(0xFF2ECC71); // green
  static const Color inflightColor = Color(0xFFAF52DE); // violet

  static const double markerSize = 24;
  static const double markerOutlineWidth = 1.25;

  static DroneOperationalState stateFrom({
    required String status,
    required bool armed,
  }) {
    final normalized = status.trim().toLowerCase();
    // Treat explicit in-flight as strongest state.
    if (normalized.contains('in_flight') || normalized.contains('inflight')) {
      return DroneOperationalState.inflight;
    }

    // If we don't have a known flight status, fall back to armed/disarmed.
    return armed ? DroneOperationalState.armed : DroneOperationalState.disarmed;
  }

  static String stateLabel(DroneOperationalState s) {
    switch (s) {
      case DroneOperationalState.armed:
        return 'armed';
      case DroneOperationalState.disarmed:
        return 'disarmed';
      case DroneOperationalState.inflight:
        return 'inflight';
    }
  }

  static Color stateColor(DroneOperationalState s) {
    switch (s) {
      case DroneOperationalState.armed:
        return armedColor;
      case DroneOperationalState.inflight:
        return inflightColor;
      case DroneOperationalState.disarmed:
        return disarmedColor;
    }
  }
}
