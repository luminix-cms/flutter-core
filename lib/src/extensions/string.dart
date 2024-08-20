extension StringtoCamelCaseExtension on String {
  String camelCase() {
    if (isEmpty) return '';

    final words = replaceAll(
            RegExp(r'[^\w\s]+'), '') // Remove caracteres especiais
        .split(' ')
        .where((word) => word.isNotEmpty) // Remove palavras vazias
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase());

    return words.first + words.skip(1).join('');
  }
}

extension StringCapitalizeExtension on String {
  String capitalize() {
    switch (length) {
      case 0:
        return this;
      case 1:
        return toUpperCase();
      default:
        return substring(0, 1).toUpperCase() + substring(1);
    }
  }
}
