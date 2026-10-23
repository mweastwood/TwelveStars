import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
import 'package:twelve_stars/widgets/home_language_selector_card.dart';
import 'package:twelve_stars/widgets/collapsible_selector_bar.dart';
import 'package:twelve_stars/widgets/reader/reader_text_options_sheet.dart';
import 'package:twelve_stars/screens/rosary_screen.dart';
import 'package:twelve_stars/screens/bible_tab.dart';
import 'package:twelve_stars/screens/missal_tab.dart';
import 'package:twelve_stars/screens/library_tab.dart';
import 'package:twelve_stars/screens/saints_screen.dart';
import 'package:twelve_stars/screens/confirmation_discernment_screen.dart';
import 'package:twelve_stars/screens/bible_notes_screen.dart';
import 'package:twelve_stars/screens/settings_screen.dart';
import 'package:twelve_stars/logic/utils/layout_breakpoints.dart';
import 'package:twelve_stars/logic/utils/app_version.dart';

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
  List<Prayer>? _prayers;
  bool _loading = true;
  String? _error;
  UserSettings? _settings;
  double _fontSize = 16.0;

  bool _isSearching = false;
  String _searchQuery = '';
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  late final CollapsibleSelectorController _languageSelectorController;
  final ScrollController _prayersScrollController = ScrollController();
  final ScrollController _missalScrollController = ScrollController();
  final GlobalKey<BibleTabState> _bibleTabKey = GlobalKey<BibleTabState>();
  final LibraryTabController _libraryTabController = LibraryTabController();

  static const double _kLanguageSelectorTopSpacerHeight = 92.0;
  static final RegExp _whitespaceRegex = RegExp(r'\s+');

  ScrollController? get _activeScrollController {
    if (_currentTab == 0) return _missalScrollController;
    if (_currentTab == 1) return _prayersScrollController;
    return null;
  }

  @override
  void dispose() {
    UserSettingsController.instance.removeListener(_onSettingsChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _languageSelectorController.dispose();
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
    _languageSelectorController = CollapsibleSelectorController(
      vsync: this,
      topSpacerHeight: _kLanguageSelectorTopSpacerHeight,
      activeScrollController: () => _activeScrollController,
      onStatusSettled: () {
        if (mounted) setState(() {});
      },
    );
    UserSettingsController.instance.addListener(_onSettingsChanged);
    _loadData();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final settings = UserSettingsController.instance.value;
    final languageChanged =
        _primaryLanguage != settings.primaryLanguage ||
        _compareLanguage != settings.compareLanguage;
    _settings = settings;
    if (languageChanged) {
      setState(() {
        _primaryLanguage = settings.primaryLanguage;
        _compareLanguage = settings.compareLanguage;
      });
    }
  }

  void _toggleLanguageSelectors() {
    _languageSelectorController.toggle();
    setState(() {});
  }

  Future<void> _loadData() async {
    try {
      final prayers = await PrayerDatabase.loadPrayers();
      final settings = await UserSettingsController.instance.load();
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
        final nextCompare = _compareLanguage == lang ? null : _compareLanguage;
        setState(() {
          _primaryLanguage = lang;
          _compareLanguage = nextCompare;
        });
        UserSettingsController.instance.mutate((s) {
          s.primaryLanguageCode = lang.code;
          s.compareLanguageCode = nextCompare?.code ?? 'none';
        });
      },
      onSecondaryChanged: (lang) {
        final nextPrimary = (lang != null && _primaryLanguage == lang)
            ? PrayerLanguage.values.firstWhere((l) => l != lang)
            : _primaryLanguage;
        setState(() {
          _compareLanguage = lang;
          _primaryLanguage = nextPrimary;
        });
        UserSettingsController.instance.mutate((s) {
          s.compareLanguageCode = lang?.code ?? 'none';
          s.primaryLanguageCode = nextPrimary.code;
        });
      },
      onSwap: () {
        if (_compareLanguage == null) return;
        final nextPrimary = _compareLanguage!;
        final nextCompare = _primaryLanguage;
        setState(() {
          _primaryLanguage = nextPrimary;
          _compareLanguage = nextCompare;
        });
        UserSettingsController.instance.mutate((s) {
          s.primaryLanguageCode = nextPrimary.code;
          s.compareLanguageCode = nextCompare.code;
        });
      },
      onClearSecondary: () {
        setState(() {
          _compareLanguage = null;
        });
        UserSettingsController.instance.mutate((s) {
          s.compareLanguageCode = 'none';
        });
      },
    );
  }

  void _openFontDialog(BuildContext context) {
    ReaderTextOptionsSheet.show(
      context,
      fontSize: _fontSize,
      minFontSize: 12.0,
      maxFontSize: 28.0,
      divisions: 16,
      onFontSizeChanged: (val) {
        setState(() {
          _fontSize = val;
        });
      },
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentTab = index;
      if (index != 1 && _isSearching) {
        _closeSearch();
      }
    });
  }

  Widget _buildActiveTab(ThemeData theme, {required bool isWide}) {
    switch (_currentTab) {
      case 0:
        return MissalTab(
          primaryLanguage: _primaryLanguage,
          compareLanguage: _compareLanguage,
          initialDate: widget.initialDate,
          languageSelectorAnimation: _languageSelectorController.animation,
          scrollController: _missalScrollController,
          fontSize: _fontSize,
        );
      case 1:
        if (_loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error != null) {
          return Center(child: Text('Error loading prayers: $_error'));
        }
        return _buildPrayersTab(theme, isWide: isWide);
      case 2:
        return BibleTab(key: _bibleTabKey);
      case 3:
        return LibraryTab(controller: _libraryTabController);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = isWideScreen(context);

    final content = Stack(
      children: [
        _buildActiveTab(theme, isWide: isWide),
        if (_currentTab == 0 || _currentTab == 1)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CollapsibleSelectorBar(
              animation: _languageSelectorController.animation,
              padding: EdgeInsets.zero,
              child: _languageSelectorController.isVisibleOrAnimating
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
      ],
    );

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
              _currentTab == 2) ...[
            IconButton(
              icon: const Icon(Icons.text_fields),
              tooltip: 'Text Options',
              onPressed: () => _openFontDialog(context),
            ),
            IconButton(
              icon: Icon(
                _currentTab == 2
                    ? (_bibleTabKey.currentState?.showTranslationSelectors ??
                              false
                          ? Icons.translate
                          : Icons.translate_outlined)
                    : (_languageSelectorController.isExpanded
                          ? Icons.translate
                          : Icons.translate_outlined),
              ),
              tooltip: _currentTab == 2
                  ? ((_bibleTabKey.currentState?.showTranslationSelectors ??
                            false)
                        ? 'Hide translation options'
                        : 'Select translations')
                  : (_languageSelectorController.isExpanded
                        ? 'Hide language options'
                        : 'Select languages'),
              onPressed: () {
                if (_currentTab == 2) {
                  _bibleTabKey.currentState?.toggleTranslationSelectors();
                  setState(() {});
                } else {
                  _toggleLanguageSelectors();
                }
              },
            ),
            if (_currentTab == 1)
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search prayers',
                onPressed: _openSearch,
              ),
          ] else if (_currentTab == 3) ...[
            IconButton(
              key: const Key('library_saved_appbar_button'),
              icon: const Icon(Icons.bookmarks_outlined),
              tooltip: 'Saved Passages & Notes',
              onPressed: () {
                _libraryTabController.showSavedModalSheet();
              },
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _currentTab,
                    onDestinationSelected: _onTabSelected,
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.church_outlined),
                        selectedIcon: Icon(Icons.church),
                        label: Text('Missal'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.volunteer_activism_outlined),
                        selectedIcon: Icon(Icons.volunteer_activism),
                        label: Text('Prayers'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.menu_book_outlined),
                        selectedIcon: Icon(Icons.menu_book),
                        label: Text('Bible'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.library_books_outlined),
                        selectedIcon: Icon(Icons.library_books),
                        label: Text('Library'),
                      ),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: content),
                ],
              )
            : content,
      ),
      floatingActionButton: _currentTab == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RosaryScreen(
                      prayers: _prayers,
                      primaryLanguage: _primaryLanguage,
                      compareLanguage: _compareLanguage,
                      initialDate: widget.initialDate,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.grain),
              label: const Text('Start Rosary'),
            )
          : null,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _currentTab,
              onDestinationSelected: _onTabSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.church_outlined),
                  selectedIcon: Icon(Icons.church),
                  label: 'Missal',
                ),
                NavigationDestination(
                  icon: Icon(Icons.volunteer_activism_outlined),
                  selectedIcon: Icon(Icons.volunteer_activism),
                  label: 'Prayers',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Bible',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_books_outlined),
                  selectedIcon: Icon(Icons.library_books),
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
          if (_currentTab == 1 && !_isSearching && !isEditableFocused) {
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Menu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          ListTile(
            key: const Key('drawer_saints_tile'),
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Saint Database'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SaintsScreen()),
              );
            },
          ),
          ListTile(
            key: const Key('drawer_confirmation_tile'),
            leading: const Icon(Icons.psychology_alt_outlined),
            title: const Text('Confirmation Discernment'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfirmationDiscernmentScreen(),
                ),
              );
            },
          ),
          ListTile(
            key: const Key('drawer_bible_notes_tile'),
            leading: const Icon(Icons.edit_note_rounded),
            title: const Text('Bible Notes'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BibleNotesScreen(
                    onSelectFavorite: (fav) {
                      Navigator.pop(context);
                      setState(() => _currentTab = 2); // Switch to Bible tab
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _bibleTabKey.currentState?.navigateToFavorite(fav);
                      });
                    },
                    onSelectComment: (comment) {
                      Navigator.pop(context);
                      setState(() => _currentTab = 2); // Switch to Bible tab
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _bibleTabKey.currentState?.navigateToComment(comment);
                      });
                    },
                  ),
                ),
              );
            },
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
          const Divider(),
          ListTile(
            key: const Key('drawer_version_tile'),
            leading: const Icon(Icons.info_outline),
            title: Text(AppVersion.display),
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(Prayer prayer) {
    final prefKey = '${prayer.prayerId}_${_primaryLanguage.code}';
    final initialVersion = _settings?.getPreferredVersionIndex(prefKey) ?? 0;

    return RepaintBoundary(
      child: PrayerCard(
        key: ValueKey(prayer.prayerId),
        prayer: prayer,
        selectedLanguage: _primaryLanguage,
        compareLanguage: _compareLanguage,
        initialVersionIndex: initialVersion,
        fontSize: _fontSize,
        onVersionChanged: (newIndex) async {
          await UserSettingsController.instance.mutate((s) {
            s.setPreferredVersionIndex(prefKey, newIndex);
          });
        },
      ),
    );
  }

  Widget _buildFooterQuote(ThemeData theme) {
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
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPrayersTab(ThemeData theme, {required bool isWide}) {
    final prayers = _prayers;
    if (prayers == null || prayers.isEmpty) {
      return const Center(child: Text('No prayers found.'));
    }

    final query = _searchQuery.trim().toLowerCase();
    final queryWords = query.isEmpty
        ? const <String>[]
        : query.split(_whitespaceRegex).where((w) => w.isNotEmpty).toList();

    final filteredPrayers = prayers.where((prayer) {
      if (prayer.category == 'liturgy') return false;
      final transList = prayer.translations[_primaryLanguage];
      if (transList == null || transList.isEmpty) return false;
      if (queryWords.isEmpty) return true;
      final trans = transList[0];

      final title = trans.title.toLowerCase();
      final subtitle = trans.subtitle.toLowerCase();
      final text = trans.text.toLowerCase();

      return queryWords.every((word) {
        return title.contains(word) ||
            subtitle.contains(word) ||
            text.contains(word);
      });
    }).toList();

    if (filteredPrayers.isEmpty) {
      return ListView(
        controller: _prayersScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          SizeTransition(
            sizeFactor: _languageSelectorController.animation,
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

    if (isWide) {
      return CustomScrollView(
        controller: _prayersScrollController,
        scrollCacheExtent: const ScrollCacheExtent.pixels(10000.0),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 12.0,
              ),
              child: SizeTransition(
                sizeFactor: _languageSelectorController.animation,
                alignment: Alignment.topCenter,
                child: const SizedBox(
                  height: _kLanguageSelectorTopSpacerHeight,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverCrossAxisGroup(
              slivers: [
                SliverCrossAxisExpanded(
                  flex: 1,
                  sliver: SliverList.builder(
                    itemCount: (filteredPrayers.length + 1) ~/ 2,
                    itemBuilder: (context, index) {
                      return _buildPrayerCard(filteredPrayers[index * 2]);
                    },
                  ),
                ),
                const SliverConstrainedCrossAxis(
                  maxExtent: 12.0,
                  sliver: SliverToBoxAdapter(),
                ),
                SliverCrossAxisExpanded(
                  flex: 1,
                  sliver: SliverList.builder(
                    itemCount: filteredPrayers.length ~/ 2,
                    itemBuilder: (context, index) {
                      return _buildPrayerCard(filteredPrayers[index * 2 + 1]);
                    },
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 12.0,
              ),
              child: _buildFooterQuote(theme),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _prayersScrollController,
      scrollCacheExtent: const ScrollCacheExtent.pixels(10000.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: filteredPrayers.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return SizeTransition(
            sizeFactor: _languageSelectorController.animation,
            alignment: Alignment.topCenter,
            child: const SizedBox(height: _kLanguageSelectorTopSpacerHeight),
          );
        }
        if (index == filteredPrayers.length + 1) {
          return _buildFooterQuote(theme);
        }

        final prayer = filteredPrayers[index - 1];
        return _buildPrayerCard(prayer);
      },
    );
  }
}
