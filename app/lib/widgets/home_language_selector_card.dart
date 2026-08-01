import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/prayers.dart';

class HomeLanguageSelectorCard extends StatelessWidget {
  final PrayerLanguage primaryLanguage;
  final PrayerLanguage? compareLanguage;
  final ValueChanged<PrayerLanguage> onPrimaryChanged;
  final ValueChanged<PrayerLanguage?> onSecondaryChanged;
  final VoidCallback onSwap;
  final VoidCallback onClearSecondary;

  const HomeLanguageSelectorCard({
    super.key,
    required this.primaryLanguage,
    required this.compareLanguage,
    required this.onPrimaryChanged,
    required this.onSecondaryChanged,
    required this.onSwap,
    required this.onClearSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: const ValueKey('home_language_selector_card'),
      margin: EdgeInsets.zero,
      elevation: 6.0,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Left dropdown (Primary Language)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 20,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Primary Language',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildPrimaryDropdown(
                    primaryLanguage,
                    onPrimaryChanged,
                    theme,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.swap_horiz,
                color: compareLanguage != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                size: 20,
              ),
              tooltip: 'Swap Languages',
              onPressed: compareLanguage == null ? null : onSwap,
            ),
            const SizedBox(width: 4),
            // Right dropdown (Secondary Language)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Secondary Language',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Visibility(
                          visible: compareLanguage != null,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: InkWell(
                            key: const ValueKey('clear_secondary_language'),
                            onTap: onClearSecondary,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildSecondaryDropdown(
                    compareLanguage,
                    onSecondaryChanged,
                    theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryDropdown(
    PrayerLanguage value,
    ValueChanged<PrayerLanguage> onChanged,
    ThemeData theme,
  ) {
    return SizedBox(
      height: 36,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PrayerLanguage>(
          value: value,
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          isDense: true,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          dropdownColor: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          selectedItemBuilder: (BuildContext context) {
            return PrayerLanguage.values.map((lang) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        lang.flag,
                        style: const TextStyle(fontSize: 16, height: 1.0),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lang.nativeName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList();
          },
          items: PrayerLanguage.values.map((lang) {
            return DropdownMenuItem<PrayerLanguage>(
              value: lang,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  right: 4.0,
                  top: 2.0,
                  bottom: 2.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(lang.flag, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lang.nativeName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSecondaryDropdown(
    PrayerLanguage? value,
    ValueChanged<PrayerLanguage?> onChanged,
    ThemeData theme,
  ) {
    final items = <PrayerLanguage?>[null, ...PrayerLanguage.values];
    return SizedBox(
      height: 36,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PrayerLanguage?>(
          value: value,
          onChanged: onChanged,
          isDense: true,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          dropdownColor: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          selectedItemBuilder: (BuildContext context) {
            return items.map((lang) {
              if (lang == null) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '🚫',
                          style: TextStyle(fontSize: 16, height: 1.0),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'None',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        lang.flag,
                        style: const TextStyle(fontSize: 16, height: 1.0),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lang.nativeName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList();
          },
          items: items.map((lang) {
            if (lang == null) {
              return DropdownMenuItem<PrayerLanguage?>(
                value: null,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 12.0,
                    right: 4.0,
                    top: 2.0,
                    bottom: 2.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('🚫', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'None',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return DropdownMenuItem<PrayerLanguage?>(
              value: lang,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  right: 4.0,
                  top: 2.0,
                  bottom: 2.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(lang.flag, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lang.nativeName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
