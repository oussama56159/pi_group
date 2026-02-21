/**
 * Mock mode hook: Simulates backend when no API is available.
 * Populates stores with mock data and simulates live telemetry updates.
 */
import { useEffect, useRef } from 'react';
import { useAuthStore } from '@/stores/authStore';
import { useFleetStore } from '@/stores/fleetStore';
import { useTelemetryStore } from '@/stores/telemetryStore';
import { useMissionStore } from '@/stores/missionStore';
import { mockUser, mockVehicles, mockFleets, mockMissions, mockAlerts } from './mockData';
import { TOKEN_KEY } from '@/config/constants';

export function useMockMode(enabled = false) {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const intervalRef = useRef(null);

  useEffect(() => {
    if (!enabled) return;
    if (!isAuthenticated) return;

    // Populate fleet store
    useFleetStore.setState({ vehicles: mockVehicles, fleets: mockFleets, isLoading: false });
    useMissionStore.setState({ missions: mockMissions, isLoading: false });

    // Populate alerts
    mockAlerts.forEach((a) => useTelemetryStore.getState().addAlert(a));

    // Initialize telemetry for all vehicles
    mockVehicles.forEach((v) => {
      useTelemetryStore.getState().updateVehicleTelemetry(v.id, {
        position: v.position,
        battery: v.battery,
        gps_fix: v.gps_fix,
        satellites: v.satellites,
        mode: v.mode,
        armed: v.armed,
        airspeed: v.airspeed,
        groundspeed: v.groundspeed,
        heading: v.heading,
        altitude: v.position.alt,
        roll: 0, pitch: 0, yaw: v.heading,
        throttle: v.armed ? 55 : 0,
        climb_rate: 0,
        voltage: 22.4,
        current: v.armed ? 12.5 : 0,
      });
      useTelemetryStore.getState().setConnectionStatus(v.id, v.status === 'offline' ? 'disconnected' : 'connected');
    });

    // Simulate live telemetry updates
    intervalRef.current = setInterval(() => {
      const vehicles = useFleetStore.getState().vehicles;
      vehicles.forEach((v) => {
        if (v.status === 'offline' || v.status === 'maintenance') return;
        const prev = useTelemetryStore.getState().vehicleTelemetry[v.id] || {};
        const jitter = () => (Math.random() - 0.5) * 0.0002;
        const batteryDrain = v.armed ? Math.random() * 0.05 : 0;

        useTelemetryStore.getState().updateVehicleTelemetry(v.id, {
          ...prev,
          position: {
            lat: (prev.position?.lat || v.position.lat) + (v.armed ? jitter() : 0),
            lng: (prev.position?.lng || v.position.lng) + (v.armed ? jitter() : 0),
            alt: v.position.alt + (v.armed ? (Math.random() - 0.5) * 2 : 0),
          },
          battery: Math.max(0, (prev.battery ?? v.battery) - batteryDrain),
          heading: ((prev.heading ?? v.heading) + (v.armed ? (Math.random() - 0.5) * 5 : 0) + 360) % 360,
          airspeed: v.armed ? v.airspeed + (Math.random() - 0.5) * 2 : 0,
          groundspeed: v.armed ? v.groundspeed + (Math.random() - 0.5) * 2 : 0,
          altitude: v.position.alt + (v.armed ? (Math.random() - 0.5) * 2 : 0),
          roll: v.armed ? (Math.random() - 0.5) * 10 : 0,
          pitch: v.armed ? (Math.random() - 0.5) * 8 : 0,
          climb_rate: v.armed ? (Math.random() - 0.5) * 2 : 0,
          throttle: v.armed ? 50 + Math.random() * 15 : 0,
          voltage: 22.4 - (100 - (prev.battery ?? v.battery)) * 0.06,
          current: v.armed ? 10 + Math.random() * 5 : 0.1,
          satellites: v.satellites + Math.floor((Math.random() - 0.5) * 2),
        });
      });
    }, 1000);

    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [enabled, isAuthenticated]);
}

/** Enable demo login without real API */
export function useMockLogin() {
  return async (credentials) => {
    if (credentials.email === 'admin@aerocommand.io' && credentials.password === 'admin123') {
      localStorage.setItem(TOKEN_KEY, 'mock-jwt-token');
      useAuthStore.setState({ user: mockUser, isAuthenticated: true, isLoading: false, error: null });
      return { user: mockUser, access_token: 'mock-jwt-token' };
    }
    useAuthStore.setState({ error: 'Invalid credentials', isLoading: false });
    throw new Error('Invalid credentials');
  };
}

