import Modal from '@/components/ui/Modal';
import Badge from '@/components/ui/Badge';
import { useUIStore } from '@/stores/uiStore';
import { getActionMeta } from '@/actions/registry';

function Field({ label, value }) {
  if (!value) return null;
  return (
    <div className="py-2 border-b border-slate-700/50">
      <p className="text-[10px] uppercase tracking-wider text-slate-500">{label}</p>
      <p className="text-sm text-slate-200 mt-1 whitespace-pre-wrap">{value}</p>
    </div>
  );
}

export default function ActionDetailsModal() {
  const details = useUIStore((s) => s.actionDetails);
  const close = useUIStore((s) => s.closeActionDetails);
  if (!details) return null;

  const meta = getActionMeta(details.actionId);
  if (!meta) return null;

  return (
    <Modal
      isOpen={!!details}
      onClose={close}
      title="Action Details"
      size="lg"
      footer={null}
    >
      <div className="space-y-3">
        <div className="flex items-start justify-between gap-3">
          <div>
            <p className="text-xs text-slate-500">{meta.category?.toUpperCase?.() || 'ACTION'} • {details.actionId}</p>
            <h3 className="text-lg font-semibold text-slate-100">{meta.name}</h3>
            <p className="text-sm text-slate-400 mt-1">{meta.description}</p>
          </div>
          <div className="flex gap-2">
            {meta.riskLevel && (
              <Badge color={meta.riskLevel === 'critical' ? 'red' : meta.riskLevel === 'high' ? 'amber' : 'gray'}>
                {meta.riskLevel}
              </Badge>
            )}
            {meta.safetyClass && (
              <Badge color={meta.safetyClass === 'life_safety' ? 'red' : meta.safetyClass === 'flight_safety' ? 'amber' : 'gray'}>
                {meta.safetyClass}
              </Badge>
            )}
          </div>
        </div>

        <Field label="Role / Purpose" value={meta.purpose} />
        <Field label="Functional Impact" value={meta.functionalImpact} />
        <Field label="Technical Impact" value={meta.technicalImpact} />
        <Field label="Safety Impact" value={meta.safetyImpact} />
        <Field label="Preconditions" value={(meta.preconditions || []).join('\n')} />
        <Field label="Postconditions" value={(meta.postconditions || []).join('\n')} />
        <Field label="Failure Scenarios" value={(meta.failureScenarios || []).join('\n')} />
        <Field label="Emergency Behavior" value={meta.emergencyBehavior} />
        <Field label="Dependencies" value={(meta.dependencies || []).join('\n')} />
        <Field label="Operator Responsibility" value={meta.operatorResponsibility} />
      </div>
    </Modal>
  );
}
