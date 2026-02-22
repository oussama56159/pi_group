import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { API_BASE_URL, TOKEN_KEY, REFRESH_TOKEN_KEY, ROLE_HIERARCHY } from '@/config/constants';
import { authAPI } from '@/lib/api/endpoints';

function getApiErrorMessage(err, fallback) {
  // Axios error shapes:
  // - err.response: server responded (4xx/5xx)
  // - err.request: request made but no response (network/CORS)
  // - else: something else happened
  const detail = err?.response?.data?.detail;
  if (typeof detail === 'string' && detail.trim()) return detail;

  const status = err?.response?.status;
  if (status) {
    if (status === 404) {
      return `API endpoint not found (${API_BASE_URL}). Check that VITE_API_BASE_URL points to your backend (ending with /api/v1).`;
    }
    if (status >= 500) {
      return 'Server error. Please try again in a moment.';
    }
  }

  // Common Vercel failure: frontend deployed, backend not reachable or CORS blocked.
  if (err?.request && !err?.response) {
    return `Cannot reach the API at ${API_BASE_URL}. On Vercel, set VITE_API_BASE_URL to your backend URL (…/api/v1) and ensure backend CORS allows your Vercel domain.`;
  }

  return fallback;
}

export const useAuthStore = create(
  persist(
    (set, get) => ({
      user: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,

      login: async (credentials) => {
        set({ isLoading: true, error: null });
        try {
          const { data } = await authAPI.login(credentials);
          localStorage.setItem(TOKEN_KEY, data.access_token);
          localStorage.setItem(REFRESH_TOKEN_KEY, data.refresh_token);
          set({ user: data.user, isAuthenticated: true, isLoading: false });
          return data;
        } catch (err) {
          const msg = getApiErrorMessage(err, 'Login failed');
          set({ error: msg, isLoading: false });
          throw err;
        }
      },

      register: async (userData) => {
        set({ isLoading: true, error: null });
        try {
          const { data } = await authAPI.register(userData);
          set({ isLoading: false });
          return data;
        } catch (err) {
          const msg = getApiErrorMessage(err, 'Registration failed');
          set({ error: msg, isLoading: false });
          throw err;
        }
      },

      logout: () => {
        localStorage.removeItem(TOKEN_KEY);
        localStorage.removeItem(REFRESH_TOKEN_KEY);
        set({ user: null, isAuthenticated: false, error: null });
      },

      fetchUser: async () => {
        const token = localStorage.getItem(TOKEN_KEY);
        if (!token) return;
        set({ isLoading: true });
        try {
          const { data } = await authAPI.me();
          set({ user: data, isAuthenticated: true, isLoading: false });
        } catch {
          set({ user: null, isAuthenticated: false, isLoading: false });
          localStorage.removeItem(TOKEN_KEY);
          localStorage.removeItem(REFRESH_TOKEN_KEY);
        }
      },

      hasRole: (requiredRole) => {
        const { user } = get();
        if (!user) return false;
        return (ROLE_HIERARCHY[user.role] || 0) >= (ROLE_HIERARCHY[requiredRole] || 0);
      },

      hasAnyRole: (roles) => {
        const { user } = get();
        if (!user) return false;
        return roles.includes(user.role);
      },

      clearError: () => set({ error: null }),
    }),
    {
      name: 'aero-auth-store',
      partialize: (state) => ({ user: state.user, isAuthenticated: state.isAuthenticated }),
    }
  )
);

