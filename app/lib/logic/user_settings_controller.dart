import 'package:flutter/foundation.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';

class UserSettingsController extends ValueNotifier<UserSettings> {
  static final UserSettingsController instance =
      UserSettingsController._internal();

  UserSettingsController._internal() : super(UserSettings());

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<UserSettings>? _inFlightLoad;
  int _mutationVersion = 0;

  void _setValueAndNotify(UserSettings newValue) {
    final alreadyEqual = identical(value, newValue) || value == newValue;
    value = newValue;
    if (alreadyEqual) {
      notifyListeners();
    }
  }

  Future<UserSettings> load() async {
    if (_inFlightLoad != null) {
      return _inFlightLoad!;
    }
    final loadVersion = _mutationVersion;
    final future = PrayerDatabase.loadSettings();
    _inFlightLoad = future;
    try {
      final loaded = await future;
      if (_mutationVersion == loadVersion) {
        _isInitialized = true;
        _setValueAndNotify(loaded);
      }
      return value;
    } finally {
      if (identical(_inFlightLoad, future)) {
        _inFlightLoad = null;
      }
    }
  }

  Future<void> update(UserSettings settings) async {
    _mutationVersion++;
    _inFlightLoad = null;
    _isInitialized = true;
    _setValueAndNotify(settings);
    await PrayerDatabase.saveSettings(settings);
  }

  /// Mutates the active [UserSettings] in place, notifies all listeners,
  /// and persists the updated state to [PrayerDatabase].
  Future<UserSettings> mutate(
    void Function(UserSettings settings) mutator,
  ) async {
    if (!_isInitialized) {
      if (PrayerDatabase.mockSettings != null) {
        value = PrayerDatabase.mockSettings!;
        _isInitialized = true;
      } else if (PrayerDatabase.mockPrayers != null) {
        _isInitialized = true;
      } else {
        final loaded = await PrayerDatabase.loadSettings();
        value = loaded;
        _isInitialized = true;
      }
    } else if (PrayerDatabase.mockSettings != null &&
        !identical(value, PrayerDatabase.mockSettings)) {
      value = PrayerDatabase.mockSettings!;
    }
    final current = value;
    mutator(current);
    await update(current);
    return current;
  }

  @visibleForTesting
  void resetForTesting() {
    _mutationVersion++;
    _inFlightLoad = null;
    _isInitialized = false;
    value = UserSettings();
  }
}
