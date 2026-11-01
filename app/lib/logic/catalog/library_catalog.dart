import '../reader/library_models.dart';
import 'library_catalog_data.dart';

export 'library_catalog_data.dart';

class LibraryCatalog {
  static const List<BaltimoreVolume> baltimoreVolumes = kBaltimoreVolumes;
  static const List<BaltimoreVolume> ignatiusVolumes = kIgnatiusVolumes;
  static const List<BaltimoreVolume> polycarpVolumes = kPolycarpVolumes;
  static const List<BaltimoreVolume> justinVolumes = kJustinVolumes;
  static const List<BaltimoreVolume> irenaeusVolumes = kIrenaeusVolumes;
  static const List<BaltimoreVolume> confessionsVolumes = kConfessionsVolumes;
  static const List<BaltimoreVolume> cityOfGodVolumes = kCityOfGodVolumes;
  static const List<BaltimoreVolume> cyrilVolumes = kCyrilVolumes;
  static const List<BaltimoreVolume> gregoryVolumes = kGregoryVolumes;
  static const List<BaltimoreVolume> gregoryPastoralRuleVolumes =
      kGregoryPastoralRuleVolumes;
  static const List<BaltimoreVolume> chrysostomOnThePriesthoodVolumes =
      kChrysostomOnThePriesthoodVolumes;
  static const List<BaltimoreVolume> damasceneOrthodoxFaithVolumes =
      kDamasceneOrthodoxFaithVolumes;
  static const List<BaltimoreVolume> ambroseVolumes = kAmbroseVolumes;
  static const List<BaltimoreVolume> leoGreatVolumes = kLeoGreatVolumes;
  static const List<BaltimoreVolume> cyprianVolumes = kCyprianVolumes;
  static const List<BaltimoreVolume> aquinasCompendiumVolumes =
      kAquinasCompendiumVolumes;
  static const List<BaltimoreVolume> aquinasCatecheticalVolumes =
      kAquinasCatecheticalVolumes;
  static const List<BaltimoreVolume> anselmCurDeusHomoVolumes =
      kAnselmCurDeusHomoVolumes;
  static const List<BaltimoreVolume> devoutLifeVolumes = kDevoutLifeVolumes;
  static const List<BaltimoreVolume> salesLoveOfGodVolumes =
      kSalesLoveOfGodVolumes;
  static const List<BaltimoreVolume> teresaWayOfPerfectionVolumes =
      kTeresaWayOfPerfectionVolumes;

  static const List<LibraryBookItem> _catalog = kLibraryCatalog;

  static List<LibraryBookItem> getCatalog() => _catalog;

  static final List<String> _allCatalogPaths = List.unmodifiable([
    for (final item in _catalog) ...item.allAssetPaths,
  ]);

  static List<String> getAllCatalogPaths() => _allCatalogPaths;

  static final Map<String, LibraryBookItem> _booksById = Map.unmodifiable({
    for (final item in _catalog) item.id: item,
  });

  static final Map<String, String?> _authorSaintIdsByKey = () {
    final map = <String, String?>{};
    final volumeKeySaints = <String, Set<String?>>{};

    for (final item in _catalog) {
      map[item.id] = item.authorSaintId;
      if (item.defaultAssetPath != null) {
        map[item.defaultAssetPath!] = item.authorSaintId;
        map[LibraryBookItem.assetStem(item.defaultAssetPath!)] =
            item.authorSaintId;
      }
      if (item.volumes != null) {
        for (final vol in item.volumes!) {
          map['${item.id}:${vol.volumeKey}'] = item.authorSaintId;
          map[vol.assetPath] = item.authorSaintId;
          map[LibraryBookItem.assetStem(vol.assetPath)] = item.authorSaintId;
          volumeKeySaints
              .putIfAbsent(vol.volumeKey, () => <String?>{})
              .add(item.authorSaintId);
        }
      }
    }

    for (final entry in volumeKeySaints.entries) {
      if (!map.containsKey(entry.key) && entry.value.length == 1) {
        map[entry.key] = entry.value.first;
      }
    }

    return Map<String, String?>.unmodifiable(map);
  }();

