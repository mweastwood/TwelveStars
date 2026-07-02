import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_database.dart';

class BibleTab extends StatefulWidget {
  const BibleTab({super.key});

  @override
  State<BibleTab> createState() => _BibleTabState();
}

class _BibleTabState extends State<BibleTab> {
  List<BibleVerse> _verses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBibleData();
  }

  Future<void> _loadBibleData() async {
    try {
      final db = BibleDatabaseHelper.db;
      await db.ensurePopulated();
      final verses = await db.getChapterVerses('CPDV', 1, 1);
      if (mounted) {
        setState(() {
          _verses = verses;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error loading Bible: $_error'));
    }
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genesis 1',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Catholic Public Domain Version (CPDV)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.outline,
              ),
            ),
            const Divider(height: 24),
            ..._verses.map((verse) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyLarge,
                    children: [
                      TextSpan(
                        text: '${verse.verseNumber}  ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: verse.verseText,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
