import 'package:flutter/material.dart';
import '../logic/bible_translation_info.dart';
import 'bible/bible_translation_item_card.dart';
import 'common/dual_target_selector_row.dart';
export '../logic/bible_translation_info.dart'
    show TranslationApprovalStatus, BibleTranslationSelectorResult;
export 'bible/bible_approval_badge.dart';
export 'bible/bible_translation_item_card.dart';

enum BibleTranslationTarget { primary, compare }

class BibleTranslationSelectorDialog extends StatefulWidget {
  final String currentPrimaryCode;
  final String? currentCompareCode;
  final BibleTranslationTarget initialTarget;
  final int? currentBookNumber;
  final ValueChanged<String> onPrimarySelected;
  final ValueChanged<String?> onCompareSelected;

  const BibleTranslationSelectorDialog({
    super.key,
    required this.currentPrimaryCode,
    required this.currentCompareCode,
    this.initialTarget = BibleTranslationTarget.primary,
    this.currentBookNumber,
    required this.onPrimarySelected,
    required this.onCompareSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentPrimaryCode,
    required String? currentCompareCode,
    BibleTranslationTarget initialTarget = BibleTranslationTarget.primary,
    int? currentBookNumber,
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
          currentBookNumber: currentBookNumber,
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

  static const List<String> _availableFilters =
      BibleTranslationInfo.dialogFilterTags;

  static String? _normalizeCompareCode(String? code) =>
      BibleTranslationInfo.normalizeSecondaryCode(code);

  @override
  void initState() {
    super.initState();
    _selectedPrimary = widget.currentPrimaryCode;
    _selectedCompare = _normalizeCompareCode(widget.currentCompareCode);
    _activeTarget = widget.initialTarget;
  }

  @override
  void didUpdateWidget(covariant BibleTranslationSelectorDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPrimaryCode != widget.currentPrimaryCode) {
      _selectedPrimary = widget.currentPrimaryCode;
    }
    if (oldWidget.currentCompareCode != widget.currentCompareCode) {
      _selectedCompare = _normalizeCompareCode(widget.currentCompareCode);
    }
  }

  void _swapTranslations() {
    if (_selectedCompare == null) return;
    final resolved = BibleTranslationInfo.swapSelections(
      currentPrimary: _selectedPrimary,
      currentSecondary: _selectedCompare,
    );
    setState(() {
      _selectedPrimary = resolved.primary;
      _selectedCompare = resolved.secondary;
    });
    widget.onPrimarySelected(_selectedPrimary);
    widget.onCompareSelected(_selectedCompare);
  }

  void _selectPrimary(String code) {
    final resolved = BibleTranslationInfo.resolvePrimarySelection(
      currentPrimary: _selectedPrimary,
      currentSecondary: _selectedCompare,
      newPrimary: code,
    );
    setState(() {
      _selectedPrimary = resolved.primary;
      _selectedCompare = resolved.secondary;
    });
    widget.onPrimarySelected(_selectedPrimary);
    widget.onCompareSelected(_selectedCompare);
  }

  void _selectSecondary(String code) {
    final resolved = BibleTranslationInfo.resolveSecondarySelection(
      currentPrimary: _selectedPrimary,
      currentSecondary: _selectedCompare,
      newSecondary: code,
    );
    setState(() {
      _selectedPrimary = resolved.primary;
      _selectedCompare = resolved.secondary;
    });
    if (resolved.primaryChanged) {
      widget.onPrimarySelected(_selectedPrimary);
    }
    widget.onCompareSelected(_selectedCompare);
  }

  void _clearSecondary() {
    final resolved = BibleTranslationInfo.resolveSecondarySelection(
      currentPrimary: _selectedPrimary,
      currentSecondary: _selectedCompare,
      newSecondary: null,
    );
    setState(() {
      _selectedCompare = resolved.secondary;
    });
    widget.onCompareSelected(resolved.secondary);
  }

  List<BibleTranslationInfo> get _filteredTranslations =>
      BibleTranslationInfo.filterTranslations(
        query: _searchQuery,
        selectedFilters: _selectedFilters,
      );

  Widget _buildTargetSlot({
    required ThemeData theme,
    required BibleTranslationTarget target,
    required String label,
    required String valueText,
    required Color accentColor,
    Color? valueColor,
    Widget? trailing,
  }) {
    final isActive = _activeTarget == target;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note, size: 14, color: accentColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          valueText,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return InkWell(
      onTap: () {
        setState(() {
          _activeTarget = target;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? accentColor
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isActive ? 2.0 : 1.0,
          ),
        ),
        child: trailing == null
            ? content
            : Row(
                children: [
                  Expanded(child: content),
                  trailing,
                ],
              ),
      ),
    );
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
                child: DualTargetSelectorRow(
                  canSwap: _selectedCompare != null,
                  onSwap: _swapTranslations,
                  swapIconSize: null,
                  primaryChild: _buildTargetSlot(
                    theme: theme,
                    target: BibleTranslationTarget.primary,
                    label: 'Selecting Primary',
                    valueText: primaryItem.shortName,
                    accentColor: theme.colorScheme.primary,
                  ),
                  secondaryChild: _buildTargetSlot(
                    theme: theme,
                    target: BibleTranslationTarget.compare,
                    label: 'Selecting Secondary',
                    valueText: compareItem?.shortName ?? 'None',
                    accentColor: theme.colorScheme.secondary,
                    valueColor: compareItem == null
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                    trailing: _selectedCompare != null
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Clear Secondary',
                            onPressed: _clearSecondary,
                            visualDensity: VisualDensity.compact,
                          )
                        : null,
                  ),
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

                        return BibleTranslationItemCard(
                          item: item,
                          isPrimary: isPrimary,
                          isCompare: isCompare,
                          currentBookNumber: widget.currentBookNumber,
                          onTap: () {
                            if (_activeTarget ==
                                BibleTranslationTarget.primary) {
                              _selectPrimary(item.code);
                            } else {
                              _selectSecondary(item.code);
                            }
                          },
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
