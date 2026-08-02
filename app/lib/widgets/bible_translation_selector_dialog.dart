import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_translation_info.dart';

enum BibleTranslationTarget { primary, compare }

class BibleTranslationSelectorDialog extends StatefulWidget {
  final String currentPrimaryCode;
  final String? currentCompareCode;
  final BibleTranslationTarget initialTarget;
  final ValueChanged<String> onPrimarySelected;
  final ValueChanged<String?> onCompareSelected;

  const BibleTranslationSelectorDialog({
    super.key,
    required this.currentPrimaryCode,
    required this.currentCompareCode,
    this.initialTarget = BibleTranslationTarget.primary,
    required this.onPrimarySelected,
    required this.onCompareSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentPrimaryCode,
    required String? currentCompareCode,
    BibleTranslationTarget initialTarget = BibleTranslationTarget.primary,
    required ValueChanged<String> onPrimarySelected,
    required ValueChanged<String?> onCompareSelected,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Bible Translation Selector',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim1, anim2) {
        return BibleTranslationSelectorDialog(
          currentPrimaryCode: currentPrimaryCode,
          currentCompareCode: currentCompareCode,
          initialTarget: initialTarget,
          onPrimarySelected: onPrimarySelected,
          onCompareSelected: onCompareSelected,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.easeOutCubic.transform(anim1.value);
        return Transform.scale(
          scale: 0.9 + (0.1 * curvedValue),
          child: Opacity(opacity: anim1.value, child: child),
        );
      },
    );
  }

  @override
  State<BibleTranslationSelectorDialog> createState() =>
      _BibleTranslationSelectorDialogState();
}

