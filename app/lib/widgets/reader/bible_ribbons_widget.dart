import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/bible_numbering_mapper.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/user_settings_controller.dart';
import 'package:twelve_stars/theme/app_theme_tokens.dart';
import 'package:twelve_stars/widgets/reader/ribbon_pattern_painter.dart';

export 'ribbon_pattern_painter.dart';

class BibleRibbonsWidget extends StatelessWidget {
  final List<BibleRibbonBookmark>? bookmarks;
  final void Function(int ribbonIndex, BibleRibbonBookmark? bookmark)
  onRibbonTap;
  final void Function(int ribbonIndex) onRibbonLongPress;
  final BibleNumberingSystem? numberingSystem;

  static const List<Color> ribbonColors = [
    AppThemeTokens.liturgicalRed,
    AppThemeTokens.liturgicalGold,
    AppThemeTokens.liturgicalGreen,
    AppThemeTokens.liturgicalPurple,
  ];

  static const List<String> ribbonNames = [
    'Red Ribbon',
    'Gold Ribbon',
    'Green Ribbon',
    'Purple Ribbon',
  ];

  const BibleRibbonsWidget({
    super.key,
    this.bookmarks,
    required this.onRibbonTap,
    required this.onRibbonLongPress,
    this.numberingSystem,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveNumberingSystem =
        numberingSystem ??
        UserSettingsController.instance.value.bibleNumberingSystem;
    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(4, (index) {
          BibleRibbonBookmark? bookmark;
          if (bookmarks != null) {
            for (final b in bookmarks!) {
              if (b.ribbonIndex == index) {
                bookmark = b;
                break;
              }
            }
          }

          final isAssigned = bookmark != null;
          final color = ribbonColors[index];
          final ribbonName = ribbonNames[index];

          final String tooltipMessage;
          if (isAssigned) {
            final book =
                catholicBooksByNumber[bookmark.bookNumber] ??
                catholicBooks.first;
            final chapterRef = BibleVerseResolver.formatChapterReference(
              bookNumber: book.bookNumber,
              bookName: book.bookName,
              chapter: bookmark.chapter,
              numberingSystem: effectiveNumberingSystem,
            );
            tooltipMessage = '$ribbonName: $chapterRef';
          } else {
            tooltipMessage =
                'Ribbon ${index + 1}: Unassigned (Long press to set)';
          }

          return Tooltip(
            message: tooltipMessage,
            triggerMode: TooltipTriggerMode.manual,
            child: GestureDetector(
              key: Key('bible_ribbon_$index'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onRibbonTap(index, bookmark),
              onLongPress: () => onRibbonLongPress(index),
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0.0 : 3.0,
                  right: index == 3 ? 16.0 : 3.0,
                ),
                child: PhysicalShape(
                  clipper: const RibbonClipper(),
                  clipBehavior: Clip.antiAlias,
                  elevation: isAssigned ? 2.0 : 0.0,
                  shadowColor: Colors.black45,
                  color: isAssigned ? color : color.withValues(alpha: 0.35),
                  child: const SizedBox(width: 16.0, height: 38.0),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class BiblePageRibbon extends StatelessWidget {
  final int ribbonIndex;

  const BiblePageRibbon({super.key, required this.ribbonIndex});

  @override
  Widget build(BuildContext context) {
    final color =
        (ribbonIndex >= 0 &&
            ribbonIndex < BibleRibbonsWidget.ribbonColors.length)
        ? BibleRibbonsWidget.ribbonColors[ribbonIndex]
        : BibleRibbonsWidget.ribbonColors[0];

    return RepaintBoundary(
      child: PhysicalShape(
        key: Key('bible_page_ribbon_$ribbonIndex'),
        clipper: const PageRibbonClipper(),
        clipBehavior: Clip.antiAlias,
        elevation: 2.0,
        shadowColor: Colors.black38,
        color: color,
        child: SizedBox(
          width: 16.0,
          height: double.infinity,
          child: CustomPaint(
            isComplex: true,
            willChange: false,
            painter: PageRibbonPatternPainter(
              ribbonIndex: ribbonIndex,
              stripeColor: Colors.white.withValues(alpha: 0.14),
              edgeColor: Colors.black.withValues(alpha: 0.10),
            ),
          ),
        ),
      ),
    );
  }
}

class BiblePageRibbonsWidget extends StatelessWidget {
  final List<BibleRibbonBookmark>? bookmarks;
  final int bookNumber;
  final int chapter;
  final double top;
  final double bottom;
  final double left;
  final double width;

  static const List<Color> ribbonColors = BibleRibbonsWidget.ribbonColors;
  static final Tween<Offset> _slideOffsetTween = Tween<Offset>(
    begin: const Offset(0.0, -1.0),
    end: Offset.zero,
  );

  const BiblePageRibbonsWidget({
    super.key,
    this.bookmarks,
    required this.bookNumber,
    required this.chapter,
    this.top = 0.0,
    this.bottom = 0.0,
    this.left = 4.0,
    this.width = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    BibleRibbonBookmark? matchingBookmark;
    if (bookmarks != null && bookmarks!.isNotEmpty) {
      for (final b in bookmarks!) {
        if (b.bookNumber == bookNumber && b.chapter == chapter) {
          matchingBookmark = b;
          break;
        }
      }
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      width: width,
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: _slideOffsetTween.animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[...previousChildren, ?currentChild],
            );
          },
          child: matchingBookmark != null
              ? BiblePageRibbon(
                  key: ValueKey<int>(matchingBookmark.ribbonIndex),
                  ribbonIndex: matchingBookmark.ribbonIndex,
                )
              : const SizedBox.shrink(key: ValueKey<String>('empty')),
        ),
      ),
    );
  }
}
