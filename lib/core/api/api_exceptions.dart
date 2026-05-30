/// Typed exceptions raised by [StaffApiClient].
///
/// Screens and controllers branch on these instead of inspecting Dio errors
/// directly, keeping the rest of the app independent of the transport.
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Connectivity failure, timeout, or socket error.
class NetworkException extends ApiException {
  const NetworkException(super.message, {super.cause});
}

/// HTTP 401 — session missing or expired.
class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message, {super.cause});
}

/// HTTP 4xx other than 401, with the server's message when available.
class ClientApiException extends ApiException {
  const ClientApiException(
    super.message, {
    required this.statusCode,
    this.code,
    this.distanceMeters,
    this.allowedRadiusMeters,
    super.cause,
  });

  final int statusCode;
  final String? code;

  /// Populated for attendance location failures (e.g. `OUT_OF_RANGE`) so the UI
  /// can tell the user how far away they are and the shop's allowed radius.
  final int? distanceMeters;
  final int? allowedRadiusMeters;
}

/// HTTP 5xx.
class ServerApiException extends ApiException {
  const ServerApiException(
    super.message, {
    required this.statusCode,
    super.cause,
  });

  final int statusCode;
}
