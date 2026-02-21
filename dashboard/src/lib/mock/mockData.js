// ─── Mock data for demo/development mode ───

export const mockUser = {
  id: '1',
  name: 'Admin Operator',
  email: 'admin@aerocommand.io',
  role: 'super_admin',
  organization: 'AeroCommand HQ',
  avatar: null,
};

export const mockVehicles = [
  { id: 'v1', name: 'Eagle-01', callsign: 'EGL01', type: 'quadcopter', status: 'in_flight', fleet_id: 'f1', firmware: 'PX4 1.14.3',
    position: { lat: 36.8065, lng: 10.1815, alt: 120 }, battery: 78, gps_fix: 3, satellites: 14, mode: 'MISSION', armed: true, airspeed: 12.5, groundspeed: 11.8, heading: 245, uptime: 3420 },
  { id: 'v2', name: 'Falcon-02', callsign: 'FLC02', type: 'hexacopter', status: 'armed', fleet_id: 'f1', firmware: 'PX4 1.14.3',
    position: { lat: 36.8120, lng: 10.1700, alt: 0 }, battery: 95, gps_fix: 3, satellites: 18, mode: 'STABILIZED', armed: true, airspeed: 0, groundspeed: 0, heading: 90, uptime: 120 },
  { id: 'v3', name: 'Hawk-03', callsign: 'HWK03', type: 'fixed_wing', status: 'in_flight', fleet_id: 'f1', firmware: 'ArduPlane 4.4',
    position: { lat: 36.7900, lng: 10.2000, alt: 250 }, battery: 62, gps_fix: 3, satellites: 16, mode: 'MISSION', armed: true, airspeed: 22.3, groundspeed: 25.1, heading: 180, uptime: 5400 },
  { id: 'v4', name: 'Rover-Alpha', callsign: 'RVA01', type: 'rover', status: 'online', fleet_id: 'f2', firmware: 'ArduRover 4.4',
    position: { lat: 36.8200, lng: 10.1600, alt: 0 }, battery: 88, gps_fix: 3, satellites: 12, mode: 'MANUAL', armed: false, airspeed: 0, groundspeed: 0, heading: 0, uptime: 0 },
  { id: 'v5', name: 'Shadow-05', callsign: 'SHD05', type: 'vtol', status: 'maintenance', fleet_id: 'f1', firmware: 'PX4 1.14.3',
    position: { lat: 36.8000, lng: 10.1900, alt: 0 }, battery: 45, gps_fix: 0, satellites: 0, mode: 'MANUAL', armed: false, airspeed: 0, groundspeed: 0, heading: 0, uptime: 0 },
  { id: 'v6', name: 'Phoenix-06', callsign: 'PHX06', type: 'quadcopter', status: 'offline', fleet_id: 'f2', firmware: 'PX4 1.13.3',
    position: { lat: 36.8150, lng: 10.1750, alt: 0 }, battery: 0, gps_fix: 0, satellites: 0, mode: 'MANUAL', armed: false, airspeed: 0, groundspeed: 0, heading: 0, uptime: 0 },
  { id: 'v7', name: 'Osprey-07', callsign: 'OSP07', type: 'quadcopter', status: 'in_flight', fleet_id: 'f1', firmware: 'PX4 1.14.3',
    position: { lat: 36.7980, lng: 10.1680, alt: 85 }, battery: 54, gps_fix: 3, satellites: 15, mode: 'LOITER', armed: true, airspeed: 0.5, groundspeed: 0.3, heading: 310, uptime: 7200 },
  { id: 'v8', name: 'Condor-08', callsign: 'CND08', type: 'hexacopter', status: 'charging', fleet_id: 'f2', firmware: 'PX4 1.14.3',
    position: { lat: 36.8100, lng: 10.1850, alt: 0 }, battery: 32, gps_fix: 0, satellites: 0, mode: 'MANUAL', armed: false, airspeed: 0, groundspeed: 0, heading: 0, uptime: 0 },
];

export const mockFleets = [
  { id: 'f1', name: 'Alpha Squadron', description: 'Primary surveillance fleet', vehicleCount: 5, onlineCount: 3 },
  { id: 'f2', name: 'Bravo Team', description: 'Ground operations unit', vehicleCount: 3, onlineCount: 1 },
];

