import apiClient from '@/lib/api/client';

export async function postActionAudit(event) {
  try {
    await apiClient.post('/actions/audit', event);
  } catch {
    // Audit logging must never block UX.
  }
}

export async function fetchActionRegistry() {
  const { data } = await apiClient.get('/actions/registry');
  return data;
}
