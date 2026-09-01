import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'catalog/library_catalog.dart';
import 'reader/library_models.dart';

export 'catalog/library_catalog.dart';
export 'reader/library_models.dart';

typedef LibraryDatabase = LibraryHelper;

class _SearchableBookItem {
  final String bookTitle;
  final String sectionId;
  final String sectionTitle;
  final String fullText;
  final String lowerText;

  _SearchableBookItem({
    required this.bookTitle,
    required this.sectionId,
    required this.sectionTitle,
    required this.fullText,
    required this.lowerText,
  });
}

ParsedBookData _parseBookDataInBackground(String rawJson) {
  final map = json.decode(rawJson) as Map<String, dynamic>;
  return ParsedBookData.fromJson(map);
}


class LibraryHelper {
  static const int maxCacheSize = 5;
  static final Map<String, ParsedBookData> _cache = {};
  static final Map<String, List<_SearchableBookItem>> _searchIndex = {};
  static final Map<String, Future<ParsedBookData>> _inFlight = {};
  static final Map<String, Future<List<_SearchableBookItem>>> _inFlightSearch =
      {};

  @visibleForTesting
  static int get cacheSize => _cache.length;

  @visibleForTesting
  static int get searchIndexSize => _searchIndex.length;

  @visibleForTesting
  static void clearCache() {
    _cache.clear();
    _searchIndex.clear();
    _inFlight.clear();
    _inFlightSearch.clear();
  }

  @visibleForTesting
  static void clearSearchIndex() {
    _searchIndex.clear();
    _inFlightSearch.clear();
  }

  // Backward compatibility forwarding methods and properties
  static List<LibraryBookItem> getCatalog() => LibraryCatalog.getCatalog();
  static List<String> getAllCatalogPaths() =>
      LibraryCatalog.getAllCatalogPaths();

  static List<BaltimoreVolume> get baltimoreVolumes =>
      LibraryCatalog.baltimoreVolumes;
  static List<BaltimoreVolume> get ignatiusVolumes =>
      LibraryCatalog.ignatiusVolumes;
  static List<BaltimoreVolume> get polycarpVolumes =>
      LibraryCatalog.polycarpVolumes;
  static List<BaltimoreVolume> get justinVolumes =>
      LibraryCatalog.justinVolumes;
  static List<BaltimoreVolume> get irenaeusVolumes =>
      LibraryCatalog.irenaeusVolumes;
  static List<BaltimoreVolume> get confessionsVolumes =>
      LibraryCatalog.confessionsVolumes;
  static List<BaltimoreVolume> get cityOfGodVolumes =>
      LibraryCatalog.cityOfGodVolumes;
  static List<BaltimoreVolume> get cyrilVolumes => LibraryCatalog.cyrilVolumes;
  static List<BaltimoreVolume> get gregoryVolumes =>
      LibraryCatalog.gregoryVolumes;
  static List<BaltimoreVolume> get gregoryPastoralRuleVolumes =>
      LibraryCatalog.gregoryPastoralRuleVolumes;
  static List<BaltimoreVolume> get chrysostomOnThePriesthoodVolumes =>
      LibraryCatalog.chrysostomOnThePriesthoodVolumes;
  static List<BaltimoreVolume> get damasceneOrthodoxFaithVolumes =>
      LibraryCatalog.damasceneOrthodoxFaithVolumes;
  static List<BaltimoreVolume> get ambroseVolumes =>
      LibraryCatalog.ambroseVolumes;
  static List<BaltimoreVolume> get leoGreatVolumes =>
      LibraryCatalog.leoGreatVolumes;
  static List<BaltimoreVolume> get cyprianVolumes =>
      LibraryCatalog.cyprianVolumes;
  static List<BaltimoreVolume> get aquinasCompendiumVolumes =>
      LibraryCatalog.aquinasCompendiumVolumes;
  static List<BaltimoreVolume> get aquinasCatecheticalVolumes =>
      LibraryCatalog.aquinasCatecheticalVolumes;
  static List<BaltimoreVolume> get anselmCurDeusHomoVolumes =>
      LibraryCatalog.anselmCurDeusHomoVolumes;
  static List<BaltimoreVolume> get devoutLifeVolumes =>
      LibraryCatalog.devoutLifeVolumes;
  static List<BaltimoreVolume> get salesLoveOfGodVolumes =>
      LibraryCatalog.salesLoveOfGodVolumes;
  static List<BaltimoreVolume> get teresaWayOfPerfectionVolumes =>
      LibraryCatalog.teresaWayOfPerfectionVolumes;

