import { useEffect, useRef } from 'react';
import { useMissionStore } from '@/stores/missionStore';
import { TOKEN_KEY, WS_BASE_URL } from '@/config/constants';

export function useMissionStream(vehicleId) {
  const applyAssignmentUpdate = useMissionStore((s) => s.applyAssignmentUpdate);
  const wsRef = useRef(null);

  useEffect(() => {
    if (!vehicleId) return;

    const token = localStorage.getItem(TOKEN_KEY);
    const channels = `vehicle:${vehicleId}`;
    const url = `${WS_BASE_URL}?channels=${encodeURIComponent(channels)}${token ? `&token=${token}` : ''}`;
    const ws = new WebSocket(url);
    wsRef.current = ws;

    ws.onmessage = (event) => {
      try {
        const message = JSON.parse(event.data);
        if (message?.type === 'mission') {
          applyAssignmentUpdate(message.data);
        }
      } catch {
        // Ignore parse errors
      }
    };

    return () => {
      ws.close(1000, 'Client disconnect');
      wsRef.current = null;
    };
  }, [vehicleId, applyAssignmentUpdate]);
}
