import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import App from './App.jsx';
import MockModeProvider from './lib/mock/MockModeProvider.jsx';
import { initTheme } from '@/lib/theme/theme';
import AppErrorBoundary from '@/components/shared/AppErrorBoundary';
import './index.css';

initTheme();

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
      staleTime: 30_000,
    },
  },
});

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <BrowserRouter>
      <QueryClientProvider client={queryClient}>
        <AppErrorBoundary>
          <MockModeProvider />
          <App />
        </AppErrorBoundary>
      </QueryClientProvider>
    </BrowserRouter>
  </StrictMode>,
);
