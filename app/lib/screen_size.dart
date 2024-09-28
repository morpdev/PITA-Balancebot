import 'package:flutter/material.dart';

class ScreenSize {
  static double aspectRatio = 1.0;
  static double width = 1.0;
  static double height = 1.0;
  static EdgeInsets padding;
  static Orientation orientation;

  void init(BuildContext context) {
    MediaQueryData _mediaQuery = MediaQuery.of(context);
    aspectRatio = _mediaQuery.size.aspectRatio;
    width = _mediaQuery.size.width;
    height = _mediaQuery.size.height;
    orientation = _mediaQuery.orientation;
    padding = _mediaQuery.padding;
  }
}

double adaptiveScreenWidth(double width) {
  return (width * ScreenSize.width) / 411.43;
}

double adaptiveScreenHeight(double height) {
  return (height * ScreenSize.height) / 683.43;
}