export const mockMissions = [
  { id: 'm1', name: 'Perimeter Survey Alpha', status: 'in_progress', vehicle_id: 'v1', type: 'survey', progress: 67,
    waypoints: [
      { id: 'w1', seq: 0, lat: 36.8065, lng: 10.1815, alt: 120, type: 'waypoint', command: 'NAV_WAYPOINT' },
      { id: 'w2', seq: 1, lat: 36.8100, lng: 10.1850, alt: 120, type: 'waypoint', command: 'NAV_WAYPOINT' },
      { id: 'w3', seq: 2, lat: 36.8130, lng: 10.1800, alt: 100, type: 'waypoint', command: 'NAV_WAYPOINT' },
      { id: 'w4', seq: 3, lat: 36.8100, lng: 10.1750, alt: 100, type: 'waypoint', command: 'NAV_WAYPOINT' },
      { id: 'w5', seq: 4, lat: 36.8065, lng: 10.1815, alt: 50, type: 'rtl', command: 'NAV_RETURN_TO_LAUNCH' },
    ], createdAt: '2026-02-07T08:30:00Z' },
  { id: 'm2', name: 'Sector 7 Mapping', status: 'planned', vehicle_id: null, type: 'mapping', progress: 0,
    waypoints: [
      { id: 'w6', seq: 0, lat: 36.7950, lng: 10.1900, alt: 150, type: 'waypoint', command: 'NAV_WAYPOINT' },
      { id: 'w7', seq: 1, lat: 36.8000, lng: 10.2000, alt: 150, type: 'waypoint', command: 'NAV_WAYPOINT' },
    ], createdAt: '2026-02-06T14:00:00Z' },
  { id: 'm3', name: 'Coastal Patrol', status: 'completed', vehicle_id: 'v3', type: 'patrol', progress: 100,
    waypoints: [], createdAt: '2026-02-05T06:00:00Z' },
];

export const mockAlerts = [
  { id: 'a1', severity: 'critical', message: 'Osprey-07 battery below 30% threshold', vehicle_id: 'v7', timestamp: Date.now() - 60000, acknowledged: false },
  { id: 'a2', severity: 'warning', message: 'Hawk-03 GPS signal degraded to 2D fix', vehicle_id: 'v3', timestamp: Date.now() - 120000, acknowledged: false },
  { id: 'a3', severity: 'info', message: 'Eagle-01 mission waypoint 4/5 reached', vehicle_id: 'v1', timestamp: Date.now() - 300000, acknowledged: true },
  { id: 'a4', severity: 'warning', message: 'Condor-08 charging slower than expected', vehicle_id: 'v8', timestamp: Date.now() - 600000, acknowledged: false },
  { id: 'a5', severity: 'critical', message: 'Shadow-05 requires firmware update', vehicle_id: 'v5', timestamp: Date.now() - 900000, acknowledged: false },
];

export const mockAnalytics = {
  totalFlightHours: 1247,
  totalMissions: 342,
  activeDrones: 3,
  totalDrones: 8,
  avgFlightTime: 42,
  successRate: 96.8,
  incidentsThisMonth: 2,
  flightHoursHistory: Array.from({ length: 30 }, (_, i) => ({
    date: new Date(Date.now() - (29 - i) * 86400000).toISOString().slice(0, 10),
    hours: Math.floor(Math.random() * 20 + 20),
    missions: Math.floor(Math.random() * 8 + 4),
  })),
  vehicleUtilization: [
    { name: 'Eagle-01', hours: 245, missions: 67 },
    { name: 'Falcon-02', hours: 198, missions: 54 },
    { name: 'Hawk-03', hours: 312, missions: 89 },
    { name: 'Osprey-07', hours: 178, missions: 48 },
    { name: 'Condor-08', hours: 134, missions: 38 },
  ],
  statusDistribution: [
    { name: 'In Flight', value: 3, color: '#3b82f6' },
    { name: 'Online', value: 1, color: '#22c55e' },
    { name: 'Maintenance', value: 1, color: '#f59e0b' },
    { name: 'Offline', value: 1, color: '#64748b' },
    { name: 'Charging', value: 1, color: '#8b5cf6' },
    { name: 'Armed', value: 1, color: '#ef4444' },
  ],
};

export const mockUsers = [
  { id: 'u1', name: 'Admin Operator', email: 'admin@aerocommand.io', role: 'super_admin', status: 'active', lastLogin: '2026-02-07T10:00:00Z' },
  { id: 'u2', name: 'Sarah Chen', email: 'sarah@aerocommand.io', role: 'pilot', status: 'active', lastLogin: '2026-02-07T09:30:00Z' },
  { id: 'u3', name: 'Marcus Williams', email: 'marcus@aerocommand.io', role: 'operator', status: 'active', lastLogin: '2026-02-06T18:00:00Z' },
  { id: 'u4', name: 'Elena Rodriguez', email: 'elena@aerocommand.io', role: 'viewer', status: 'active', lastLogin: '2026-02-06T14:00:00Z' },
  { id: 'u5', name: 'James Park', email: 'james@aerocommand.io', role: 'admin', status: 'inactive', lastLogin: '2026-01-20T08:00:00Z' },
];

