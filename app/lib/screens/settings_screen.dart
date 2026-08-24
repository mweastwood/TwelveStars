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

  Future<void> _updateAngelusEnabled(bool value) async {
    if (_settings == null) return;
    setState(() {
      _settings!.angelusReminderEnabled = value;
    });
    await PrayerDatabase.saveSettings(_settings!);
    await NotificationService.syncAngelusNotifications(_settings!);
  }

  Future<void> _updateAngelusMorning(bool value) async {
    if (_settings == null) return;
    setState(() {
      _settings!.angelusMorningEnabled = value;
    });
    await PrayerDatabase.saveSettings(_settings!);
    await NotificationService.syncAngelusNotifications(_settings!);
  }

  Future<void> _updateAngelusMidday(bool value) async {
    if (_settings == null) return;
    setState(() {
      _settings!.angelusMiddayEnabled = value;
    });
    await PrayerDatabase.saveSettings(_settings!);
    await NotificationService.syncAngelusNotifications(_settings!);
  }

  Future<void> _updateAngelusEvening(bool value) async {
    if (_settings == null) return;
    setState(() {
      _settings!.angelusEveningEnabled = value;
    });
    await PrayerDatabase.saveSettings(_settings!);
    await NotificationService.syncAngelusNotifications(_settings!);
  }

  Future<void> _updateRosaryEnabled(bool value) async {
    if (_settings == null) return;
    setState(() {
      _settings!.rosaryReminderEnabled = value;
    });
    await PrayerDatabase.saveSettings(_settings!);
    await NotificationService.syncRosaryNotification(_settings!);
  }

  Future<void> _updateRosaryTime(TimeOfDay time) async {
    if (_settings == null) return;
    setState(() {
      _settings!.rosaryReminderHour = time.hour;
      _settings!.rosaryReminderMinute = time.minute;
    });
    await PrayerDatabase.saveSettings(_settings!);
    await NotificationService.syncRosaryNotification(_settings!);
  }

  Future<void> _updateMorningPrayerEnabled(bool value) async {
    if (_settings == null) return;
    setState(() {
      _settings!.morningPrayerReminderEnabled = value;
    });
    await PrayerDatabase.saveSettings(_settings!);
    await NotificationService.syncMorningPrayerNotification(_settings!);
  }

  Future<void> _updateMorningPrayerTime(TimeOfDay time) async {
    if (_settings == null) return;
    setState(() {
      _settings!.morningPrayerReminderHour = time.hour;
      _settings!.morningPrayerReminderMinute = time.minute;
    });
    await PrayerDatabase.saveSettings(_settings!);
    await NotificationService.syncMorningPrayerNotification(_settings!);
  }

  Future<void> _updateNightPrayerEnabled(bool value) async {
    if (_settings == null) return;
    setState(() {
      _settings!.nightPrayerReminderEnabled = value;
    });
    await PrayerDatabase.saveSettings(_settings!);
    await NotificationService.syncNightPrayerNotification(_settings!);
  }

  Future<void> _updateNightPrayerTime(TimeOfDay time) async {
    if (_settings == null) return;
    setState(() {
      _settings!.nightPrayerReminderHour = time.hour;
      _settings!.nightPrayerReminderMinute = time.minute;
    });
    await PrayerDatabase.saveSettings(_settings!);
    await NotificationService.syncNightPrayerNotification(_settings!);
  }

  Future<void> _updateBibleNumberingSystem(BibleNumberingSystem system) async {
    if (_settings == null) return;
    setState(() {
      _settings!.bibleNumberingSystem = system;
    });
    await PrayerDatabase.saveSettings(_settings!);
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Prayer Reminders',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SwitchListTile(
                  key: const Key('settings_sunday_notifications_tile'),
                  secondary: const Icon(Icons.calendar_today),
                  title: const Text('Sunday Liturgical Notification'),
                  subtitle: const Text(
                    'Weekly Sunday morning reminder with current liturgical season and color accent',
                  ),
                  value: _settings!.sundayNotificationsEnabled,
                  onChanged: _updateSundayNotifications,
                ),
                const Divider(),
                SwitchListTile(
                  key: const Key('settings_angelus_tile'),
                  secondary: const Icon(Icons.notifications_active),
                  title: const Text('The Angelus / Regina Caeli'),
                  subtitle: const Text(
                    'Traditional devotion (switches to Regina Caeli during Easter)',
                  ),
                  value: _settings!.angelusReminderEnabled,
                  onChanged: _updateAngelusEnabled,
                ),
                if (_settings!.angelusReminderEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 72.0,
                      right: 16.0,
                      bottom: 8.0,
                    ),
                    child: Wrap(
                      spacing: 8.0,
                      children: [
                        FilterChip(
                          key: const Key('settings_angelus_morning_chip'),
                          label: const Text('6:00 AM'),
                          selected: _settings!.angelusMorningEnabled,
                          onSelected: _updateAngelusMorning,
                        ),
                        FilterChip(
                          key: const Key('settings_angelus_midday_chip'),
                          label: const Text('12:00 PM'),
                          selected: _settings!.angelusMiddayEnabled,
                          onSelected: _updateAngelusMidday,
                        ),
                        FilterChip(
                          key: const Key('settings_angelus_evening_chip'),
                          label: const Text('6:00 PM'),
                          selected: _settings!.angelusEveningEnabled,
                          onSelected: _updateAngelusEvening,
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(),
                ListTile(
                  key: const Key('settings_rosary_tile'),
                  leading: const Icon(Icons.auto_stories),
                  title: const Text('Daily Rosary'),
                  subtitle: Text(
                    _settings!.rosaryReminderEnabled
                        ? 'Daily reminder at ${_formatTime(_settings!.rosaryReminderHour, _settings!.rosaryReminderMinute)} for the day\'s mystery'
                        : 'Daily reminder for the mystery of the day',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_settings!.rosaryReminderEnabled)
                        ActionChip(
                          key: const Key('settings_rosary_time_button'),
                          label: Text(
                            _formatTime(
                              _settings!.rosaryReminderHour,
                              _settings!.rosaryReminderMinute,
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: _settings!.rosaryReminderHour,
                                minute: _settings!.rosaryReminderMinute,
                              ),
                            );
                            if (picked != null) {
                              _updateRosaryTime(picked);
                            }
                          },
                        ),
                      Switch(
                        key: const Key('settings_rosary_switch'),
                        value: _settings!.rosaryReminderEnabled,
                        onChanged: _updateRosaryEnabled,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  key: const Key('settings_morning_prayer_tile'),
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: const Text('Morning Prayer'),
                  subtitle: Text(
                    _settings!.morningPrayerReminderEnabled
                        ? 'Daily morning offering at ${_formatTime(_settings!.morningPrayerReminderHour, _settings!.morningPrayerReminderMinute)}'
                        : 'Daily morning offering reminder',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_settings!.morningPrayerReminderEnabled)
                        ActionChip(
                          key: const Key('settings_morning_prayer_time_button'),
                          label: Text(
                            _formatTime(
                              _settings!.morningPrayerReminderHour,
                              _settings!.morningPrayerReminderMinute,
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: _settings!.morningPrayerReminderHour,
                                minute: _settings!.morningPrayerReminderMinute,
                              ),
                            );
                            if (picked != null) {
                              _updateMorningPrayerTime(picked);
                            }
                          },
                        ),
                      Switch(
                        key: const Key('settings_morning_prayer_switch'),
                        value: _settings!.morningPrayerReminderEnabled,
                        onChanged: _updateMorningPrayerEnabled,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  key: const Key('settings_night_prayer_tile'),
                  leading: const Icon(Icons.bedtime_outlined),
                  title: const Text('Night Prayer (Compline)'),
                  subtitle: Text(
                    _settings!.nightPrayerReminderEnabled
                        ? 'Night prayer & examination of conscience at ${_formatTime(_settings!.nightPrayerReminderHour, _settings!.nightPrayerReminderMinute)}'
                        : 'Night prayer & examination of conscience reminder',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_settings!.nightPrayerReminderEnabled)
                        ActionChip(
                          key: const Key('settings_night_prayer_time_button'),
                          label: Text(
                            _formatTime(
                              _settings!.nightPrayerReminderHour,
                              _settings!.nightPrayerReminderMinute,
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: _settings!.nightPrayerReminderHour,
                                minute: _settings!.nightPrayerReminderMinute,
                              ),
                            );
                            if (picked != null) {
                              _updateNightPrayerTime(picked);
                            }
                          },
                        ),
                      Switch(
                        key: const Key('settings_night_prayer_switch'),
                        value: _settings!.nightPrayerReminderEnabled,
                        onChanged: _updateNightPrayerEnabled,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
