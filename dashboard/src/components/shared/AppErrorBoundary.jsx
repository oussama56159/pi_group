import React from 'react';

export default class AppErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, errorMessage: '' };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, errorMessage: error?.message || 'Unknown error' };
  }

  componentDidCatch(error) {
    console.error('App runtime error:', error);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-slate-950 text-slate-100 flex items-center justify-center px-6">
          <div className="max-w-xl w-full bg-slate-900 border border-slate-800 rounded-xl p-6">
            <h1 className="text-xl font-semibold text-slate-100">UI runtime error detected</h1>
            <p className="text-sm text-slate-400 mt-2">
              The page crashed, but the app is still recoverable.
            </p>
            <p className="text-xs text-red-400 mt-3 break-all">
              {this.state.errorMessage}
            </p>
            <div className="mt-5">
              <button
                onClick={() => window.location.reload()}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg text-sm font-medium"
              >
                Reload App
              </button>
            </div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}
