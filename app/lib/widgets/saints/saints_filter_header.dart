import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/widgets/saints/saint_ui_extensions.dart';

/// Search bar and horizontal filter ribbon for the Saint Database screen.
class SaintsFilterHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final bool doctorsOnly;
  final ValueChanged<bool> onDoctorsOnlyChanged;
  final String? selectedGender;
  final ValueChanged<String?> onGenderChanged;
  final SaintCategory? selectedCategory;
  final ValueChanged<SaintCategory?> onCategoryChanged;
  final SaintEra selectedEra;
  final ValueChanged<SaintEra> onEraChanged;
  final int? selectedFeastMonth;
  final ValueChanged<int?> onFeastMonthChanged;

  const SaintsFilterHeader({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.doctorsOnly,
    required this.onDoctorsOnlyChanged,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.selectedEra,
    required this.onEraChanged,
    required this.selectedFeastMonth,
    required this.onFeastMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Search Box
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: TextField(
            key: const Key('saints_search_field'),
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search saints by name, patronage, nationality...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      key: const Key('clear_saints_search_button'),
                      icon: const Icon(Icons.clear),
                      onPressed: onClearSearch,
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
            onChanged: onSearchChanged,
          ),
        ),

        // 2. Horizontal Filter Ribbon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
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
                    color: doctorsOnly
                        ? Colors.amber
                        : theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  selected: doctorsOnly,
                  onSelected: onDoctorsOnlyChanged,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  key: const Key('men_filter_chip'),
                  label: const Text('Men'),
                  showCheckmark: false,
                  avatar: Icon(
                    Icons.male,
                    color: selectedGender == 'male'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  selected: selectedGender == 'male',
                  onSelected: (selected) =>
                      onGenderChanged(selected ? 'male' : null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  key: const Key('women_filter_chip'),
                  label: const Text('Women'),
                  showCheckmark: false,
                  avatar: Icon(
                    Icons.female,
                    color: selectedGender == 'female'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  selected: selectedGender == 'female',
                  onSelected: (selected) =>
                      onGenderChanged(selected ? 'female' : null),
                ),
                const SizedBox(width: 8),
                // Standard Category Order
                ...SaintCategory.values
                    .where(
                      (c) =>
                          c != SaintCategory.other && c != SaintCategory.doctor,
                    )
                    .map((cat) {
                      final isSelected = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          key: Key(cat.filterChipKey),
                          label: Text(cat.filterLabel),
                          showCheckmark: false,
                          avatar: Icon(
                            cat.icon,
                            color: isSelected
                                ? cat.color(theme)
                                : theme.colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          selected: isSelected,
                          onSelected: (selected) =>
                              onCategoryChanged(selected ? cat : null),
                        ),
                      );
                    }),
                PopupMenuButton<SaintEra>(
                  tooltip: 'Filter by Era',
                  initialValue: selectedEra,
                  onSelected: onEraChanged,
                  itemBuilder: (context) => SaintEra.values.map((era) {
                    return PopupMenuItem(value: era, child: Text(era.label));
                  }).toList(),
                  child: Chip(
                    avatar: Icon(
                      Icons.history_toggle_off,
                      size: 16,
                      color: selectedEra != SaintEra.all
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    label: Text(
                      selectedEra == SaintEra.all
                          ? 'All Eras'
                          : selectedEra.label,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<int?>(
                  tooltip: 'Filter by Feast Month',
                  initialValue: selectedFeastMonth,
                  onSelected: onFeastMonthChanged,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: null, child: Text('All Months')),
                    ...List.generate(kMonthNames.length, (index) {
                      return PopupMenuItem(
                        value: index + 1,
                        child: Text(kMonthNames[index]),
                      );
                    }),
                  ],
                  child: Chip(
                    avatar: Icon(
                      Icons.calendar_month,
                      size: 16,
                      color: selectedFeastMonth != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    label: Text(
                      selectedFeastMonth == null
                          ? 'All Months'
                          : kMonthNames[selectedFeastMonth! - 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