  static Future<ParsedBookData> loadBookData(String assetPath) async {
    if (_cache.containsKey(assetPath)) {
      final cached = _cache.remove(assetPath)!;
      _cache[assetPath] = cached;
      return cached;
    }
    if (_inFlight.containsKey(assetPath)) {
      return _inFlight[assetPath]!;
    }
    final future = _loadBookDataInternal(assetPath);
    _inFlight[assetPath] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(assetPath);
    }
  }

  static Future<ParsedBookData> _loadBookDataInternal(String assetPath) async {
    final rawString = await rootBundle.loadString(assetPath);
    final parsed = await compute(_parseBookDataInBackground, rawString);
    if (_cache.length >= maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[assetPath] = parsed;
    return parsed;
  }

  static List<_SearchableBookItem> _extractSearchableItems(
    ParsedBookData book,
  ) {
    final items = <_SearchableBookItem>[];
    for (final sec in book.sections) {
      for (final item in sec.content) {
        String fullText = '';
        if (item.type == 'qa') {
          fullText =
              'Q. ${item.questionNumber} ${item.question ?? ""} A. ${item.answer ?? ""}';
        } else {
          fullText = item.text ?? '';
        }
        items.add(
          _SearchableBookItem(
            bookTitle: book.title,
            sectionId: sec.id,
            sectionTitle: sec.title,
            fullText: fullText,
            lowerText: fullText.toLowerCase(),
          ),
        );
      }
    }
    return items;
  }

  static Future<List<_SearchableBookItem>> _getSearchableItems(
    String assetPath,
  ) async {
    if (_searchIndex.containsKey(assetPath)) {
      return _searchIndex[assetPath]!;
    }
    if (_cache.containsKey(assetPath)) {
      final book = _cache[assetPath]!;
      final items = _extractSearchableItems(book);
      _searchIndex[assetPath] = items;
      return items;
    }
    if (_inFlightSearch.containsKey(assetPath)) {
      return _inFlightSearch[assetPath]!;
    }
    final future = _loadSearchableItemsInternal(assetPath);
    _inFlightSearch[assetPath] = future;
    try {
      return await future;
    } finally {
      _inFlightSearch.remove(assetPath);
    }
  }

  static Future<List<_SearchableBookItem>> _loadSearchableItemsInternal(
    String assetPath,
  ) async {
    final rawString = await rootBundle.loadString(assetPath);
    final book = await compute(_parseBookDataInBackground, rawString);
    final items = _extractSearchableItems(book);
    _searchIndex[assetPath] = items;
    return items;
  }

  static Future<List<BookSearchResult>> searchCatalog(
    String query, {
    int limit = 50,
  }) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];
    final words = cleanQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return [];

    final catalog = getCatalog();
    final allResults = <BookSearchResult>[];

    for (final bookItem in catalog) {
      final assetPaths = bookItem.allAssetPaths;
      for (final path in assetPaths) {
        try {
          final searchableItems = await _getSearchableItems(path);
          for (final item in searchableItems) {
            final matches = words.every((w) => item.lowerText.contains(w));
            if (matches) {
              int matchIdx = item.lowerText.indexOf(words.first);
              int start = (matchIdx - 30).clamp(0, item.fullText.length);
              int end = (matchIdx + 120).clamp(0, item.fullText.length);
              String snippet = item.fullText
                  .substring(start, end)
                  .replaceAll('\n', ' ');
              if (start > 0) snippet = '...$snippet';
              if (end < item.fullText.length) snippet = '$snippet...';

              allResults.add(
                BookSearchResult(
                  bookTitle: item.bookTitle,
                  sectionId: item.sectionId,
                  sectionTitle: item.sectionTitle,
                  matchedSnippet: snippet,
                ),
              );
              if (allResults.length >= limit) break;
            }
          }
        } catch (_) {}
        if (allResults.length >= limit) break;
      }
      if (allResults.length >= limit) break;
    }

    return allResults;
  }

  static List<BookSearchResult> searchInBook(
    ParsedBookData book,
    String query,
  ) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];
    final words = cleanQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return [];

    final results = <BookSearchResult>[];

    for (final sec in book.sections) {
      for (final item in sec.content) {
        String fullText = '';
        if (item.type == 'qa') {
          fullText =
              'Q. ${item.questionNumber} ${item.question ?? ""} A. ${item.answer ?? ""}';
        } else {
          fullText = item.text ?? '';
        }

        final lowerText = fullText.toLowerCase();
        final matches = words.every((w) => lowerText.contains(w));
        if (matches) {
          int matchIdx = lowerText.indexOf(words.first);
          int start = (matchIdx - 30).clamp(0, fullText.length);
          int end = (matchIdx + 120).clamp(0, fullText.length);
          String snippet = fullText.substring(start, end).replaceAll('\n', ' ');
          if (start > 0) snippet = '...$snippet';
          if (end < fullText.length) snippet = '$snippet...';

          results.add(
            BookSearchResult(
              bookTitle: book.title,
              sectionId: sec.id,
              sectionTitle: sec.title,
              matchedSnippet: snippet,
            ),
          );
          if (results.length >= 50) break;
        }
      }
      if (results.length >= 50) break;
    }

    return results;
  }
}
