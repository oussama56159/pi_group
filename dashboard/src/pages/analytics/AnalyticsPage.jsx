import {
  BarChart, Bar, LineChart, Line, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, AreaChart, Area, Legend,
} from 'recharts';
import Card, { CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import Badge from '@/components/ui/Badge';
import { mockAnalytics } from '@/lib/mock/mockData';
import { Clock, TrendingUp, Target, AlertTriangle } from 'lucide-react';

const chartTooltipStyle = { backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: 8, color: '#f1f5f9' };
const COLORS = ['#3b82f6', '#22c55e', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4'];

function StatCard({ icon: Icon, label, value, sub, color = 'blue' }) {
  const colors = { blue: 'from-blue-500 to-blue-600', green: 'from-emerald-500 to-emerald-600', amber: 'from-amber-500 to-amber-600', purple: 'from-purple-500 to-purple-600' };
  return (
    <Card>
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-slate-400">{label}</p>
          <p className="text-2xl font-bold text-slate-100 mt-1">{value}</p>
          {sub && <p className="text-xs text-slate-500 mt-1">{sub}</p>}
        </div>
        <div className={`p-2.5 rounded-xl bg-gradient-to-br ${colors[color]} shadow-lg`}>
          <Icon className="w-5 h-5 text-white" />
        </div>
      </div>
    </Card>
  );
}

export default function AnalyticsPage() {
  const a = mockAnalytics;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-100">Analytics Dashboard</h1>
        <p className="text-sm text-slate-400 mt-1">Fleet performance metrics and operational insights</p>
      </div>

      {/* KPIs */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <StatCard icon={Clock} label="Total Flight Hours" value={a.totalFlightHours.toLocaleString()} sub="All time" color="blue" />
        <StatCard icon={Target} label="Total Missions" value={a.totalMissions} sub={`${a.successRate}% success rate`} color="green" />
        <StatCard icon={TrendingUp} label="Avg Flight Time" value={`${a.avgFlightTime} min`} sub="Per mission" color="purple" />
        <StatCard icon={AlertTriangle} label="Incidents" value={a.incidentsThisMonth} sub="This month" color="amber" />
      </div>

      {/* Charts Row 1 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader><CardTitle subtitle="Daily operational statistics">Flight Hours Trend</CardTitle></CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={280}>
              <AreaChart data={a.flightHoursHistory}>
                <defs>
                  <linearGradient id="gradHours" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" />
                <XAxis dataKey="date" tick={{ fill: '#64748b', fontSize: 10 }} tickFormatter={(v) => v.slice(5)} axisLine={{ stroke: '#334155' }} />
                <YAxis tick={{ fill: '#64748b', fontSize: 10 }} axisLine={{ stroke: '#334155' }} />
                <Tooltip contentStyle={chartTooltipStyle} />
                <Area type="monotone" dataKey="hours" stroke="#3b82f6" fill="url(#gradHours)" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle subtitle="Fleet status breakdown">Status Distribution</CardTitle></CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie data={a.statusDistribution} cx="50%" cy="50%" innerRadius={60} outerRadius={100} paddingAngle={4} dataKey="value" nameKey="name">
                  {a.statusDistribution.map((entry, i) => <Cell key={i} fill={entry.color} stroke="none" />)}
                </Pie>
                <Tooltip contentStyle={chartTooltipStyle} />
                <Legend wrapperStyle={{ fontSize: 12, color: '#94a3b8' }} />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      {/* Vehicle Utilization */}
      <Card>
        <CardHeader><CardTitle subtitle="Hours and missions per vehicle">Vehicle Utilization</CardTitle></CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={a.vehicleUtilization}>
              <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" />
              <XAxis dataKey="name" tick={{ fill: '#64748b', fontSize: 11 }} axisLine={{ stroke: '#334155' }} />
              <YAxis tick={{ fill: '#64748b', fontSize: 10 }} axisLine={{ stroke: '#334155' }} />
              <Tooltip contentStyle={chartTooltipStyle} />
              <Legend wrapperStyle={{ fontSize: 12, color: '#94a3b8' }} />
              <Bar dataKey="hours" fill="#3b82f6" radius={[4, 4, 0, 0]} name="Flight Hours" />
              <Bar dataKey="missions" fill="#8b5cf6" radius={[4, 4, 0, 0]} name="Missions" />
            </BarChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Missions per Day */}
      <Card>
        <CardHeader><CardTitle subtitle="Missions completed daily">Daily Mission Count</CardTitle></CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={240}>
            <LineChart data={a.flightHoursHistory}>
              <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" />
              <XAxis dataKey="date" tick={{ fill: '#64748b', fontSize: 10 }} tickFormatter={(v) => v.slice(5)} axisLine={{ stroke: '#334155' }} />
              <YAxis tick={{ fill: '#64748b', fontSize: 10 }} axisLine={{ stroke: '#334155' }} />
              <Tooltip contentStyle={chartTooltipStyle} />
              <Line type="monotone" dataKey="missions" stroke="#22c55e" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>
    </div>
  );
}

