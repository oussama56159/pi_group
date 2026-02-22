import { useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Mail, Send, ArrowLeft, User, FileText } from 'lucide-react';
import Button from '@/components/ui/Button';
import Input from '@/components/ui/Input';
import env from '@/config/env';
import { authAPI } from '@/lib/api/endpoints';

function isValidEmail(value) {
  const s = String(value || '').trim();
  if (!s) return false;
  // Simple sanity check (good enough for UI validation)
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s);
}

function buildDefaultMessage(email) {
  const safeEmail = String(email || '').trim() || '<your email>';
  return [
    'Hello AeroCommand Dev/Admin Team,',
    '',
    'Please help me reset my password for the following account:',
    `- Email: ${safeEmail}`,
    '',
    'If possible, please confirm once the reset is complete and share any next steps for signing back in.',
    '',
    'Thanks,',
    safeEmail,
  ].join('\n');
}

export default function PasswordRecoveryRequestPage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const initialEmail = useMemo(() => (searchParams.get('email') || '').trim(), [searchParams]);

  const [fromEmail, setFromEmail] = useState(initialEmail);
  const [message, setMessage] = useState(() => buildDefaultMessage(initialEmail));

  const [touched, setTouched] = useState({ email: false, message: false });
  const [isSending, setIsSending] = useState(false);
  const [status, setStatus] = useState({ type: 'idle', text: '' });

  // If user arrived with a query email after initial mount (rare), prefill once.
  const didPrefillRef = useRef(false);
  useEffect(() => {
    if (didPrefillRef.current) return;
    if (!initialEmail) return;
    didPrefillRef.current = true;
    setFromEmail(initialEmail);
    setMessage(buildDefaultMessage(initialEmail));
  }, [initialEmail]);

  const recipient = env.SUPPORT_EMAIL;
  const subject = 'Password reset request - AeroCommand';

  const errors = useMemo(() => {
    const next = { email: '', message: '' };
    if (!fromEmail.trim()) next.email = 'Email is required';
    else if (!isValidEmail(fromEmail)) next.email = 'Enter a valid email address';

    if (!message.trim()) next.message = 'Message cannot be empty';

    return next;
  }, [fromEmail, message]);

  const canSend = !errors.email && !errors.message && !isSending;

  const handleSend = async (e) => {
    e.preventDefault();
    setStatus({ type: 'idle', text: '' });
    setTouched({ email: true, message: true });

    if (!canSend) {
      setStatus({ type: 'error', text: 'Please fix the highlighted fields.' });
      return;
    }

    setIsSending(true);
    try {
      await authAPI.requestPasswordRecovery({
        email: fromEmail.trim(),
        message: message.trim(),
      });

      setStatus({ type: 'success', text: 'Request sent. Dev/Admin will contact you shortly.' });
    } catch (err) {
      const msg = err?.response?.data?.detail || err?.message || 'Failed to send request.';
      setStatus({ type: 'error', text: msg });
    } finally {
      setIsSending(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950 px-4">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-blue-900/20 via-slate-950 to-slate-950" />
      <div className="relative w-full max-w-md">
        <button
          type="button"
          onClick={() => navigate('/login')}
          className="inline-flex items-center gap-2 text-sm text-slate-400 hover:text-slate-200 mb-4"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to sign in
        </button>

        <div className="bg-slate-900/80 backdrop-blur-xl border border-slate-800 rounded-2xl p-8">
          <h2 className="text-xl font-semibold text-slate-100">Password Recovery</h2>
          <p className="text-sm text-slate-400 mt-2">
            This will send a request email to the system Dev/Admin support team. You can review and edit the message before sending.
          </p>

          {status.type !== 'idle' && (
            <div
              className={
                `mt-4 p-3 rounded-lg text-sm border ` +
                (status.type === 'success'
                  ? 'bg-emerald-500/10 border-emerald-500/20 text-emerald-300'
                  : 'bg-red-500/10 border-red-500/20 text-red-400')
              }
            >
              {status.text}
            </div>
          )}

          <form onSubmit={handleSend} className="space-y-5 mt-6">
            <Input
              label="Recipient (Dev/Admin)"
              type="email"
              icon={Mail}
              value={recipient}
              readOnly
            />

            <Input
              label="Your login email"
              type="email"
              icon={User}
              placeholder="you@company.com"
              value={fromEmail}
              onChange={(e) => {
                setFromEmail(e.target.value);
                if (!touched.email) setTouched((s) => ({ ...s, email: true }));
              }}
              onBlur={() => setTouched((s) => ({ ...s, email: true }))}
              error={touched.email ? errors.email : ''}
              required
            />

            <Input
              label="Subject"
              type="text"
              icon={FileText}
              value={subject}
              readOnly
            />

            <div className="w-full">
              <label className="block text-sm font-medium text-slate-300 mb-1.5">Message</label>
              <div className="relative">
                <textarea
                  className={
                    `w-full bg-slate-800 border rounded-lg px-4 py-2.5 text-sm text-slate-100 ` +
                    `placeholder:text-slate-500 transition-colors duration-200 focus:outline-none focus:ring-2 ` +
                    `focus:ring-blue-500/50 focus:border-blue-500 ` +
                    (touched.message && errors.message ? 'border-red-500 focus:ring-red-500/50 focus:border-red-500' : 'border-slate-700')
                  }
                  rows={9}
                  value={message}
                  onChange={(e) => {
                    setMessage(e.target.value);
                    if (!touched.message) setTouched((s) => ({ ...s, message: true }));
                  }}
                  onBlur={() => setTouched((s) => ({ ...s, message: true }))}
                />
              </div>
              {touched.message && errors.message && <p className="mt-1 text-xs text-red-400">{errors.message}</p>}
              <p className="mt-1 text-xs text-slate-500">You can edit this message before sending.</p>
            </div>

            <Button type="submit" fullWidth loading={isSending} disabled={!canSend} icon={Send} size="lg">
              Send Request
            </Button>
          </form>
        </div>
      </div>
    </div>
  );
}