  /// Looks up a [LibraryBookItem] by its exact [bookId] in [catalog] (or the
  /// default catalog in O(1) time when [catalog] is omitted).
  static LibraryBookItem? findBookById(
    String bookId, {
    List<LibraryBookItem>? catalog,
  }) {
    if (catalog == null || identical(catalog, _catalog)) {
      return _booksById[bookId];
    }
    for (final b in catalog) {
      if (b.id == bookId) return b;
    }
    return null;
  }

  /// Resolves the `authorSaintId` associated with a book ID, volume key, or
  /// asset path/stem. When [bookId] is provided alongside a generic volume key
  /// (such as `'book1'`), resolves the saint for that specific book series.
  static String? resolveAuthorSaintId(String bookOrVolumeId, {String? bookId}) {
    if (bookId != null && bookId.isNotEmpty) {
      final composite = _authorSaintIdsByKey['$bookId:$bookOrVolumeId'];
      if (composite != null) return composite;
      final byBook = _authorSaintIdsByKey[bookId];
      if (byBook != null) return byBook;
    }
    return _authorSaintIdsByKey[bookOrVolumeId] ??
        _authorSaintIdsByKey[LibraryBookItem.assetStem(bookOrVolumeId)];
  }

  /// Resolves a [ResolvedLibraryTarget] matching [bookId], [volumeKey], or
  /// [assetPath] across [catalog] (or the default catalog).
  static ResolvedLibraryTarget? resolveTarget({
    String? bookId,
    String? volumeKey,
    String? assetPath,
    List<LibraryBookItem>? catalog,
    bool fallbackToFirstBook = false,
    bool fallbackToFirstVolume = false,
  }) {
    final items = catalog ?? _catalog;
    LibraryBookItem? matchedBook;
    BaltimoreVolume? matchedVolume;
    String? matchedVolumeKey = volumeKey;
    String? matchedAssetPath = assetPath;

    // Pass 1: Exact book ID or exact/stem match on book defaultAssetPath
    for (final b in items) {
      if (bookId != null && b.id == bookId) {
        matchedBook = b;
        break;
      }
      if (assetPath != null &&
          b.defaultAssetPath != null &&
          LibraryBookItem.matchesAssetExact(b.defaultAssetPath!, assetPath)) {
        matchedBook = b;
        matchedAssetPath = b.defaultAssetPath;
        break;
      }
      if (bookId != null &&
          b.defaultAssetPath != null &&
          LibraryBookItem.matchesAssetExact(b.defaultAssetPath!, bookId)) {
        matchedBook = b;
        matchedAssetPath ??= b.defaultAssetPath;
        break;
      }
    }

    // Pass 2: Exact/stem match on volume assetPath first, then exact volumeKey
    if (matchedBook == null) {
      for (final b in items) {
        if (b.volumes == null) continue;
        for (final v in b.volumes!) {
          final matchesAssetPath =
              (assetPath != null &&
                  LibraryBookItem.matchesAssetExact(v.assetPath, assetPath)) ||
              (bookId != null &&
                  LibraryBookItem.matchesAssetExact(v.assetPath, bookId));
          if (matchesAssetPath) {
            matchedBook = b;
            matchedVolume = v;
            matchedVolumeKey = v.volumeKey;
            matchedAssetPath = v.assetPath;
            break;
          }
        }
        if (matchedBook != null) break;
      }
    }
    if (matchedBook == null) {
      for (final b in items) {
        if (b.volumes == null) continue;
        for (final v in b.volumes!) {
          final matchesVolumeKey =
              (volumeKey != null && v.volumeKey == volumeKey) ||
              (bookId != null && v.volumeKey == bookId);
          if (matchesVolumeKey) {
            matchedBook = b;
            matchedVolume = v;
            matchedVolumeKey = v.volumeKey;
            matchedAssetPath = v.assetPath;
            break;
          }
        }
        if (matchedBook != null) break;
      }
    }

    // Pass 3: Boundary-safe substring fallback (where 'book1' does not match 'book10')
    if (matchedBook == null) {
      for (final b in items) {
        if (b.defaultAssetPath != null) {
          final matchesSingleVolumeSubstring =
              (assetPath != null &&
                  LibraryBookItem.matchesAssetBoundarySubstring(
                    b.defaultAssetPath!,
                    assetPath,
                  )) ||
              (bookId != null &&
                  LibraryBookItem.matchesAssetBoundarySubstring(
                    b.defaultAssetPath!,
                    bookId,
                  ));
          if (matchesSingleVolumeSubstring) {
            matchedBook = b;
            matchedAssetPath = b.defaultAssetPath;
            break;
          }
        }
        if (b.volumes != null) {
          for (final v in b.volumes!) {
            final matchesSubstring =
                (assetPath != null &&
                    LibraryBookItem.matchesAssetBoundarySubstring(
                      v.assetPath,
                      assetPath,
                    )) ||
                (bookId != null &&
                    LibraryBookItem.matchesAssetBoundarySubstring(
                      v.assetPath,
                      bookId,
                    ));
            if (matchesSubstring) {
              matchedBook = b;
              matchedVolume = v;
              matchedVolumeKey = v.volumeKey;
              matchedAssetPath = v.assetPath;
              break;
            }
          }
        }
        if (matchedBook != null) break;
      }
    }

    if (matchedBook == null && fallbackToFirstBook && items.isNotEmpty) {
      matchedBook = items.first;
    }
    if (matchedBook == null) return null;

    if (matchedBook.isSeries) {
      matchedVolume ??= matchedBook.resolveVolume(
        volumeKey: matchedVolumeKey,
        assetPath: matchedAssetPath,
        fallbackToFirst:
            fallbackToFirstVolume ||
            matchedVolumeKey != null ||
            matchedAssetPath != null,
      );
      if (matchedVolume != null) {
        matchedVolumeKey = matchedVolume.volumeKey;
        matchedAssetPath = matchedVolume.assetPath;
      }
    } else {
      matchedAssetPath ??= matchedBook.defaultAssetPath;
    }

    return ResolvedLibraryTarget(
      book: matchedBook,
      volume: matchedVolume,
      volumeKey: matchedVolumeKey,
      assetPath: matchedAssetPath,
    );
  }

