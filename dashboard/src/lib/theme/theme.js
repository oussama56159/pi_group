const THEME_KEY = 'aero_theme';

export function getStoredTheme() {
  if (typeof window === 'undefined') return null;
  const value = window.localStorage.getItem(THEME_KEY);
  return value === 'light' || value === 'dark' ? value : null;
}

export function setTheme(theme) {
  const next = theme === 'light' ? 'light' : 'dark';
  if (typeof document !== 'undefined') {
    document.documentElement.dataset.theme = next;
  }
  if (typeof window !== 'undefined') {
    window.localStorage.setItem(THEME_KEY, next);
  }
  return next;
}

export function initTheme() {
  const stored = getStoredTheme();
  return setTheme(stored || 'dark');
}

export function isDarkTheme() {
  return (typeof document !== 'undefined')
    ? (document.documentElement.dataset.theme || 'dark') === 'dark'
    : true;
}
