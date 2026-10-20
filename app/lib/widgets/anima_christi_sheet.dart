import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';

/// Modal bottom sheet widget displaying the Anima Christi prayer
/// for silent thanksgiving after receiving Holy Communion.
class AnimaChristiSheet extends StatefulWidget {
  final Prayer prayer;
  final PrayerLanguage primaryLanguage;
  final PrayerLanguage? compareLanguage;
  final double fontSize;
  final UserSettings? settings;
  final ValueChanged<int>? onVersionChanged;

  const AnimaChristiSheet({
    super.key,
    required this.prayer,
    required this.primaryLanguage,
    this.compareLanguage,
    this.fontSize = 16.0,
    this.settings,
    this.onVersionChanged,
  });

  /// Displays the [AnimaChristiSheet] in a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required Prayer prayer,
    required PrayerLanguage primaryLanguage,
    PrayerLanguage? compareLanguage,
    double fontSize = 16.0,
    UserSettings? settings,
    ValueChanged<int>? onVersionChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AnimaChristiSheet(
        prayer: prayer,
        primaryLanguage: primaryLanguage,
        compareLanguage: compareLanguage,
        fontSize: fontSize,
        settings: settings,
        onVersionChanged: onVersionChanged,
      ),
    );
  }

  @override
  State<AnimaChristiSheet> createState() => _AnimaChristiSheetState();
}

class _AnimaChristiSheetState extends State<AnimaChristiSheet> {
  UserSettings? _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    UserSettingsController.instance.addListener(_onSettingsChanged);
    if (_settings == null) {
      _loadSettings();
    }
  }

  @override
  void dispose() {
    UserSettingsController.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {
      _settings = UserSettingsController.instance.value;
    });
  }

  Future<void> _loadSettings() async {
    try {
      final s = await UserSettingsController.instance.load();
      if (mounted) {
        setState(() {
          _settings = s;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefKey = '${widget.prayer.prayerId}_${widget.primaryLanguage.code}';
    final initialVersion = _settings?.getPreferredVersionIndex(prefKey) ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.auto_stories,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anima Christi',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Thanksgiving after Communion',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              PrayerCard(
                prayer: widget.prayer,
                selectedLanguage: widget.primaryLanguage,
                compareLanguage: widget.compareLanguage,
                initialVersionIndex: initialVersion,
                fontSize: widget.fontSize,
                onVersionChanged: (newIndex) async {
                  if (widget.onVersionChanged != null) {
                    widget.onVersionChanged!(newIndex);
                  }
                  if (_settings != null) {
                    _settings!.setPreferredVersionIndex(prefKey, newIndex);
                    await UserSettingsController.instance.update(_settings!);
                  } else {
                    await UserSettingsController.instance.mutate((s) {
                      s.setPreferredVersionIndex(prefKey, newIndex);
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
