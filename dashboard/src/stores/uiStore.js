import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export const useUIStore = create(
  persist(
    (set) => ({
      sidebarCollapsed: false,
      sidebarMobileOpen: false,
      activeModal: null,
      modalData: null,
      commandConfirmation: null,
      actionConfirmation: null,
      actionDetails: null,
      toasts: [],
      mapFullscreen: false,

      toggleSidebar: () => set((s) => ({ sidebarCollapsed: !s.sidebarCollapsed })),
      setSidebarCollapsed: (collapsed) => set({ sidebarCollapsed: collapsed }),
      toggleMobileSidebar: () => set((s) => ({ sidebarMobileOpen: !s.sidebarMobileOpen })),
      closeMobileSidebar: () => set({ sidebarMobileOpen: false }),

      openModal: (modalId, data = null) => set({ activeModal: modalId, modalData: data }),
      closeModal: () => set({ activeModal: null, modalData: null }),

      requestCommandConfirmation: (command) => set({ commandConfirmation: command }),
      clearCommandConfirmation: () => set({ commandConfirmation: null }),

      requestActionConfirmation: (payload) => set({ actionConfirmation: payload }),
      clearActionConfirmation: () => set({ actionConfirmation: null }),

      openActionDetails: (payload) => set({ actionDetails: payload }),
      closeActionDetails: () => set({ actionDetails: null }),

      addToast: (toast) => {
        const id = crypto.randomUUID();
        set((s) => ({
          toasts: [...s.toasts, { ...toast, id, createdAt: Date.now() }],
        }));
        setTimeout(() => {
          set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) }));
        }, toast.duration || 5000);
        return id;
      },

      removeToast: (id) => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })),

      toggleMapFullscreen: () => set((s) => ({ mapFullscreen: !s.mapFullscreen })),
    }),
    {
      name: 'aero-ui-store',
      partialize: (state) => ({ sidebarCollapsed: state.sidebarCollapsed }),
    }
  )
);

