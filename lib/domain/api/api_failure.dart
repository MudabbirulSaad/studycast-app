class ApiFailure implements Exception {
  const ApiFailure({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
    this.validationErrors = const [],
    this.cause,
  });

  final int? statusCode;
  final String? code;
  final String message;
  final Object? details;
  final List<ValidationIssue> validationErrors;
  final Object? cause;

  @override
  String toString() {
    final prefix = statusCode == null ? 'ApiFailure' : 'ApiFailure($statusCode)';
    return '$prefix: $message';
  }
}

class ValidationIssue {
  const ValidationIssue({
    required this.location,
    required this.message,
    required this.type,
  });

  final List<Object?> location;
  final String message;
  final String type;

  factory ValidationIssue.fromJson(Map<String, Object?> json) {
    return ValidationIssue(
      location: (json['loc'] as List<Object?>? ?? const []),
      message: json['msg'] as String? ?? 'Validation error',
      type: json['type'] as String? ?? 'validation_error',
    );
  }
}
