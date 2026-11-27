import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/widgets/saints/saint_ui_extensions.dart';

/// Represents a single pixel-art sprite asset for a [Saint].
class SaintSpriteVariant {
  /// Relative Flutter asset path (e.g. `assets/saints/thomas-aquinas.png`).
  final String assetPath;

  /// Human-readable title for this sprite (especially useful for Marian titles).
  final String label;

  /// Optional shorter label for compact grid tiles.
  final String? shortLabel;

  const SaintSpriteVariant({
    required this.assetPath,
    required this.label,
    this.shortLabel,
  });

  /// Label displayed inside compact gallery cards.
  String get displayLabel => shortLabel ?? label;
}

/// The six Marian pixel-art sprites available for `mary-mother-of-god`.
const List<SaintSpriteVariant> kMarianSpriteVariants = [
  SaintSpriteVariant(
    assetPath: 'assets/saints/our-lady-of-grace.png',
    label: 'Our Lady of Grace',
    shortLabel: 'Grace',
  ),
  SaintSpriteVariant(
    assetPath: 'assets/saints/immaculate-heart-of-mary.png',
    label: 'Immaculate Heart of Mary',
    shortLabel: 'Immaculate Heart',
  ),
  SaintSpriteVariant(
    assetPath: 'assets/saints/our-lady-of-guadalupe.png',
    label: 'Our Lady of Guadalupe',
    shortLabel: 'Guadalupe',
  ),
  SaintSpriteVariant(
    assetPath: 'assets/saints/our-lady-of-lourdes.png',
    label: 'Our Lady of Lourdes',
    shortLabel: 'Lourdes',
  ),
  SaintSpriteVariant(
    assetPath: 'assets/saints/our-lady-of-fatima.png',
    label: 'Our Lady of Fatima',
    shortLabel: 'Fatima',
  ),
  SaintSpriteVariant(
    assetPath: 'assets/saints/our-lady-of-la-vang.png',
    label: 'Our Lady of La Vang',
    shortLabel: 'La Vang',
  ),
];

/// Extension mapping a [Saint] to its bundled pixel-art sprite asset(s).
extension SaintSpriteExtension on Saint {
  /// All pixel-art sprite variants associated with this saint.
  ///
  /// The Blessed Virgin Mary (`mary-mother-of-god`) has six Marian title
  /// sprites; all other saints map 1:1 to `assets/saints/<id>.png`.
  List<SaintSpriteVariant> get spriteVariants {
    if (id == 'mary-mother-of-god') {
      return kMarianSpriteVariants;
    }
    return [
      SaintSpriteVariant(assetPath: 'assets/saints/$id.png', label: shortName),
    ];
  }

  /// The primary/default pixel-art sprite asset path for this saint.
  String get primarySpriteAssetPath => spriteVariants.first.assetPath;

  /// Whether this saint has multiple selectable sprite variants (e.g. Mary).
  bool get hasMultipleSprites => spriteVariants.length > 1;
}

/// Renders a crisp nearest-neighbor 32x32 pixel-art saint sprite with a
/// graceful fallback icon if the asset is unavailable (such as for synthetic
/// saints in tests).
class SaintSpriteImage extends StatelessWidget {
  final String assetPath;
  final double size;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double? fallbackIconSize;

  const SaintSpriteImage({
    super.key,
    required this.assetPath,
    required this.size,
    required this.fallbackIcon,
    required this.fallbackColor,
    this.fallbackIconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          fallbackIcon,
          color: fallbackColor,
          size: fallbackIconSize ?? (size * 0.6),
        );
      },
    );
  }
}

/// Framed pixel-art avatar container for a [Saint], styled with the saint's
/// primary category accent color and falling back to [Saint.categoryIcon].
class SaintSpriteAvatar extends StatelessWidget {
  final Saint saint;

  /// Optional override asset path (e.g. a selected Marian title variant).
  final String? assetPath;

  /// Outer container size in logical pixels.
  final double size;

  /// Inner sprite size in logical pixels. Defaults to `32` for small avatars
  /// or `size - 8` for larger avatars to preserve crisp pixel-art scaling.
  final double? imageSize;

  /// Corner radius of the avatar frame.
  final double borderRadius;

  const SaintSpriteAvatar({
    super.key,
    required this.saint,
    this.assetPath,
    this.size = 44,
    this.imageSize,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = saint.categoryColor(theme);
    final resolvedImageSize = imageSize ?? (size >= 64 ? 64.0 : 32.0);

    return Container(
      key: Key('saint_sprite_avatar_${saint.id}'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: catColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: catColor.withValues(alpha: 0.3), width: 1),
      ),
      alignment: Alignment.center,
      child: SaintSpriteImage(
        assetPath: assetPath ?? saint.primarySpriteAssetPath,
        size: resolvedImageSize,
        fallbackIcon: saint.categoryIcon,
        fallbackColor: catColor,
        fallbackIconSize: size * 0.5,
      ),
    );
  }
}
