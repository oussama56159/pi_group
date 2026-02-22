import { useEffect, useMemo, useState } from 'react';
import { Plus, Search, UserX, Pencil } from 'lucide-react';
import Card, { CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import Button from '@/components/ui/Button';
import Badge from '@/components/ui/Badge';
import Input from '@/components/ui/Input';
import Modal from '@/components/ui/Modal';
import { organizationAPI, userAPI } from '@/lib/api/endpoints';
import { useAuthStore } from '@/stores/authStore';

const roleColors = {
  super_admin: 'purple',
  admin: 'blue',
  pilot: 'cyan',
  operator: 'green',
  viewer: 'gray',
};

const roleLabel = (role) => {
  if (!role) return '';
  if (role === 'super_admin') return 'Dev';
  return role.replaceAll('_', ' ').replace(/\b\w/g, (c) => c.toUpperCase());
};

export default function UsersPage() {
  const currentUser = useAuthStore((s) => s.user);
  const isSuperAdmin = currentUser?.role === 'super_admin';
  const isAdminOrDev = currentUser?.role === 'admin' || currentUser?.role === 'super_admin';
  const [users, setUsers] = useState([]);
  const [organizations, setOrganizations] = useState([]);
  const [orgMap, setOrgMap] = useState({});
  const [orgEdits, setOrgEdits] = useState({});
  const [orgLoading, setOrgLoading] = useState(false);
  const [showAddOrg, setShowAddOrg] = useState(false);
  const [newOrg, setNewOrg] = useState({ name: '', slug: '', expires_at: '' });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [showAddUser, setShowAddUser] = useState(false);
  const [roleFilter, setRoleFilter] = useState('all');
  const [newUser, setNewUser] = useState({
    name: '',
    email: '',
    password: '',
    role: 'viewer',
    organization_id: currentUser?.organization_id || '',
    expires_at: '',
  });
  const [saving, setSaving] = useState(false);
  const [edits, setEdits] = useState({});

  const [showEditUser, setShowEditUser] = useState(false);
  const [editUser, setEditUser] = useState(null);
  const [editForm, setEditForm] = useState({ name: '', email: '', password: '' });

  const loadUsers = async () => {
    setLoading(true);
    setError('');
    try {
      const { data } = await userAPI.list();
      setUsers(data || []);
      const draft = {};
      (data || []).forEach((u) => {
        draft[u.id] = {
          role: u.role,
          is_active: u.is_active,
          organization_id: u.organization_id || '',
          expires_at: u.expires_at ? new Date(u.expires_at).toISOString().slice(0, 16) : '',
        };
      });
      setEdits(draft);
    } catch (err) {
      setError(err?.response?.data?.detail || err?.message || 'Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  useEffect(() => {
    let isMounted = true;
    const loadOrganizations = async () => {
      setOrgLoading(true);
      try {
        const { data } = await organizationAPI.list();
        if (!isMounted) return;
        const orgs = data || [];
        setOrganizations(orgs);
        const map = {};
        const draft = {};
        orgs.forEach((org) => {
          map[org.id] = org.name;
          draft[org.id] = {
            name: org.name,
            slug: org.slug,
            is_active: org.is_active,
            expires_at: org.expires_at ? new Date(org.expires_at).toISOString().slice(0, 16) : '',
          };
        });
        setOrgMap(map);
        setOrgEdits(draft);
      } catch (err) {
        setError(err?.response?.data?.detail || err?.message || 'Failed to load organizations');
      } finally {
        if (isMounted) setOrgLoading(false);
      }
    };
    loadOrganizations();
    return () => { isMounted = false; };
  }, []);

  const filtered = useMemo(() => users.filter((u) => {
    if (roleFilter !== 'all' && u.role !== roleFilter) return false;
    if (search) {
      const s = search.toLowerCase();
      return u.name.toLowerCase().includes(s) || u.email.toLowerCase().includes(s);
    }
    return true;
  }), [users, roleFilter, search]);

  const handleCreateUser = async () => {
    setSaving(true);
    setError('');
    try {
      if (newUser.role === 'admin' && !newUser.organization_id) {
        setError('Please assign an organization for admin user.');
        setSaving(false);
        return;
      }

      const payload = {
        name: newUser.name,
        email: newUser.email,
        password: newUser.password,
        role: newUser.role,
        organization_id: newUser.organization_id || null,
        expires_at: newUser.expires_at ? new Date(newUser.expires_at).toISOString() : null,
      };
      await userAPI.create(payload);
      setShowAddUser(false);
      setNewUser({
        name: '',
        email: '',
        password: '',
        role: 'viewer',
        organization_id: currentUser?.organization_id || '',
        expires_at: '',
      });
      await loadUsers();
    } catch (err) {
      setError(err?.response?.data?.detail || err?.message || 'Failed to create user');
    } finally {
      setSaving(false);
    }
  };

  const handleSave = async (id) => {
    setSaving(true);
    setError('');
    try {
      const update = edits[id] || {};
      if (update.role === 'admin' && !update.organization_id) {
        setError('Admin must have one organization.');
        setSaving(false);
        return;
      }
      await userAPI.update(id, {
        role: update.role,
        is_active: update.is_active,
        organization_id: update.organization_id || null,
        expires_at: update.expires_at ? new Date(update.expires_at).toISOString() : null,
      });
      await loadUsers();
    } catch (err) {
      setError(err?.response?.data?.detail || err?.message || 'Failed to update user');
    } finally {
      setSaving(false);
    }
  };

  const handleDeactivate = async (id) => {
    setSaving(true);
    setError('');
    try {
      await userAPI.deactivate(id);
      await loadUsers();
    } catch (err) {
      setError(err?.response?.data?.detail || err?.message || 'Failed to deactivate user');
    } finally {
      setSaving(false);
    }
  };

  const canManageUser = (targetUser) => {
    if (!isAdminOrDev) return false;
    if (!targetUser) return false;
    if (currentUser?.role === 'super_admin') return true;
    // Admins cannot modify admin-level users.
    return targetUser.role !== 'admin' && targetUser.role !== 'super_admin';
  };

  const openEditUser = (u) => {
    setEditUser(u);
    setEditForm({
      name: u?.name || '',
      email: u?.email || '',
      password: '',
    });
    setShowEditUser(true);
  };

  const handleEditUserSave = async () => {
    if (!editUser) return;
    setSaving(true);
    setError('');
    try {
      const name = editForm.name.trim();
      const email = editForm.email.trim();
      const password = editForm.password;

      await userAPI.update(editUser.id, {
        name,
        email,
      });
      if (password && password.trim().length > 0) {
        await userAPI.updatePassword(editUser.id, password.trim());
      }

      setShowEditUser(false);
      setEditUser(null);
      setEditForm({ name: '', email: '', password: '' });
      await loadUsers();
    } catch (err) {
      setError(err?.response?.data?.detail || err?.message || 'Failed to update user');
    } finally {
      setSaving(false);
    }
  };

  const reloadOrganizations = async () => {
    const { data } = await organizationAPI.list();
    const orgs = data || [];
    setOrganizations(orgs);
    const map = {};
    const draft = {};
    orgs.forEach((org) => {
      map[org.id] = org.name;
      draft[org.id] = {
        name: org.name,
        slug: org.slug,
        is_active: org.is_active,
        expires_at: org.expires_at ? new Date(org.expires_at).toISOString().slice(0, 16) : '',
      };
    });
    setOrgMap(map);
    setOrgEdits(draft);
  };

  const handleCreateOrganization = async () => {
    setSaving(true);
    setError('');
    try {
      await organizationAPI.create({
        name: newOrg.name,
        slug: newOrg.slug,
        expires_at: newOrg.expires_at ? new Date(newOrg.expires_at).toISOString() : null,
      });
      setShowAddOrg(false);
      setNewOrg({ name: '', slug: '', expires_at: '' });
      await reloadOrganizations();
    } catch (err) {
      setError(err?.response?.data?.detail || err?.message || 'Failed to create organization');
    } finally {
      setSaving(false);
    }
  };

  const handleOrganizationSave = async (orgId) => {
    setSaving(true);
    setError('');
    try {
      const update = orgEdits[orgId] || {};
      await organizationAPI.update(orgId, {
        ...update,
        expires_at: update.expires_at ? new Date(update.expires_at).toISOString() : null,
      });
      await reloadOrganizations();
    } catch (err) {
      setError(err?.response?.data?.detail || err?.message || 'Failed to update organization');
    } finally {
      setSaving(false);
    }
  };

  const handleOrganizationDisable = async (orgId) => {
    setSaving(true);
    setError('');
    try {
      await organizationAPI.deactivate(orgId);
      await reloadOrganizations();
    } catch (err) {
      setError(err?.response?.data?.detail || err?.message || 'Failed to disable organization');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-100">User Management</h1>
          <p className="text-sm text-slate-400 mt-1">{users.length} users registered</p>
        </div>
        <Button icon={Plus} onClick={() => setShowAddUser(true)}>Add User</Button>
      </div>

      {error && <div className="text-sm text-red-400">{error}</div>}

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex-1 min-w-[200px] max-w-sm">
          <Input icon={Search} placeholder="Search users..." value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
        <select className="bg-slate-800 border border-slate-700 text-sm text-slate-300 rounded-lg px-3 py-2.5"
          value={roleFilter} onChange={(e) => setRoleFilter(e.target.value)}>
          <option value="all">All Roles</option>
          <option value="super_admin">Dev</option>
          <option value="admin">Admin</option>
          <option value="pilot">Pilot</option>
          <option value="operator">Operator</option>
          <option value="viewer">Viewer</option>
        </select>
      </div>

      {/* Users Table */}
      <Card padding={false}>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-700">
                <th className="text-left text-xs uppercase tracking-wider text-slate-500 px-5 py-3">User</th>
                <th className="text-left text-xs uppercase tracking-wider text-slate-500 px-5 py-3">Role</th>
                <th className="text-left text-xs uppercase tracking-wider text-slate-500 px-5 py-3">Organization</th>
                <th className="text-left text-xs uppercase tracking-wider text-slate-500 px-5 py-3">Status</th>
                <th className="text-left text-xs uppercase tracking-wider text-slate-500 px-5 py-3">Expires</th>
                <th className="text-right text-xs uppercase tracking-wider text-slate-500 px-5 py-3">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr><td colSpan={6} className="px-5 py-4 text-sm text-slate-400">Loading users...</td></tr>
              )}
              {filtered.map((user) => (
                <tr key={user.id} className="border-b border-slate-700/50 hover:bg-slate-700/20 transition-colors">
                  <td className="px-5 py-3">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white text-sm font-bold">
                        {user.name.charAt(0)}
                      </div>
                      <div>
                        <p className="text-sm font-medium text-slate-200">{user.name}</p>
                        <p className="text-xs text-slate-500">{user.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-5 py-3">
                    <select
                      className="bg-slate-800 border border-slate-700 rounded px-2 py-1 text-sm text-slate-200"
                      value={edits[user.id]?.role || user.role}
                      disabled={!canManageUser(user)}
                      onChange={(e) => setEdits((prev) => ({
                        ...prev,
                        [user.id]: { ...prev[user.id], role: e.target.value },
                      }))}
                    >
                      {Object.keys(roleColors).map((role) => (
                        <option key={role} value={role}>{roleLabel(role)}</option>
                      ))}
                    </select>
                  </td>
                  <td className="px-5 py-3">
                    {isSuperAdmin ? (
                      <select
                        className="bg-slate-800 border border-slate-700 rounded px-2 py-1 text-sm text-slate-200 min-w-[180px]"
                        value={edits[user.id]?.organization_id || ''}
                        disabled={!canManageUser(user)}
                        onChange={(e) => setEdits((prev) => ({
                          ...prev,
                          [user.id]: { ...prev[user.id], organization_id: e.target.value },
                        }))}
                      >
                        <option value="">No organization</option>
                        {organizations.map((org) => (
                          <option key={org.id} value={org.id}>{org.name}</option>
                        ))}
                      </select>
                    ) : (
                      <span className="text-sm text-slate-300">{orgMap[user.organization_id] || '—'}</span>
                    )}
                  </td>
                  <td className="px-5 py-3">
                    <label className="inline-flex items-center gap-2 text-sm text-slate-300">
                      <input
                        type="checkbox"
                        className="accent-blue-500"
                        checked={edits[user.id]?.is_active ?? user.is_active}
                        disabled={!canManageUser(user) || user.id === currentUser?.id}
                        onChange={(e) => setEdits((prev) => ({
                          ...prev,
                          [user.id]: { ...prev[user.id], is_active: e.target.checked },
                        }))}
                      />
                      <Badge color={(edits[user.id]?.is_active ?? user.is_active) ? 'green' : 'gray'} dot>
                        {(edits[user.id]?.is_active ?? user.is_active) ? 'active' : 'disabled'}
                      </Badge>
                    </label>
                  </td>
                  <td className="px-5 py-3">
                    <input
                      type="datetime-local"
                      className="bg-slate-800 border border-slate-700 rounded px-2 py-1 text-sm text-slate-200"
                      value={edits[user.id]?.expires_at || ''}
                      disabled={!canManageUser(user)}
                      onChange={(e) => setEdits((prev) => ({
                        ...prev,
                        [user.id]: { ...prev[user.id], expires_at: e.target.value },
                      }))}
                    />
                  </td>
                  <td className="px-5 py-3 text-right">
                    <div className="flex items-center justify-end gap-1">
                      <Button size="sm" variant="secondary" onClick={() => handleSave(user.id)} loading={saving} disabled={!canManageUser(user)}>Save</Button>
                      <button
                        type="button"
                        title="Edit"
                        onClick={() => openEditUser(user)}
                        disabled={!canManageUser(user)}
                        className="p-1.5 rounded-lg text-slate-500 hover:text-slate-200 hover:bg-slate-700/50 disabled:opacity-40 disabled:cursor-not-allowed"
                      >
                        <Pencil className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        title="Delete"
                        onClick={() => handleDeactivate(user.id)}
                        disabled={!canManageUser(user) || user.id === currentUser?.id}
                        className="p-1.5 rounded-lg text-slate-500 hover:text-red-400 hover:bg-slate-700/50 disabled:opacity-40 disabled:cursor-not-allowed"
                      >
                        <UserX className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      {/* Organizations Table */}
      <Card padding={false}>
        <div className="p-4 flex items-center justify-between border-b border-slate-700/50">
          <div>
            <h2 className="text-base font-semibold text-slate-100">Organizations</h2>
            <p className="text-xs text-slate-400 mt-1">Organization management moved here from Admin Panel.</p>
          </div>
          {isSuperAdmin && <Button size="sm" onClick={() => setShowAddOrg(true)}>Add Organization</Button>}
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-700">
                <th className="text-left text-xs uppercase tracking-wider text-slate-500 px-5 py-3">Name</th>
                <th className="text-left text-xs uppercase tracking-wider text-slate-500 px-5 py-3">Slug</th>
                <th className="text-left text-xs uppercase tracking-wider text-slate-500 px-5 py-3">Active</th>
                <th className="text-left text-xs uppercase tracking-wider text-slate-500 px-5 py-3">Expires</th>
                <th className="text-right text-xs uppercase tracking-wider text-slate-500 px-5 py-3">Actions</th>
              </tr>
            </thead>
            <tbody>
              {orgLoading && <tr><td colSpan={5} className="px-5 py-4 text-sm text-slate-400">Loading organizations...</td></tr>}
              {!orgLoading && organizations.map((org) => (
                <tr key={org.id} className="border-b border-slate-700/50 hover:bg-slate-700/20 transition-colors">
                  <td className="px-5 py-3">
                    <input
                      className="bg-slate-800 border border-slate-700 rounded px-2 py-1 text-sm text-slate-200 min-w-[180px]"
                      value={orgEdits[org.id]?.name || org.name}
                      onChange={(e) => setOrgEdits((prev) => ({ ...prev, [org.id]: { ...prev[org.id], name: e.target.value } }))}
                    />
                  </td>
                  <td className="px-5 py-3">
                    <input
                      className="bg-slate-800 border border-slate-700 rounded px-2 py-1 text-sm text-slate-200 min-w-[140px]"
                      value={orgEdits[org.id]?.slug || org.slug}
                      onChange={(e) => setOrgEdits((prev) => ({ ...prev, [org.id]: { ...prev[org.id], slug: e.target.value } }))}
                    />
                  </td>
                  <td className="px-5 py-3">
                    <label className="inline-flex items-center gap-2 text-sm text-slate-300">
                      <input
                        type="checkbox"
                        className="accent-blue-500"
                        checked={orgEdits[org.id]?.is_active ?? org.is_active}
                        onChange={(e) => setOrgEdits((prev) => ({ ...prev, [org.id]: { ...prev[org.id], is_active: e.target.checked } }))}
                      />
                      <Badge color={(orgEdits[org.id]?.is_active ?? org.is_active) ? 'green' : 'gray'} dot>
                        {(orgEdits[org.id]?.is_active ?? org.is_active) ? 'active' : 'disabled'}
                      </Badge>
                    </label>
                  </td>
                  <td className="px-5 py-3">
                    <input
                      type="datetime-local"
                      className="bg-slate-800 border border-slate-700 rounded px-2 py-1 text-sm text-slate-200"
                      value={orgEdits[org.id]?.expires_at || ''}
                      onChange={(e) => setOrgEdits((prev) => ({ ...prev, [org.id]: { ...prev[org.id], expires_at: e.target.value } }))}
                    />
                  </td>
                  <td className="px-5 py-3 text-right">
                    <div className="flex items-center justify-end gap-2">
                      <Button size="sm" variant="secondary" onClick={() => handleOrganizationSave(org.id)} loading={saving}>Save</Button>
                      {isSuperAdmin && <Button size="sm" variant="danger" onClick={() => handleOrganizationDisable(org.id)} loading={saving}>Disable</Button>}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      {/* Add User Modal */}
      <Modal isOpen={showAddUser} onClose={() => setShowAddUser(false)} title="Add New User" size="md"
        footer={<><Button variant="secondary" onClick={() => setShowAddUser(false)}>Cancel</Button><Button loading={saving} onClick={handleCreateUser}>Create User</Button></>}>
        <div className="space-y-4">
          <Input label="Full Name" placeholder="John Doe" value={newUser.name} onChange={(e) => setNewUser((s) => ({ ...s, name: e.target.value }))} />
          <Input label="Email" type="email" placeholder="john@aerocommand.io" value={newUser.email} onChange={(e) => setNewUser((s) => ({ ...s, email: e.target.value }))} />
          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1.5">Role</label>
            <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2.5 text-sm text-slate-300" value={newUser.role} onChange={(e) => setNewUser((s) => ({ ...s, role: e.target.value }))}>
              {Object.keys(roleColors).map((role) => (
                <option key={role} value={role}>{roleLabel(role)}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1.5">Organization</label>
            <select
              className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2.5 text-sm text-slate-300"
              value={newUser.organization_id}
              onChange={(e) => setNewUser((s) => ({ ...s, organization_id: e.target.value }))}
              disabled={!isSuperAdmin}
            >
              {isSuperAdmin && <option value="">No organization</option>}
              {organizations.map((org) => (
                <option key={org.id} value={org.id}>{org.name}</option>
              ))}
            </select>
            {newUser.role === 'admin' && !newUser.organization_id && (
              <p className="mt-1 text-xs text-amber-400">Admin must be assigned to one organization.</p>
            )}
            {!isSuperAdmin && (
              <p className="mt-1 text-xs text-slate-500">Admins create users only inside their own organization.</p>
            )}
          </div>
          <Input label="Temporary Password" type="password" placeholder="••••••••" value={newUser.password} onChange={(e) => setNewUser((s) => ({ ...s, password: e.target.value }))} />
          <Input label="Expires At (optional)" type="datetime-local" value={newUser.expires_at} onChange={(e) => setNewUser((s) => ({ ...s, expires_at: e.target.value }))} />
        </div>
      </Modal>

      {/* Edit User Modal */}
      <Modal
        isOpen={showEditUser}
        onClose={() => setShowEditUser(false)}
        title="Edit User"
        size="md"
        footer={
          <>
            <Button variant="secondary" onClick={() => setShowEditUser(false)}>Cancel</Button>
            <Button loading={saving} onClick={handleEditUserSave}>Save Changes</Button>
          </>
        }
      >
        <div className="space-y-4">
          <Input
            label="Full Name"
            placeholder="John Doe"
            value={editForm.name}
            onChange={(e) => setEditForm((s) => ({ ...s, name: e.target.value }))}
          />
          <Input
            label="Email"
            type="email"
            placeholder="john@aerocommand.io"
            value={editForm.email}
            onChange={(e) => setEditForm((s) => ({ ...s, email: e.target.value }))}
          />
          <Input
            label="New Password (optional)"
            type="password"
            placeholder="Leave blank to keep current"
            value={editForm.password}
            onChange={(e) => setEditForm((s) => ({ ...s, password: e.target.value }))}
          />
          <p className="text-xs text-slate-500">
            Password reset is immediate. Share it securely with the user.
          </p>
        </div>
      </Modal>

      <Modal
        isOpen={showAddOrg}
        onClose={() => setShowAddOrg(false)}
        title="Add New Organization"
        size="md"
        footer={<><Button variant="secondary" onClick={() => setShowAddOrg(false)}>Cancel</Button><Button loading={saving} onClick={handleCreateOrganization}>Create Organization</Button></>}
      >
        <div className="space-y-4">
          <Input label="Organization Name" placeholder="AeroCommand HQ" value={newOrg.name} onChange={(e) => setNewOrg((s) => ({ ...s, name: e.target.value }))} />
          <Input label="Slug" placeholder="aerocommand" value={newOrg.slug} onChange={(e) => setNewOrg((s) => ({ ...s, slug: e.target.value }))} />
          <Input label="Expires At (optional)" type="datetime-local" value={newOrg.expires_at} onChange={(e) => setNewOrg((s) => ({ ...s, expires_at: e.target.value }))} />
        </div>
      </Modal>
    </div>
  );
}

