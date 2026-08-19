import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/saint_models.dart';

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

  void _showSaintDetails(BuildContext context, Saint saint) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          saint.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      if (saint.isDoctor)
                        Tooltip(
                          message: 'Doctor of the Church',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.shade700,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Doctor',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (saint.dateRange.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      saint.dateRange,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  if (saint.feastDay != null) ...[
                    _buildInfoRow(
                      context,
                      icon: Icons.calendar_month_outlined,
                      label: 'Feast Day',
                      value: saint.feastDay!,
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildInfoRow(
                    context,
                    icon: Icons.public_outlined,
                    label: 'Nationality & Origin',
                    value: saint.nationality,
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow(
                    context,
                    icon: Icons.work_outline,
                    label: 'Vocation & Profession',
                    value: saint.profession,
                  ),
                  const SizedBox(height: 12),

                  if (saint.patronage != null &&
                      saint.patronage!.isNotEmpty) ...[
                    _buildInfoRow(
                      context,
                      icon: Icons.shield_outlined,
                      label: 'Patronage',
                      value: saint.patronage!,
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (saint.summary != null && saint.summary!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Biography & Significance',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      saint.summary!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Confirmation Tip: Choose a confirmation patron saint whose virtues and life inspire your Christian vocation.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.secondary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
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
                        onTap: () => _showSaintDetails(context, saint),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
