import 'package:digital_wardrobe_app/core/services/supabase_service.dart';
import 'package:digital_wardrobe_app/features/ootd/models/weather_data.dart';
import 'package:digital_wardrobe_app/features/ootd/services/location_service.dart';
import 'package:digital_wardrobe_app/features/ootd/services/weather_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<LocationService> locationServiceProvider =
    Provider<LocationService>((Ref ref) => const LocationService());

final Provider<WeatherRepository> weatherRepositoryProvider =
    Provider<WeatherRepository>(
      (Ref ref) => WeatherRepository(SupabaseService.client),
    );

final FutureProvider<WeatherData?> ootdWeatherProvider =
    FutureProvider<WeatherData?>((Ref ref) async {
      final LocationResult location = await ref
          .watch(locationServiceProvider)
          .currentLocation();

      if (!location.hasLocation) {
        return null;
      }

      return ref
          .watch(weatherRepositoryProvider)
          .fetchForLocation(location: location.location!);
    });
