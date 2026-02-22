import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_controller.dart';
import '../../config/endpoint_controller.dart';
import 'password_recovery_request_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _loadedRemembered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRemembered());
  }

  Future<void> _loadRemembered() async {
    if (_loadedRemembered) return;

    final auth = context.read<AuthController>();
    final creds = await auth.loadRememberedCredentials();
    if (!mounted) return;

    setState(() {
      _loadedRemembered = true;
      _rememberMe = creds != null;
      if (creds != null) {
        _email.text = creds.email;
        _password.text = creds.password;
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    final endpoints = context.read<EndpointController>();
    if (!_formKey.currentState!.validate()) return;

    final email = _email.text.trim();
    final password = _password.text.trim();

    try {
      await auth.login(email: email, password: password);
      await auth.rememberCredentials(
        remember: _rememberMe,
        email: email,
        password: password,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = auth.error ?? e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$msg\nBackend: ${endpoints.apiBaseUrl}')),
      );
    }
  }

  Future<void> _tryDemo() async {
    final auth = context.read<AuthController>();
    await auth.loginDemo();
  }

  Future<void> _editBackendUrl() async {
    final endpoints = context.read<EndpointController>();
    final res = await showDialog<String>(
      context: context,
      builder: (_) => _BackendUrlDialog(initialValue: endpoints.apiBaseUrl),
    );

    if (!mounted) return;
    if (res == 'saved') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backend set to ${endpoints.apiBaseUrl}')),
      );
    } else if (res == 'reset') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backend URL reset to default')),
      );
    }
  }

  void _forgotPassword() {
    final initialEmail = _email.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PasswordRecoveryRequestScreen(initialEmail: initialEmail.isEmpty ? null : initialEmail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final endpoints = context.watch<EndpointController>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/app_icon.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('AeroCommand', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to monitor your fleet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _email,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.username, AutofillHints.email],
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.password],
                              validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: auth.isLoading ? null : _forgotPassword,
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: auth.isLoading
                                      ? null
                                      : (v) async {
                                          final next = v ?? false;
                                          setState(() => _rememberMe = next);
                                          if (!next) {
                                            await context.read<AuthController>().clearRememberedCredentials();
                                          }
                                        },
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Remember me',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: auth.isLoading ? null : _submit,
                              icon: const Icon(Icons.login),
                              label: Text(auth.isLoading ? 'Signing in…' : 'Sign in'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: auth.isLoading ? null : _tryDemo,
                              icon: const Icon(Icons.play_circle_outline),
                              label: const Text('Try Demo'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: auth.isLoading ? null : _editBackendUrl,
                              icon: const Icon(Icons.settings_input_component_outlined),
                              label: const Text('Backend URL'),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Current: ${endpoints.display}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tip: Android emulator uses 10.0.2.2 to reach your PC backend.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackendUrlDialog extends StatefulWidget {
  const _BackendUrlDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_BackendUrlDialog> createState() => _BackendUrlDialogState();
}

class _BackendUrlDialogState extends State<_BackendUrlDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final endpoints = context.read<EndpointController>();

    return AlertDialog(
      title: const Text('Backend URL'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Set the API base URL (it will be normalized to end with /api/v1).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'API Base URL',
              hintText: 'https://xxxx.trycloudflare.com/api/v1',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'WebSocket URL will be derived automatically after saving.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('cancel'),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await endpoints.reset();
            if (context.mounted) Navigator.of(context).pop('reset');
          },
          child: const Text('Reset'),
        ),
        FilledButton(
          onPressed: () async {
            try {
              await endpoints.setApiBaseUrl(_controller.text.trim());
              if (context.mounted) Navigator.of(context).pop('saved');
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
