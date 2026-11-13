import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/reader/library_reader_adapter.dart';
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

  static List<ReaderTocEntry> entriesFromBook(ParsedBookData book) =>
      LibraryReaderAdapter.buildTocEntries(book);

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
