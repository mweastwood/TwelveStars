import 'package:flutter/widgets.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';

class UserSettingsController extends ValueNotifier<UserSettings> {
  static final UserSettingsController instance =
      UserSettingsController._internal();

  UserSettingsController._internal() : super(UserSettings());

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<UserSettings>? _inFlightLoad;
  Future<void>? _inFlightSave;
  int _resetVersion = 0;
  int _mutationVersion = 0;
  int _pendingSaveCount = 0;
  int? _syncedPrayerCatalogVersion;

  /// Keeps the in-memory [UserSettings.prayerCatalogVersion] synchronized when
  /// [PrayerDatabase.loadPrayers] seeds or upgrades the prayer catalog.
  void syncPrayerCatalogVersion(int version) {
    _syncedPrayerCatalogVersion = version;
    value.prayerCatalogVersion = version;
  }

  /// Clears the cached prayer catalog version (e.g., when [PrayerDatabase.resetCache] is called).
  void clearSyncedPrayerCatalogVersion() {
    _syncedPrayerCatalogVersion = null;
  }

  void _setValueAndNotify(UserSettings newValue) {
    final alreadyEqual = identical(value, newValue) || value == newValue;
    value = newValue;
    if (alreadyEqual) {
      notifyListeners();
    }
  }

  Future<UserSettings> load() {
    if (_pendingSaveCount > 0) {
      return Future.value(value);
    }
    if (_inFlightLoad != null) {
      return _inFlightLoad!;
    }
    late final Future<UserSettings> future;
    future = _performLoad().whenComplete(() {
      if (identical(_inFlightLoad, future)) {
        _inFlightLoad = null;
      }
    });
    _inFlightLoad = future;
    return future;
  }

  Future<UserSettings> _performLoad() async {
    final resetVersion = _resetVersion;
    final loadVersion = _mutationVersion;
    final loaded = await PrayerDatabase.loadSettings();
    if (_syncedPrayerCatalogVersion != null &&
        loaded.prayerCatalogVersion < _syncedPrayerCatalogVersion!) {
      loaded.prayerCatalogVersion = _syncedPrayerCatalogVersion!;
    }
    if (_resetVersion == resetVersion &&
        _mutationVersion == loadVersion &&
        _pendingSaveCount == 0) {
      _isInitialized = true;
      _setValueAndNotify(loaded);
    }
    return value;
  }

  Future<void> update(UserSettings settings) async {
    final resetVersion = _resetVersion;
    final saveVersion = ++_mutationVersion;
    _inFlightLoad = null;
    _isInitialized = true;
    if (_syncedPrayerCatalogVersion != null &&
        settings.prayerCatalogVersion < _syncedPrayerCatalogVersion!) {
      settings.prayerCatalogVersion = _syncedPrayerCatalogVersion!;
    }
    _pendingSaveCount++;
    try {
      _setValueAndNotify(settings);
      if (_resetVersion != resetVersion) return;

      final previousSave = _inFlightSave;
      final currentSave = () async {
        if (previousSave != null) {
          try {
            await previousSave;
          } catch (_) {}
        }
        if (_resetVersion == resetVersion && _mutationVersion == saveVersion) {
          await PrayerDatabase.saveSettings(settings);
        }
      }();
      _inFlightSave = currentSave;
      try {
        await currentSave;
      } finally {
        if (identical(_inFlightSave, currentSave)) {
          _inFlightSave = null;
        }
      }
    } finally {
      if (_resetVersion == resetVersion && _pendingSaveCount > 0) {
        _pendingSaveCount--;
      }
    }
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
        await load();
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
    _resetVersion++;
    _mutationVersion++;
    _pendingSaveCount = 0;
    _inFlightLoad = null;
    _inFlightSave = null;
    _syncedPrayerCatalogVersion = null;
    _isInitialized = false;
    value = UserSettings();
  }
}

/// Reusable [State] mixin that subscribes to [UserSettingsController.instance]
/// in [initState], unsubscribes in [dispose], and forwards updates while
/// [mounted] to [onUserSettingsChanged].
mixin UserSettingsStateMixin<T extends StatefulWidget> on State<T> {
  UserSettings get currentSettings => UserSettingsController.instance.value;

  @override
  void initState() {
    super.initState();
    UserSettingsController.instance.addListener(_handleUserSettingsChanged);
  }

  @override
  void dispose() {
    UserSettingsController.instance.removeListener(_handleUserSettingsChanged);
    super.dispose();
  }

  void _handleUserSettingsChanged() {
    if (!mounted) return;
    onUserSettingsChanged(currentSettings);
  }

  /// Invoked whenever [UserSettingsController.instance] notifies while [mounted].
  @protected
  void onUserSettingsChanged(UserSettings settings) {}

  /// Ensures [UserSettingsController.instance] has loaded persisted settings.
  @protected
  Future<UserSettings> ensureUserSettingsLoaded() {
    return UserSettingsController.instance.load();
  }
}
