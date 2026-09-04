import 'package:flutter/material.dart';

import '../a11y_service.dart';
import '../config/a11y_configuration.dart';
import '../models/a11y_profile.dart';
import '../theme/a11y_theme_extension.dart';
import 'a11y_action_button.dart';
import 'a11y_center_controller.dart';
import 'a11y_profile_card.dart';
import 'a11y_semantics_header.dart';

class A11yOnboardingScreen extends StatefulWidget {
  const A11yOnboardingScreen({
    super.key,
    required this.service,
    this.onFinished,
    this.controller,
  });

  final A11yService service;
  final VoidCallback? onFinished;
  final A11yCenterController? controller;

  @override
  State<A11yOnboardingScreen> createState() => _A11yOnboardingScreenState();
}

class _A11yOnboardingScreenState extends State<A11yOnboardingScreen> {
  A11yCenterController? _owned;

  A11yCenterController get _controller =>
      widget.controller ??
      (_owned ??= A11yCenterController(service: widget.service));

  A11yConfiguration get _configuration => widget.service.configuration;

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = A11yThemeExtension.of(context);
    final strings = _configuration.strings;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(color: theme.colorScheme.surface),
        child: Stack(
          children: [
            if (extension.decorativeBackgrounds)
              // Decoração é a primeira coisa que sai quando a pessoa pede menos
              // ruído: fora da semântica e fora do teste de acerto.
              Positioned.fill(
                child: ExcludeSemantics(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _A11yDotsPainter(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            A11ySemanticsHeader(
                              label: strings.onboardingTitle,
                              child: Text(
                                strings.onboardingTitle,
                                style: theme.textTheme.headlineSmall,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.onboardingSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _profiles(context),
                          ],
                        ),
                      ),
                    ),
                    _footer(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profiles(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth >= 420 ? 3 : 2;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final profile in _configuration.profiles)
              _card(context, profile, width),
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, A11yProfile profile, double width) {
    final selected = _controller.has(profile);
    void toggle() => _controller.toggleProfile(profile);

    return _configuration.profileCardBuilder?.call(
          context,
          profile,
          selected,
          toggle,
        ) ??
        A11yProfileCard(
          configuration: _configuration,
          profile: profile,
          selected: selected,
          onToggle: toggle,
          showSubtitle: false,
          width: width,
        );
  }

  Widget _footer(BuildContext context) {
    final strings = _configuration.strings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          A11yActionButton(
            label: strings.onboardingContinueLabel,
            onPressed: _continue,
          ),
          const SizedBox(height: 8),
          A11yActionButton(
            label: strings.onboardingSkipLabel,
            emphasis: A11yActionEmphasis.plain,
            onPressed: _skip,
          ),
        ],
      ),
    );
  }

  Future<void> _continue() async {
    await _controller.completeOnboarding();
    if (!mounted) return;

    widget.onFinished?.call();
  }

  // Pular descarta a seleção pendente: quem não confirmou não escolheu.
  Future<void> _skip() async {
    _controller.discard();
    await widget.service.completeOnboarding();
    if (!mounted) return;

    widget.onFinished?.call();
  }
}

class _A11yDotsPainter extends CustomPainter {
  const _A11yDotsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 24.0;

    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_A11yDotsPainter oldDelegate) =>
      oldDelegate.color != color;
}
