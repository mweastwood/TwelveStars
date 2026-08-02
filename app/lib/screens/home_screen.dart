import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
import 'package:twelve_stars/widgets/home_language_selector_card.dart';
import 'package:twelve_stars/screens/rosary_screen.dart';
import 'package:twelve_stars/screens/bible_tab.dart';
import 'package:twelve_stars/screens/missal_tab.dart';
import 'package:twelve_stars/screens/library_tab.dart';
import 'package:twelve_stars/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final DateTime? initialDate;
  const HomeScreen({super.key, this.initialDate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  PrayerLanguage _primaryLanguage = PrayerLanguage.english;
  PrayerLanguage? _compareLanguage = PrayerLanguage.latin;
  bool _showLanguageSelectors = false;
  List<Prayer>? _prayers;
  bool _loading = true;
  String? _error;
  UserSettings? _settings;
  double _fontSize = 16.0;

  bool _isSearching = false;
  String _searchQuery = '';
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  late final AnimationController _languageSelectorAnimationController;
  late final CurvedAnimation _languageSelectorAnimation;
  final ScrollController _prayersScrollController = ScrollController();
  final ScrollController _missalScrollController = ScrollController();

  static const double _kLanguageSelectorTopSpacerHeight = 92.0;

  bool _wasScrolledDown = false;
  double _initialScrollOffset = 0.0;

  ScrollController? get _activeScrollController {
    if (_currentTab == 0) return _prayersScrollController;
    if (_currentTab == 1) return _missalScrollController;
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _languageSelectorAnimationController.removeListener(
      _onLanguageSelectorAnimationTick,
    );
    _languageSelectorAnimationController.dispose();
    _prayersScrollController.dispose();
    _missalScrollController.dispose();
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
    _languageSelectorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: _showLanguageSelectors ? 1.0 : 0.0,
    );
    _languageSelectorAnimation = CurvedAnimation(
      parent: _languageSelectorAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _languageSelectorAnimationController.addListener(
      _onLanguageSelectorAnimationTick,
    );
    _languageSelectorAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed ||
          status == AnimationStatus.completed) {
        if (mounted) setState(() {});
      }
    });
    _loadData();
  }

  void _toggleLanguageSelectors() {
    final controller = _activeScrollController;
    final offset = controller != null && controller.hasClients
        ? controller.offset
        : 0.0;
    _wasScrolledDown = offset > 5.0;
    _initialScrollOffset =
        offset -
        (_kLanguageSelectorTopSpacerHeight * _languageSelectorAnimation.value);

    if (_showLanguageSelectors) {
      _showLanguageSelectors = false;
      _languageSelectorAnimationController.reverse();
    } else {
      _showLanguageSelectors = true;
      _languageSelectorAnimationController.forward();
    }
    setState(() {});
  }

  void _onLanguageSelectorAnimationTick() {
    final controller = _activeScrollController;
    if (!_wasScrolledDown || controller == null || !controller.hasClients) {
      return;
    }

    final targetOffset =
        _initialScrollOffset +
        (_kLanguageSelectorTopSpacerHeight * _languageSelectorAnimation.value);
    final maxExtent =
        controller.position.maxScrollExtent + _kLanguageSelectorTopSpacerHeight;
    controller.jumpTo(targetOffset.clamp(0.0, maxExtent));
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
    return HomeLanguageSelectorCard(
      primaryLanguage: _primaryLanguage,
      compareLanguage: _compareLanguage,
      onPrimaryChanged: (lang) {
        setState(() {
          _primaryLanguage = lang;
          if (_compareLanguage == lang) {
            _compareLanguage = null;
          }
          _settings?.primaryLanguageCode = lang.code;
          _settings?.compareLanguageCode = _compareLanguage?.code ?? 'none';
        });
        if (_settings != null) {
          PrayerDatabase.saveSettings(_settings!);
        }
      },
      onSecondaryChanged: (lang) {
        setState(() {
          _compareLanguage = lang;
          if (lang != null && _primaryLanguage == lang) {
            _primaryLanguage = PrayerLanguage.values.firstWhere(
              (l) => l != lang,
            );
          }
          _settings?.compareLanguageCode = lang?.code ?? 'none';
          _settings?.primaryLanguageCode = _primaryLanguage.code;
        });
        if (_settings != null) {
          PrayerDatabase.saveSettings(_settings!);
        }
      },
      onSwap: () {
        if (_compareLanguage == null) return;
        setState(() {
          final temp = _primaryLanguage;
          _primaryLanguage = _compareLanguage!;
          _compareLanguage = temp;
          _settings?.primaryLanguageCode = _primaryLanguage.code;
          _settings?.compareLanguageCode = _compareLanguage?.code ?? 'none';
        });
        if (_settings != null) {
          PrayerDatabase.saveSettings(_settings!);
        }
      },
      onClearSecondary: () {
        setState(() {
          _compareLanguage = null;
          _settings?.compareLanguageCode = 'none';
        });
        if (_settings != null) {
          PrayerDatabase.saveSettings(_settings!);
        }
      },
    );
  }

  void _openFontDialog(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reading Options',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.format_size, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Font Size: ${_fontSize.round()} pt',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Slider(
                    value: _fontSize,
                    min: 12.0,
                    max: 28.0,
                    divisions: 16,
                    label: '${_fontSize.round()}',
                    onChanged: (val) {
                      setSheetState(() {
                        _fontSize = val;
                      });
                      setState(() {
                        _fontSize = val;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
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
      MissalTab(
        primaryLanguage: _primaryLanguage,
        compareLanguage: _compareLanguage,
        initialDate: widget.initialDate,
        languageSelectorAnimation: _languageSelectorAnimation,
        scrollController: _missalScrollController,
        fontSize: _fontSize,
      ),
      const BibleTab(),
      const LibraryTab(),
    ];

    final scaffold = Scaffold(
      drawer: _buildDrawer(context),
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
          else if (_currentTab == 0 ||
              _currentTab == 1 ||
              _currentTab == 3) ...[
            IconButton(
              icon: const Icon(Icons.text_fields),
              tooltip: 'Text Options',
              onPressed: () => _openFontDialog(context, theme),
            ),
            IconButton(
              icon: Icon(
                _showLanguageSelectors
                    ? Icons.translate
                    : Icons.translate_outlined,
              ),
              tooltip: _showLanguageSelectors
                  ? 'Hide language options'
                  : 'Select languages',
              onPressed: _toggleLanguageSelectors,
            ),
            if (_currentTab == 0)
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search prayers',
                onPressed: _openSearch,
              ),
          ],
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            tabs[_currentTab],
            if (_currentTab == 0 || _currentTab == 1)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizeTransition(
                  sizeFactor: _languageSelectorAnimation,
                  alignment: Alignment.topCenter,
                  child: FadeTransition(
                    opacity: _languageSelectorAnimation,
                    child:
                        _showLanguageSelectors ||
                            _languageSelectorAnimationController.value > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            color: Colors.transparent,
                            child: _buildGlobalLanguageSelectors(theme),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ),
      ),
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
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Missal',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Bible',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_library_outlined),
            selectedIcon: Icon(Icons.local_library),
            label: 'Library',
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Twelve Stars',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            key: const Key('drawer_settings_tile'),
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) {
                _loadData();
              });
            },
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

    if (filteredPrayers.isEmpty) {
      return ListView(
        controller: _prayersScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          SizeTransition(
            sizeFactor: _languageSelectorAnimation,
            alignment: Alignment.topCenter,
            child: const SizedBox(height: _kLanguageSelectorTopSpacerHeight),
          ),
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
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _prayersScrollController,
      // ignore: deprecated_member_use
      cacheExtent: 10000.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: filteredPrayers.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return SizeTransition(
            sizeFactor: _languageSelectorAnimation,
            alignment: Alignment.topCenter,
            child: const SizedBox(height: _kLanguageSelectorTopSpacerHeight),
          );
        }
        if (index == filteredPrayers.length + 1) {
          return Column(
            children: [
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
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.8,
                  ),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          );
        }

        final prayer = filteredPrayers[index - 1];
        final prefKey = '${prayer.prayerId}_${_primaryLanguage.code}';
        final initialVersion =
            _settings?.preferredVersions
                ?.firstWhere(
                  (p) => p.key == prefKey,
                  orElse: () => PrayerVersionPreference(),
                )
                .versionIndex ??
            0;

        return RepaintBoundary(
          child: PrayerCard(
            key: ValueKey(prayer.prayerId),
            prayer: prayer,
            selectedLanguage: _primaryLanguage,
            compareLanguage: _compareLanguage,
            initialVersionIndex: initialVersion,
            fontSize: _fontSize,
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
          ),
        );
      },
    );
  }
}
