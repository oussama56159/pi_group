import { useState } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area } from 'recharts';
import Card, { CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import Badge from '@/components/ui/Badge';
import StatusIndicator from '@/components/ui/StatusIndicator';
import { useFleetStore } from '@/stores/fleetStore';
import { useTelemetryStore } from '@/stores/telemetryStore';
import { Radio, Activity } from 'lucide-react';

const chartTheme = { stroke: '#334155', text: '#64748b', grid: '#1e293b' };

function TelemetryChart({ title, data, dataKey, color = '#3b82f6', unit = '' }) {
  return (
    <Card>
      <CardHeader><CardTitle>{title}</CardTitle></CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={200}>
          <AreaChart data={data}>
            <defs>
              <linearGradient id={`grad-${dataKey}`} x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor={color} stopOpacity={0.3} />
                <stop offset="95%" stopColor={color} stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke={chartTheme.grid} />
            <XAxis dataKey="time" tick={{ fill: chartTheme.text, fontSize: 10 }} axisLine={{ stroke: chartTheme.stroke }} />
            <YAxis tick={{ fill: chartTheme.text, fontSize: 10 }} axisLine={{ stroke: chartTheme.stroke }} />
            <Tooltip contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: 8, color: '#f1f5f9' }}
              formatter={(val) => [`${val.toFixed(2)} ${unit}`, title]} />
            <Area type="monotone" dataKey={dataKey} stroke={color} fill={`url(#grad-${dataKey})`} strokeWidth={2} dot={false} />
          </AreaChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}

export default function TelemetryPage() {
  const vehicles = useFleetStore((s) => s.vehicles);
  const allTelemetry = useTelemetryStore((s) => s.vehicleTelemetry);
  const connectionStatus = useTelemetryStore((s) => s.connectionStatus);
  const [selectedId, setSelectedId] = useState(vehicles.find((v) => v.status !== 'offline')?.id || vehicles[0]?.id);

  const t = allTelemetry[selectedId];
  const history = t?.history || [];
  const chartData = history.slice(-60).map((h, i) => ({
    time: i,
    altitude: h.altitude ?? 0,
    speed: h.groundspeed ?? 0,
    battery: h.battery ?? 0,
    heading: h.heading ?? 0,
    roll: h.roll ?? 0,
    pitch: h.pitch ?? 0,
    throttle: h.throttle ?? 0,
    climb: h.climb_rate ?? 0,
  }));

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-100">Real-Time Telemetry</h1>
          <p className="text-sm text-slate-400 mt-1">Live sensor data streams from fleet vehicles</p>
        </div>
        <div className="flex items-center gap-2">
          <Activity className="w-4 h-4 text-emerald-400 animate-pulse" />
          <span className="text-sm text-emerald-400">Live</span>
        </div>
      </div>

      {/* Vehicle Selector */}
      <div className="flex gap-2 overflow-x-auto pb-2">
        {vehicles.map((v) => (
          <button
            key={v.id}
            onClick={() => setSelectedId(v.id)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg border text-sm font-medium whitespace-nowrap transition-all ${
              selectedId === v.id
                ? 'bg-blue-600/20 border-blue-500/30 text-blue-400'
                : 'bg-slate-800 border-slate-700 text-slate-400 hover:bg-slate-700'
            }`}
          >
            <StatusIndicator status={connectionStatus[v.id] || 'disconnected'} size="sm" />
            {v.name}
          </button>
        ))}
      </div>

      {/* Live Values Strip */}
      {t && (
        <div className="grid grid-cols-3 sm:grid-cols-4 lg:grid-cols-8 gap-3">
          {[
            { label: 'ALT', value: `${(t.altitude ?? 0).toFixed(1)}m`, color: 'text-blue-400' },
            { label: 'SPD', value: `${(t.groundspeed ?? 0).toFixed(1)}m/s`, color: 'text-cyan-400' },
            { label: 'BAT', value: `${Math.round(t.battery ?? 0)}%`, color: (t.battery ?? 0) > 50 ? 'text-emerald-400' : 'text-red-400' },
            { label: 'HDG', value: `${Math.round(t.heading ?? 0)}°`, color: 'text-amber-400' },
            { label: 'THR', value: `${Math.round(t.throttle ?? 0)}%`, color: 'text-purple-400' },
            { label: 'VS', value: `${(t.climb_rate ?? 0).toFixed(1)}m/s`, color: 'text-emerald-400' },
            { label: 'SAT', value: `${t.satellites ?? 0}`, color: 'text-blue-400' },
            { label: 'VOLT', value: `${(t.voltage ?? 0).toFixed(1)}V`, color: 'text-amber-400' },
          ].map(({ label, value, color }) => (
            <div key={label} className="bg-slate-800 border border-slate-700 rounded-lg p-2 text-center">
              <p className="text-[10px] text-slate-500 uppercase tracking-wider">{label}</p>
              <p className={`text-sm font-bold telemetry-value ${color}`}>{value}</p>
            </div>
          ))}
        </div>
      )}

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <TelemetryChart title="Altitude" data={chartData} dataKey="altitude" color="#3b82f6" unit="m" />
        <TelemetryChart title="Ground Speed" data={chartData} dataKey="speed" color="#06b6d4" unit="m/s" />
        <TelemetryChart title="Battery" data={chartData} dataKey="battery" color="#22c55e" unit="%" />
        <TelemetryChart title="Heading" data={chartData} dataKey="heading" color="#f59e0b" unit="°" />
        <TelemetryChart title="Throttle" data={chartData} dataKey="throttle" color="#8b5cf6" unit="%" />
        <TelemetryChart title="Climb Rate" data={chartData} dataKey="climb" color="#22c55e" unit="m/s" />
      </div>
    </div>
  );
}

