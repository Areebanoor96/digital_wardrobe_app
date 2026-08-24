import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/data/repositories/wear_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WearLog.fromJson', () {
    test('parses a complete wear log row', () {
      final WearLog log = WearLog.fromJson(<String, dynamic>{
        'id': 'log-1',
        'member_id': 'member-1',
        'garment_id': 'garment-1',
        'worn_date': '2026-08-10',
        'outfit_id': 'outfit-1',
        'event_name': 'University',
        'notes': 'Wore to campus',
        'laundry_status_after': 'dirty',
        'weather_temp': 31.5,
        'weather_cond': 'Clouds',
      });

      expect(log.id, 'log-1');
      expect(log.memberId, 'member-1');
      expect(log.garmentId, 'garment-1');
      expect(log.wornDate, DateTime(2026, 8, 10));
      expect(log.outfitId, 'outfit-1');
      expect(log.eventName, 'University');
      expect(log.notes, 'Wore to campus');
      expect(log.laundryStatusAfter, LaundryStatus.dirty);
      expect(log.weatherTemp, 31.5);
      expect(log.weatherCondition, 'Clouds');
    });

    test('event, notes and laundry status are optional', () {
      final WearLog log = WearLog.fromJson(<String, dynamic>{
        'id': 'log-2',
        'member_id': 'member-1',
        'garment_id': 'garment-1',
        'worn_date': '2026-08-11',
        'event_name': null,
        'notes': null,
        'laundry_status_after': null,
      });

      expect(log.eventName, isNull);
      expect(log.notes, isNull);
      expect(log.laundryStatusAfter, isNull);
    });

    test('parses each laundry status value', () {
      for (final LaundryStatus status in LaundryStatus.values) {
        final WearLog log = WearLog.fromJson(<String, dynamic>{
          'id': 'log-3',
          'member_id': 'member-1',
          'garment_id': 'garment-1',
          'worn_date': '2026-08-12',
          'laundry_status_after': status.name,
        });

        expect(log.laundryStatusAfter, status);
      }
    });
  });

  group('WearLogRepository.resolveWornDate', () {
    final DateTime now = DateTime(2026, 8, 13, 15, 30);

    test('defaults to today when no date is provided', () {
      expect(
        WearLogRepository.resolveWornDate(null, now: now),
        DateTime(2026, 8, 13),
      );
    });

    test('normalizes a selected date to its date only', () {
      expect(
        WearLogRepository.resolveWornDate(
          DateTime(2026, 8, 5, 23, 59),
          now: now,
        ),
        DateTime(2026, 8, 5),
      );
    });

    test('accepts today as a valid wear date', () {
      expect(
        WearLogRepository.resolveWornDate(DateTime(2026, 8, 13), now: now),
        DateTime(2026, 8, 13),
      );
    });

    test('throws for a wear date in the future', () {
      expect(
        () =>
            WearLogRepository.resolveWornDate(DateTime(2026, 8, 14), now: now),
        throwsArgumentError,
      );
    });
  });

  group('WearLogRepository.buildWearLogRow', () {
    final DateTime wornDate = DateTime(2026, 8, 13);

    Map<String, dynamic> build({
      String? eventName,
      String? notes,
      String? outfitId,
      LaundryStatus? laundryStatusAfter,
      double? weatherTemp,
      String? weatherCondition,
    }) {
      return WearLogRepository.buildWearLogRow(
        userId: 'user-1',
        memberId: 'member-1',
        garmentId: 'garment-1',
        wornDate: wornDate,
        outfitId: outfitId,
        eventName: eventName,
        notes: notes,
        laundryStatusAfter: laundryStatusAfter,
        weatherTemp: weatherTemp,
        weatherCondition: weatherCondition,
      );
    }

    test('writes the selected wear date as a date only', () {
      final Map<String, dynamic> row = build();
      expect(row['worn_date'], '2026-08-13');
    });

    test('event can be omitted', () {
      expect(build(eventName: null)['event_name'], isNull);
      expect(build(eventName: '   ')['event_name'], isNull);
    });

    test('event is trimmed when provided', () {
      expect(build(eventName: '  University  ')['event_name'], 'University');
    });

    test('notes can be omitted and are trimmed', () {
      expect(build(notes: null)['notes'], isNull);
      expect(build(notes: '   ')['notes'], isNull);
      expect(build(notes: '  Campus  ')['notes'], 'Campus');
    });

    test('stores the chosen laundry status and outfit id', () {
      expect(
        build(laundryStatusAfter: LaundryStatus.clean)['laundry_status_after'],
        'clean',
      );
      expect(
        build(laundryStatusAfter: LaundryStatus.dirty)['laundry_status_after'],
        'dirty',
      );
      expect(build(laundryStatusAfter: null)['laundry_status_after'], isNull);
      expect(build(outfitId: 'outfit-1')['outfit_id'], 'outfit-1');
      expect(build(outfitId: null)['outfit_id'], isNull);
    });

    test('weather fields are optional and trimmed', () {
      expect(build(weatherTemp: null)['weather_temp'], isNull);
      expect(build(weatherCondition: '   ')['weather_cond'], isNull);

      final Map<String, dynamic> row = build(
        weatherTemp: 32.2,
        weatherCondition: '  Rain  ',
      );

      expect(row['weather_temp'], 32.2);
      expect(row['weather_cond'], 'Rain');
    });
  });
}
