import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const List<String> a11yFontLicenseAssets = [
  'packages/luminix_flutter/assets/fonts/AtkinsonHyperlegible/OFL.txt',
  'packages/luminix_flutter/assets/fonts/Lexend/OFL.txt',
  'packages/luminix_flutter/assets/fonts/OpenDyslexic/OFL.txt',
];

bool _registered = false;

// As fontes entram no bundle de todo app consumidor, com a11y ligada ou não —
// a atribuição da OFL acompanha a distribuição, não o opt-in.
void registerA11yFontLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(a11yFontLicenses);
}

Stream<LicenseEntry> a11yFontLicenses() async* {
  for (final asset in a11yFontLicenseAssets) {
    yield LicenseEntryWithLineBreaks(const [
      'luminix_flutter',
    ], await rootBundle.loadString(asset));
  }
}
