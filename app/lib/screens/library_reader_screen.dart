import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/library_database.dart';

class LibraryReaderScreen extends StatefulWidget {
  final LibraryBookItem bookItem;
  final String? initialAssetPath;
  final String? initialVolumeKey;

  const LibraryReaderScreen({
    super.key,
    required this.bookItem,
    this.initialAssetPath,
    this.initialVolumeKey,
  });

  @override
  State<LibraryReaderScreen> createState() => _LibraryReaderScreenState();
}

class _LibraryReaderScreenState extends State<LibraryReaderScreen> {
  late String _currentAssetPath;
  String? _currentVolumeKey;
  bool _isLoading = true;
  String? _error;
  ParsedBookData? _bookData;

  int _currentSectionIndex = 0;
  double _fontSize = 16.0;

  bool _isSearching = false;
  String _searchQuery = '';
  List<BookSearchResult> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.bookItem.isSeries) {
      _currentVolumeKey =
          widget.initialVolumeKey ?? widget.bookItem.volumes!.first.volumeKey;
      final selectedVol = widget.bookItem.volumes!.firstWhere(
        (v) => v.volumeKey == _currentVolumeKey,
        orElse: () => widget.bookItem.volumes!.first,
      );
      _currentAssetPath = selectedVol.assetPath;
    } else {
      _currentAssetPath =
          widget.initialAssetPath ?? widget.bookItem.defaultAssetPath!;
    }
    _loadBookData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await LibraryHelper.loadBookData(_currentAssetPath);
      if (mounted) {
        setState(() {
          _bookData = data;
          _currentSectionIndex = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _switchVolume(BaltimoreVolume vol) {
    if (_currentVolumeKey == vol.volumeKey) return;
    setState(() {
      _currentVolumeKey = vol.volumeKey;
      _currentAssetPath = vol.assetPath;
    });
    _loadBookData();
  }

  void _openTocSheet(BuildContext context, ThemeData theme) {
    final book = _bookData;
    if (book == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Table of Contents',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: book.sections.length,
                      itemBuilder: (context, idx) {
                        final sec = book.sections[idx];
                        final isSelected = idx == _currentSectionIndex;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text(
                            sec.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: sec.subtitle.isNotEmpty
                              ? Text(
                                  sec.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _currentSectionIndex = idx;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openFontDialog(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reading Options',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.format_size, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Font Size: ${_fontSize.round()} pt',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Slider(
                    value: _fontSize,
                    min: 12.0,
                    max: 28.0,
                    divisions: 16,
                    label: '${_fontSize.round()}',
                    onChanged: (val) {
                      setSheetState(() {
                        _fontSize = val;
                      });
                      setState(() {
                        _fontSize = val;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _performSearch(String query) {
    if (_bookData == null) return;
    final results = LibraryHelper.searchInBook(_bookData!, query);
    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = _bookData;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: const InputDecoration(
                  hintText: 'Search in book...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                  _performSearch(val);
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.bookItem.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book != null)
                    Text(
                      book.subtitle.isNotEmpty ? book.subtitle : book.title,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _searchResults = [];
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search in Book',
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.list),
              tooltip: 'Table of Contents',
              onPressed: () => _openTocSheet(context, theme),
            ),
            IconButton(
              icon: const Icon(Icons.text_fields),
              tooltip: 'Text Options',
              onPressed: () => _openFontDialog(context, theme),
            ),
          ],
        ],
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                    _searchResults = [];
                  });
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Series Volume Selector Header (for Baltimore Catechism)
            if (widget.bookItem.isSeries && !_isSearching)
              Container(
                color: theme.colorScheme.surfaceContainerLow,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Text(
                      'Edition: ',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: widget.bookItem.volumes!.map((vol) {
                            final isSel = vol.volumeKey == _currentVolumeKey;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: Text(vol.shortName),
                                selected: isSel,
                                onSelected: (selected) {
                                  if (selected) _switchVolume(vol);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Reader / Search Results View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Error loading book: $_error',
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _isSearching
                  ? _buildSearchResultsView(theme)
                  : _buildSectionContentView(theme, book!),
            ),

            // Bottom Section Navigation Footer
            if (!_isSearching && book != null && book.sections.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous Section',
                      onPressed: _currentSectionIndex > 0
                          ? () {
                              setState(() {
                                _currentSectionIndex--;
                              });
                            }
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        'Section ${_currentSectionIndex + 1} of ${book.sections.length}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next Section',
                      onPressed: _currentSectionIndex < book.sections.length - 1
                          ? () {
                              setState(() {
                                _currentSectionIndex++;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsView(ThemeData theme) {
    if (_searchQuery.trim().isEmpty) {
      return Center(
        child: Text(
          'Type a search term to find in this book.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'No matches found for "$_searchQuery".',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, idx) {
        final res = _searchResults[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 10.0),
          child: ListTile(
            title: Text(
              res.sectionTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                res.matchedSnippet,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            onTap: () {
              final secIdx =
                  _bookData?.sections.indexWhere(
                    (s) => s.id == res.sectionId,
                  ) ??
                  -1;
              if (secIdx >= 0) {
                setState(() {
                  _currentSectionIndex = secIdx;
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                  _searchResults = [];
                });
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionContentView(ThemeData theme, ParsedBookData book) {
    if (book.sections.isEmpty) {
      return const Center(child: Text('No content found in this volume.'));
    }

    final sec = book.sections[_currentSectionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            sec.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          if (sec.subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              sec.subtitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Content Items
          ...sec.content.map((item) {
            if (item.type == 'heading') {
              return Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 12.0),
                child: Text(
                  item.text ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    height: 1.4,
                  ),
                ),
              );
            } else if (item.type == 'qa') {
              final qPrefix =
                  (item.questionNumber != null && item.questionNumber! > 0)
                  ? 'Q. ${item.questionNumber}. '
                  : 'Q. ';
              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: _fontSize,
                          height: 1.5,
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: qPrefix,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          TextSpan(
                            text: item.question ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: _fontSize,
                          height: 1.5,
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: 'A. ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          TextSpan(text: item.answer ?? ''),
                        ],
                      ),
                    ),
                    if (item.explanation != null &&
                        item.explanation!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.7,
                              ),
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          item.explanation!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: _fontSize - 1,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  item.text ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: _fontSize,
                    height: 1.6,
                  ),
                ),
              );
            }
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
