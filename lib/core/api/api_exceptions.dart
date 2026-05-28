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
    super.cause,
  });

  final int statusCode;
  final String? code;
}

/// HTTP 5xx.
class ServerApiException extends ApiException {
  const ServerApiException(super.message, {required this.statusCode, super.cause});

  final int statusCode;
}
