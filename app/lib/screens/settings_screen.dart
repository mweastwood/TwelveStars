import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/prayers.dart';

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

  Future<void> _updateHaptics(bool value) async {
    if (_settings == null) return;
    setState(() {
      _settings!.hapticsEnabled = value;
    });
    await PrayerDatabase.saveSettings(_settings!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading || _settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
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
              ],
            ),
    );
  }
}
