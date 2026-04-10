class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Object? details;
  final Object? rawBody;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.details,
    this.rawBody,
  });

  @override
  String toString() {
    final base = 'ApiException($statusCode): $message';
    if (details == null) return base;
    return '$base (details: $details)';
  }
}
