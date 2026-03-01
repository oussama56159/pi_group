# Drone Map UI (Fleet)

This app renders live drone/vehicle positions on the Fleet map using **flutter_map**.

## Data shape

Markers are built from two sources:

- `VehicleModel` (REST):
  - `id` (String)
  - `name` (String)
  - `callsign` (String)
  - `status` (String) — may include values like `in_flight`, `online`, or be empty/unknown

- `TelemetrySummary` (realtime):
  - `lat` / `lng` (double)
  - `heading` (double degrees)
  - `alt` (double meters)
  - `groundspeed` (double m/s)
  - `armed` (bool)

A marker is shown only when telemetry exists and `lat/lng` are non-zero.

## State styling

Operational state is derived from `(VehicleModel.status, TelemetrySummary.armed)` in:

- [lib/src/ui/widgets/drone_map_styles.dart](lib/src/ui/widgets/drone_map_styles.dart)

State → color mapping (required by spec):

- `armed` → red
- `disarmed` → green
- `inflight` → violet

If `status` contains `in_flight` → `inflight` (takes precedence).
Otherwise: `armed ? armed : disarmed`.

## Labels & selection

- Drone names are shown on tap/selection; the selected drone label stays visible.
- First tap selects a drone; tapping the selected drone again opens its details screen.

## Configuration points

- Marker + label widget: [lib/src/ui/widgets/drone_map_marker.dart](lib/src/ui/widgets/drone_map_marker.dart)
- Fleet tab screen (search bar + embedded map + list): [lib/src/ui/tabs/fleet_tab.dart](lib/src/ui/tabs/fleet_tab.dart)
- Fullscreen map: [lib/src/ui/screens/fleet_map_fullscreen_screen.dart](lib/src/ui/screens/fleet_map_fullscreen_screen.dart)
