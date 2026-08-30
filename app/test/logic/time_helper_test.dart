import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/time_helper.dart';

void main() {
  group('TimeHelper', () {
    setUp(() {
      TimeHelper.setCustomTime(null);
    });

    tearDown(() {
      TimeHelper.setCustomTime(null);
    });

    group('Default System Time', () {
      test('returns system time when no custom time is set', () {
        final before = DateTime.now();
        final helperNow = TimeHelper.now();
        final after = DateTime.now();

        expect(helperNow.isBefore(before), isFalse);
        expect(helperNow.isAfter(after), isFalse);
        expect(
          helperNow.difference(before).inMilliseconds,
          lessThanOrEqualTo(1000),
        );
      });
    });

    group('Custom Time Override', () {
      test(
        'returns fixed overridden timestamp when setCustomTime is called',
        () {
          final customTime = DateTime(2026, 8, 15, 10, 30, 0);
          TimeHelper.setCustomTime(customTime);

          expect(TimeHelper.now(), equals(customTime));
        },
      );

      test(
        'reflects updated timestamp when setCustomTime is called multiple times',
        () {
          final firstTime = DateTime(2025, 1, 1, 0, 0, 0);
          final secondTime = DateTime(2026, 12, 25, 18, 45, 30);
          final utcTime = DateTime.utc(2024, 2, 29, 12, 0, 0);

          TimeHelper.setCustomTime(firstTime);
          expect(TimeHelper.now(), equals(firstTime));

          TimeHelper.setCustomTime(secondTime);
          expect(TimeHelper.now(), equals(secondTime));

          TimeHelper.setCustomTime(utcTime);
          expect(TimeHelper.now(), equals(utcTime));
        },
      );
    });

    group('Resetting Custom Time', () {
      test(
        'restores default system time when setCustomTime is reset to null',
        () {
          final customTime = DateTime(2020, 1, 1);
          TimeHelper.setCustomTime(customTime);
          expect(TimeHelper.now(), equals(customTime));

          TimeHelper.setCustomTime(null);

          final before = DateTime.now();
          final helperNow = TimeHelper.now();
          final after = DateTime.now();

          expect(helperNow.isBefore(before), isFalse);
          expect(helperNow.isAfter(after), isFalse);
          expect(
            helperNow.difference(before).inMilliseconds,
            lessThanOrEqualTo(1000),
          );
        },
      );
    });
  });
}
