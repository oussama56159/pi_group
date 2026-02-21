import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Radar, Mail, Lock, Eye, EyeOff } from 'lucide-react';
import Button from '@/components/ui/Button';
import Input from '@/components/ui/Input';
import { useAuthStore } from '@/stores/authStore';
import { useMockLogin } from '@/lib/mock/useMockMode';

const MOCK_MODE_KEY = 'aero_mock_mode';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPw, setShowPw] = useState(false);
  const login = useAuthStore((s) => s.login);
  const isLoading = useAuthStore((s) => s.isLoading);
  const error = useAuthStore((s) => s.error);
  const navigate = useNavigate();
  const mockLogin = useMockLogin();
  const mockEnabled = (() => {
    const stored = typeof window !== 'undefined' ? localStorage.getItem(MOCK_MODE_KEY) : null;
    if (stored !== null) return stored === 'true';
    return import.meta.env.VITE_MOCK_MODE === 'true';
  })();

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      // Try real API first, fall back to mock login
      try {
        await login({ email, password });
      } catch (err) {
        if (!mockEnabled) throw err;
        await mockLogin({ email, password });
      }
      navigate('/');
    } catch { /* error set in store */ }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950 px-4">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-blue-900/20 via-slate-950 to-slate-950" />
      <div className="relative w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-blue-500 to-cyan-500 mb-4 shadow-lg shadow-blue-500/25">
            <Radar className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-slate-100">AeroCommand</h1>
          <p className="text-sm text-slate-400 mt-1">Cloud Fleet Management Platform</p>
        </div>

        {/* Form */}
        <div className="bg-slate-900/80 backdrop-blur-xl border border-slate-800 rounded-2xl p-8">
          <h2 className="text-xl font-semibold text-slate-100 mb-6">Sign in to your account</h2>
          {error && (
            <div className="mb-4 p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-sm text-red-400">
              {error}
            </div>
          )}
          <form onSubmit={handleSubmit} className="space-y-5">
            <Input
              label="Email"
              type="email"
              icon={Mail}
              placeholder="operator@aerocommand.io"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
            <div className="relative">
              <Input
                label="Password"
                type={showPw ? 'text' : 'password'}
                icon={Lock}
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
              <button
                type="button"
                onClick={() => setShowPw(!showPw)}
                className="absolute right-3 top-[38px] text-slate-500 hover:text-slate-300"
              >
                {showPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
            <div className="flex items-center justify-between text-sm">
              <label className="flex items-center gap-2 text-slate-400">
                <input type="checkbox" className="rounded border-slate-600 bg-slate-800" />
                Remember me
              </label>
              <a href="#" className="text-blue-400 hover:text-blue-300">Forgot password?</a>
            </div>
            <Button type="submit" fullWidth loading={isLoading} size="lg">
              Sign In
            </Button>
          </form>
          <p className="mt-6 text-center text-sm text-slate-500">
            Accounts are created by your organization admin.
          </p>
        </div>

        {/* Demo credentials */}
        <div className="mt-4 p-3 bg-slate-800/50 border border-slate-700/50 rounded-xl text-center">
          <p className="text-xs text-slate-500">Default owner (dev): owner@makerskills.com / makerskills_owner_change_me</p>
        </div>
      </div>
    </div>
  );
}

