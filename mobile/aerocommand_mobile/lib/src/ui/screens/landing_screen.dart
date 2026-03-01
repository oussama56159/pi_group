import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({
    super.key,
    required this.onGetStarted,
  });

  final VoidCallback onGetStarted;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              scheme.primary.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOut,
                  opacity: _visible ? 1 : 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOut,
                    offset: _visible ? Offset.zero : const Offset(0, 0.03),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/app_icon.png',
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              semanticLabel: 'AeroCommand logo',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AeroCommand',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Fleet management for drones and robots — real‑time telemetry, monitoring, and control in one place.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: widget.onGetStarted,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Get Started'),
                          ),
                        ),
                        const SizedBox(height: 26),
                        _PartnerBlock(
                          label: 'Powered by / In partnership with',
                          assetPath: 'assets/maker skills logo.png',
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PartnerBlock extends StatelessWidget {
  const _PartnerBlock({
    required this.label,
    required this.assetPath,
  });

  final String label;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: label,
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
            ),
            child: Image.asset(
              assetPath,
              height: 34,
              fit: BoxFit.contain,
              semanticLabel: 'MakerSkills logo',
            ),
          ),
        ],
      ),
    );
  }
}
