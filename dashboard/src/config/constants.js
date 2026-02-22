// ─── API Configuration ───
const IS_BROWSER = typeof window !== 'undefined';
const DEFAULT_API_BASE_URL = IS_BROWSER
  ? '/api/v1'
  : 'http://localhost:8000/api/v1';
const DEFAULT_WS_BASE_URL = IS_BROWSER
  ? `${window.location.protocol === 'https:' ? 'wss' : 'ws'}://${window.location.host}/api/v1/telemetry/ws`
  : 'ws://localhost:8000/api/v1/telemetry/ws';

export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || DEFAULT_API_BASE_URL;
export const WS_BASE_URL = import.meta.env.VITE_WS_BASE_URL || DEFAULT_WS_BASE_URL;
const DEFAULT_MQTT_BROKER_URL = IS_BROWSER
  ? `${window.location.protocol === 'https:' ? 'wss' : 'ws'}://${window.location.hostname}:8083/mqtt`
  : 'ws://localhost:8083/mqtt';

export const MQTT_BROKER_URL = import.meta.env.VITE_MQTT_BROKER_URL || DEFAULT_MQTT_BROKER_URL;

// ─── Auth ───
export const TOKEN_KEY = 'aero_access_token';
export const REFRESH_TOKEN_KEY = 'aero_refresh_token';
export const TOKEN_EXPIRY_KEY = 'aero_token_expiry';

// ─── Roles ───
export const ROLES = {
  SUPER_ADMIN: 'super_admin',
  ADMIN: 'admin',
  OPERATOR: 'operator',
  VIEWER: 'viewer',
  PILOT: 'pilot',
};

export const ROLE_HIERARCHY = {
  [ROLES.SUPER_ADMIN]: 5,
  [ROLES.ADMIN]: 4,
  [ROLES.PILOT]: 3,
  [ROLES.OPERATOR]: 2,
  [ROLES.VIEWER]: 1,
};

// ─── Vehicle Types ───
export const VEHICLE_TYPES = {
  QUADCOPTER: 'quadcopter',
  HEXACOPTER: 'hexacopter',
  OCTOCOPTER: 'octocopter',
  FIXED_WING: 'fixed_wing',
  VTOL: 'vtol',
  ROVER: 'rover',
  SUBMARINE: 'submarine',
};

// ─── MAVLink Flight Modes (PX4) ───
export const FLIGHT_MODES = {
  MANUAL: { id: 0, label: 'Manual', color: '#ef4444' },
  ALTITUDE: { id: 1, label: 'Altitude', color: '#f59e0b' },
  POSITION: { id: 2, label: 'Position', color: '#22c55e' },
  OFFBOARD: { id: 3, label: 'Offboard', color: '#8b5cf6' },
  STABILIZED: { id: 4, label: 'Stabilized', color: '#06b6d4' },
  ACRO: { id: 5, label: 'Acro', color: '#ef4444' },
  RATTITUDE: { id: 6, label: 'Rattitude', color: '#f59e0b' },
  MISSION: { id: 7, label: 'Mission', color: '#3b82f6' },
  LOITER: { id: 8, label: 'Loiter', color: '#22c55e' },
  RTL: { id: 9, label: 'RTL', color: '#f59e0b' },
  LAND: { id: 10, label: 'Land', color: '#06b6d4' },
  TAKEOFF: { id: 11, label: 'Takeoff', color: '#8b5cf6' },
  FOLLOW_ME: { id: 12, label: 'Follow Me', color: '#3b82f6' },
  PRECISION_LAND: { id: 13, label: 'Precision Land', color: '#06b6d4' },
};

// ─── Vehicle Status ───
export const VEHICLE_STATUS = {
  ONLINE: 'online',
  OFFLINE: 'offline',
  ARMED: 'armed',
  DISARMED: 'disarmed',
  IN_FLIGHT: 'in_flight',
  LANDING: 'landing',
  EMERGENCY: 'emergency',
  MAINTENANCE: 'maintenance',
  CHARGING: 'charging',
};

// ─── Command Types ───
export const COMMANDS = {
  ARM: 'arm',
  DISARM: 'disarm',
  TAKEOFF: 'takeoff',
  LAND: 'land',
  RTL: 'rtl',
  HOLD: 'hold',
  SET_MODE: 'set_mode',
  GOTO: 'goto',
  SET_SPEED: 'set_speed',
  SET_ALTITUDE: 'set_altitude',
  EMERGENCY_STOP: 'emergency_stop',
  REBOOT: 'reboot',
  START_MISSION: 'mission_start',
  PAUSE_MISSION: 'mission_pause',
  RESUME_MISSION: 'mission_resume',
};

// ─── Alert Severity ───
export const ALERT_SEVERITY = {
  CRITICAL: 'critical',
  WARNING: 'warning',
  INFO: 'info',
  SUCCESS: 'success',
};

// ─── Telemetry Update Rates (ms) ───
export const TELEMETRY_RATES = {
  POSITION: 100,
  ATTITUDE: 50,
  BATTERY: 1000,
  GPS: 200,
  STATUS: 500,
  HEARTBEAT: 1000,
};

// ─── Map Configuration ───
export const MAP_CONFIG = {
  DEFAULT_CENTER: [36.8065, 10.1815],
  DEFAULT_ZOOM: 13,
  MAX_ZOOM: 22,
  MIN_ZOOM: 3,
  TILE_LAYER: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
  TILE_ATTRIBUTION: '&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a> &copy; <a href="https://carto.com/">CARTO</a>',
};

// ─── Dashboard Refresh ───
export const REFRESH_INTERVALS = {
  FLEET_STATUS: 5000,
  ALERTS: 3000,
  ANALYTICS: 30000,
  MISSIONS: 10000,
};

