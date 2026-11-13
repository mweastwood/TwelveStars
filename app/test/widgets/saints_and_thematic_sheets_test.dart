import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/logic/thematic_database.dart';
import 'package:twelve_stars/widgets/saints/saint_ui_extensions.dart';
import 'package:twelve_stars/widgets/saints/saints_filter_header.dart';
import 'package:twelve_stars/widgets/saints/saints_sort_sheet.dart';
import 'package:twelve_stars/widgets/thematic_theme_picker_sheet.dart';

void main() {
  group('SaintsFilterHeader Widget Tests', () {
    testWidgets(
      'renders search field, filter chips, era and month popups, and invokes callbacks',
      (tester) async {
        final searchController = TextEditingController();
        addTearDown(searchController.dispose);
        String searchQuery = '';
        bool cleared = false;
        bool doctorsOnly = false;
        String? selectedGender;
        SaintCategory? selectedCategory;
        SaintEra selectedEra = SaintEra.all;
        int? selectedFeastMonth;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return SaintsFilterHeader(
                    searchController: searchController,
                    searchQuery: searchQuery,
                    onSearchChanged: (val) => setState(() => searchQuery = val),
                    onClearSearch: () => setState(() {
                      cleared = true;
                      searchController.clear();
                      searchQuery = '';
                    }),
                    doctorsOnly: doctorsOnly,
                    onDoctorsOnlyChanged: (val) =>
                        setState(() => doctorsOnly = val),
                    selectedGender: selectedGender,
                    onGenderChanged: (val) =>
                        setState(() => selectedGender = val),
                    selectedCategory: selectedCategory,
                    onCategoryChanged: (val) =>
                        setState(() => selectedCategory = val),
                    selectedEra: selectedEra,
                    onEraChanged: (val) => setState(() => selectedEra = val),
                    selectedFeastMonth: selectedFeastMonth,
                    onFeastMonthChanged: (val) =>
                        setState(() => selectedFeastMonth = val),
                  );
                },
              ),
            ),
          ),
        );

        // Search field & clear button
        final searchFinder = find.byKey(const Key('saints_search_field'));
        expect(searchFinder, findsOneWidget);
        expect(
          find.byKey(const Key('clear_saints_search_button')),
          findsNothing,
        );

        await tester.enterText(searchFinder, 'Aquinas');
        await tester.pump();
        expect(searchQuery, 'Aquinas');
        expect(
          find.byKey(const Key('clear_saints_search_button')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('clear_saints_search_button')));
        await tester.pump();
        expect(cleared, isTrue);
        expect(searchQuery, '');

        // Doctors filter chip
        await tester.tap(find.byKey(const Key('doctor_filter_chip')));
        await tester.pump();
        expect(doctorsOnly, isTrue);

        // Gender filter chips
        await tester.tap(find.byKey(const Key('men_filter_chip')));
        await tester.pump();
        expect(selectedGender, 'male');

        await tester.tap(find.byKey(const Key('women_filter_chip')));
        await tester.pump();
        expect(selectedGender, 'female');

        await tester.tap(find.byKey(const Key('women_filter_chip')));
        await tester.pump();
        expect(selectedGender, isNull);

        // Category filter chip
        final priestsChip = find.byKey(Key(SaintCategory.priest.filterChipKey));
        await tester.ensureVisible(priestsChip);
        await tester.pumpAndSettle();
        await tester.tap(priestsChip);
        await tester.pump();
        expect(selectedCategory, SaintCategory.priest);

        await tester.tap(priestsChip);
        await tester.pump();
        expect(selectedCategory, isNull);

        // Era popup menu
        final eraMenu = find.byTooltip('Filter by Era');
        await tester.ensureVisible(eraMenu);
        await tester.pumpAndSettle();
        await tester.tap(eraMenu);
        await tester.pumpAndSettle();
        await tester.tap(find.text(SaintEra.medieval.label).last);
        await tester.pumpAndSettle();
        expect(selectedEra, SaintEra.medieval);

        // Feast month popup menu
        final monthMenu = find.byTooltip('Filter by Feast Month');
        await tester.ensureVisible(monthMenu);
        await tester.pumpAndSettle();
        await tester.tap(monthMenu);
        await tester.pumpAndSettle();
        await tester.tap(find.text('October').last);
        await tester.pumpAndSettle();
        expect(selectedFeastMonth, 10);
      },
    );
  });

  group('SaintsSortSheet Widget Tests', () {
    testWidgets(
      'SaintsSortSheet.show displays sort options and selects new option',
      (tester) async {
        SaintSortOption currentSort = SaintSortOption.nameAsc;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    SaintsSortSheet.show(
                      context,
                      selectedOption: currentSort,
                      onOptionSelected: (option) {
                        currentSort = option;
                      },
                    );
                  },
                  child: const Text('Open Sort'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Sort'));
        await tester.pumpAndSettle();

        expect(find.text('Sort Saints'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);

        for (final option in SaintSortOption.values) {
          expect(find.byKey(Key('sort_option_${option.name}')), findsOneWidget);
        }

        await tester.tap(find.byKey(const Key('sort_option_feastDay')));
        await tester.pumpAndSettle();

        expect(currentSort, SaintSortOption.feastDay);
        expect(find.text('Sort Saints'), findsNothing);
      },
    );
  });

  group('ThematicThemePickerSheet Widget Tests', () {
    testWidgets(
      'ThematicThemePickerSheet.show renders categories, counts, and selects theme',
      (tester) async {
        String selectedTheme = 'sacraments.eucharist';
        final counts = <String, int>{
          'sacraments.eucharist': 12,
          'sacraments.baptism': 7,
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    ThematicThemePickerSheet.show(
                      context,
                      selectedThemeId: selectedTheme,
                      themeCounts: counts,
                      onThemeSelected: (themeId) {
                        selectedTheme = themeId;
                      },
                    );
                  },
                  child: const Text('Open Theme Picker'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Theme Picker'));
        await tester.pumpAndSettle();

        expect(find.text('Select Theme'), findsOneWidget);
        expect(
          find.text('${ThematicHelper.allThemes.length} Themes'),
          findsOneWidget,
        );
        expect(find.text('12'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);

        final baptismTile = find.text('Holy Baptism & Regeneration');
        expect(baptismTile, findsOneWidget);
        await tester.tap(baptismTile);
        await tester.pumpAndSettle();

        expect(selectedTheme, 'sacraments.baptism');
        expect(find.text('Select Theme'), findsNothing);
      },
    );
  });
}
