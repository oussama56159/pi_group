import { CheckCircle, AlertTriangle, XCircle, Info, X } from 'lucide-react';
import { clsx } from 'clsx';
import { useUIStore } from '@/stores/uiStore';

const icons = {
  success: CheckCircle,
  warning: AlertTriangle,
  error: XCircle,
  info: Info,
};

const styles = {
  success: 'border-emerald-500/50 bg-emerald-500/10',
  warning: 'border-amber-500/50 bg-amber-500/10',
  error: 'border-red-500/50 bg-red-500/10',
  info: 'border-blue-500/50 bg-blue-500/10',
};

const iconColors = {
  success: 'text-emerald-400',
  warning: 'text-amber-400',
  error: 'text-red-400',
  info: 'text-blue-400',
};

export default function ToastContainer() {
  const toasts = useUIStore((s) => s.toasts);
  const removeToast = useUIStore((s) => s.removeToast);

  if (!toasts.length) return null;

  return (
    <div className="fixed bottom-4 right-4 z-[100] flex flex-col gap-2 max-w-sm">
      {toasts.map((toast) => {
        const Icon = icons[toast.type] || Info;
        return (
          <div
            key={toast.id}
            className={clsx(
              'flex items-start gap-3 px-4 py-3 rounded-xl border backdrop-blur-sm shadow-xl',
              'animate-in slide-in-from-right duration-300',
              styles[toast.type] || styles.info
            )}
          >
            <Icon className={clsx('w-5 h-5 mt-0.5 shrink-0', iconColors[toast.type])} />
            <div className="flex-1 min-w-0">
              {toast.title && <p className="text-sm font-medium text-slate-100">{toast.title}</p>}
              <p className="text-sm text-slate-300">{toast.message}</p>
            </div>
            <button onClick={() => removeToast(toast.id)} className="p-0.5 text-slate-500 hover:text-slate-300">
              <X className="w-4 h-4" />
            </button>
          </div>
        );
      })}
    </div>
  );
}

