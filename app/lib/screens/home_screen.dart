import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
import 'package:twelve_stars/screens/rosary_screen.dart';
import 'package:twelve_stars/screens/bible_tab.dart';
import 'package:twelve_stars/screens/calendar_tab.dart';
import 'package:twelve_stars/screens/missal_tab.dart';

class HomeScreen extends StatefulWidget {
  final DateTime? initialDate;
  const HomeScreen({super.key, this.initialDate});

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
  UserSettings? _settings;

  bool _isSearching = false;
  String _searchQuery = '';
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() {
      _isSearching = true;
    });
    _searchFocusNode.requestFocus();
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prayers = await PrayerDatabase.loadPrayers();
      final settings = await PrayerDatabase.loadSettings();
      if (mounted) {
        setState(() {
          _prayers = prayers;
          _settings = settings;
          _primaryLanguage = settings.primaryLanguage;
          _compareLanguage = settings.compareLanguage;
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
                        _settings?.primaryLanguageCode = lang
                            .toString()
                            .split('.')
                            .last;
                        _settings?.compareLanguageCode = _compareLanguage
                            .toString()
                            .split('.')
                            .last;
                      });
                      if (_settings != null) {
                        PrayerDatabase.saveSettings(_settings!);
                      }
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
                        _settings?.compareLanguageCode = lang
                            .toString()
                            .split('.')
                            .last;
                        _settings?.primaryLanguageCode = _primaryLanguage
                            .toString()
                            .split('.')
                            .last;
                      });
                      if (_settings != null) {
                        PrayerDatabase.saveSettings(_settings!);
                      }
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
      CalendarTab(initialDate: widget.initialDate),
      MissalTab(
        primaryLanguage: _primaryLanguage,
        compareLanguage: _compareLanguage,
      ),
      const BibleTab(),
    ];

    final scaffold = Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: const InputDecoration(
                  hintText: 'Search prayers...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : const Text('Twelve Stars'),
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _closeSearch,
              )
            : null,
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
                _searchFocusNode.requestFocus();
              },
            )
          else if (_currentTab == 0)
            IconButton(icon: const Icon(Icons.search), onPressed: _openSearch),
        ],
      ),
      body: SafeArea(child: tabs[_currentTab]),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RosaryScreen(
                      prayers: _prayers,
                      primaryLanguage: _primaryLanguage,
                      compareLanguage: _compareLanguage,
                      onLaunchSource: _launchSourceUrl,
                      initialDate: widget.initialDate,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.grain),
              label: const Text('Start Rosary'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() {
            _currentTab = index;
            if (index != 0 && _isSearching) {
              _closeSearch();
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Prayers',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Missal',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Bible',
          ),
        ],
      ),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.slash): () {
          final primaryFocus = FocusManager.instance.primaryFocus;
          final isEditableFocused =
              primaryFocus?.context?.widget is EditableText;
          if (_currentTab == 0 && !_isSearching && !isEditableFocused) {
            _openSearch();
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_isSearching) {
            _closeSearch();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: !_isSearching,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_isSearching) {
              _closeSearch();
            }
          },
          child: scaffold,
        ),
      ),
    );
  }

  Widget _buildPrayersTab(ThemeData theme) {
    final prayers = _prayers;
    if (prayers == null || prayers.isEmpty) {
      return const Center(child: Text('No prayers found.'));
    }

    final query = _searchQuery.trim().toLowerCase();
    final filteredPrayers = prayers.where((prayer) {
      if (prayer.category == 'liturgy') return false;
      final transList = prayer.translations[_primaryLanguage];
      if (transList == null || transList.isEmpty) return false;
      if (query.isEmpty) return true;
      final trans = transList[0];

      final queryWords = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
      if (queryWords.isEmpty) return true;

      return queryWords.every((word) {
        final matchTitle = trans.title.toLowerCase().contains(word);
        final matchSubtitle = trans.subtitle.toLowerCase().contains(word);
        final matchText = trans.text.toLowerCase().contains(word);
        return matchTitle || matchSubtitle || matchText;
      });
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          _buildGlobalLanguageSelectors(theme),
          const SizedBox(height: 12),
          if (filteredPrayers.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  Text(
                    'No prayers matching "$_searchQuery"',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                    child: const Text('Clear search'),
                  ),
                ],
              ),
            )
          else
            ...filteredPrayers.map((prayer) {
              final prefKey =
                  '${prayer.prayerId}_${_primaryLanguage.toString().split('.').last}';
              final initialVersion =
                  _settings?.preferredVersions
                      ?.firstWhere(
                        (p) => p.key == prefKey,
                        orElse: () => PrayerVersionPreference(),
                      )
                      .versionIndex ??
                  0;

              return PrayerCard(
                prayer: prayer,
                selectedLanguage: _primaryLanguage,
                compareLanguage: _compareLanguage,
                initialVersionIndex: initialVersion,
                onVersionChanged: (newIndex) async {
                  if (_settings != null) {
                    final list = _settings!.preferredVersions ?? [];
                    final idx = list.indexWhere((p) => p.key == prefKey);
                    if (idx >= 0) {
                      list[idx].versionIndex = newIndex;
                    } else {
                      list.add(PrayerVersionPreference(prefKey, newIndex));
                    }
                    _settings!.preferredVersions = list;
                    await PrayerDatabase.saveSettings(_settings!);
                  }
                },
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
