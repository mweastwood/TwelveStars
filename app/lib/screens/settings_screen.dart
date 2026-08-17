import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/notification_service.dart';
import 'package:twelve_stars/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserSettings? _settings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await PrayerDatabase.loadSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _loading = false;
      });
    }
  }

  bool get _isSystemThemeSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  List<AppThemeMode> get _availableThemeModes {
    if (_isSystemThemeSupported) {
      return AppThemeMode.values;
    } else {
      return AppThemeMode.values
          .where((mode) => mode != AppThemeMode.system)
          .toList();
    }
  }

  Future<void> _updateHaptics(bool value) async {
    if (_settings == null) return;
    setState(() {
      _settings!.hapticsEnabled = value;
    });
    await PrayerDatabase.saveSettings(_settings!);
  }

  Future<void> _updateThemeMode(AppThemeMode mode) async {
    if (_settings == null) return;
    setState(() {
      _settings!.appThemeMode = mode;
    });
    await PrayerDatabase.saveSettings(_settings!);
    TwelveStarsApp.themeNotifier.value = mode;
  }

  Future<void> _updateSundayNotifications(bool value) async {
    if (_settings == null) return;
    setState(() {
      _settings!.sundayNotificationsEnabled = value;
    });
    await PrayerDatabase.saveSettings(_settings!);
    await NotificationService.syncSundayNotification(_settings!);
  }

  Future<void> _updateBibleNumberingSystem(BibleNumberingSystem system) async {
    if (_settings == null) return;
    setState(() {
      _settings!.bibleNumberingSystem = system;
    });
    await PrayerDatabase.saveSettings(_settings!);
  }

  @override
  Widget build(BuildContext context) {
    final availableModes = _availableThemeModes;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading || _settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  key: const Key('settings_theme_tile'),
                  leading: const Icon(Icons.palette),
                  title: const Text('Theme'),
                  subtitle: Text(_settings!.appThemeMode.label),
                  trailing: DropdownButton<AppThemeMode>(
                    key: const Key('settings_theme_dropdown'),
                    value: availableModes.contains(_settings!.appThemeMode)
                        ? _settings!.appThemeMode
                        : AppThemeMode.marianBlue,
                    items: availableModes.map((mode) {
                      return DropdownMenuItem<AppThemeMode>(
                        key: Key('settings_theme_option_${mode.code}'),
                        value: mode,
                        child: Text(mode.label),
                      );
                    }).toList(),
                    onChanged: (newMode) {
                      if (newMode != null) {
                        _updateThemeMode(newMode);
                      }
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  key: const Key('settings_bible_numbering_tile'),
                  leading: const Icon(Icons.format_list_numbered),
                  title: const Text('Bible Numbering System'),
                  subtitle: Text(_settings!.bibleNumberingSystem.description),
                  trailing: DropdownButton<BibleNumberingSystem>(
                    key: const Key('settings_bible_numbering_dropdown'),
                    value: _settings!.bibleNumberingSystem,
                    items: BibleNumberingSystem.values.map((sys) {
                      return DropdownMenuItem<BibleNumberingSystem>(
                        key: Key('settings_bible_numbering_option_${sys.code}'),
                        value: sys,
                        child: Text(sys.label),
                      );
                    }).toList(),
                    onChanged: (newSys) {
                      if (newSys != null) {
                        _updateBibleNumberingSystem(newSys);
                      }
                    },
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  key: const Key('settings_haptics_tile'),
                  secondary: const Icon(Icons.vibration),
                  title: const Text('Haptic Feedback'),
                  subtitle: const Text(
                    'Vibrate during Rosary navigation and bead interactions',
                  ),
                  value: _settings!.hapticsEnabled,
                  onChanged: _updateHaptics,
                ),
                const Divider(),
                SwitchListTile(
                  key: const Key('settings_sunday_notifications_tile'),
                  secondary: const Icon(Icons.notifications_active),
                  title: const Text('Sunday Liturgical Notification'),
                  subtitle: const Text(
                    'Weekly Sunday morning reminder with current liturgical season and color accent',
                  ),
                  value: _settings!.sundayNotificationsEnabled,
                  onChanged: _updateSundayNotifications,
                ),
              ],
            ),
    );
  }
}
