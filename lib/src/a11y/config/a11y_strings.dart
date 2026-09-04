import '../models/a11y_profile.dart';
import '../models/a11y_settings.dart';

class A11yStrings {
  const A11yStrings({
    this.centerTitle = 'Acessibilidade',
    this.centerSubtitle = 'Escolha o que deixa o app mais fácil pra você',
    this.openCenterLabel = 'Abrir ajustes de acessibilidade',
    this.closeCenterLabel = 'Fechar ajustes de acessibilidade',
    this.applyLabel = 'Aplicar ajustes',
    this.resetLabel = 'Voltar ao padrão',
    this.profilesSectionLabel = 'Como você prefere usar o app',
    this.textSizeSectionLabel = 'Tamanho do texto',
    this.contrastSectionLabel = 'Cores e contraste',
    this.previewSectionLabel = 'Prévia',
    this.previewSample = 'O texto do app vai ficar assim.',
    this.textScaleLabels = const ['P', 'M', 'G', 'GG'],
    this.contrastStandardLabel = 'Padrão',
    this.contrastGrayscaleLabel = 'Tons de cinza',
    this.contrastEnhancedLabel = 'Mais contraste',
    this.contrastHighLabel = 'Contraste máximo',
    this.onboardingTitle = 'Vamos deixar do seu jeito',
    this.onboardingSubtitle = 'Você pode mudar isso depois, quando quiser',
    this.onboardingContinueLabel = 'Continuar',
    this.onboardingSkipLabel = 'Pular por agora',
    this.lowVisionTitle = 'Enxergo com dificuldade',
    this.lowVisionSubtitle = 'Baixa visão',
    this.colorBlindnessTitle = 'Dificuldade com cores',
    this.colorBlindnessSubtitle = 'Daltonismo',
    this.epilepsyTitle = 'Sensível a luzes',
    this.epilepsySubtitle = 'Epilepsia',
    this.adhdTitle = 'Me distraio fácil',
    this.adhdSubtitle = 'TDAH',
    this.dyslexiaTitle = 'Dificuldade pra ler',
    this.dyslexiaSubtitle = 'Dislexia',
    this.hearingImpairmentTitle = 'Dificuldade pra ouvir',
    this.hearingImpairmentSubtitle = 'Deficiência auditiva',
  });

  final String centerTitle;
  final String centerSubtitle;
  final String openCenterLabel;
  final String closeCenterLabel;
  final String applyLabel;
  final String resetLabel;
  final String profilesSectionLabel;
  final String textSizeSectionLabel;
  final String contrastSectionLabel;
  final String previewSectionLabel;
  final String previewSample;
  final List<String> textScaleLabels;
  final String contrastStandardLabel;
  final String contrastGrayscaleLabel;
  final String contrastEnhancedLabel;
  final String contrastHighLabel;
  final String onboardingTitle;
  final String onboardingSubtitle;
  final String onboardingContinueLabel;
  final String onboardingSkipLabel;
  final String lowVisionTitle;
  final String lowVisionSubtitle;
  final String colorBlindnessTitle;
  final String colorBlindnessSubtitle;
  final String epilepsyTitle;
  final String epilepsySubtitle;
  final String adhdTitle;
  final String adhdSubtitle;
  final String dyslexiaTitle;
  final String dyslexiaSubtitle;
  final String hearingImpairmentTitle;
  final String hearingImpairmentSubtitle;

  String profileTitle(A11yProfile profile) => switch (profile) {
    A11yProfile.lowVision => lowVisionTitle,
    A11yProfile.colorBlindness => colorBlindnessTitle,
    A11yProfile.epilepsy => epilepsyTitle,
    A11yProfile.adhd => adhdTitle,
    A11yProfile.dyslexia => dyslexiaTitle,
    A11yProfile.hearingImpairment => hearingImpairmentTitle,
  };

  String profileSubtitle(A11yProfile profile) => switch (profile) {
    A11yProfile.lowVision => lowVisionSubtitle,
    A11yProfile.colorBlindness => colorBlindnessSubtitle,
    A11yProfile.epilepsy => epilepsySubtitle,
    A11yProfile.adhd => adhdSubtitle,
    A11yProfile.dyslexia => dyslexiaSubtitle,
    A11yProfile.hearingImpairment => hearingImpairmentSubtitle,
  };

