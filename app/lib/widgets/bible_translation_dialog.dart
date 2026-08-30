import 'package:flutter/material.dart';
import 'package:twelve_stars/widgets/bible_translation_selector_dialog.dart';

enum BibleTranslationDialogMode { primary, compare }

class BibleTranslationDialog extends StatelessWidget {
  final BibleTranslationDialogMode mode;
  final String currentPrimary;
  final String currentCompare;

  const BibleTranslationDialog({
    super.key,
    required this.mode,
    required this.currentPrimary,
    required this.currentCompare,
  });

  @override
  Widget build(BuildContext context) {
    return BibleTranslationSelectorDialog(
      currentPrimaryCode: currentPrimary,
      currentCompareCode: currentCompare == 'none' ? null : currentCompare,
      initialTarget: mode == BibleTranslationDialogMode.compare
          ? BibleTranslationTarget.compare
          : BibleTranslationTarget.primary,
      onPrimarySelected: (newPrimary) {
        Navigator.of(context).pop(newPrimary);
      },
      onCompareSelected: (newCompare) {
        Navigator.of(context).pop(newCompare ?? 'none');
      },
    );
  }
}
