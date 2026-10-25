import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/reader/reader_adapter.dart';
import 'package:twelve_stars/logic/reader/reader_models.dart';
import 'package:twelve_stars/logic/reader/reader_selection_controller.dart';
import 'reader_parallel_view.dart';
import 'reader_selection_action_bar.dart';
import 'reader_text_options_sheet.dart';
import 'reader_toc_bottom_sheet.dart';

class CoreReaderShell extends StatefulWidget {
  final ReaderAdapter adapter;
  final int initialSectionIndex;
  final String? primaryVariant;
  final String? compareVariant;
  final List<Widget>? extraActions;

  const CoreReaderShell({
    super.key,
    required this.adapter,
    this.initialSectionIndex = 0,
    this.primaryVariant,
    this.compareVariant,
    this.extraActions,
  });

  @override
  State<CoreReaderShell> createState() => _CoreReaderShellState();
}

class _CoreReaderShellState extends State<CoreReaderShell> {
  late PageController _pageController;
  late int _currentSectionIndex;
  final ReaderSelectionController _selectionController =
      ReaderSelectionController();
  final Map<int, ReaderSection> _loadedSections = {};
  ReaderDocument? _document;
  double _fontSize = 16.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentSectionIndex = widget.initialSectionIndex;
    _pageController = PageController(initialPage: widget.initialSectionIndex);
    _loadDocument();
  }

  @override
  void didUpdateWidget(CoreReaderShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adapter != widget.adapter ||
        oldWidget.primaryVariant != widget.primaryVariant ||
        oldWidget.compareVariant != widget.compareVariant) {
      _loadedSections.clear();
      _selectionController.clear();
      if (oldWidget.adapter != widget.adapter) {
        _loadDocument();
      }
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    final doc = await widget.adapter.loadDocument();
    if (mounted) {
      setState(() {
        _document = doc;
        _loading = false;
      });
    }
  }

  Future<ReaderSection> _getSection(int sectionIdx) async {
    final cached = _loadedSections[sectionIdx];
    if (cached != null) return cached;
    final loaded = await widget.adapter.loadSection(
      sectionIdx,
      primaryVariant: widget.primaryVariant,
      compareVariant: widget.compareVariant,
    );
    _loadedSections[sectionIdx] = loaded;
    return loaded;
  }

  void _openTocSheet(BuildContext context) {
    if (_document == null) return;
    ReaderTocBottomSheet.show(
      context,
      documentTitle: _document!.title,
      tocEntries: _document!.tocEntries,
      currentSectionIndex: _currentSectionIndex,
      onSectionSelected: (index) {
        setState(() {
          _currentSectionIndex = index;
          _selectionController.clear();
        });
        _pageController.jumpToPage(index);
      },
    );
  }

  void _openTextOptionsSheet(BuildContext context) {
    ReaderTextOptionsSheet.show(
      context,
      fontSize: _fontSize,
      onFontSizeChanged: (val) {
        setState(() {
          _fontSize = val;
        });
      },
    );
  }

  Set<String> _selectedNodeIdsForSection(ReaderSection section) {
    if (!_selectionController.hasSelection) return const <String>{};
    final start = _selectionController.start!;
    final end = _selectionController.end!;
    final ids = <String>{};
    for (int i = start; i <= end && i < section.nodes.length; i++) {
      if (i >= 0) {
        ids.add(section.nodes[i].id);
      }
    }
    return ids;
  }

  Widget _buildSelectionActionBar(ReaderDocument doc, ReaderSection section) {
    final start = _selectionController.start!;
    final end = _selectionController.end!;
    final count = _selectionController.selectedCount;
    final clampedStart = start.clamp(0, section.nodes.length - 1);
    final clampedEnd = end.clamp(0, section.nodes.length - 1);
    final selectedNodes = section.nodes.sublist(clampedStart, clampedEnd + 1);
    final firstNode = selectedNodes.first;
    final textPreview = selectedNodes
        .map(
          (n) => n.nodeType == ReaderNodeType.qa
              ? 'Q. ${n.question ?? ''}\nA. ${n.answer ?? ''}'
              : (n.primaryText ?? ''),
        )
        .where((s) => s.isNotEmpty)
        .join('\n');
    final citation = section.title;

    return ReaderSelectionActionBar(
      title: citation,
      selectedCount: count,
      onSaveFavorite: () async {
        await widget.adapter.saveBookmark(
          ReaderBookmark(
            id: '',
            documentId: doc.documentId,
            sectionIndex: _currentSectionIndex,
            nodeId: firstNode.id,
            textPreview: '$citation\n$textPreview',
            timestamp: DateTime.now(),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved $citation to Favorites'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _selectionController.clear());
        }
      },
      onCopy: () async {
        await Clipboard.setData(ClipboardData(text: '$citation\n$textPreview'));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied $citation to clipboard'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _selectionController.clear());
        }
      },
      onClearSelection: () => setState(() => _selectionController.clear()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doc = _document;

    if (_loading || doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final activeSection = _loadedSections[_currentSectionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doc.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (doc.subtitle != null)
              Text(
                doc.subtitle!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          if (widget.extraActions != null) ...widget.extraActions!,
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Text Options',
            onPressed: () => _openTextOptionsSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Table of Contents',
            onPressed: () => _openTocSheet(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: doc.sectionsCount,
            onPageChanged: (pageIndex) {
              setState(() {
                _currentSectionIndex = pageIndex;
                _selectionController.clear();
              });
            },
            itemBuilder: (context, pageIndex) {
              return FutureBuilder<ReaderSection>(
                future: _getSection(pageIndex),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final section = snapshot.data!;
                  final isCurrentPage = pageIndex == _currentSectionIndex;
                  final selectedIds = isCurrentPage
                      ? _selectedNodeIdsForSection(section)
                      : const <String>{};

                  return ReaderParallelView(
                    nodes: section.nodes,
                    fontSize: _fontSize,
                    selectedNodeIds: selectedIds,
                    header: Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (section.subtitle != null &&
                              section.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              section.subtitle!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    onNodeLongPress: isCurrentPage
                        ? (nodeId) {
                            final idx = section.nodes.indexWhere(
                              (n) => n.id == nodeId,
                            );
                            if (idx != -1) {
                              setState(() {
                                _selectionController.onLongPress(idx);
                              });
                            }
                          }
                        : null,
                    onNodeTap: isCurrentPage
                        ? (nodeId) {
                            final idx = section.nodes.indexWhere(
                              (n) => n.id == nodeId,
                            );
                            if (idx != -1 &&
                                _selectionController.hasSelection) {
                              setState(() {
                                _selectionController.onTap(idx);
                              });
                            }
                          }
                        : null,
                  );
                },
              );
            },
          ),
          if (_selectionController.hasSelection &&
              activeSection != null &&
              activeSection.nodes.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildSelectionActionBar(doc, activeSection),
            ),
        ],
      ),
    );
  }
}
