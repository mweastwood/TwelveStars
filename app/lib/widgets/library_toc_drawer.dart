import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/reader_models.dart';
import 'package:twelve_stars/widgets/reader/reader_toc_bottom_sheet.dart';

class LibraryTocDrawer extends StatelessWidget {
  final ParsedBookData book;
  final int currentSectionIndex;
  final ValueChanged<int> onSectionSelected;

  const LibraryTocDrawer({
    super.key,
    required this.book,
    required this.currentSectionIndex,
    required this.onSectionSelected,
  });

  static List<ReaderTocEntry> entriesFromBook(ParsedBookData book) {
    return [
      for (int idx = 0; idx < book.sections.length; idx++)
        ReaderTocEntry(
          index: idx,
          title: book.sections[idx].title,
          subtitle: book.sections[idx].subtitle.isNotEmpty
              ? book.sections[idx].subtitle
              : null,
        ),
    ];
  }

  static Future<void> show(
    BuildContext context, {
    required ParsedBookData book,
    required int currentSectionIndex,
    required ValueChanged<int> onSectionSelected,
  }) {
    return ReaderTocBottomSheet.show(
      context,
      tocEntries: entriesFromBook(book),
      currentSectionIndex: currentSectionIndex,
      onSectionSelected: onSectionSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReaderTocBottomSheet(
      tocEntries: entriesFromBook(book),
      currentSectionIndex: currentSectionIndex,
      onSectionSelected: onSectionSelected,
      popOnSelect: false,
    );
  }
}
