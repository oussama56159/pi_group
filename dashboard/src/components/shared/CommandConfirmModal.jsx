import { useUIStore } from '@/stores/uiStore';
import { useFleetStore } from '@/stores/fleetStore';
import Modal from '@/components/ui/Modal';
import Button from '@/components/ui/Button';
import { AlertTriangle, ShieldAlert } from 'lucide-react';
import { useState } from 'react';

const dangerCommands = ['arm', 'emergency_stop', 'reboot', 'disarm'];

export default function CommandConfirmModal() {
  const cmd = useUIStore((s) => s.commandConfirmation);
  const clear = useUIStore((s) => s.clearCommandConfirmation);
  const addToast = useUIStore((s) => s.addToast);
  const sendCommand = useFleetStore((s) => s.sendCommand);
  const [loading, setLoading] = useState(false);

  if (!cmd) return null;

  const isDanger = dangerCommands.includes(cmd.command);

  const handleConfirm = async () => {
    setLoading(true);
    try {
      await sendCommand(cmd.vehicleId, { command: cmd.command, params: cmd.params });
      addToast({
        type: 'success',
        title: 'Command Sent',
        message: `${cmd.command.toUpperCase()} sent to ${cmd.vehicleName || 'vehicle'}`,
      });
      clear();
    } catch (err) {
      addToast({
        type: 'error',
        title: 'Command Failed',
        message: err.response?.data?.detail || err.message,
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal
      isOpen={!!cmd}
      onClose={clear}
      title="Confirm Command"
      size="sm"
      footer={
        <>
          <Button variant="secondary" onClick={clear}>Cancel</Button>
          <Button variant={isDanger ? 'danger' : 'primary'} onClick={handleConfirm} loading={loading}>
            {isDanger ? 'Confirm Dangerous Action' : 'Send Command'}
          </Button>
        </>
      }
    >
      <div className="text-center py-4">
        {isDanger ? (
          <ShieldAlert className="w-12 h-12 text-red-400 mx-auto mb-3" />
        ) : (
          <AlertTriangle className="w-12 h-12 text-amber-400 mx-auto mb-3" />
        )}
        <h3 className="text-lg font-semibold text-slate-100 mb-2">
          {cmd.command?.replace(/_/g, ' ').toUpperCase()}
        </h3>
        <p className="text-sm text-slate-400">
          Send <strong className="text-slate-200">{cmd.command}</strong> command to{' '}
          <strong className="text-slate-200">{cmd.vehicleName || cmd.vehicleId}</strong>?
        </p>
        {isDanger && (
          <p className="mt-3 text-xs text-red-400 bg-red-500/10 border border-red-500/20 rounded-lg p-2">
            This is a critical safety command. Ensure operational area is clear.
          </p>
        )}
      </div>
    </Modal>
  );
}

