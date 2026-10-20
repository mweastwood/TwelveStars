import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared controller managing contiguous range selection, temporary target
/// highlighting, and auto-scroll lifecycle across Scripture and Library readers.
class ReaderSelectionController {
  int? _firstSelected;
  int? _lastSelected;

  int? _temporaryHighlightStart;
  int? _temporaryHighlightEnd;
  String? _lastProcessedSessionId;
  bool _hasProcessedInitialTarget = false;
  Timer? _highlightTimer;

  int? get firstSelected => _firstSelected;
  int? get lastSelected => _lastSelected;

  int? get temporaryHighlightStart => _temporaryHighlightStart;
  int? get temporaryHighlightEnd => _temporaryHighlightEnd;

  bool get hasSelection => _firstSelected != null && _lastSelected != null;

  bool get hasTemporaryHighlight =>
      _temporaryHighlightStart != null && _temporaryHighlightEnd != null;

  int? get start => hasSelection ? min(_firstSelected!, _lastSelected!) : null;

  int? get end => hasSelection ? max(_firstSelected!, _lastSelected!) : null;

  int get selectedCount => hasSelection ? (end! - start! + 1) : 0;

  int? get effectiveHighlightStart =>
      start ??
      (hasTemporaryHighlight
          ? min(_temporaryHighlightStart!, _temporaryHighlightEnd!)
          : null);

  int? get effectiveHighlightEnd =>
      end ??
      (hasTemporaryHighlight
          ? max(_temporaryHighlightStart!, _temporaryHighlightEnd!)
          : null);

  /// Returns `true` if [value] falls within either the active user selection
  /// range or the active temporary target highlight range.
  bool isSelected(int value) {
    if (hasSelection) {
      return value >= start! && value <= end!;
    }
    if (hasTemporaryHighlight) {
      final tStart = min(_temporaryHighlightStart!, _temporaryHighlightEnd!);
      final tEnd = max(_temporaryHighlightStart!, _temporaryHighlightEnd!);
      return value >= tStart && value <= tEnd;
    }
    return false;
  }

  /// Initiates a selection at [value] on long press.
  void onLongPress(int value, {bool playClickSound = true}) {
    if (playClickSound) {
      SystemSound.play(SystemSoundType.click);
    }
    _firstSelected = value;
    _lastSelected = value;
  }

  /// Expands or updates the active selection end to [value] when a selection
  /// is already active. Returns `true` if the selection changed.
  bool onTap(int value) {
    if (_firstSelected != null) {
      _lastSelected = value;
      return true;
    }
    return false;
  }

  /// Clears the active user selection. If [clearTemporaryHighlight] is `true`,
  /// also clears any active temporary target highlight.
  void clear({bool clearTemporaryHighlight = false}) {
    _firstSelected = null;
    _lastSelected = null;
    if (clearTemporaryHighlight) {
      _temporaryHighlightStart = null;
      _temporaryHighlightEnd = null;
    }
  }

  /// Determines whether a navigation target should be processed based on
  /// [navigationSessionId] or initial load state.
  bool shouldProcessTarget({
    required bool hasTarget,
    String? navigationSessionId,
    bool requireSessionIdMatchOnly = false,
  }) {
    if (!hasTarget) return false;
    if (requireSessionIdMatchOnly) {
      return navigationSessionId != _lastProcessedSessionId;
    }
    return navigationSessionId != null
        ? navigationSessionId != _lastProcessedSessionId
        : !_hasProcessedInitialTarget;
  }

  /// Records that the target for [navigationSessionId] has been processed, sets
  /// the temporary highlight range, and schedules a timer to clear it.
  void activateTemporaryHighlight({
    required int? start,
    required int? end,
    String? navigationSessionId,
    Duration duration = const Duration(seconds: 2),
    required VoidCallback onExpired,
  }) {
    _hasProcessedInitialTarget = true;
    _lastProcessedSessionId = navigationSessionId;
    _temporaryHighlightStart = start;
    _temporaryHighlightEnd = end;

    _highlightTimer?.cancel();
    _highlightTimer = Timer(duration, () {
      _temporaryHighlightStart = null;
      _temporaryHighlightEnd = null;
      onExpired();
    });
  }

  /// Scrolls [targetKey]'s context into view on the next frame if mounted.
  void scrollToKeyPostFrame(
    GlobalKey? Function() resolveTargetKey, {
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = resolveTargetKey();
      final context = key?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: duration,
          curve: curve,
          alignment: alignment,
        );
      }
    });
  }

  void dispose() {
    _highlightTimer?.cancel();
    _highlightTimer = null;
  }
}
