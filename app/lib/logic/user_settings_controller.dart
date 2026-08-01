import 'package:flutter/foundation.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';

class UserSettingsController extends ValueNotifier<UserSettings> {
  static final UserSettingsController instance =
      UserSettingsController._internal();

  UserSettingsController._internal() : super(UserSettings());

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> load() async {
    value = await PrayerDatabase.loadSettings();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> update(UserSettings settings) async {
    value = settings;
    await PrayerDatabase.saveSettings(settings);
    notifyListeners();
  }
}
