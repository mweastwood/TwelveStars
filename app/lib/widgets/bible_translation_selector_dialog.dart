import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_translation_info.dart';

class BibleTranslationSelectorDialog extends StatefulWidget {
  final String currentPrimaryCode;
  final String? currentCompareCode;
  final ValueChanged<String> onPrimarySelected;
  final ValueChanged<String?> onCompareSelected;

  const BibleTranslationSelectorDialog({
    super.key,
    required this.currentPrimaryCode,
    required this.currentCompareCode,
    required this.onPrimarySelected,
    required this.onCompareSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentPrimaryCode,
    required String? currentCompareCode,
    required ValueChanged<String> onPrimarySelected,
    required ValueChanged<String?> onCompareSelected,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => BibleTranslationSelectorDialog(
        currentPrimaryCode: currentPrimaryCode,
        currentCompareCode: currentCompareCode,
        onPrimarySelected: onPrimarySelected,
        onCompareSelected: onCompareSelected,
      ),
    );
  }

  @override
  State<BibleTranslationSelectorDialog> createState() =>
      _BibleTranslationSelectorDialogState();
}

class _BibleTranslationSelectorDialogState
    extends State<BibleTranslationSelectorDialog> {
  late String _activeTarget; // 'primary' or 'compare'
  late String _selectedPrimary;
  late String? _selectedCompare;
  String _searchQuery = '';
  String _activeFilter =
      'All'; // 'All', 'Imprimatur', 'English', 'Latin', 'Spanish', 'Ancient'

  @override
  void initState() {
    super.initState();
    _activeTarget = 'primary';
    _selectedPrimary = widget.currentPrimaryCode;
    _selectedCompare = widget.currentCompareCode;
  }

  List<BibleTranslationInfo> get _filteredTranslations {
    return BibleTranslationInfo.allTranslations.where((t) {
      // Search query matching
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = t.name.toLowerCase().contains(query);
        final matchShort = t.shortName.toLowerCase().contains(query);
        final matchCode = t.code.toLowerCase().contains(query);
        final matchLang = t.languages.any(
          (l) => l.toLowerCase().contains(query),
        );
        final matchOrigin = t.originDescription.toLowerCase().contains(query);
        final matchUsage = t.churchUsage.toLowerCase().contains(query);
        if (!matchName &&
            !matchShort &&
            !matchCode &&
            !matchLang &&
            !matchOrigin &&
            !matchUsage) {
          return false;
        }
      }

      // Category filter matching
      switch (_activeFilter) {
        case 'Imprimatur':
          return t.approvalStatus == BibleApprovalStatus.imprimatur;
        case 'English':
          return t.primaryLanguageCode == 'en';
        case 'Latin':
          return t.primaryLanguageCode == 'la';
        case 'Spanish':
          return t.primaryLanguageCode == 'es';
        case 'Ancient':
          return t.approvalStatus == BibleApprovalStatus.canonicalSourceText ||
              t.primaryLanguageCode == 'el' ||
              t.primaryLanguageCode == 'he';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildApprovalBadge(BibleApprovalStatus status, ThemeData theme) {
    switch (status) {
      case BibleApprovalStatus.imprimatur:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                '✓ Imprimatur',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case BibleApprovalStatus.noImprimatur:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.orange.shade800),
              const SizedBox(width: 4),
              Text(
                '✗ No Imprimatur',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case BibleApprovalStatus.canonicalSourceText:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance, size: 14, color: Colors.purple),
              const SizedBox(width: 4),
              Text(
                '🏛️ Canonical Source',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.purple.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Title & Close button
            Row(
              children: [
                Icon(
                  Icons.menu_book,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bible Translations',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mode Selector: Primary vs Compare
            SegmentedButton<String>(
              segments: [
                ButtonSegment<String>(
                  value: 'primary',
                  label: Text('Primary: ${_selectedPrimary.toUpperCase()}'),
                  icon: const Icon(Icons.star),
                ),
                ButtonSegment<String>(
                  value: 'compare',
                  label: Text(
                    _selectedCompare == null
                        ? 'Compare Mode (Off)'
                        : 'Compare: ${_selectedCompare!.toUpperCase()}',
                  ),
                  icon: const Icon(Icons.compare_arrows),
                ),
              ],
              selected: {_activeTarget},
              onSelectionChanged: (selection) {
                setState(() {
                  _activeTarget = selection.first;
                });
              },
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search translations, language, date...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 8),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    [
                      'All',
                      'Imprimatur',
                      'English',
                      'Latin',
                      'Spanish',
                      'Ancient',
                    ].map((filter) {
                      final selected = _activeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: FilterChip(
                          label: Text(filter),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _activeFilter = filter;
                            });
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
              ),
            ),
            const Divider(height: 20),

            // Translation List
            Expanded(
              child: _filteredTranslations.isEmpty
                  ? Center(
                      child: Text(
                        'No translations matching "$_searchQuery"',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredTranslations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _filteredTranslations[index];
                        final isPrimary = _selectedPrimary == item.code;
                        final isCompare = _selectedCompare == item.code;

                        return Card(
                          elevation: isPrimary || isCompare ? 2 : 0,
                          color: isPrimary
                              ? theme.colorScheme.primaryContainer.withValues(
                                  alpha: 0.3,
                                )
                              : isCompare
                              ? theme.colorScheme.secondaryContainer.withValues(
                                  alpha: 0.3,
                                )
                              : theme.colorScheme.surfaceContainerHigh
                                    .withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isPrimary
                                  ? theme.colorScheme.primary
                                  : isCompare
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.outlineVariant.withValues(
                                      alpha: 0.5,
                                    ),
                              width: isPrimary || isCompare ? 2.0 : 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header line: Code & Name + Approval Badge
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.code,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.languages.join(", ")} • Date: ${item.publicationDate} • ${item.publicDomainStatus}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Approval badge
                                _buildApprovalBadge(item.approvalStatus, theme),
                                const SizedBox(height: 10),

                                // Origin & Church Usage description
                                Text(
                                  '🏛️ Origin: ${item.originDescription}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '✝️ Usage: ${item.churchUsage}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Action Buttons
                                Row(
                                  children: [
                                    if (_activeTarget == 'primary') ...[
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: Icon(
                                            isPrimary
                                                ? Icons.check
                                                : Icons.star,
                                          ),
                                          label: Text(
                                            isPrimary
                                                ? 'Primary Selected'
                                                : 'Set as Primary',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isPrimary
                                                ? theme.colorScheme.primary
                                                : null,
                                            foregroundColor: isPrimary
                                                ? theme.colorScheme.onPrimary
                                                : null,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _selectedPrimary = item.code;
                                            });
                                            widget.onPrimarySelected(item.code);
                                          },
                                        ),
                                      ),
                                    ] else ...[
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: Icon(
                                            isCompare
                                                ? Icons.check
                                                : Icons.compare_arrows,
                                          ),
                                          label: Text(
                                            isCompare
                                                ? 'Compare Selected'
                                                : 'Set as Compare',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isCompare
                                                ? theme.colorScheme.secondary
                                                : null,
                                            foregroundColor: isCompare
                                                ? theme.colorScheme.onSecondary
                                                : null,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _selectedCompare = item.code;
                                            });
                                            widget.onCompareSelected(item.code);
                                          },
                                        ),
                                      ),
                                      if (isCompare) ...[
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedCompare = null;
                                            });
                                            widget.onCompareSelected(null);
                                          },
                                          child: const Text('Clear'),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
