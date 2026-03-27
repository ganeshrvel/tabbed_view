class TabbedViewThemeConstants {
  static const double minimalIconSize = 6;
  static const double defaultIconSize = 14;

  static const double arrowCircleSize = 20.0;
  static const double arrowIconSize = 12.0;
  static const double arrowScrollDelta = 200.0;
  static const double infoIconSize = 16.0;

  static const double arrowLeftPaddingStart = 6.0;
  static const double arrowLeftPaddingEnd = 6.0;
  static const double arrowRightPaddingStart = 6.0;
  static const double arrowRightPaddingEnd = 0.0;

  static double normalize(double buttonIconSize) {
    if (buttonIconSize >= TabbedViewThemeConstants.minimalIconSize) {
      return buttonIconSize;
    }
    return TabbedViewThemeConstants.minimalIconSize;
  }
}
