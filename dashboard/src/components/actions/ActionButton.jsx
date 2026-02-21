import Button from '@/components/ui/Button';
import { useAuthStore } from '@/stores/authStore';
import { useUIStore } from '@/stores/uiStore';
import { getActionMeta } from '@/actions/registry';
import { buildTooltip, isRoleAllowed, mapColorToButtonVariant } from '@/actions/policy';
import { postActionAudit } from '@/lib/api/actions';

/**
 * ActionButton: wraps the design-system Button and binds it to an actionId.
 *
 * UX:
 * - Tooltip via `title`
 * - Shift+Click opens Action Details panel
 * - Optional confirm modal via uiStore.requestActionConfirmation
 */
export default function ActionButton({
  actionId,
  onAction,
  actionContext,
  disabled: disabledProp,
  disabledReason,
  variant,
  title,
  ...props
}) {
  const userRole = useAuthStore((s) => s.user?.role);
  const openActionDetails = useUIStore((s) => s.openActionDetails);
  const requestActionConfirmation = useUIStore((s) => s.requestActionConfirmation);

  const meta = getActionMeta(actionId);
  const visible = isRoleAllowed(userRole, meta?.permissionsRequired);
  if (!visible) return null;

  const disabled = !!disabledProp;
  const computedTitle = title || buildTooltip(meta, { disabledReason: disabled ? disabledReason : undefined });
  const computedVariant = variant || mapColorToButtonVariant(meta?.colorSemantics);

  const shouldAudit = !!meta?.logging?.auditTrail;
  const emitAudit = (outcome, { message, payload } = {}) => {
    if (!shouldAudit) return;
    void postActionAudit({
      action_id: actionId,
      outcome,
      message,
      payload,
    });
  };

  const handleClick = async (e) => {
    if (meta && e.shiftKey) {
      openActionDetails({ actionId, context: actionContext || null });
      return;
    }
    if (disabled) return;

    if (meta?.confirmation?.required) {
      requestActionConfirmation({
        actionId,
        context: actionContext || null,
        onConfirm: async () => {
          try {
            await onAction?.(e);
            emitAudit('success', { payload: { context: actionContext || null } });
          } catch (err) {
            emitAudit('failure', {
              message: err?.message || 'Action failed',
              payload: { context: actionContext || null },
            });
            throw err;
          }
        },
      });
      return;
    }

    try {
      await onAction?.(e);
      emitAudit('success', { payload: { context: actionContext || null } });
    } catch (err) {
      emitAudit('failure', {
        message: err?.message || 'Action failed',
        payload: { context: actionContext || null },
      });
      throw err;
    }
  };

  return (
    <Button
      {...props}
      variant={computedVariant}
      disabled={disabled}
      onClick={handleClick}
      title={computedTitle}
      aria-label={meta?.name || props['aria-label']}
    />
  );
}
