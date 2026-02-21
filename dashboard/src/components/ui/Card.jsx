import { clsx } from 'clsx';

export default function Card({ children, className, padding = true, hover = false, ...props }) {
  return (
    <div
      className={clsx(
        'bg-slate-800/80 border border-slate-700/50 rounded-xl backdrop-blur-sm',
        padding && 'p-5',
        hover && 'hover:border-slate-600 hover:bg-slate-800 transition-all duration-200 cursor-pointer',
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
}

export function CardHeader({ children, className, action }) {
  return (
    <div className={clsx('flex items-center justify-between mb-4', className)}>
      <div>{children}</div>
      {action && <div>{action}</div>}
    </div>
  );
}

export function CardTitle({ children, className, subtitle }) {
  return (
    <div>
      <h3 className={clsx('text-lg font-semibold text-slate-100', className)}>{children}</h3>
      {subtitle && <p className="text-sm text-slate-400 mt-0.5">{subtitle}</p>}
    </div>
  );
}

export function CardContent({ children, className }) {
  return <div className={clsx(className)}>{children}</div>;
}

