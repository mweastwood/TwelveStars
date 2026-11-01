import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/logic/utils/layout_breakpoints.dart';
import 'package:twelve_stars/screens/confirmation_discernment_screen.dart';
import 'package:twelve_stars/widgets/saint_card.dart';
import 'package:twelve_stars/widgets/saints/saint_ui_extensions.dart';
import 'package:twelve_stars/widgets/saints/saints_filter_header.dart';
import 'package:twelve_stars/widgets/saints/saints_sort_sheet.dart';
import 'package:twelve_stars/widgets/scripture_footer_quote.dart';
import 'package:twelve_stars/widgets/two_column_sliver_list.dart';

class SaintsScreen extends StatefulWidget {
  const SaintsScreen({super.key});

  @override
  State<SaintsScreen> createState() => _SaintsScreenState();
}

class _SaintsScreenState extends State<SaintsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Saint> _allSaints = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  bool _doctorsOnly = false;
  String? _selectedGender;
  SaintCategory? _selectedCategory;
  SaintEra _selectedEra = SaintEra.all;
  int? _selectedFeastMonth;
  SaintSortOption _sortOption = SaintSortOption.nameAsc;

  @override
  void initState() {
    super.initState();
    _loadSaints();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSaints() async {
    try {
      final saints = await SaintDatabase.loadSaints();
      if (mounted) {
        setState(() {
          _allSaints = saints;
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

  void _resetAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _doctorsOnly = false;
      _selectedGender = null;
      _selectedCategory = null;
      _selectedEra = SaintEra.all;
      _selectedFeastMonth = null;
    });
  }

  void _openSortDialog(BuildContext context) {
    SaintsSortSheet.show(
      context,
      selectedOption: _sortOption,
      onOptionSelected: (option) {
        setState(() {
          _sortOption = option;
        });
      },
    );
  }

  Widget _buildFooterQuote(ThemeData theme) {
    return const ScriptureFooterQuote(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      quote:
          '“Therefore, since we are surrounded by so great a cloud of witnesses, let us also lay aside every weight, and run with perseverance the race that is set before us.”',
      attribution: '— Hebrews 12:1',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = isWideScreen(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saint Database')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saint Database')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading saints: $_error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadSaints();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredSaints = SaintDatabase.searchSaints(
      _allSaints,
      query: _searchQuery,
      doctorsOnly: _doctorsOnly,
      gender: _selectedGender,
      category: _selectedCategory,
      era: _selectedEra,
      feastMonth: _selectedFeastMonth,
      sortBy: _sortOption,
    );

    final hasActiveFilters =
        _searchQuery.isNotEmpty ||
        _doctorsOnly ||
        _selectedGender != null ||
        _selectedCategory != null ||
        _selectedEra != SaintEra.all ||
        _selectedFeastMonth != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saint Database'),
        actions: [
          IconButton(
            key: const Key('confirmation_discernment_button'),
            icon: const Icon(Icons.psychology_alt_outlined),
            tooltip: 'Confirmation Saint Discernment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfirmationDiscernmentScreen(),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('saints_sort_button'),
            icon: Icon(_sortOption.icon),
            tooltip: 'Sort: ${_sortOption.label}',
            onPressed: () => _openSortDialog(context),
          ),
          if (hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              tooltip: 'Reset all filters',
              onPressed: _resetAllFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          SaintsFilterHeader(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            onClearSearch: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
            doctorsOnly: _doctorsOnly,
            onDoctorsOnlyChanged: (selected) {
              setState(() {
                _doctorsOnly = selected;
              });
            },
            selectedGender: _selectedGender,
            onGenderChanged: (gender) {
              setState(() {
                _selectedGender = gender;
              });
            },
            selectedCategory: _selectedCategory,
            onCategoryChanged: (cat) {
              setState(() {
                _selectedCategory = cat;
              });
            },
            selectedEra: _selectedEra,
            onEraChanged: (era) {
              setState(() {
                _selectedEra = era;
              });
            },
            selectedFeastMonth: _selectedFeastMonth,
            onFeastMonthChanged: (month) {
              setState(() {
                _selectedFeastMonth = month;
              });
            },
          ),

          // 3. Count & Active Info Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredSaints.length} ${filteredSaints.length == 1 ? "saint" : "saints"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _sortOption.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 4. Saints Cards List
          Expanded(
            child: filteredSaints.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No saints found',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _doctorsOnly && _selectedGender != null
                                ? 'No ${_selectedGender == "male" ? "male" : "female"} Doctors of the Church match your query.'
                                : _doctorsOnly
                                ? 'No Doctors of the Church match your query.'
                                : _selectedGender != null
                                ? 'No ${_selectedGender == "male" ? "male" : "female"} saints match your query.'
                                : hasActiveFilters && _searchQuery.isEmpty
                                ? 'Try adjusting or clearing your active filters.'
                                : 'Try searching for a different keyword or name.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (hasActiveFilters) ...[
                            const SizedBox(height: 16),
                            OutlinedButton(
                              key: const Key('reset_filters_button'),
                              onPressed: _resetAllFilters,
                              child: const Text('Reset filters'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : isWide
                ? CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        sliver: TwoColumnSliverList(
                          itemCount: filteredSaints.length,
                          itemBuilder: (context, index) =>
                              SaintCard(saint: filteredSaints[index]),
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildFooterQuote(theme)),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    itemCount: filteredSaints.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filteredSaints.length) {
                        return _buildFooterQuote(theme);
                      }
                      final saint = filteredSaints[index];
                      return SaintCard(saint: saint);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