class _BibleTranslationSelectorDialogState
    extends State<BibleTranslationSelectorDialog> {
  late String _selectedPrimary;
  late String? _selectedCompare;
  late BibleTranslationTarget _activeTarget;
  String _searchQuery = '';
  final Set<String> _selectedFilters = <String>{};

  static const List<String> _availableFilters = [
    'Imprimatur',
    'English',
    'Latin',
    'Spanish',
    'Ancient',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPrimary = widget.currentPrimaryCode;
    _selectedCompare = widget.currentCompareCode;
    _activeTarget = widget.initialTarget;
  }

  void _swapTranslations() {
    if (_selectedCompare == null) return;
    final oldPrimary = _selectedPrimary;
    final oldCompare = _selectedCompare;
    setState(() {
      _selectedPrimary = oldCompare!;
      _selectedCompare = oldPrimary;
    });
    widget.onPrimarySelected(_selectedPrimary);
    widget.onCompareSelected(_selectedCompare);
  }

  void _selectPrimary(String code) {
    setState(() {
      _selectedPrimary = code;
      if (_selectedCompare == code) {
        _selectedCompare = null;
      }
    });
    widget.onPrimarySelected(_selectedPrimary);
    widget.onCompareSelected(_selectedCompare);
  }

  void _selectSecondary(String code) {
    setState(() {
      if (_selectedPrimary == code) {
        final alt = BibleTranslationInfo.allTranslations
            .map((t) => t.code)
            .firstWhere((c) => c != code);
        _selectedPrimary = alt;
        widget.onPrimarySelected(_selectedPrimary);
      }
      _selectedCompare = code;
    });
    widget.onCompareSelected(_selectedCompare);
  }

  void _clearSecondary() {
    setState(() {
      _selectedCompare = null;
    });
    widget.onCompareSelected(null);
  }

  List<BibleTranslationInfo> get _filteredTranslations {
    return BibleTranslationInfo.allTranslations.where((t) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = t.name.toLowerCase().contains(query);
        final matchShort = t.shortName.toLowerCase().contains(query);
        final matchLang = t.languages.any(
          (l) => l.toLowerCase().contains(query),
        );
        final matchOrigin = t.originDescription.toLowerCase().contains(query);
        final matchUsage = t.churchUsage.toLowerCase().contains(query);
        if (!matchName &&
            !matchShort &&
            !matchLang &&
            !matchOrigin &&
            !matchUsage) {
          return false;
        }
      }

      for (final filter in _selectedFilters) {
        switch (filter) {
          case 'Imprimatur':
            if (t.approvalStatus != BibleApprovalStatus.imprimatur) {
              return false;
            }
            break;
          case 'English':
            if (t.primaryLanguageCode != 'en') {
              return false;
            }
            break;
          case 'Latin':
            if (t.primaryLanguageCode != 'la') {
              return false;
            }
            break;
          case 'Spanish':
            if (t.primaryLanguageCode != 'es') {
              return false;
            }
            break;
          case 'Ancient':
            if (t.approvalStatus != BibleApprovalStatus.canonicalSourceText &&
                t.primaryLanguageCode != 'el' &&
                t.primaryLanguageCode != 'he') {
              return false;
            }
            break;
        }
      }

      return true;
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
    final primaryItem = BibleTranslationInfo.getByCode(_selectedPrimary);
    final compareItem = _selectedCompare == null
        ? null
        : BibleTranslationInfo.getByCode(_selectedCompare!);

    return Dialog(
      elevation: 8.0,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 750),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Title & Close button
            Row(
              children: [
                Icon(
                  Icons.menu_book,
                  color: theme.colorScheme.primary,
                  size: 28,
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

            // Target Selector Segmented Display Bar (Primary / Secondary)
            Card(
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Row(
                  children: [
                    // Primary Target Button
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _activeTarget = BibleTranslationTarget.primary;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _activeTarget ==
                                      BibleTranslationTarget.primary
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant.withValues(
                                      alpha: 0.3,
                                    ),
                              width:
                                  _activeTarget ==
                                      BibleTranslationTarget.primary
                                  ? 2.0
                                  : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.edit_note,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Selecting Primary',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                primaryItem.shortName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Swap Button
                    IconButton(
                      icon: Icon(
                        Icons.swap_horiz,
                        color: _selectedCompare != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.3,
                              ),
                      ),
                      tooltip: 'Swap Primary & Secondary',
                      onPressed: _selectedCompare == null
                          ? null
                          : _swapTranslations,
                    ),
                    const SizedBox(width: 4),

                    // Secondary Target Button & Clear Button
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _activeTarget = BibleTranslationTarget.compare;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _activeTarget ==
                                      BibleTranslationTarget.compare
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.outlineVariant.withValues(
                                      alpha: 0.3,
                                    ),
                              width:
                                  _activeTarget ==
                                      BibleTranslationTarget.compare
                                  ? 2.0
                                  : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.edit_note,
                                          size: 14,
                                          color: theme.colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            'Selecting Secondary',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      compareItem?.shortName ?? 'None',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: compareItem == null
                                                ? theme
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                : null,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedCompare != null) ...[
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  tooltip: 'Clear Secondary',
                                  onPressed: _clearSecondary,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by translation name, language, origin...',
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
                  borderRadius: BorderRadius.circular(14),
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

            // Multi-Select Combinable Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedFilters.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ActionChip(
                        avatar: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear Filters'),
                        onPressed: () {
                          setState(() {
                            _selectedFilters.clear();
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                  ..._availableFilters.map((filter) {
                    final isSelected = _selectedFilters.contains(filter);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedFilters.add(filter);
                            } else {
                              _selectedFilters.remove(filter);
                            }
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 20),

            // Translation List Cards with Single-Tap Selection
            Expanded(
              child: _filteredTranslations.isEmpty
                  ? Center(
                      child: Text(
                        'No translations match the selected criteria.',
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
                          elevation: isPrimary || isCompare ? 2.0 : 0.5,
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                          child: InkWell(
                            onTap: () {
                              if (_activeTarget ==
                                  BibleTranslationTarget.primary) {
                                _selectPrimary(item.code);
                              } else {
                                _selectSecondary(item.code);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: Title, Active Selection Badge & Badges
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                      if (isPrimary) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '✓ Primary',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ] else if (isCompare) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.secondary,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '✓ Secondary',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSecondary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Approval badge
                                  _buildApprovalBadge(
                                    item.approvalStatus,
                                    theme,
                                  ),
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
                                ],
                              ),
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
