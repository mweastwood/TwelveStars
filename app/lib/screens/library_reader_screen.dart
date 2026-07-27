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
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.crossRefQNum != null)
                          ActionChip(
                            avatar: Icon(
                              Icons.auto_stories_rounded,
                              size: 14,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            label: Text('Ref: #${item.crossRefQNum}'),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            backgroundColor: theme.colorScheme.primaryContainer,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                _showCrossRefModal(item.crossRefQNum!),
                          ),
                      ],
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
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'EXPLANATION',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildExplanationContent(
                              item.explanation!,
                              theme,
                              _fontSize,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildRichTextWithCitations(
                  item.text ?? '',
                  theme,
                  fontSize: _fontSize,
                  height: 1.6,
                ),
              );
            }
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _showCrossRefModal(int qNum) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (sheetCtx, scrollController) {
            return FutureBuilder<List<ParsedBookData?>>(
              future: Future.wait([
                LibraryHelper.loadBookData(
                  'assets/catechism/json/baltimore_2.json',
                ),
                LibraryHelper.loadBookData(
                  'assets/catechism/json/baltimore_4.json',
                ),
              ]),
              builder: (bCtx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final vol2 = snapshot.data![0];
                final vol4 = snapshot.data![1];

                ContentItem? q2Item;
                int? q2SecIdx;
                if (vol2 != null) {
                  for (int s = 0; s < vol2.sections.length; s++) {
                    for (final item in vol2.sections[s].content) {
                      if (item.type == 'qa' && item.questionNumber == qNum) {
                        q2Item = item;
                        q2SecIdx = s;
                        break;
                      }
                    }
                    if (q2Item != null) break;
                  }
                }

                ContentItem? q4Item;
                int? q4SecIdx;
                if (vol4 != null) {
                  for (int s = 0; s < vol4.sections.length; s++) {
                    for (final item in vol4.sections[s].content) {
                      if (item.type == 'qa' && item.questionNumber == qNum) {
                        q4Item = item;
                        q4SecIdx = s;
                        break;
                      }
                    }
                    if (q4Item != null) break;
                  }
                }

                final theme = Theme.of(context);
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Cross-Reference: Master Question #$qNum',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (q2Item != null) ...[
                        Text(
                          'Baltimore Catechism No. 2 (Confirmation Edition)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q. ${q2Item.questionNumber}. ${q2Item.question}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('A. ${q2Item.answer}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (q4Item != null) ...[
                        Text(
                          'Baltimore Catechism No. 4 (Fr. Kinkead\'s Explanation)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              left: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXPLANATION',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                q4Item.explanation ?? q4Item.answer ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (widget.bookItem.isSeries &&
                          widget.bookItem.volumes != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (q2SecIdx != null &&
                                widget.bookItem.volumes!.any(
                                  (v) => v.volumeKey == 'baltimore_2',
                                ))
                              OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.bookmark_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text('Open Vol 2'),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _switchVolume(
                                    widget.bookItem.volumes!.firstWhere(
                                      (v) => v.volumeKey == 'baltimore_2',
                                    ),
                                  );
                                  setState(() {
                                    _currentSectionIndex = q2SecIdx!;
                                  });
                                },
                              ),
                            if (q4SecIdx != null &&
                                widget.bookItem.volumes!.any(
                                  (v) => v.volumeKey == 'baltimore_4',
                                ))
                              FilledButton.icon(
                                icon: const Icon(
                                  Icons.menu_book_rounded,
                                  size: 18,
                                ),
                                label: const Text('Open Vol 4'),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _switchVolume(
                                    widget.bookItem.volumes!.firstWhere(
                                      (v) => v.volumeKey == 'baltimore_4',
                                    ),
                                  );
                                  setState(() {
                                    _currentSectionIndex = q4SecIdx!;
                                  });
                                },
                              ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildExplanationContent(
    String rawExplanation,
    ThemeData theme,
    double fontSize,
  ) {
    final paragraphs = rawExplanation
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildRichTextWithCitations(
            paragraphs[i],
            theme,
            fontSize: fontSize,
            height: 1.55,
          ),
        ],
      ],
    );
  }

  Widget _buildRichTextWithCitations(
    String text,
    ThemeData theme, {
    required double fontSize,
    required double height,
    Color? color,
  }) {
    final regExp = RegExp(
      r'\(((?:Gen|Exod|Lev|Num|Deut|Matt|Mark|Luke|John|Acts|Rom|Cor|Gal|Eph|Phil|Col|Thess|Tim|Heb|Pet|Rev|Ps|Prov|Isa|Jer)\.?\s*\d+[\d\:\,\-\s]*)\)',
      caseSensitive: false,
    );

    final matches = regExp.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: fontSize,
          height: height,
          color: color ?? theme.colorScheme.onSurface,
        ),
      );
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final m in matches) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, m.start)));
      }
      spans.add(
        TextSpan(
          text: '(${m.group(1)})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      );
      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: fontSize,
          height: height,
          color: color ?? theme.colorScheme.onSurface,
        ),
        children: spans,
      ),
    );
  }
}
