import 'package:geolocator/geolocator.dart';

/// A single high-accuracy position captured for an attendance action.
class CapturedLocation {
  const CapturedLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final int accuracyMeters;
  final DateTime capturedAt;
}

/// Outcome of a one-shot location capture. Sealed so the controller can switch
/// over the cases exhaustively.
sealed class LocationOutcome {
  const LocationOutcome();
}

class LocationCaptured extends LocationOutcome {
  const LocationCaptured(this.location);
  final CapturedLocation location;
}

class LocationServiceDisabled extends LocationOutcome {
  const LocationServiceDisabled();
}

class LocationPermissionDenied extends LocationOutcome {
  const LocationPermissionDenied({this.permanently = false});
  final bool permanently;
}

class LocationCaptureFailed extends LocationOutcome {
  const LocationCaptureFailed(this.message);
  final String message;
}

/// Captures the device location once. Abstracted so the controller can be
/// tested without the platform plugin.
abstract class LocationProvider {
  Future<LocationOutcome> capture();
}

/// [LocationProvider] backed by the `geolocator` plugin. Requests permission on
/// demand and takes a single high-accuracy reading — no background tracking.
class GeolocatorLocationProvider implements LocationProvider {
  const GeolocatorLocationProvider();

  @override
  Future<LocationOutcome> capture() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationServiceDisabled();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationPermissionDenied(permanently: true);
    }
    if (permission == LocationPermission.denied) {
      return const LocationPermissionDenied();
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          // Bound the wait so a stuck GPS fix can't pin the button on "Working…".
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationCaptured(
        CapturedLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy.round(),
          capturedAt: position.timestamp.toUtc(),
        ),
      );
    } catch (_) {
      return const LocationCaptureFailed(
        'Could not read your location. Try again.',
      );
    }
  }
}
