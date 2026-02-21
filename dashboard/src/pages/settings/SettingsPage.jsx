import { useState } from 'react';
import { Save, User, Bell, Map, Key, Palette, Monitor } from 'lucide-react';
import Card, { CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import Button from '@/components/ui/Button';
import Input from '@/components/ui/Input';
import { useAuthStore } from '@/stores/authStore';

function ToggleSwitch({ enabled, onChange, label, description }) {
  return (
    <div className="flex items-center justify-between py-3">
      <div>
        <p className="text-sm text-slate-200">{label}</p>
        {description && <p className="text-xs text-slate-500 mt-0.5">{description}</p>}
      </div>
      <button onClick={() => onChange(!enabled)}
        className={`relative w-11 h-6 rounded-full transition-colors ${enabled ? 'bg-blue-600' : 'bg-slate-700'}`}>
        <span className={`absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${enabled ? 'translate-x-5' : ''}`} />
      </button>
    </div>
  );
}

export default function SettingsPage() {
  const user = useAuthStore((s) => s.user);
  const [activeSection, setActiveSection] = useState('profile');
  const [notifications, setNotifications] = useState({
    criticalAlerts: true, warnings: true, missionUpdates: true, systemEmails: false, sound: true,
  });
  const [mapPrefs, setMapPrefs] = useState({
    darkTiles: true, showLabels: true, autoCenter: true, clusterMarkers: false, show3D: false,
  });
  const [telemetryPrefs, setTelemetryPrefs] = useState({
    highRate: false, showHistory: true, audioAlerts: true,
  });

  const sections = [
    { id: 'profile', label: 'Profile', icon: User },
    { id: 'notifications', label: 'Notifications', icon: Bell },
    { id: 'map', label: 'Map & Display', icon: Map },
    { id: 'telemetry', label: 'Telemetry', icon: Monitor },
    { id: 'api', label: 'API Keys', icon: Key },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-100">Settings</h1>
        <p className="text-sm text-slate-400 mt-1">Manage your preferences and configuration</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Sidebar */}
        <div className="space-y-1">
          {sections.map((s) => {
            const Icon = s.icon;
            return (
              <button key={s.id} onClick={() => setActiveSection(s.id)}
                className={`w-full flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm font-medium transition-all ${
                  activeSection === s.id ? 'bg-blue-600/20 text-blue-400 border border-blue-500/20' : 'text-slate-400 hover:bg-slate-800 border border-transparent'
                }`}>
                <Icon className="w-4 h-4" />{s.label}
              </button>
            );
          })}
        </div>

        {/* Content */}
        <div className="lg:col-span-3">
          {activeSection === 'profile' && (
            <Card>
              <CardHeader><CardTitle subtitle="Your personal information">Profile Settings</CardTitle></CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center gap-4 mb-6">
                  <div className="w-16 h-16 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white text-2xl font-bold">
                    {user?.name?.charAt(0) || 'U'}
                  </div>
                  <div><Button variant="secondary" size="sm">Change Avatar</Button></div>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <Input label="Full Name" defaultValue={user?.name || ''} />
                  <Input label="Email" type="email" defaultValue={user?.email || ''} />
                  <Input label="Organization" defaultValue={user?.organization || 'AeroCommand HQ'} />
                  <Input label="Role" defaultValue={user?.role?.replace('_', ' ') || ''} disabled />
                </div>
                <div className="flex justify-end gap-2 pt-4 border-t border-slate-700">
                  <Button variant="secondary">Cancel</Button>
                  <Button icon={Save}>Save Changes</Button>
                </div>
              </CardContent>
            </Card>
          )}

          {activeSection === 'notifications' && (
            <Card>
              <CardHeader><CardTitle subtitle="Configure alert delivery">Notification Preferences</CardTitle></CardHeader>
              <CardContent className="divide-y divide-slate-700/50">
                <ToggleSwitch label="Critical Alerts" description="Immediate notification for critical system events"
                  enabled={notifications.criticalAlerts} onChange={(v) => setNotifications((p) => ({ ...p, criticalAlerts: v }))} />
                <ToggleSwitch label="Warnings" description="Battery low, GPS signal loss, geofence breach"
                  enabled={notifications.warnings} onChange={(v) => setNotifications((p) => ({ ...p, warnings: v }))} />
                <ToggleSwitch label="Mission Updates" description="Mission start, completion, waypoint reached"
                  enabled={notifications.missionUpdates} onChange={(v) => setNotifications((p) => ({ ...p, missionUpdates: v }))} />
                <ToggleSwitch label="Email Notifications" description="Send alerts via email"
                  enabled={notifications.systemEmails} onChange={(v) => setNotifications((p) => ({ ...p, systemEmails: v }))} />
                <ToggleSwitch label="Sound Alerts" description="Play audio for critical events"
                  enabled={notifications.sound} onChange={(v) => setNotifications((p) => ({ ...p, sound: v }))} />
              </CardContent>
            </Card>
          )}

          {activeSection === 'map' && (
            <Card>
              <CardHeader><CardTitle subtitle="Map visualization preferences">Map & Display</CardTitle></CardHeader>
              <CardContent className="divide-y divide-slate-700/50">
                <ToggleSwitch label="Dark Map Tiles" description="Use dark-themed map base layer"
                  enabled={mapPrefs.darkTiles} onChange={(v) => setMapPrefs((p) => ({ ...p, darkTiles: v }))} />
                <ToggleSwitch label="Show Labels" description="Display vehicle names on map"
                  enabled={mapPrefs.showLabels} onChange={(v) => setMapPrefs((p) => ({ ...p, showLabels: v }))} />
                <ToggleSwitch label="Auto-center on Active" description="Center map on active vehicle"
                  enabled={mapPrefs.autoCenter} onChange={(v) => setMapPrefs((p) => ({ ...p, autoCenter: v }))} />
                <ToggleSwitch label="Cluster Markers" description="Group nearby vehicles at low zoom"
                  enabled={mapPrefs.clusterMarkers} onChange={(v) => setMapPrefs((p) => ({ ...p, clusterMarkers: v }))} />
              </CardContent>
            </Card>
          )}

          {activeSection === 'telemetry' && (
            <Card>
              <CardHeader><CardTitle subtitle="Telemetry stream settings">Telemetry Configuration</CardTitle></CardHeader>
              <CardContent className="divide-y divide-slate-700/50">
                <ToggleSwitch label="High-Rate Telemetry" description="50Hz attitude data (higher bandwidth)"
                  enabled={telemetryPrefs.highRate} onChange={(v) => setTelemetryPrefs((p) => ({ ...p, highRate: v }))} />
                <ToggleSwitch label="Show History Charts" description="Display telemetry trend charts"
                  enabled={telemetryPrefs.showHistory} onChange={(v) => setTelemetryPrefs((p) => ({ ...p, showHistory: v }))} />
                <ToggleSwitch label="Audio Alerts" description="Sound on critical telemetry thresholds"
                  enabled={telemetryPrefs.audioAlerts} onChange={(v) => setTelemetryPrefs((p) => ({ ...p, audioAlerts: v }))} />
              </CardContent>
            </Card>
          )}

          {activeSection === 'api' && (
            <Card>
              <CardHeader action={<Button size="sm" icon={Key}>Generate Key</Button>}>
                <CardTitle subtitle="Manage API access tokens">API Keys</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="p-4 bg-slate-700/20 border border-slate-700 rounded-lg">
                  <div className="flex items-center justify-between mb-2">
                    <p className="text-sm font-medium text-slate-200">Production API Key</p>
                    <Badge color="green">Active</Badge>
                  </div>
                  <code className="text-xs text-slate-400 font-mono bg-slate-800 px-3 py-1.5 rounded block">
                    aero_pk_live_••••••••••••••••••••••••
                  </code>
                  <p className="text-xs text-slate-500 mt-2">Created Feb 1, 2026 • Last used 2 hours ago</p>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}

