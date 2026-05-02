import 'package:flutter/foundation.dart';

/// An engine-supplied / app-supplied single-shot move suggestion, rendered
/// with a visually distinct style from user-drawn [ChessArrow]s and
/// auto-dismissed on the next successful move.
///
/// Concretely distinct treatment:
/// - Colour: [BoardTheme.hintArrowColor] (lime green default) instead of
///   the amber default of [ChessArrow].
/// - Geometry: a DASHED shaft (blockSize*0.15 on / blockSize*0.10 off)
///   and a STROKE-ONLY outlined arrowhead (thin border, no fill) instead
///   of the solid line + filled equilateral triangle of [ChessArrow].
///
/// ### Square notation
///
/// [startSquare] and [endSquare] use algebraic notation (e.g. `"e2"`,
/// `"e4"`). Malformed square strings result in the arrow rendering
/// off-canvas (invisible) — no exception is thrown, matching 3.0.0's
/// tolerance for malformed [ChessArrow] inputs.
///
/// ### Auto-dismiss semantics
///
/// - When [duration] is `null`, the arrow persists until the next
///   successful move (or until `hintArrow:` is replaced or set to `null`).
/// - When [duration] is non-null, the arrow auto-dismisses after that
///   duration elapses from its first render, even if no move has been made.
@immutable
class HintArrow {
  /// Creates a [HintArrow] from [startSquare] to [endSquare] using
  /// algebraic notation (e.g. `"e2"` → `"e4"`).
  ///
  /// If [duration] is non-null, the arrow auto-dismisses after that
  /// duration elapses from its first render, even if no move has been
  /// made. If `null`, the arrow persists until the next successful move
  /// (or until `hintArrow:` is replaced or set to `null`).
  const HintArrow({
    required this.startSquare,
    required this.endSquare,
    this.duration,
  });

  /// Algebraic source square, e.g. `"e2"`.
  final String startSquare;

  /// Algebraic destination square, e.g. `"e4"`.
  final String endSquare;

  /// Optional timer before auto-dismissal. `null` means "persist until
  /// next move".
  final Duration? duration;

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    return other is HintArrow &&
        other.startSquare == startSquare &&
        other.endSquare == endSquare &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(startSquare, endSquare, duration);
}