  /// Constructs a fallback [ResolvedLibraryTarget] when a passage's `bookId` is
  /// not found in the static catalog, inferring category and JSON asset path.
  static ResolvedLibraryTarget buildFallbackTarget({
    required String bookId,
    required String bookTitle,
    required String author,
    String? authorSaintId,
  }) {
    String inferredCategory = 'Theology';
    final lowerTitle = bookTitle.toLowerCase();
    final lowerAuthor = author.toLowerCase();
    final lowerId = bookId.toLowerCase();

    if (lowerTitle.contains('catechism') ||
        lowerId.contains('baltimore') ||
        lowerId.contains('trent')) {
      inferredCategory = 'Catechisms';
    } else if (lowerAuthor.contains('apostolic') ||
        lowerId.contains('didache') ||
        lowerId.contains('clement') ||
        lowerId.contains('ignatius') ||
        lowerId.contains('polycarp') ||
        lowerId.contains('diognetus')) {
      inferredCategory = 'Apostolic Fathers';
    } else if (lowerAuthor.contains('augustine') ||
        lowerAuthor.contains('chrysostom') ||
        lowerAuthor.contains('athanasius') ||
        lowerAuthor.contains('ambrose') ||
        lowerAuthor.contains('basil') ||
        lowerAuthor.contains('gregory') ||
        lowerAuthor.contains('jerome') ||
        lowerAuthor.contains('cyprian') ||
        lowerAuthor.contains('cyril') ||
        lowerAuthor.contains('damascene') ||
        lowerAuthor.contains('irenaeus') ||
        lowerAuthor.contains('justin')) {
      inferredCategory = 'Early Church Fathers';
    } else if (lowerAuthor.contains('aquinas') ||
        lowerAuthor.contains('anselm') ||
        lowerAuthor.contains('bonaventure') ||
        lowerAuthor.contains('teresa') ||
        lowerAuthor.contains('john of the cross') ||
        lowerAuthor.contains('francis de sales')) {
      inferredCategory = 'Doctor of the Church';
    }

    String assetPath = bookId;
    if (!assetPath.startsWith('assets/')) {
      if (!assetPath.endsWith('.json')) {
        assetPath = 'assets/catechism/json/$assetPath.json';
      } else {
        assetPath = 'assets/catechism/json/$assetPath';
      }
    }

    final fallbackBook = LibraryBookItem(
      id: bookId,
      title: bookTitle,
      subtitle: '',
      category: inferredCategory,
      author: author,
      authorSaintId: authorSaintId,
      description: '',
      defaultAssetPath: assetPath,
    );

    return ResolvedLibraryTarget(book: fallbackBook, assetPath: assetPath);
  }
}
