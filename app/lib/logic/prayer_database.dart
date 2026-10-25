import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';

class PrayerDatabase {
  static const int kPrayerCatalogVersion = 4;

  static List<Prayer>? mockPrayers;
  static UserSettings? mockSettings;
  static List<Prayer>? _cachedPrayers;
  static Future<List<Prayer>>? _inFlightLoad;

  @visibleForTesting
  static void resetCache() {
    _cachedPrayers = null;
    _inFlightLoad = null;
  }

  // Fetch all prayers from the database
  static Future<List<Prayer>> loadPrayers() {
    if (mockPrayers != null) {
      return Future.value(mockPrayers!);
    }
    if (_cachedPrayers != null) {
      return Future.value(_cachedPrayers!);
    }
    if (_inFlightLoad != null) {
      return _inFlightLoad!;
    }

    final future = _performLoadPrayers();
    _inFlightLoad = future;
    return future.whenComplete(() {
      if (identical(_inFlightLoad, future)) {
        _inFlightLoad = null;
      }
    });
  }

  static Future<List<Prayer>> _performLoadPrayers() async {
    final db = BibleDatabaseHelper.db;
    final list = await db.getAllPrayers();
    final settings = await db.getUserSettings();

    if (list.isNotEmpty &&
        settings?.prayerCatalogVersion == kPrayerCatalogVersion) {
      UserSettingsController.instance.syncPrayerCatalogVersion(
        kPrayerCatalogVersion,
      );
      _cachedPrayers = list;
      return list;
    }

    final compiledPrayers = await _loadPrayersFromWebJson();
    int autoId = 1;
    for (final prayer in compiledPrayers) {
      prayer.isarId = autoId++;
    }
    await db.updatePrayers(compiledPrayers);
    compiledPrayers.sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));

    final currentSettings =
        (await db.getUserSettings()) ?? settings ?? UserSettings();
    currentSettings.prayerCatalogVersion = kPrayerCatalogVersion;
    await db.saveUserSettings(currentSettings);
    UserSettingsController.instance.syncPrayerCatalogVersion(
      kPrayerCatalogVersion,
    );

    _cachedPrayers = compiledPrayers;
    return compiledPrayers;
  }

  static Future<UserSettings> loadSettings() async {
    if (mockSettings != null) {
      return mockSettings!;
    }
    if (mockPrayers != null) {
      return UserSettings();
    }
    final db = BibleDatabaseHelper.db;
    var settings = await db.getUserSettings();
    if (settings == null) {
      settings = UserSettings();
      await db.saveUserSettings(settings);
    }
    return settings;
  }

  static Future<void> saveSettings(UserSettings settings) async {
    if (mockSettings != null) {
      mockSettings = settings;
      return;
    }
    if (mockPrayers != null) return;
    final db = BibleDatabaseHelper.db;
    await db.saveUserSettings(settings);
  }

  static Future<List<Prayer>> _loadPrayersFromWebJson() async {
    final jsonStr = await rootBundle.loadString('assets/prayers.json');
    return loadPrayersFromJson(jsonStr);
  }

  static List<Prayer> loadPrayersFromJson(String jsonStr) {
    if (jsonStr.isEmpty) return [];

    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } catch (_) {
      return [];
    }

    if (decoded is! List) {
      return [];
    }

    final List<Prayer> prayers = [];

    for (final item in decoded) {
      if (item is! Map) continue;
      final pMap = item is Map<String, dynamic>
          ? item
          : Map<String, dynamic>.from(item);
      final prayer = Prayer.tryFromAssetJson(pMap);
      if (prayer != null) {
        prayers.add(prayer);
      }
    }

    return prayers;
  }
}
