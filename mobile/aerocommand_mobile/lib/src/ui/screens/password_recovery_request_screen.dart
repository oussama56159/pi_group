import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../api/api_error.dart';
import '../../config/app_config.dart';
import '../../config/endpoint_controller.dart';

class PasswordRecoveryRequestScreen extends StatefulWidget {
  const PasswordRecoveryRequestScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<PasswordRecoveryRequestScreen> createState() => _PasswordRecoveryRequestScreenState();
}

class _PasswordRecoveryRequestScreenState extends State<PasswordRecoveryRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _message;

  bool _isSending = false;
  ({String type, String text}) _status = (type: 'idle', text: '');

  @override
  void initState() {
    super.initState();
    final initialEmail = (widget.initialEmail ?? '').trim();
    _email = TextEditingController(text: initialEmail);
    _message = TextEditingController(text: _defaultMessage(initialEmail));
  }

  @override
  void dispose() {
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  static String _defaultMessage(String email) {
    final safeEmail = email.trim().isEmpty ? '<your email>' : email.trim();
    return [
      'Hello AeroCommand Dev/Admin Team,',
      '',
      'Please help me reset my password for the following account:',
      '- Email: $safeEmail',
      '',
      'If possible, please confirm once the reset is complete and share any next steps for signing back in.',
      '',
      'Thanks,',
      safeEmail,
    ].join('\n');
  }

  static bool _looksLikeEmail(String v) {
    final s = v.trim();
    final at = s.indexOf('@');
    if (at <= 0) return false;
    final dot = s.indexOf('.', at + 2);
    if (dot <= at + 1) return false;
    if (dot >= s.length - 1) return false;
    return true;
  }

  String _subject() => 'Password reset request - AeroCommand';

  Future<void> _send() async {
    if (_isSending) return;

    setState(() {
      _status = (type: 'idle', text: '');
    });

    if (!_formKey.currentState!.validate()) return;

    final fromEmail = _email.text.trim();
    final body = _message.text.trim();

    setState(() {
      _isSending = true;
    });

    try {
      setState(() {
        _status = (type: 'idle', text: '');
      });

      final api = context.read<ApiClient>();

      await api.postJson(
        '/auth/password-recovery-request',
        {
          'email': fromEmail,
          'message': body,
        },
      );

      if (!mounted) return;
      setState(() {
        _status = (type: 'success', text: 'Request sent. Dev/Admin will contact you shortly.');
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _status = (type: 'error', text: 'Failed to send request (${e.statusCode}): ${e.message}');
      });
    } catch (e) {
      if (!mounted) return;
      final endpoints = context.read<EndpointController>();
      setState(() {
        _status = (type: 'error', text: 'Could not reach backend (${endpoints.apiBaseUrl}): ${e.toString()}');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Recovery'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Request a password reset',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'This will send a request to the system Dev/Admin support team.\n'
                  'You can review and edit the message before sending.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            initialValue: AppConfig.supportEmail,
                            decoration: const InputDecoration(
                              labelText: 'Recipient (Dev/Admin)',
                              prefixIcon: Icon(Icons.support_agent_outlined),
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _email,
                            decoration: const InputDecoration(
                              labelText: 'Your login email',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'Email is required';
                              if (!_looksLikeEmail(s)) return 'Enter a valid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Subject',
                              prefixIcon: const Icon(Icons.subject_outlined),
                            ),
                            readOnly: true,
                            initialValue: _subject(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _message,
                            decoration: const InputDecoration(
                              labelText: 'Message',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.edit_note_outlined),
                              helperText: 'You can edit this message before sending.',
                            ),
                            keyboardType: TextInputType.multiline,
                            maxLines: 10,
                            minLines: 6,
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'Message cannot be empty';
                              if (s.length < 10) return 'Message must be at least 10 characters';
                              return null;
                            },
                          ),
                          if (_status.type != 'idle') ...[
                            const SizedBox(height: 12),
                            Text(
                              _status.text,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _status.type == 'success' ? color.primary : color.error,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _isSending ? null : _send,
                            icon: _isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send),
                            label: Text(_isSending ? 'Sending…' : 'Send Request'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
