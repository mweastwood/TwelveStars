import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/widgets/saint_details_sheet.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Saint Database')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              children: [
                FilterChip(
                  key: const Key('doctor_filter_chip'),
                  label: const Text('Doctors of the Church only'),
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
                const Spacer(),
                Text(
                  '${filteredSaints.length} ${filteredSaints.length == 1 ? "saint" : "saints"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filteredSaints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No saints found',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _doctorsOnly
                              ? 'No Doctors of the Church match your query.'
                              : 'Try searching for a different keyword or name.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty || _doctorsOnly) ...[
                          const SizedBox(height: 16),
                          OutlinedButton(
                            key: const Key('reset_filters_button'),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _doctorsOnly = false;
                              });
                            },
                            child: const Text('Reset filters'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredSaints.length,
                    itemBuilder: (context, index) {
                      final saint = filteredSaints[index];
                      final titleText = saint.dateRange.isNotEmpty
                          ? '${saint.name} (${saint.dateRange})'
                          : saint.name;

                      return ListTile(
                        key: Key('saint_tile_${saint.id}'),
                        leading: saint.isDoctor
                            ? Tooltip(
                                message: 'Doctor of the Church',
                                child: const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                              )
                            : Icon(
                                Icons.person_outline,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                        title: Text(
                          titleText,
                          style: TextStyle(
                            fontWeight: saint.isDoctor
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${saint.nationality} • ${saint.profession}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (saint.patronage != null &&
                                saint.patronage!.isNotEmpty)
                              Text(
                                'Patron: ${saint.patronage}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => SaintDetailsSheet.show(context, saint),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
