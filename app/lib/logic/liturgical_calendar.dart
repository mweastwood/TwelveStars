import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/liturgical_calendar_core.dart';

export 'package:twelve_stars/logic/liturgical_calendar_core.dart';

extension LiturgicalColorUiExtension on LiturgicalColor {
  Color get colorWidget {
    switch (this) {
      case LiturgicalColor.green:
        return const Color(0xFF2E7D32);
      case LiturgicalColor.purple:
        return const Color(0xFF6A1B9A);
      case LiturgicalColor.white:
        return const Color(0xFFC68A00); // Liturgical Gold/White
      case LiturgicalColor.red:
        return const Color(0xFFC62828);
      case LiturgicalColor.rose:
        return const Color(0xFFD81B60);
    }
  }
}

extension LiturgicalDayUiExtension on LiturgicalDay {
  Color get colorWidget => color.colorWidget;
}
