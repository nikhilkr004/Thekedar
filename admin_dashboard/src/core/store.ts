import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export type AdminRole = 'Super Admin' | 'Admin' | 'Moderator' | 'Support' | 'Accountant';

interface AdminUser {
  id: string;
  email: string;
  fullName: string;
  role: AdminRole;
}

interface ActivityEvent {
  id: string;
  user: string;
  action: string;
  timestamp: string;
  type: 'info' | 'success' | 'warning' | 'error';
}

interface AdminState {
  user: AdminUser | null;
  isAuthenticated: boolean;
  activeSocketsCount: number;
  recentActivities: ActivityEvent[];
  login: (user: AdminUser) => void;
  logout: () => void;
  updateSocketsCount: (count: number) => void;
  addActivity: (activity: Omit<ActivityEvent, 'id' | 'timestamp'>) => void;
}

export const useAdminStore = create<AdminState>()(
  persist(
    (set) => ({
      user: null,
      isAuthenticated: false,
      activeSocketsCount: 12, // Default/fallback simulation count
      recentActivities: [
        {
          id: '1',
          user: 'Amit Sharma',
          action: 'Posted new renovation project',
          timestamp: 'Just now',
          type: 'success',
        },
        {
          id: '2',
          user: 'Rajesh Kumar',
          action: 'Purchased starter credit pack (50 Cr)',
          timestamp: '2m ago',
          type: 'info',
        },
        {
          id: '3',
          user: 'Vikram Singh',
          action: 'Failed liveness checking verification',
          timestamp: '15m ago',
          type: 'warning',
        },
      ],
      login: (user) => set({ user, isAuthenticated: true }),
      logout: () => set({ user: null, isAuthenticated: false }),
      updateSocketsCount: (count) => set({ activeSocketsCount: count }),
      addActivity: (act) =>
        set((state) => ({
          recentActivities: [
            {
              ...act,
              id: Math.random().toString(),
              timestamp: 'Just now',
            },
            ...state.recentActivities.slice(0, 19),
          ],
        })),
    }),
    {
      name: 'thekedar-admin-auth-storage',
    }
  )
);
