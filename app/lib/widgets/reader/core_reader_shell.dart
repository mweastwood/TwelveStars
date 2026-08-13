import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/reader/reader_adapter.dart';
import 'package:twelve_stars/logic/reader/reader_models.dart';
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
    this.initialSectionIndex = 1,
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
  ReaderDocument? _document;
  double _fontSize = 16.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentSectionIndex = widget.initialSectionIndex;
    _pageController = PageController(
      initialPage: widget.initialSectionIndex - 1,
    );
    _loadDocument();
  }

  @override
  void dispose() {
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
        });
        _pageController.jumpToPage(index - 1);
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
      body: PageView.builder(
        controller: _pageController,
        itemCount: doc.sectionsCount,
        onPageChanged: (pageIndex) {
          setState(() {
            _currentSectionIndex = pageIndex + 1;
          });
        },
        itemBuilder: (context, pageIndex) {
          final sectionIdx = pageIndex + 1;
          return FutureBuilder<ReaderSection>(
            future: widget.adapter.loadSection(
              sectionIdx,
              primaryVariant: widget.primaryVariant,
              compareVariant: widget.compareVariant,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final section = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
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
                    const SizedBox(height: 16),
                    ...section.nodes.map(
                      (node) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          node.primaryText ?? '',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: _fontSize,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
