class InputSanitizer {
  static final RegExp _multiSpace = RegExp(r'\s+');
  static final RegExp _invalidNameChars = RegExp(r"[^A-Za-zÀ-ÿ\s'\-.]");

  static String cleanNamePart(String value) {
    final normalized = value.replaceAll(_multiSpace, ' ').trim();
    final filtered = normalized.replaceAll(_invalidNameChars, '');
    return filtered.replaceAll(_multiSpace, ' ').trim();
  }

  static String titleCase(String value) {
    final words = cleanNamePart(value).split(_multiSpace);
    final normalizedWords = <String>[];
    for (final word in words) {
      if (word.isEmpty) continue;
      normalizedWords.add(
        word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : ''),
      );
    }
    return normalizedWords.join(' ');
  }

  static String composeFullName({
    required String firstName,
    String middleName = '',
    required String lastName,
  }) {
    final parts = <String>[
      titleCase(firstName),
      titleCase(middleName),
      titleCase(lastName),
    ].where((part) => part.isNotEmpty).toList(growable: false);
    return parts.join(' ').trim();
  }

  static String normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[\s\-()]'), '').trim();
  }
}