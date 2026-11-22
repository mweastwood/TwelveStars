import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/bible_database.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/library_database.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/screens/bible_notes_screen.dart';
import 'package:twelve_stars/screens/confirmation_discernment_screen.dart';
import 'package:twelve_stars/screens/home_screen.dart';
import 'package:twelve_stars/screens/library_reader_screen.dart';
import 'package:twelve_stars/screens/rosary_screen.dart';
import 'package:twelve_stars/screens/saints_screen.dart';
import 'package:twelve_stars/screens/settings_screen.dart';
import 'package:twelve_stars/screens/thematic_quote_browser_screen.dart';
import 'package:twelve_stars/screens/website_viewer_screen.dart';

/// Canonical URL paths and builders for Twelve Stars.
class AppRoutes {
  static const String root = '/';
  static const String missal = '/missal';
  static const String prayers = '/prayers';
  static const String rosary = '/prayers/rosary';
  static const String bible = '/bible';
  static const String bibleNotes = '/bible/notes';
  static const String library = '/library';
  static const String libraryBook = '/library/book';
  static const String libraryThemes = '/library/themes';
  static const String libraryWeb = '/library/web';
  static const String saints = '/saints';
  static const String discernment = '/discernment';
  static const String settings = '/settings';

  static String tabPath(int index) {
    switch (index) {
      case 0:
        return missal;
      case 1:
        return prayers;
      case 2:
        return bible;
      case 3:
        return library;
      default:
        return missal;
    }
  }

  static int tabIndexForPath(String path) {
    if (path.startsWith(prayers)) return 1;
    if (path.startsWith(bible)) return 2;
    if (path.startsWith(library)) return 3;
    return 0;
  }

  static String missalPath({DateTime? date}) {
    if (date == null) return missal;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$missal?date=$y-$m-$d';
  }

  static String biblePath({String? bookSlug, int? chapter, int? verse}) {
    if (bookSlug == null || chapter == null) return bible;
    final base = '$bible/${Uri.encodeComponent(bookSlug)}/$chapter';
    if (verse != null) return '$base?v=$verse';
    return base;
  }

  static String libraryBookPath(
    String bookId, {
    String? volumeKey,
    String? sectionId,
    int? questionNumber,
    int? itemIndex,
  }) {
    final encodedId = Uri.encodeComponent(bookId);
    final path = (volumeKey != null && volumeKey.isNotEmpty)
        ? '$libraryBook/$encodedId/${Uri.encodeComponent(volumeKey)}'
        : '$libraryBook/$encodedId';
    final query = <String, String>{};
    if (sectionId != null && sectionId.isNotEmpty) {
      query['section'] = sectionId;
    }
    if (questionNumber != null) {
      query['q'] = questionNumber.toString();
    }
    if (itemIndex != null) {
      query['item'] = itemIndex.toString();
    }
    if (query.isEmpty) return path;
    return Uri(path: path, queryParameters: query).toString();
  }

  static String libraryThemePath(String themeId) {
    return '$libraryThemes/${Uri.encodeComponent(themeId)}';
  }

  static String libraryWebPath(String url, {String? title}) {
    final query = <String, String>{'url': url};
    if (title != null && title.isNotEmpty) {
      query['title'] = title;
    }
    return Uri(path: libraryWeb, queryParameters: query).toString();
  }

  static String bookSlug(BibleBook book) {
    return book.bookName.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  }

  static BibleBook? findBibleBook(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final asInt = int.tryParse(normalized);
    for (final book in catholicBooks) {
      if (asInt != null && book.bookNumber == asInt) return book;
      if (book.abbrev.toLowerCase() == normalized) return book;
      if (bookSlug(book) == normalized) return book;
      if (book.bookName.toLowerCase() == normalized) return book;
    }
    return null;
  }

  static DateTime? parseDateQuery(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw.trim());
    if (match == null) return null;
    final y = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    final d = int.tryParse(match.group(3)!);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}

/// Optional route extras passed during in-app navigation to preserve
/// already-loaded state while still keeping clean shareable URLs.
class RosaryRouteExtra {
  final List<Prayer>? prayers;
  final PrayerLanguage primaryLanguage;
  final PrayerLanguage? compareLanguage;
  final DateTime? initialDate;
  final bool? hapticsEnabled;
  final double fontSize;

  const RosaryRouteExtra({
    this.prayers,
    required this.primaryLanguage,
    this.compareLanguage,
    this.initialDate,
    this.hapticsEnabled,
    this.fontSize = 16.0,
  });
}

class LibraryReaderRouteExtra {
  final LibraryBookItem bookItem;
  final String? initialAssetPath;
  final String? initialVolumeKey;
  final String? initialSectionId;
  final int? initialSectionIndex;
  final int? initialQuestionNumber;
  final int? initialItemIndex;
  final String? navigationSessionId;
  final VoidCallback? onFavoriteSaved;

  const LibraryReaderRouteExtra({
    required this.bookItem,
    this.initialAssetPath,
    this.initialVolumeKey,
    this.initialSectionId,
    this.initialSectionIndex,
    this.initialQuestionNumber,
    this.initialItemIndex,
    this.navigationSessionId,
    this.onFavoriteSaved,
  });
}

class BibleNotesRouteExtra {
  final ValueChanged<FavoritePassage>? onSelectFavorite;
  final ValueChanged<UserComment>? onSelectComment;

  const BibleNotesRouteExtra({this.onSelectFavorite, this.onSelectComment});
}

class BibleDeepLinkTarget {
  final BibleBook book;
  final int chapter;
  final int? verse;