  String contrastLabel(A11yContrastMode mode) => switch (mode) {
    A11yContrastMode.standard => contrastStandardLabel,
    A11yContrastMode.grayscale => contrastGrayscaleLabel,
    A11yContrastMode.enhancedContrast => contrastEnhancedLabel,
    A11yContrastMode.highContrast => contrastHighLabel,
  };

  String textScaleLabel(int step) {
    if (step < 0 || step >= textScaleLabels.length) return '';
    return textScaleLabels[step];
  }

  A11yStrings copyWith({
    String? centerTitle,
    String? centerSubtitle,
    String? openCenterLabel,
    String? closeCenterLabel,
    String? applyLabel,
    String? resetLabel,
    String? profilesSectionLabel,
    String? textSizeSectionLabel,
    String? contrastSectionLabel,
    String? previewSectionLabel,
    String? previewSample,
    List<String>? textScaleLabels,
    String? contrastStandardLabel,
    String? contrastGrayscaleLabel,
    String? contrastEnhancedLabel,
    String? contrastHighLabel,
    String? onboardingTitle,
    String? onboardingSubtitle,
    String? onboardingContinueLabel,
    String? onboardingSkipLabel,
    String? lowVisionTitle,
    String? lowVisionSubtitle,
    String? colorBlindnessTitle,
    String? colorBlindnessSubtitle,
    String? epilepsyTitle,
    String? epilepsySubtitle,
    String? adhdTitle,
    String? adhdSubtitle,
    String? dyslexiaTitle,
    String? dyslexiaSubtitle,
    String? hearingImpairmentTitle,
    String? hearingImpairmentSubtitle,
  }) {
    return A11yStrings(
      centerTitle: centerTitle ?? this.centerTitle,
      centerSubtitle: centerSubtitle ?? this.centerSubtitle,
      openCenterLabel: openCenterLabel ?? this.openCenterLabel,
      closeCenterLabel: closeCenterLabel ?? this.closeCenterLabel,
      applyLabel: applyLabel ?? this.applyLabel,
      resetLabel: resetLabel ?? this.resetLabel,
      profilesSectionLabel: profilesSectionLabel ?? this.profilesSectionLabel,
      textSizeSectionLabel: textSizeSectionLabel ?? this.textSizeSectionLabel,
      contrastSectionLabel: contrastSectionLabel ?? this.contrastSectionLabel,
      previewSectionLabel: previewSectionLabel ?? this.previewSectionLabel,
      previewSample: previewSample ?? this.previewSample,
      textScaleLabels: textScaleLabels ?? this.textScaleLabels,
      contrastStandardLabel:
          contrastStandardLabel ?? this.contrastStandardLabel,
      contrastGrayscaleLabel:
          contrastGrayscaleLabel ?? this.contrastGrayscaleLabel,
      contrastEnhancedLabel:
          contrastEnhancedLabel ?? this.contrastEnhancedLabel,
      contrastHighLabel: contrastHighLabel ?? this.contrastHighLabel,
      onboardingTitle: onboardingTitle ?? this.onboardingTitle,
      onboardingSubtitle: onboardingSubtitle ?? this.onboardingSubtitle,
      onboardingContinueLabel:
          onboardingContinueLabel ?? this.onboardingContinueLabel,
      onboardingSkipLabel: onboardingSkipLabel ?? this.onboardingSkipLabel,
      lowVisionTitle: lowVisionTitle ?? this.lowVisionTitle,
      lowVisionSubtitle: lowVisionSubtitle ?? this.lowVisionSubtitle,
      colorBlindnessTitle: colorBlindnessTitle ?? this.colorBlindnessTitle,
      colorBlindnessSubtitle:
          colorBlindnessSubtitle ?? this.colorBlindnessSubtitle,
      epilepsyTitle: epilepsyTitle ?? this.epilepsyTitle,
      epilepsySubtitle: epilepsySubtitle ?? this.epilepsySubtitle,
      adhdTitle: adhdTitle ?? this.adhdTitle,
      adhdSubtitle: adhdSubtitle ?? this.adhdSubtitle,
      dyslexiaTitle: dyslexiaTitle ?? this.dyslexiaTitle,
      dyslexiaSubtitle: dyslexiaSubtitle ?? this.dyslexiaSubtitle,
      hearingImpairmentTitle:
          hearingImpairmentTitle ?? this.hearingImpairmentTitle,
      hearingImpairmentSubtitle:
          hearingImpairmentSubtitle ?? this.hearingImpairmentSubtitle,
    );
  }
}
