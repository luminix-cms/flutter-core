import 'package:flutter/material.dart';

import '../a11y_service.dart';
import '../config/a11y_configuration.dart';
import '../models/a11y_profile.dart';
import 'a11y_action_button.dart';
import 'a11y_center_controller.dart';
import 'a11y_choice_row.dart';
import 'a11y_contrast_swatch_row.dart';
import 'a11y_labeled_button.dart';
import 'a11y_preview_card.dart';
import 'a11y_profile_card.dart';
import 'a11y_scope_data.dart';
import 'a11y_semantics_header.dart';

// Apresentador por rota, para quem abre a Central de um item de menu em vez do
// FAB: exige um Navigator, que o A11yCenterHost não tem.
Future<void> showA11yCenter(BuildContext context) {
  final service = A11yScopeData.maybeOf(context)?.service;
  if (service == null) return Future<void>.value();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0x00000000),
    builder: (context) => A11yCenterSheet(
      service: service,
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}

class A11yCenterSheet extends StatefulWidget {
  const A11yCenterSheet({
    super.key,
    required this.service,
    required this.onClose,
    this.controller,
    this.maxHeightFactor = 0.85,
  });

  final A11yService service;
  final VoidCallback onClose;
  final A11yCenterController? controller;
  final double maxHeightFactor;

  @override
  State<A11yCenterSheet> createState() => _A11yCenterSheetState();
}

class _A11yCenterSheetState extends State<A11yCenterSheet> {
  A11yCenterController? _owned;

  A11yCenterController get _controller => widget.controller ?? _ensureOwned();

  A11yCenterController _ensureOwned() =>
      _owned ??= A11yCenterController(service: widget.service);

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  A11yConfiguration get _configuration => widget.service.configuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return ConstrainedBox(
      // ConstrainedBox e não SizedBox: com poucos perfis a folha deve poder
      // ficar menor que a fração máxima em vez de esticar em branco.
      constraints: BoxConstraints(
        maxHeight: media.size.height * widget.maxHeightFactor,
      ),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(context),
                // Flexible e não Expanded: Expanded força a coluna a ocupar
                // toda a altura máxima, e a folha nunca encolheria.
                Flexible(child: _body(context)),
                _footer(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final strings = _configuration.strings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                A11ySemanticsHeader(
                  label: strings.centerTitle,
                  child: Text(
                    strings.centerTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.centerSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          A11yLabeledButton(
            label: strings.closeCenterLabel,
            onPressed: widget.onClose,
            borderRadius: BorderRadius.circular(24),
            child: Icon(
              _configuration.icons.close,
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final strings = _configuration.strings;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _section(context, strings.profilesSectionLabel, _profiles(context)),
          _section(context, strings.textSizeSectionLabel, _textSize(context)),
          _section(
            context,
            strings.contrastSectionLabel,
            A11yContrastSwatchRow(
              configuration: _configuration,
              value: _controller.pendingSettings.contrastMode,
              onChanged: _controller.setContrastMode,
            ),
          ),
          _preview(context),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          A11ySemanticsHeader(
            label: label,
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _profiles(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
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
          width: width,
        );
  }

  Widget _textSize(BuildContext context) {
    final steps = _configuration.textScaleSteps;
    final strings = _configuration.strings;

    return A11yChoiceRow<int>(
      value: _controller.textScaleStep,
      onChanged: _controller.setTextScaleStep,
      textScaleOfLabel: (index) => steps[index],
      choices: [
        for (var i = 0; i < steps.length; i++)
          A11yChoice(value: i, label: strings.textScaleLabel(i)),
      ],
    );
  }

  Widget _preview(BuildContext context) {
    final settings = _controller.pendingSettings;

    return _configuration.previewBuilder?.call(context, settings) ??
        A11yPreviewCard(settings: settings);
  }

  Widget _footer(BuildContext context) {
    final strings = _configuration.strings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          A11yActionButton(label: strings.applyLabel, onPressed: _apply),
          const SizedBox(height: 8),
          A11yActionButton(
            label: strings.resetLabel,
            emphasis: A11yActionEmphasis.plain,
            onPressed: _controller.restoreDefaults,
          ),
        ],
      ),
    );
  }

  Future<void> _apply() async {
    await _controller.apply();
    if (!mounted) return;

    widget.onClose();
  }
}
