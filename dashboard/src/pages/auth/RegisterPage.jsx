import { Link } from 'react-router-dom';
import { Radar } from 'lucide-react';

export default function RegisterPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950 px-4">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-blue-900/20 via-slate-950 to-slate-950" />
      <div className="relative w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-blue-500 to-cyan-500 mb-4 shadow-lg shadow-blue-500/25">
            <Radar className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-slate-100">AeroCommand</h1>
          <p className="text-sm text-slate-400 mt-1">Create your operator account</p>
        </div>

        <div className="bg-slate-900/80 backdrop-blur-xl border border-slate-800 rounded-2xl p-8">
          <h2 className="text-xl font-semibold text-slate-100 mb-4">Registration disabled</h2>
          <div className="p-3 bg-amber-500/10 border border-amber-500/20 rounded-lg text-sm text-amber-300">
            Public signup is disabled. Ask your Super Admin or Admin to create your account from the admin panel.
          </div>
          <p className="mt-6 text-center text-sm text-slate-500">
            Already have an account? <Link to="/login" className="text-blue-400 hover:text-blue-300 font-medium">Sign in</Link>
          </p>
        </div>
      </div>
    </div>
  );
}

