import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/notification_service.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with UserSettingsStateMixin<SettingsScreen> {
  UserSettings? _settings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void onUserSettingsChanged(UserSettings settings) {
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _loadSettings() async {
    final settings = await ensureUserSettingsLoaded();
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
        defaultTargetPlatform == TargetPlatform.iOS ||
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
    await UserSettingsController.instance.mutate((s) {
      s.hapticsEnabled = value;
    });
  }

  Future<void> _updateThemeMode(AppThemeMode mode) async {
    if (_settings == null) return;
    await UserSettingsController.instance.mutate((s) {
      s.appThemeMode = mode;
    });
    TwelveStarsApp.themeNotifier.value = mode;
  }

  Future<void> _safeSync(Future<void> Function() syncAction) async {
    try {
      await syncAction();
    } catch (e, stack) {
      debugPrint('SettingsScreen notification sync error: $e\n$stack');
    }
  }

  Future<void> _updateSundayNotifications(bool value) async {
    if (_settings == null) return;
    final updated = await UserSettingsController.instance.mutate((s) {
      s.sundayNotificationsEnabled = value;
    });
    await _safeSync(() => NotificationService.syncSundayNotification(updated));
  }

  Future<void> _updateAngelusEnabled(bool value) async {
    if (_settings == null) return;
    final updated = await UserSettingsController.instance.mutate((s) {
      s.angelusReminderEnabled = value;
    });
    await _safeSync(
      () => NotificationService.syncAngelusNotifications(updated),
    );
  }

  Future<void> _updateAngelusMorning(bool value) async {
    if (_settings == null) return;
    final updated = await UserSettingsController.instance.mutate((s) {
      s.angelusMorningEnabled = value;
    });
    await _safeSync(
      () => NotificationService.syncAngelusNotifications(updated),
    );
  }

  Future<void> _updateAngelusMidday(bool value) async {
    if (_settings == null) return;
    final updated = await UserSettingsController.instance.mutate((s) {
      s.angelusMiddayEnabled = value;
    });
    await _safeSync(
      () => NotificationService.syncAngelusNotifications(updated),
    );
  }

  Future<void> _updateAngelusEvening(bool value) async {
    if (_settings == null) return;
    final updated = await UserSettingsController.instance.mutate((s) {
      s.angelusEveningEnabled = value;
    });
    await _safeSync(
      () => NotificationService.syncAngelusNotifications(updated),
    );
  }

  Future<void> _updateRosaryEnabled(bool value) async {
    if (_settings == null) return;
    final updated = await UserSettingsController.instance.mutate((s) {
      s.rosaryReminderEnabled = value;
    });
    await _safeSync(() => NotificationService.syncRosaryNotification(updated));
  }

  Future<void> _updateRosaryTime(TimeOfDay time) async {
    if (_settings == null) return;
    final updated = await UserSettingsController.instance.mutate((s) {
      s.rosaryReminderHour = time.hour;
      s.rosaryReminderMinute = time.minute;
    });
    await _safeSync(() => NotificationService.syncRosaryNotification(updated));
  }

  Future<void> _updateMorningPrayerEnabled(bool value) async {
    if (_settings == null) return;
    final updated = await UserSettingsController.instance.mutate((s) {
      s.morningPrayerReminderEnabled = value;
    });
    await _safeSync(
      () => NotificationService.syncMorningPrayerNotification(updated),
    );
  }

  Future<void> _updateMorningPrayerTime(TimeOfDay time) async {
    if (_settings == null) return;
    final updated = await UserSettingsController.instance.mutate((s) {
      s.morningPrayerReminderHour = time.hour;
      s.morningPrayerReminderMinute = time.minute;
    });
    await _safeSync(
      () => NotificationService.syncMorningPrayerNotification(updated),
    );
  }

  Future<void> _updateNightPrayerEnabled(bool value) async {
    if (_settings == null) return;
    final updated = await UserSettingsController.instance.mutate((s) {
      s.nightPrayerReminderEnabled = value;
    });
    await _safeSync(
      () => NotificationService.syncNightPrayerNotification(updated),
    );
  }

  Future<void> _updateNightPrayerTime(TimeOfDay time) async {
    if (_settings == null) return;
    final updated = await UserSettingsController.instance.mutate((s) {
      s.nightPrayerReminderHour = time.hour;
      s.nightPrayerReminderMinute = time.minute;
    });
    await _safeSync(
      () => NotificationService.syncNightPrayerNotification(updated),
    );
  }

  Future<void> _updateBibleNumberingSystem(BibleNumberingSystem system) async {
    if (_settings == null) return;
    await UserSettingsController.instance.mutate((s) {
      s.bibleNumberingSystem = system;
    });
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
                _TimedReminderTile(
                  tileKey: const Key('settings_rosary_tile'),
                  timeButtonKey: const Key('settings_rosary_time_button'),
                  switchKey: const Key('settings_rosary_switch'),
                  icon: Icons.auto_stories,
                  title: 'Daily Rosary',
                  enabled: _settings!.rosaryReminderEnabled,
                  hour: _settings!.rosaryReminderHour,
                  minute: _settings!.rosaryReminderMinute,
                  enabledSubtitleBuilder: (time) =>
                      'Daily reminder at $time for the day\'s mystery',
                  disabledSubtitle: 'Daily reminder for the mystery of the day',
                  onEnabledChanged: _updateRosaryEnabled,
                  onTimeChanged: _updateRosaryTime,
                ),
                const Divider(),
                _TimedReminderTile(
                  tileKey: const Key('settings_morning_prayer_tile'),
                  timeButtonKey: const Key(
                    'settings_morning_prayer_time_button',
                  ),
                  switchKey: const Key('settings_morning_prayer_switch'),
                  icon: Icons.wb_sunny_outlined,
                  title: 'Morning Prayer',
                  enabled: _settings!.morningPrayerReminderEnabled,
                  hour: _settings!.morningPrayerReminderHour,
                  minute: _settings!.morningPrayerReminderMinute,
                  enabledSubtitleBuilder: (time) =>
                      'Daily morning offering at $time',
                  disabledSubtitle: 'Daily morning offering reminder',
                  onEnabledChanged: _updateMorningPrayerEnabled,
                  onTimeChanged: _updateMorningPrayerTime,
                ),
                const Divider(),
                _TimedReminderTile(
                  tileKey: const Key('settings_night_prayer_tile'),
                  timeButtonKey: const Key('settings_night_prayer_time_button'),
                  switchKey: const Key('settings_night_prayer_switch'),
                  icon: Icons.bedtime_outlined,
                  title: 'Night Prayer (Compline)',
                  enabled: _settings!.nightPrayerReminderEnabled,
                  hour: _settings!.nightPrayerReminderHour,
                  minute: _settings!.nightPrayerReminderMinute,
                  enabledSubtitleBuilder: (time) =>
                      'Night prayer & examination of conscience at $time',
                  disabledSubtitle:
                      'Night prayer & examination of conscience reminder',
                  onEnabledChanged: _updateNightPrayerEnabled,
                  onTimeChanged: _updateNightPrayerTime,
                ),
              ],
            ),
    );
  }
}

class _TimedReminderTile extends StatelessWidget {
  final Key tileKey;
  final Key timeButtonKey;
  final Key switchKey;
  final IconData icon;
  final String title;
  final String Function(String formattedTime) enabledSubtitleBuilder;
  final String disabledSubtitle;
  final bool enabled;
  final int hour;
  final int minute;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const _TimedReminderTile({
    required this.tileKey,
    required this.timeButtonKey,
    required this.switchKey,
    required this.icon,
    required this.title,
    required this.enabledSubtitleBuilder,
    required this.disabledSubtitle,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.onEnabledChanged,
    required this.onTimeChanged,
  });

  static String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatTime(hour, minute);
    return ListTile(
      key: tileKey,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        enabled ? enabledSubtitleBuilder(formattedTime) : disabledSubtitle,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (enabled)
            ActionChip(
              key: timeButtonKey,
              label: Text(formattedTime),
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: hour, minute: minute),
                );
                if (!context.mounted) return;
                if (picked != null) {
                  onTimeChanged(picked);
                }
              },
            ),
          Switch(key: switchKey, value: enabled, onChanged: onEnabledChanged),
        ],
      ),
    );
  }
}
