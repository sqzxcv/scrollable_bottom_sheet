import 'package:flutter/material.dart';
import 'package:scrollable_bottom_sheet/scrollable_bottom_sheet.dart';

abstract class ScrollableInterface {
  //re-set minimum height to make [ScrollableBottomSheetByContent] possible
  void setMinimumHeight(double newMinimumHeight);

  //re-set half height to make [ScrollableBottomSheetByContent] possible
  void setHalfHeight(double newHalfHeight);

  /// animate current Bottom Sheet to [minimumHeight] (if specified)
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToMinimum(BuildContext context, {bool willPop = false, Duration duration = const Duration(milliseconds: 200)});

  /// animate current Bottom Sheet to 0.0
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToZero(BuildContext context, {bool willPop = false, Duration duration = const Duration(milliseconds: 200)});

  /// animate current Bottom Sheet to initialHeight
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToHalf(BuildContext context, {Duration duration = const Duration(milliseconds: 200)});

  /// animate current Bottom Sheet to maximum height available
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToFull(BuildContext context, {Duration duration = const Duration(milliseconds: 200)});

  void setScrollState(ScrollState sState);

  void setFullHeight(double newFullHeight);
}

class ScrollableController {
  ScrollableInterface _interface;

  set interface(ScrollableInterface value) {
    _interface = value;
  }

  //re-set minimum height to make [ScrollableBottomSheetByContent] possible
  void setMinimumHeight(double newMinimumHeight) {
    if (_interface != null) _interface.setMinimumHeight(newMinimumHeight);
  }

  //re-set half height to make [ScrollableBottomSheetByContent] possible
  void setHalfHeight(double newHalfHeight) {
    if (_interface != null) _interface.setHalfHeight(newHalfHeight);
  }

  /// animate current Bottom Sheet to [minimumHeight] (if specified)
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToMinimum(BuildContext context, {bool willPop = false, Duration duration = const Duration(milliseconds: 200)}) {
    if (_interface != null) _interface.animateToMinimum(context, willPop: willPop, duration: duration);
  }

  /// animate current Bottom Sheet to 0.0
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToZero(BuildContext context, {bool willPop = false, Duration duration = const Duration(milliseconds: 200)}) {
    if (_interface != null) _interface.animateToZero(context, willPop: willPop, duration: duration);
  }

  /// animate current Bottom Sheet to initialHeight
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToHalf(BuildContext context, {Duration duration = const Duration(milliseconds: 200)}) {
    if (_interface != null) _interface.animateToHalf(context, duration: duration);
  }

  /// animate current Bottom Sheet to maximum height available
  /// you can call this method from Global Key
  ///
  /// See [example/main.dart] for example
  void animateToFull(BuildContext context, {Duration duration = const Duration(milliseconds: 200)}) {
    if (_interface != null) _interface.animateToFull(context, duration: duration);
  }

  void setScrollState(ScrollState sState) {
    if (_interface != null) _interface.setScrollState(sState);
  }

  void setFullHeight(double newFullHeight) {
    if (_interface != null) _interface.setFullHeight(newFullHeight);
  }
}