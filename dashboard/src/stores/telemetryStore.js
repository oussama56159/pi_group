import { create } from 'zustand';

const MAX_HISTORY_POINTS = 200;

export const useTelemetryStore = create((set, get) => ({
  vehicleTelemetry: {},
  connectionStatus: {},
  alerts: [],
  unreadAlertCount: 0,

  updateVehicleTelemetry: (vehicleId, data) => {
    set((state) => {
      const existing = state.vehicleTelemetry[vehicleId] || { history: [] };
      const history = [...existing.history, { ...data, timestamp: Date.now() }];
      if (history.length > MAX_HISTORY_POINTS) history.shift();
      return {
        vehicleTelemetry: {
          ...state.vehicleTelemetry,
          [vehicleId]: { ...data, history, lastUpdate: Date.now() },
        },
      };
    });
  },

  setConnectionStatus: (vehicleId, status) => {
    set((state) => ({
      connectionStatus: { ...state.connectionStatus, [vehicleId]: status },
    }));
  },

  addAlert: (alert) => {
    set((state) => ({
      alerts: [{ ...alert, id: alert.id || crypto.randomUUID(), receivedAt: Date.now() }, ...state.alerts].slice(0, 500),
      unreadAlertCount: state.unreadAlertCount + 1,
    }));
  },

  acknowledgeAlert: (alertId) => {
    set((state) => ({
      alerts: state.alerts.map((a) => (a.id === alertId ? { ...a, acknowledged: true } : a)),
      unreadAlertCount: Math.max(0, state.unreadAlertCount - 1),
    }));
  },

  dismissAlert: (alertId) => {
    set((state) => ({
      alerts: state.alerts.filter((a) => a.id !== alertId),
    }));
  },

  clearAllAlerts: () => set({ alerts: [], unreadAlertCount: 0 }),

  markAllRead: () => set({ unreadAlertCount: 0 }),

  getVehicleTelemetry: (vehicleId) => get().vehicleTelemetry[vehicleId] || null,

  getConnectionStatus: (vehicleId) => get().connectionStatus[vehicleId] || 'disconnected',

  getCriticalAlerts: () => get().alerts.filter((a) => a.severity === 'critical' && !a.acknowledged),
}));

