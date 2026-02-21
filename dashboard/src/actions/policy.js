import { ROLE_HIERARCHY } from '@/config/constants';

export function isRoleAllowed(userRole, allowedRoles = []) {
  if (!allowedRoles || allowedRoles.length === 0) return true;
  if (!userRole) return false;

  // Allow if user role meets or exceeds the maximum required level.
  const reqMax = Math.max(...allowedRoles.map((r) => ROLE_HIERARCHY[r] || 0));
  return (ROLE_HIERARCHY[userRole] || 0) >= reqMax;
}

export function buildTooltip(meta, { disabledReason } = {}) {
  if (!meta) return disabledReason || undefined;
  const base = meta.tooltip || meta.description || meta.name;
  return disabledReason ? `${base} — Disabled: ${disabledReason}` : base;
}

export function mapColorToButtonVariant(colorSemantics) {
  switch (colorSemantics) {
    case 'danger':
      return 'danger';
    case 'warning':
      return 'warning';
    case 'success':
      return 'success';
    case 'secondary':
      return 'secondary';
    case 'ghost':
      return 'ghost';
    default:
      return 'primary';
  }
}
