import { useEffect, useMemo, useState } from 'react';
import { Plus, Trash2, GripVertical, Upload, Save, RotateCcw, Copy, Pencil, Link2, Unlink } from 'lucide-react';
import { MapContainer, TileLayer, Marker, Polyline, useMapEvent } from 'react-leaflet';
import L from 'leaflet';
import Card, { CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import ActionButton from '@/components/actions/ActionButton';
import Badge from '@/components/ui/Badge';
import Input from '@/components/ui/Input';
import Modal from '@/components/ui/Modal';
import { useMissionStore } from '@/stores/missionStore';
import { useFleetStore } from '@/stores/fleetStore';
import { MAP_CONFIG } from '@/config/constants';
import 'leaflet/dist/leaflet.css';

function createWaypointIcon(index) {
  return L.divIcon({
    className: 'aero-waypoint-icon',
    html: `<div style="width:26px;height:26px;border-radius:9999px;background:#3b82f6;border:2px solid rgba(15,23,42,0.9);color:#fff;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:12px;">${index + 1}</div>`,
    iconSize: [26, 26],
    iconAnchor: [13, 13],
  });
}

function MapClickToAdd({ onAdd }) {
  useMapEvent('click', (e) => {
    onAdd({ lat: e.latlng.lat, lng: e.latlng.lng });
  });
  return null;
}

function WaypointRow({ wp, index, onUpdate, onRemove }) {
  return (
    <div className="flex items-center gap-2 p-2 bg-slate-700/30 rounded-lg group">
      <GripVertical className="w-4 h-4 text-slate-600 cursor-grab" />
      <div className="w-6 h-6 rounded-full bg-blue-600 flex items-center justify-center text-xs font-bold text-white">{index + 1}</div>
      <div className="flex-1 grid grid-cols-3 gap-2">
        <input className="bg-slate-800 border border-slate-700 rounded px-2 py-1 text-xs text-slate-200" placeholder="Lat"
          value={wp.lat} onChange={(e) => onUpdate(wp.id, { lat: parseFloat(e.target.value) || 0 })} />
        <input className="bg-slate-800 border border-slate-700 rounded px-2 py-1 text-xs text-slate-200" placeholder="Lng"
          value={wp.lng} onChange={(e) => onUpdate(wp.id, { lng: parseFloat(e.target.value) || 0 })} />
        <input className="bg-slate-800 border border-slate-700 rounded px-2 py-1 text-xs text-slate-200" placeholder="Alt"
          value={wp.alt} onChange={(e) => onUpdate(wp.id, { alt: parseFloat(e.target.value) || 0 })} />
      </div>
      <select className="bg-slate-800 border border-slate-700 rounded px-2 py-1 text-xs text-slate-300" value={wp.command || 'NAV_WAYPOINT'}
        onChange={(e) => onUpdate(wp.id, { command: e.target.value })}>
        <option value="NAV_WAYPOINT">Waypoint</option>
        <option value="NAV_LOITER_TIME">Loiter</option>
        <option value="NAV_RETURN_TO_LAUNCH">RTL</option>
        <option value="NAV_LAND">Land</option>
        <option value="NAV_TAKEOFF">Takeoff</option>
        <option value="DO_SET_CAM_TRIGG_DIST">Camera Trigger</option>
      </select>
      <button
        onClick={() => onRemove(wp.id)}
        title="Remove waypoint (Shift+Click on toolbar actions for details)"
        className="p-1 text-slate-500 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity"
      >
        <Trash2 className="w-4 h-4" />
      </button>
    </div>
  );
}

export default function MissionPlannerPage() {
  const missions = useMissionStore((s) => s.missions);
  const selectedMissionId = useMissionStore((s) => s.selectedMissionId);
  const isLoading = useMissionStore((s) => s.isLoading);
  const fetchMissions = useMissionStore((s) => s.fetchMissions);
  const fetchMission = useMissionStore((s) => s.fetchMission);
  const createMission = useMissionStore((s) => s.createMission);
  const updateMission = useMissionStore((s) => s.updateMission);
  const deleteMission = useMissionStore((s) => s.deleteMission);
  const assignMission = useMissionStore((s) => s.assignMission);
  const unassignMission = useMissionStore((s) => s.unassignMission);
  const selectMission = useMissionStore((s) => s.selectMission);
  const waypoints = useMissionStore((s) => s.waypoints);
  const addWaypoint = useMissionStore((s) => s.addWaypoint);
  const updateWaypoint = useMissionStore((s) => s.updateWaypoint);
  const removeWaypoint = useMissionStore((s) => s.removeWaypoint);
  const clearWaypoints = useMissionStore((s) => s.clearWaypoints);
  const vehicles = useFleetStore((s) => s.vehicles);
  const fetchVehicles = useFleetStore((s) => s.fetchVehicles);
  const fleets = useFleetStore((s) => s.fleets);
  const fetchFleets = useFleetStore((s) => s.fetchFleets);
  const [showNewMission, setShowNewMission] = useState(false);
  const [showEditMission, setShowEditMission] = useState(false);
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [editingMission, setEditingMission] = useState(null);
  const [assigningMission, setAssigningMission] = useState(null);
  const [missionName, setMissionName] = useState('');
  const [selectedVehicle, setSelectedVehicle] = useState('');
  const [assignVehicleIds, setAssignVehicleIds] = useState([]);
  const [missionType, setMissionType] = useState('survey');
  const [searchQuery, setSearchQuery] = useState('');
  const [vehicleFilter, setVehicleFilter] = useState('');
  const [fleetFilter, setFleetFilter] = useState('');

  useEffect(() => {
    fetchMissions();
    fetchVehicles();
    fetchFleets();
  }, [fetchMissions, fetchVehicles, fetchFleets]);

  const handleAddWaypoint = () => {
    addWaypoint({ lat: 36.8065 + (Math.random() - 0.5) * 0.02, lng: 10.1815 + (Math.random() - 0.5) * 0.02, alt: 100, command: 'NAV_WAYPOINT' });
  };

  const path = useMemo(() => waypoints.map((wp) => [wp.lat, wp.lng]), [waypoints]);

  const filteredMissions = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    const vehicleMap = new Map(vehicles.map((v) => [v.id, v]));
    return missions.filter((m) => {
      const matchesQuery = !q || m.name?.toLowerCase().includes(q) || m.type?.toLowerCase().includes(q);
      const assigned = m.assigned_vehicle_ids || m.assignments?.filter((a) => a.active).map((a) => a.vehicle_id) || [];
      const matchesVehicle = !vehicleFilter || assigned.includes(vehicleFilter) || m.vehicle_id === vehicleFilter;
      const assignedFleetIds = assigned
        .map((id) => vehicleMap.get(id)?.fleet_id)
        .filter(Boolean);
      const matchesFleet = !fleetFilter || assignedFleetIds.includes(fleetFilter);
      return matchesQuery && matchesVehicle && matchesFleet;
    });
  }, [missions, searchQuery, vehicleFilter, fleetFilter, vehicles]);

  const openCreateModal = () => {
    setEditingMission(null);
    setMissionName('');
    setMissionType('survey');
    setSelectedVehicle('');
    setShowNewMission(true);
  };

  const openEditModal = (mission) => {
    setEditingMission(mission);
    setMissionName(mission.name || '');
    setMissionType(mission.type || 'survey');
    setSelectedVehicle(mission.vehicle_id || mission.assigned_vehicle_id || '');
    setShowEditMission(true);
  };

  const openAssignModal = (mission) => {
    setAssigningMission(mission);
    const fallback = (mission.assignments || []).filter((a) => a.active).map((a) => a.vehicle_id);
    setAssignVehicleIds(mission.assigned_vehicle_ids || fallback);
    setShowAssignModal(true);
  };

  const handleAssignMission = async () => {
    if (!assigningMission) return;
    if (assignVehicleIds.length === 0) {
      const fallback = (assigningMission.assignments || []).filter((a) => a.active).map((a) => a.vehicle_id);
      await unassignMission(assigningMission.id, assigningMission.assigned_vehicle_ids || fallback);
      setShowAssignModal(false);
      return;
    }
    await assignMission(assigningMission.id, assignVehicleIds, { replaceExisting: true });
    setShowAssignModal(false);
  };

  const handleSaveMission = async () => {
    if (!missionName.trim()) return;
    const payload = {
      name: missionName.trim(),
      type: missionType,
      vehicle_id: selectedVehicle || null,
      waypoints,
    };
    if (editingMission) {
      await updateMission(editingMission.id, payload);
      setShowEditMission(false);
    } else {
      const created = await createMission(payload);
      selectMission(created.id);
      setShowNewMission(false);
    }
  };

  const handleSelectMission = async (missionId) => {
    selectMission(missionId);
    await fetchMission(missionId);
  };

  const handleDeleteMission = async (missionId) => {
    await deleteMission(missionId);
    if (selectedMissionId === missionId) {
      selectMission(null);
      clearWaypoints();
    }
  };

  const handleDuplicateMission = async (mission) => {
    const payload = {
      name: `${mission.name} Copy`,
      type: mission.type || 'Survey',
      vehicle_id: mission.vehicle_id || mission.assigned_vehicle_id || null,
      waypoints: mission.waypoints || [],
    };
    await createMission(payload);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-100">Mission Planner</h1>
          <p className="text-sm text-slate-400 mt-1">Plan, upload and manage autonomous missions</p>
        </div>
        <ActionButton actionId="mission.create" icon={Plus} onAction={openCreateModal}>
          New Mission
        </ActionButton>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Mission List */}
        <Card className="lg:col-span-1">
          <CardHeader>
            <CardTitle subtitle={`${missions.length} missions`}>Missions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="space-y-2">
              <Input placeholder="Search missions" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} />
              <select
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-300"
                value={vehicleFilter}
                onChange={(e) => setVehicleFilter(e.target.value)}
              >
                <option value="">All vehicles</option>
                {vehicles.map((v) => (
                  <option key={v.id} value={v.id}>{v.name} ({v.callsign})</option>
                ))}
              </select>
              <select
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-300"
                value={fleetFilter}
                onChange={(e) => setFleetFilter(e.target.value)}
              >
                <option value="">All fleets</option>
                {fleets.map((f) => (
                  <option key={f.id} value={f.id}>{f.name}</option>
                ))}
              </select>
            </div>
            <div className="space-y-2 max-h-[520px] overflow-y-auto">
              {filteredMissions.map((m) => (
                (() => {
                  const assignedIds = m.assigned_vehicle_ids || (m.assignments || []).filter((a) => a.active).map((a) => a.vehicle_id) || [];
                  return (
                <div
                  key={m.id}
                  className={`p-3 rounded-lg border transition-colors ${
                    selectedMissionId === m.id
                      ? 'bg-blue-600/10 border-blue-500/40'
                      : 'bg-slate-700/30 border-slate-700 hover:bg-slate-700/50'
                  }`}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="text-sm font-medium text-slate-200">{m.name}</p>
                      <p className="text-xs text-slate-500">{m.waypoints?.length || 0} waypoints • {m.type}</p>
                    </div>
                    <Badge color={m.status === 'in_progress' ? 'blue' : m.status === 'completed' ? 'green' : 'gray'}>{m.status}</Badge>
                  </div>
                  <div className="mt-3 flex flex-wrap gap-2">
                    <ActionButton actionId="mission.load" size="xs" variant="secondary" onAction={() => handleSelectMission(m.id)}>
                      Load
                    </ActionButton>
                    <ActionButton actionId="mission.update" size="xs" variant="ghost" icon={Pencil} onAction={() => openEditModal(m)}>
                      Edit
                    </ActionButton>
                    <ActionButton actionId="mission.assign" size="xs" variant="ghost" icon={Link2} onAction={() => openAssignModal(m)}>
                      Assign
                    </ActionButton>
                    <ActionButton actionId="mission.duplicate" size="xs" variant="ghost" icon={Copy} onAction={() => handleDuplicateMission(m)}>
                      Duplicate
                    </ActionButton>
                    <ActionButton actionId="mission.delete" size="xs" variant="ghost" icon={Trash2} onAction={() => handleDeleteMission(m.id)}>
                      Delete
                    </ActionButton>
                  </div>
                  {!!assignedIds.length && (
                    <div className="mt-2 flex flex-wrap gap-1">
                      {assignedIds.slice(0, 3).map((id) => {
                        const v = vehicles.find((veh) => veh.id === id);
                        if (!v) return null;
                        return (
                          <span key={id} className="px-2 py-0.5 text-[10px] rounded-full bg-slate-700 text-slate-300">
                            {v.callsign || v.name}
                          </span>
                        );
                      })}
                      {assignedIds.length > 3 && (
                        <span className="px-2 py-0.5 text-[10px] rounded-full bg-slate-700 text-slate-400">
                          +{assignedIds.length - 3}
                        </span>
                      )}
                    </div>
                  )}
                  {m.status === 'in_progress' && (
                    <div className="mt-2 h-1.5 bg-slate-700 rounded-full overflow-hidden">
                      <div className="h-full bg-blue-500 rounded-full transition-all" style={{ width: `${m.progress}%` }} />
                    </div>
                  )}
                </div>
                  );
                })()
              ))}
              {filteredMissions.length === 0 && (
                <div className="p-6 text-center text-sm text-slate-500 border border-dashed border-slate-700 rounded-lg">
                  {isLoading ? 'Loading missions...' : 'No missions match your search.'}
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Planner */}
        <Card className="lg:col-span-2">
          <CardHeader action={
            <div className="flex gap-2">
              <ActionButton actionId="mission.draft.clear" size="xs" variant="ghost" icon={RotateCcw} onAction={clearWaypoints}>
                Clear
              </ActionButton>
              <ActionButton actionId="mission.draft.save" size="xs" variant="secondary" icon={Save} onAction={() => {}} disabled={waypoints.length === 0} disabledReason="No waypoints to save">
                Save
              </ActionButton>
              <ActionButton actionId="mission.upload" size="xs" icon={Upload} onAction={() => {}} disabled={waypoints.length === 0} disabledReason="No waypoints to upload">
                Upload
              </ActionButton>
            </div>
          }>
            <CardTitle subtitle={`${waypoints.length} waypoints defined`}>Waypoint Editor</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="rounded-xl overflow-hidden border border-slate-700 mb-4">
              <div className="h-[360px]">
                <MapContainer
                  center={MAP_CONFIG.DEFAULT_CENTER}
                  zoom={MAP_CONFIG.DEFAULT_ZOOM}
                  className="w-full h-full"
                  style={{ background: '#0f172a' }}
                  zoomControl={false}
                  attributionControl={false}
                >
                  <TileLayer
                    url={MAP_CONFIG.TILE_LAYER}
                    attribution={MAP_CONFIG.TILE_ATTRIBUTION}
                    maxZoom={MAP_CONFIG.MAX_ZOOM}
                  />
                  <MapClickToAdd
                    onAdd={({ lat, lng }) =>
                      addWaypoint({ lat, lng, alt: 100, command: 'NAV_WAYPOINT' })
                    }
                  />
                  {path.length > 1 && <Polyline positions={path} color="#3b82f6" weight={2} dashArray="8,8" />}
                  {waypoints.map((wp, i) => (
                    <Marker
                      key={wp.id}
                      position={[wp.lat, wp.lng]}
                      icon={createWaypointIcon(i)}
                      draggable
                      eventHandlers={{
                        dragend: (ev) => {
                          const p = ev.target.getLatLng();
                          updateWaypoint(wp.id, { lat: p.lat, lng: p.lng });
                        },
                      }}
                    />
                  ))}
                </MapContainer>
              </div>
              <div className="px-3 py-2 text-xs text-slate-400 bg-slate-900/40 border-t border-slate-700">
                Click the map to add a waypoint. Drag markers to adjust.
              </div>
            </div>

            {/* Header */}
            <div className="flex items-center gap-2 px-2 py-1 text-[10px] uppercase tracking-wider text-slate-500 mb-2">
              <span className="w-4" /><span className="w-6" />
              <div className="flex-1 grid grid-cols-3 gap-2"><span>Latitude</span><span>Longitude</span><span>Altitude (m)</span></div>
              <span className="w-24">Command</span><span className="w-6" />
            </div>
            <div className="space-y-1.5 max-h-[400px] overflow-y-auto">
              {waypoints.map((wp, i) => (
                <WaypointRow key={wp.id} wp={wp} index={i} onUpdate={updateWaypoint} onRemove={removeWaypoint} />
              ))}
            </div>
            <ActionButton
              actionId="mission.waypoint.add"
              onAction={handleAddWaypoint}
              fullWidth
              variant="outline"
              className="mt-3 w-full border-2 border-dashed border-slate-700 hover:border-blue-500/30"
              icon={Plus}
            >
              Add Waypoint
            </ActionButton>
          </CardContent>
        </Card>
      </div>

      {/* New Mission Modal */}
      <Modal isOpen={showNewMission} onClose={() => setShowNewMission(false)} title="Create New Mission" size="md"
        footer={<>
          <ActionButton actionId="nav.goto.dashboard" variant="secondary" onAction={() => setShowNewMission(false)}>Cancel</ActionButton>
          <ActionButton actionId="mission.create" onAction={handleSaveMission}>Create Mission</ActionButton>
        </>}>
        <div className="space-y-4">
          <Input label="Mission Name" placeholder="e.g., Perimeter Survey Alpha" value={missionName} onChange={(e) => setMissionName(e.target.value)} />
          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1.5">Assign Vehicle</label>
            <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2.5 text-sm text-slate-300" value={selectedVehicle} onChange={(e) => setSelectedVehicle(e.target.value)}>
              <option value="">Unassigned</option>
              {vehicles.map((v) => <option key={v.id} value={v.id}>{v.name} ({v.callsign})</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1.5">Mission Type</label>
            <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2.5 text-sm text-slate-300" value={missionType} onChange={(e) => setMissionType(e.target.value)}>
              <option value="waypoint">Waypoint</option>
              <option value="survey">Survey</option>
              <option value="corridor">Corridor</option>
              <option value="orbit">Orbit</option>
            </select>
          </div>
        </div>
      </Modal>

      <Modal isOpen={showEditMission} onClose={() => setShowEditMission(false)} title="Edit Mission" size="md"
        footer={<>
          <ActionButton actionId="nav.goto.dashboard" variant="secondary" onAction={() => setShowEditMission(false)}>Cancel</ActionButton>
          <ActionButton actionId="mission.update" onAction={handleSaveMission}>Save Changes</ActionButton>
        </>}>
        <div className="space-y-4">
          <Input label="Mission Name" placeholder="e.g., Perimeter Survey Alpha" value={missionName} onChange={(e) => setMissionName(e.target.value)} />
          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1.5">Assign Vehicle</label>
            <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2.5 text-sm text-slate-300" value={selectedVehicle} onChange={(e) => setSelectedVehicle(e.target.value)}>
              <option value="">Unassigned</option>
              {vehicles.map((v) => <option key={v.id} value={v.id}>{v.name} ({v.callsign})</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1.5">Mission Type</label>
            <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2.5 text-sm text-slate-300" value={missionType} onChange={(e) => setMissionType(e.target.value)}>
              <option value="waypoint">Waypoint</option>
              <option value="survey">Survey</option>
              <option value="corridor">Corridor</option>
              <option value="orbit">Orbit</option>
            </select>
          </div>
          {editingMission && (
            <div className="text-xs text-slate-500">
              Editing mission: <span className="text-slate-300">{editingMission.name}</span>
            </div>
          )}
        </div>
      </Modal>

      <Modal
        isOpen={showAssignModal}
        onClose={() => setShowAssignModal(false)}
        title="Assign Mission to Vehicles"
        size="md"
        footer={
          <>
            <ActionButton actionId="nav.goto.dashboard" variant="secondary" onAction={() => setShowAssignModal(false)}>Cancel</ActionButton>
            <ActionButton actionId="mission.assign" onAction={handleAssignMission}>
              {assignVehicleIds.length ? 'Save Assignment' : 'Unassign All'}
            </ActionButton>
          </>
        }
      >
        <div className="space-y-3">
          <p className="text-sm text-slate-400">Select one or more vehicles to bind this mission.</p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
            {vehicles.map((v) => (
              <button
                key={v.id}
                onClick={() =>
                  setAssignVehicleIds((prev) =>
                    prev.includes(v.id) ? prev.filter((id) => id !== v.id) : [...prev, v.id]
                  )
                }
                className={`p-3 rounded-lg border text-sm text-left transition-colors ${
                  assignVehicleIds.includes(v.id)
                    ? 'border-blue-500/50 bg-blue-600/10 text-blue-200'
                    : 'border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700/40'
                }`}
              >
                <div className="font-medium">{v.name}</div>
                <div className="text-xs text-slate-500">{v.callsign}</div>
              </button>
            ))}
          </div>
          <div className="flex items-center gap-2 text-xs text-slate-500">
            <Unlink className="w-4 h-4" />
            Clear all selections to unassign the mission from all vehicles.
          </div>
        </div>
      </Modal>
    </div>
  );
}

