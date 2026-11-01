/// Safe URL decode utility that prevents crashes on malformed percent-encoding
/// such as "Hong Kong [50% off]" or unescaped query strings.
String safeUrlDecode(String source) {
  if (source.isEmpty) return source;
  try {
    return Uri.decodeComponent(source);
  } catch (_) {
    // Fallback: decode character by character or replace lone % signs
    try {
      final sanitized = source.replaceAllMapped(
        RegExp(r'%(?![0-9a-fA-F]{2})'),
        (match) => '%25',
      );
      return Uri.decodeComponent(sanitized);
    } catch (_) {
      return source;
    }
  }
}