  const BibleDeepLinkTarget({
    required this.book,
    required this.chapter,
    this.verse,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BibleDeepLinkTarget &&
          book.bookNumber == other.book.bookNumber &&
          chapter == other.chapter &&
          verse == other.verse;

  @override
  int get hashCode => Object.hash(book.bookNumber, chapter, verse);
}

GoRouter createAppRouter({
  String? initialLocation,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation ?? AppRoutes.missal,
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) => AppRoutes.missal,
      ),
      ShellRoute(
        builder: (context, state, child) {
          final path = state.uri.path;
          final tabIndex = AppRoutes.tabIndexForPath(path);
          final initialDate = path.startsWith(AppRoutes.missal)
              ? AppRoutes.parseDateQuery(state.uri.queryParameters['date'])
              : null;

          BibleDeepLinkTarget? bibleTarget;
          if (path.startsWith(AppRoutes.bible)) {
            final bookParam = state.pathParameters['book'];
            final chapterParam = state.pathParameters['chapter'];
            if (bookParam != null && chapterParam != null) {
              final book = AppRoutes.findBibleBook(bookParam);
              final chapter = int.tryParse(chapterParam);
              if (book != null &&
                  chapter != null &&
                  chapter >= 1 &&
                  chapter <= book.chaptersCount) {
                final verse = int.tryParse(
                  state.uri.queryParameters['v'] ?? '',
                );
                bibleTarget = BibleDeepLinkTarget(
                  book: book,
                  chapter: chapter,
                  verse: verse,
                );
              }
            }
          }

          return HomeScreen(
            selectedTab: tabIndex,
            initialDate: initialDate,
            initialBibleTarget: bibleTarget,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.missal,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SizedBox.shrink()),
          ),
          GoRoute(
            path: AppRoutes.prayers,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SizedBox.shrink()),
          ),
          GoRoute(
            path: AppRoutes.bible,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SizedBox.shrink()),
            routes: [
              GoRoute(
                path: ':book/:chapter',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SizedBox.shrink()),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.library,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SizedBox.shrink()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.rosary,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is RosaryRouteExtra) {
            return RosaryScreen(
              prayers: extra.prayers,
              primaryLanguage: extra.primaryLanguage,
              compareLanguage: extra.compareLanguage,
              initialDate: extra.initialDate,
              hapticsEnabled: extra.hapticsEnabled,
              fontSize: extra.fontSize,
            );
          }
          final settings = UserSettingsController.instance.value;
          return RosaryScreen(
            primaryLanguage: settings.primaryLanguage,
            compareLanguage: settings.compareLanguage,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.bibleNotes,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is BibleNotesRouteExtra) {
            return BibleNotesScreen(
              onSelectFavorite: extra.onSelectFavorite,
              onSelectComment: extra.onSelectComment,
            );
          }
          return BibleNotesScreen(
            onSelectFavorite: (fav) {
              final book = catholicBooks.firstWhere(
                (b) => b.bookNumber == fav.bookNumber,
                orElse: () => catholicBooks.first,
              );
              context.go(
                AppRoutes.biblePath(
                  bookSlug: AppRoutes.bookSlug(book),
                  chapter: fav.chapter,
                  verse: fav.startVerse,
                ),
              );
            },
            onSelectComment: (comment) {
              context.go(AppRoutes.bible);
            },
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.libraryBook}/:bookId',
        builder: (context, state) => _buildLibraryReaderFromState(state),
        routes: [
          GoRoute(
            path: ':volumeKey',
            builder: (context, state) => _buildLibraryReaderFromState(state),
          ),
        ],
      ),
      GoRoute(
        path: '${AppRoutes.libraryThemes}/:themeId',
        builder: (context, state) {
          final themeId = state.pathParameters['themeId'];
          return ThematicQuoteBrowserScreen(initialThemeId: themeId);
        },
      ),
      GoRoute(
        path: AppRoutes.libraryWeb,
        builder: (context, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'Resource';
          return WebsiteViewerScreen(title: title, url: url);
        },
      ),
      GoRoute(
        path: AppRoutes.saints,
        builder: (context, state) => const SaintsScreen(),
      ),
      GoRoute(
        path: AppRoutes.discernment,
        builder: (context, state) => const ConfirmationDiscernmentScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => const HomeScreen(selectedTab: 0),
  );
}

Widget _buildLibraryReaderFromState(GoRouterState state) {
  final extra = state.extra;
  if (extra is LibraryReaderRouteExtra) {
    return LibraryReaderScreen(
      bookItem: extra.bookItem,
      initialAssetPath: extra.initialAssetPath,
      initialVolumeKey: extra.initialVolumeKey,
      initialSectionId: extra.initialSectionId,
      initialSectionIndex: extra.initialSectionIndex,
      initialQuestionNumber: extra.initialQuestionNumber,
      initialItemIndex: extra.initialItemIndex,
      navigationSessionId: extra.navigationSessionId,
      onFavoriteSaved: extra.onFavoriteSaved,
    );
  }

  final bookId = state.pathParameters['bookId'] ?? '';
  final volumeKey = state.pathParameters['volumeKey'];
  final sectionId = state.uri.queryParameters['section'];
  final questionNumber = int.tryParse(state.uri.queryParameters['q'] ?? '');
  final itemIndex = int.tryParse(state.uri.queryParameters['item'] ?? '');

  final target = LibraryDatabase.resolveTarget(
    bookId: bookId,
    volumeKey: volumeKey,
  );

  final bookItem =
      target?.book ??
      LibraryDatabase.findBookById(bookId) ??
      LibraryDatabase.getCatalog().first;

  return LibraryReaderScreen(
    bookItem: bookItem,
    initialAssetPath: target?.assetPath,
    initialVolumeKey: target?.volumeKey ?? volumeKey,
    initialSectionId: sectionId,
    initialQuestionNumber: questionNumber,
    initialItemIndex: itemIndex,
  );
}
