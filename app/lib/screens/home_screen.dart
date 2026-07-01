import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
import 'package:twelve_stars/screens/rosary_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  PrayerLanguage _primaryLanguage = PrayerLanguage.english;
  PrayerLanguage _compareLanguage = PrayerLanguage.latin;
  List<Prayer>? _prayers;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prayers = await PrayerDatabase.loadPrayers();
      if (mounted) {
        setState(() {
          _prayers = prayers;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Widget _buildGlobalLanguageSelectors(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Left dropdown (Primary Language)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primary Language',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildGlobalDropdown(_primaryLanguage, (lang) {
                    if (lang != null) {
                      setState(() {
                        _primaryLanguage = lang;
                        if (_compareLanguage == lang) {
                          // Automatically switch compare language to avoid duplicates
                          _compareLanguage = PrayerLanguage.values.firstWhere(
                            (l) => l != lang,
                          );
                        }
                      });
                    }
                  }, theme),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.swap_horiz,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 20,
            ),
            const SizedBox(width: 12),
            // Right dropdown (Compare Language)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compare Language',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildGlobalDropdown(_compareLanguage, (lang) {
                    if (lang != null) {
                      setState(() {
                        _compareLanguage = lang;
                        if (_primaryLanguage == lang) {
                          _primaryLanguage = PrayerLanguage.values.firstWhere(
                            (l) => l != lang,
                          );
                        }
                      });
                    }
                  }, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalDropdown(
    PrayerLanguage value,
    ValueChanged<PrayerLanguage?> onChanged,
    ThemeData theme,
  ) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<PrayerLanguage>(
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
    );
  }

  Future<void> _launchSourceUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch source URL: $urlString'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tabs = [
      _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error loading prayers: $_error'))
          : _buildPrayersTab(theme),
      const RosaryTab(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Twelve Stars')),
      body: SafeArea(child: tabs[_currentTab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Prayers',
          ),
          NavigationDestination(
            icon: Icon(Icons.grain_outlined),
            selectedIcon: Icon(Icons.grain),
            label: 'Rosary',
          ),
        ],
      ),
    );
  }

  Widget _buildPrayersTab(ThemeData theme) {
    final prayers = _prayers;
    if (prayers == null || prayers.isEmpty) {
      return const Center(child: Text('No prayers found.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          _buildGlobalLanguageSelectors(theme),
          const SizedBox(height: 12),
          ...prayers.map((prayer) {
            return PrayerCard(
              prayer: prayer,
              selectedLanguage: _primaryLanguage,
              compareLanguage: _compareLanguage,
              onLaunchSource: _launchSourceUrl,
            );
          }),
          const SizedBox(height: 24),
          Text(
            '“A great sign appeared in heaven: a woman clothed with the sun, with the moon under her feet, and on her head a crown of twelve stars.”',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '— Revelation 12:1',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
