import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/bible_metadata.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/theme/app_theme_tokens.dart';

class RibbonClipper extends CustomClipper<Path> {
  const RibbonClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    const double notchHeight = 8.0;
    const double r = 3.0;

    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 2, size.height - notchHeight);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BibleRibbonsWidget extends StatelessWidget {
  final List<BibleRibbonBookmark>? bookmarks;
  final void Function(int ribbonIndex, BibleRibbonBookmark? bookmark)
  onRibbonTap;
  final void Function(int ribbonIndex) onRibbonLongPress;

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
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
          final book = catholicBooks.firstWhere(
            (b) => b.bookNumber == bookmark!.bookNumber,
            orElse: () => catholicBooks.first,
          );
          tooltipMessage = '$ribbonName: ${book.bookName} ${bookmark.chapter}';
        } else {
          tooltipMessage =
              'Ribbon ${index + 1}: Unassigned (Long press to set)';
        }

        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0.0 : 6.0),
          child: Tooltip(
            message: tooltipMessage,
            triggerMode: TooltipTriggerMode.manual,
            child: GestureDetector(
              key: Key('bible_ribbon_$index'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onRibbonTap(index, bookmark),
              onLongPress: () => onRibbonLongPress(index),
              child: PhysicalShape(
                clipper: const RibbonClipper(),
                elevation: isAssigned ? 2.0 : 0.0,
                shadowColor: Colors.black45,
                color: isAssigned ? color : color.withValues(alpha: 0.35),
                child: const SizedBox(width: 16.0, height: 38.0),
              ),
            ),
          ),
        );
      }),
    );
  }
}
