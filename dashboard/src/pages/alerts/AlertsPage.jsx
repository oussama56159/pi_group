import { useState } from 'react';
import { AlertTriangle, CheckCircle, XCircle, Info, Filter, Bell, Trash2, Check } from 'lucide-react';
import Card, { CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import Button from '@/components/ui/Button';
import Badge from '@/components/ui/Badge';
import { useTelemetryStore } from '@/stores/telemetryStore';
import { useFleetStore } from '@/stores/fleetStore';

const severityConfig = {
  critical: { icon: XCircle, color: 'text-red-400', bg: 'bg-red-500/10', border: 'border-red-500/20', badge: 'red' },
  warning: { icon: AlertTriangle, color: 'text-amber-400', bg: 'bg-amber-500/10', border: 'border-amber-500/20', badge: 'amber' },
  info: { icon: Info, color: 'text-blue-400', bg: 'bg-blue-500/10', border: 'border-blue-500/20', badge: 'blue' },
  success: { icon: CheckCircle, color: 'text-emerald-400', bg: 'bg-emerald-500/10', border: 'border-emerald-500/20', badge: 'green' },
};

export default function AlertsPage() {
  const alerts = useTelemetryStore((s) => s.alerts);
  const acknowledgeAlert = useTelemetryStore((s) => s.acknowledgeAlert);
  const dismissAlert = useTelemetryStore((s) => s.dismissAlert);
  const clearAllAlerts = useTelemetryStore((s) => s.clearAllAlerts);
  const markAllRead = useTelemetryStore((s) => s.markAllRead);
  const vehicles = useFleetStore((s) => s.vehicles);
  const [filter, setFilter] = useState('all');

  const filtered = filter === 'all' ? alerts
    : filter === 'unread' ? alerts.filter((a) => !a.acknowledged)
    : alerts.filter((a) => a.severity === filter);

  const critCount = alerts.filter((a) => a.severity === 'critical' && !a.acknowledged).length;
  const warnCount = alerts.filter((a) => a.severity === 'warning' && !a.acknowledged).length;

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-100">Alert Center</h1>
          <p className="text-sm text-slate-400 mt-1">{alerts.length} alerts • {critCount} critical</p>
        </div>
        <div className="flex gap-2">
          <Button variant="secondary" size="sm" icon={Check} onClick={markAllRead}>Mark All Read</Button>
          <Button variant="ghost" size="sm" icon={Trash2} onClick={clearAllAlerts}>Clear All</Button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Critical', count: critCount, color: 'red' },
          { label: 'Warnings', count: warnCount, color: 'amber' },
          { label: 'Total Alerts', count: alerts.length, color: 'blue' },
          { label: 'Acknowledged', count: alerts.filter((a) => a.acknowledged).length, color: 'green' },
        ].map(({ label, count, color }) => (
          <Card key={label}>
            <p className="text-sm text-slate-400">{label}</p>
            <p className={`text-2xl font-bold mt-1 text-${color}-400`}>{count}</p>
          </Card>
        ))}
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2 overflow-x-auto">
        {['all', 'unread', 'critical', 'warning', 'info'].map((f) => (
          <button key={f} onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-all ${
              filter === f ? 'bg-blue-600/20 text-blue-400 border border-blue-500/30' : 'bg-slate-800 text-slate-400 border border-slate-700 hover:bg-slate-700'
            }`}>
            {f.charAt(0).toUpperCase() + f.slice(1)}
          </button>
        ))}
      </div>

      {/* Alert List */}
      <div className="space-y-2">
        {filtered.map((alert) => {
          const config = severityConfig[alert.severity] || severityConfig.info;
          const Icon = config.icon;
          const vehicleName = vehicles.find((v) => v.id === alert.vehicle_id)?.name;
          return (
            <div key={alert.id} className={`flex items-start gap-3 p-4 rounded-xl border ${config.bg} ${config.border} ${alert.acknowledged ? 'opacity-60' : ''}`}>
              <Icon className={`w-5 h-5 mt-0.5 shrink-0 ${config.color}`} />
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <Badge color={config.badge}>{alert.severity}</Badge>
                  {vehicleName && <span className="text-xs text-slate-500">{vehicleName}</span>}
                  {alert.acknowledged && <Badge color="green">ACK</Badge>}
                </div>
                <p className="text-sm text-slate-200">{alert.message}</p>
                <p className="text-xs text-slate-500 mt-1">{new Date(alert.timestamp).toLocaleString()}</p>
              </div>
              <div className="flex gap-1 shrink-0">
                {!alert.acknowledged && (
                  <button onClick={() => acknowledgeAlert(alert.id)} className="p-1.5 rounded-lg text-slate-500 hover:text-emerald-400 hover:bg-slate-700/50" title="Acknowledge">
                    <Check className="w-4 h-4" />
                  </button>
                )}
                <button onClick={() => dismissAlert(alert.id)} className="p-1.5 rounded-lg text-slate-500 hover:text-red-400 hover:bg-slate-700/50" title="Dismiss">
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          );
        })}
        {filtered.length === 0 && (
          <div className="text-center py-16">
            <Bell className="w-12 h-12 text-slate-600 mx-auto mb-3" />
            <p className="text-slate-400">No alerts to display</p>
          </div>
        )}
      </div>
    </div>
  );
}

