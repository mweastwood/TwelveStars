import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/logic/utils/layout_breakpoints.dart';
import 'package:twelve_stars/widgets/saint_card.dart';

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

  void _openSortDialog(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Icon(Icons.sort, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Sort Saints',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                ...SaintSortOption.values.map((option) {
                  final isSelected = _sortOption == option;
                  return ListTile(
                    key: Key('sort_option_${option.name}'),
                    leading: Icon(
                      option.icon,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      option.label,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _sortOption = option;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterQuote(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          Text(
            '“Therefore, since we are surrounded by so great a cloud of witnesses, let us also lay aside every weight, and run with perseverance the race that is set before us.”',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '— Hebrews 12:1',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

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
            key: const Key('saints_sort_button'),
            icon: Icon(_sortOption.icon),
            tooltip: 'Sort: ${_sortOption.label}',
            onPressed: () => _openSortDialog(context, theme),
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
          // 1. Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: TextField(
              key: const Key('saints_search_field'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search saints by name, patronage, nationality...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        key: const Key('clear_saints_search_button'),
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // 2. Horizontal Filter Ribbon
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 2.0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    key: const Key('doctor_filter_chip'),
                    label: const Text('Doctors of the Church only'),
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.star,
                      color: _doctorsOnly
                          ? Colors.amber
                          : theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    selected: _doctorsOnly,
                    onSelected: (selected) {
                      setState(() {
                        _doctorsOnly = selected;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    key: const Key('men_filter_chip'),
                    label: const Text('Men'),
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.male,
                      color: _selectedGender == 'male'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    selected: _selectedGender == 'male',
                    onSelected: (selected) {
                      setState(() {
                        _selectedGender = selected ? 'male' : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    key: const Key('women_filter_chip'),
                    label: const Text('Women'),
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.female,
                      color: _selectedGender == 'female'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    selected: _selectedGender == 'female',
                    onSelected: (selected) {
                      setState(() {
                        _selectedGender = selected ? 'female' : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    key: const Key('martyrs_filter_chip'),
                    label: const Text('Martyrs'),
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.local_fire_department,
                      color: _selectedCategory == SaintCategory.martyr
                          ? Colors.red
                          : theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    selected: _selectedCategory == SaintCategory.martyr,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected
                            ? SaintCategory.martyr
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    key: const Key('angels_filter_chip'),
                    label: const Text('Angels'),
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.flare,
                      color: _selectedCategory == SaintCategory.angel
                          ? const Color(0xFF00ACC1)
                          : theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    selected: _selectedCategory == SaintCategory.angel,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected
                            ? SaintCategory.angel
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    key: const Key('apostles_filter_chip'),
                    label: const Text('Apostles'),
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.stars,
                      color: _selectedCategory == SaintCategory.apostle
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    selected: _selectedCategory == SaintCategory.apostle,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected
                            ? SaintCategory.apostle
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    key: const Key('evangelists_filter_chip'),
                    label: const Text('Evangelists'),
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.auto_stories,
                      color: _selectedCategory == SaintCategory.evangelist
                          ? const Color(0xFFE65100)
                          : theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    selected: _selectedCategory == SaintCategory.evangelist,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected
                            ? SaintCategory.evangelist
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    key: const Key('bishops_filter_chip'),
                    label: const Text('Bishops & Popes'),
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.account_balance,
                      color: _selectedCategory == SaintCategory.popeBishop
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    selected: _selectedCategory == SaintCategory.popeBishop,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected
                            ? SaintCategory.popeBishop
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    key: const Key('religious_filter_chip'),
                    label: const Text('Priests & Religious'),
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.church,
                      color: _selectedCategory == SaintCategory.priestReligious
                          ? Colors.green
                          : theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    selected:
                        _selectedCategory == SaintCategory.priestReligious,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected
                            ? SaintCategory.priestReligious
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    key: const Key('holy_family_filter_chip'),
                    label: const Text('Holy Family'),
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.family_restroom,
                      color: _selectedCategory == SaintCategory.holyFamily
                          ? const Color(0xFFAD1457)
                          : theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    selected: _selectedCategory == SaintCategory.holyFamily,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected
                            ? SaintCategory.holyFamily
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    key: const Key('laity_filter_chip'),
                    label: const Text('Laity'),
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.groups,
                      color: _selectedCategory == SaintCategory.laity
                          ? const Color(0xFF5C6BC0)
                          : theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    selected: _selectedCategory == SaintCategory.laity,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected
                            ? SaintCategory.laity
                            : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<SaintEra>(
                    tooltip: 'Filter by Era',
                    initialValue: _selectedEra,
                    onSelected: (era) {
                      setState(() {
                        _selectedEra = era;
                      });
                    },
                    itemBuilder: (context) => SaintEra.values.map((era) {
                      return PopupMenuItem(value: era, child: Text(era.label));
                    }).toList(),
                    child: Chip(
                      avatar: Icon(
                        Icons.history_toggle_off,
                        size: 16,
                        color: _selectedEra != SaintEra.all
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        _selectedEra == SaintEra.all
                            ? 'All Eras'
                            : _selectedEra.label,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<int?>(
                    tooltip: 'Filter by Feast Month',
                    initialValue: _selectedFeastMonth,
                    onSelected: (month) {
                      setState(() {
                        _selectedFeastMonth = month;
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All Months'),
                      ),
                      ...List.generate(12, (index) {
                        return PopupMenuItem(
                          value: index + 1,
                          child: Text(_months[index]),
                        );
                      }),
                    ],
                    child: Chip(
                      avatar: Icon(
                        Icons.calendar_month,
                        size: 16,
                        color: _selectedFeastMonth != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        _selectedFeastMonth == null
                            ? 'All Months'
                            : _months[_selectedFeastMonth! - 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                        sliver: SliverCrossAxisGroup(
                          slivers: [
                            SliverCrossAxisExpanded(
                              flex: 1,
                              sliver: SliverList.builder(
                                itemCount: (filteredSaints.length + 1) ~/ 2,
                                itemBuilder: (context, index) {
                                  return SaintCard(
                                    saint: filteredSaints[index * 2],
                                  );
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
                                itemCount: filteredSaints.length ~/ 2,
                                itemBuilder: (context, index) {
                                  return SaintCard(
                                    saint: filteredSaints[index * 2 + 1],
                                  );
                                },
                              ),
                            ),
                          ],
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
