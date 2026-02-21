import { WS_BASE_URL, TOKEN_KEY } from '@/config/constants';

class WebSocketManager {
  constructor() {
    this.connections = new Map();
    this.subscribers = new Map();
    this.reconnectTimers = new Map();
    this.maxReconnectAttempts = 10;
    this.baseReconnectDelay = 1000;
  }

  connect(channel, options = {}) {
    if (this.connections.has(channel)) {
      const existing = this.connections.get(channel);
      if (existing.readyState === WebSocket.OPEN) return existing;
      existing.close();
    }

    const token = localStorage.getItem(TOKEN_KEY);
    const url = `${WS_BASE_URL}?channels=${encodeURIComponent(channel)}${token ? `&token=${token}` : ''}`;
    const ws = new WebSocket(url);
    let reconnectAttempts = 0;

    ws.onopen = () => {
      reconnectAttempts = 0;
      this._notify(channel, 'connected', { channel });
      if (options.onOpen) options.onOpen();
    };

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        this._notify(channel, 'message', data);
        if (options.onMessage) options.onMessage(data);
      } catch (e) {
        console.error(`[WS:${channel}] Parse error:`, e);
      }
    };

    ws.onclose = (event) => {
      this._notify(channel, 'disconnected', { code: event.code, reason: event.reason });
      if (!event.wasClean && reconnectAttempts < this.maxReconnectAttempts) {
        const delay = this.baseReconnectDelay * Math.pow(2, reconnectAttempts);
        const timer = setTimeout(() => {
          reconnectAttempts++;
          this.connect(channel, options);
        }, Math.min(delay, 30000));
        this.reconnectTimers.set(channel, timer);
      }
      if (options.onClose) options.onClose(event);
    };

    ws.onerror = (error) => {
      this._notify(channel, 'error', error);
      if (options.onError) options.onError(error);
    };

    this.connections.set(channel, ws);
    return ws;
  }

  disconnect(channel) {
    const ws = this.connections.get(channel);
    if (ws) {
      ws.close(1000, 'Client disconnect');
      this.connections.delete(channel);
    }
    const timer = this.reconnectTimers.get(channel);
    if (timer) {
      clearTimeout(timer);
      this.reconnectTimers.delete(channel);
    }
  }

  disconnectAll() {
    this.connections.forEach((_, channel) => this.disconnect(channel));
  }

  send(channel, data) {
    const ws = this.connections.get(channel);
    if (ws?.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify(data));
      return true;
    }
    return false;
  }

  subscribe(channel, eventType, callback) {
    const key = `${channel}:${eventType}`;
    if (!this.subscribers.has(key)) {
      this.subscribers.set(key, new Set());
    }
    this.subscribers.get(key).add(callback);
    return () => this.subscribers.get(key)?.delete(callback);
  }

  _notify(channel, eventType, data) {
    const key = `${channel}:${eventType}`;
    this.subscribers.get(key)?.forEach((cb) => {
      try { cb(data); } catch (e) { console.error(`[WS:${channel}] Subscriber error:`, e); }
    });
  }

  getState(channel) {
    const ws = this.connections.get(channel);
    if (!ws) return 'disconnected';
    switch (ws.readyState) {
      case WebSocket.CONNECTING: return 'connecting';
      case WebSocket.OPEN: return 'connected';
      case WebSocket.CLOSING: return 'closing';
      case WebSocket.CLOSED: return 'disconnected';
      default: return 'unknown';
    }
  }
}

export const wsManager = new WebSocketManager();
export default wsManager;

