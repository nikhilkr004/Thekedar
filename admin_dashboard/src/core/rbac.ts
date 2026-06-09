import { AdminRole } from './store';

export type PermissionAction = 'view' | 'create' | 'edit' | 'delete' | 'export';
export type SystemModule = 'users' | 'cms' | 'flags' | 'config' | 'notifications' | 'analytics' | 'support' | 'audits';

const permissionsSchema: Record<AdminRole, Record<SystemModule, PermissionAction[]>> = {
  'Super Admin': {
    users: ['view', 'create', 'edit', 'delete', 'export'],
    cms: ['view', 'create', 'edit', 'delete', 'export'],
    flags: ['view', 'create', 'edit', 'delete', 'export'],
    config: ['view', 'create', 'edit', 'delete', 'export'],
    notifications: ['view', 'create', 'edit', 'delete', 'export'],
    analytics: ['view', 'create', 'edit', 'delete', 'export'],
    support: ['view', 'create', 'edit', 'delete', 'export'],
    audits: ['view', 'create', 'edit', 'delete', 'export'],
  },
  'Admin': {
    users: ['view', 'create', 'edit', 'export'],
    cms: ['view', 'create', 'edit', 'delete', 'export'],
    flags: ['view', 'create', 'edit', 'export'],
    config: ['view', 'create', 'edit', 'export'],
    notifications: ['view', 'create', 'edit', 'export'],
    analytics: ['view', 'create', 'edit', 'export'],
    support: ['view', 'create', 'edit', 'export'],
    audits: ['view', 'export'],
  },
  'Moderator': {
    users: ['view', 'edit'],
    cms: ['view', 'create', 'edit'],
    flags: ['view'],
    config: ['view'],
    notifications: ['view', 'create'],
    analytics: ['view'],
    support: ['view', 'edit'],
    audits: ['view'],
  },
  'Support': {
    users: ['view'],
    cms: ['view'],
    flags: ['view'],
    config: ['view'],
    notifications: [],
    analytics: ['view'],
    support: ['view', 'create', 'edit'],
    audits: [],
  },
  'Accountant': {
    users: ['view'],
    cms: [],
    flags: [],
    config: [],
    notifications: [],
    analytics: ['view'],
    support: ['view'],
    audits: ['view', 'export'], // Can view transactions/audit details
  },
};

export function hasPermission(role: AdminRole, module: SystemModule, action: PermissionAction): boolean {
  const allowedActions = permissionsSchema[role]?.[module] || [];
  return allowedActions.includes(action);
}
