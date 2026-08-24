import 'package:geolocator/geolocator.dart' as geolocator;

class DeviceLocation {
  const DeviceLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

enum LocationAvailability {
  granted,
  denied,
  permanentlyDenied,
  servicesDisabled,
  unavailable,
}

class LocationResult {
  const LocationResult({
    required this.availability,
    this.location,
    this.message,
  });

  final LocationAvailability availability;
  final DeviceLocation? location;
  final String? message;

  bool get hasLocation => location != null;
}

class LocationService {
  const LocationService();

  Future<LocationResult> currentLocation() async {
    final bool serviceEnabled =
        await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        availability: LocationAvailability.servicesDisabled,
        message: 'Location services are disabled.',
      );
    }

    geolocator.LocationPermission permission =
        await geolocator.Geolocator.checkPermission();

    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
    }

    if (permission == geolocator.LocationPermission.denied) {
      return const LocationResult(
        availability: LocationAvailability.denied,
        message: 'Location permission was denied.',
      );
    }

    if (permission == geolocator.LocationPermission.deniedForever) {
      return const LocationResult(
        availability: LocationAvailability.permanentlyDenied,
        message: 'Location permission is permanently denied.',
      );
    }

    try {
      final geolocator.Position position =
          await geolocator.Geolocator.getCurrentPosition(
            locationSettings: const geolocator.LocationSettings(
              accuracy: geolocator.LocationAccuracy.low,
              timeLimit: Duration(seconds: 8),
            ),
          );

      return LocationResult(
        availability: LocationAvailability.granted,
        location: DeviceLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (error) {
      return LocationResult(
        availability: LocationAvailability.unavailable,
        message: 'Location is unavailable: $error',
      );
    }
  }
}
