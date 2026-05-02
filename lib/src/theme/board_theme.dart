import 'package:flutter/material.dart';

// Sentinel used by [BoardTheme.copyWith] to distinguish
// "leave this nullable field untouched" from "set it to null".
const Object _unset = Object();

/// An immutable bundle of every colour the [AdvancedChessBoard] paints.
///
/// Pass a preset (e.g. [BoardTheme.classicGreen]) or a fully-custom theme
/// via the [AdvancedChessBoard.boardTheme] parameter. Legacy per-colour
/// parameters (`lightSquareColor`, `darkSquareColor`,
/// `kingBackgroundColorOnCheckmate`) still win where they are explicitly
/// passed — see the resolution semantics in [AdvancedChessBoard]'s dartdoc.
@immutable
class BoardTheme {
  /// Creates a custom [BoardTheme].
  ///
  /// All non-nullable fields default to the 3.0.0 classic-green palette so
  /// that `const BoardTheme()` is always a safe starting point.
  const BoardTheme({
    this.lightSquareColor = const Color(0xFFEBECD0),
    this.darkSquareColor = const Color(0xFF739552),
    this.selectionColor = const Color(0x9BFFEB3B),
    this.lastMoveHighlightColor = const Color(0x80FFEB3B),
    this.legalDestinationColor = const Color(0x40000000),
    this.coordinateLabelColor,
    this.kingCheckmateColor = const Color(0x9BF44336),
    this.kingCheckColor,
    this.hintArrowColor = const Color(0x9932CD32),
    this.dragLegalRingColor = const Color(0xA0FFFFFF),
    this.dragIllegalTintColor = const Color(0x40F44336),
  });

  /// Light-square background colour. Default: `Color(0xFFEBECD0)` (3.0.0).
  final Color lightSquareColor;

  /// Dark-square background colour. Default: `Color(0xFF739552)` (3.0.0).
  final Color darkSquareColor;

  /// Translucent fill painted on the currently-selected square. Default:
  /// `Color(0x9BFFEB3B)` (yellow, alpha 155) — matches 3.0.0.
  final Color selectionColor;

  /// Translucent fill painted on the from/to squares of the last played
  /// move. Default: `Color(0x80FFEB3B)` (yellow, alpha 128) — matches 3.0.0.
  final Color lastMoveHighlightColor;

  /// Base colour for the [HighlightOverlay] legal-destination dot / ring.
  /// Default: `Color(0x40000000)` (black, alpha 64) — matches 3.0.0 shade.
  final Color legalDestinationColor;

  /// Colour of rank/file labels. When `null` (default), labels use the
  /// inverted square colour at alpha 200 — matching 3.0.0's derived label
  /// colour. When non-null, that colour is used verbatim at alpha 200.
  final Color? coordinateLabelColor;

  /// Tint drawn behind the mated king. Default: `Color(0x9BF44336)`
  /// (red, alpha 155) — matches 3.0.0.
  final Color kingCheckmateColor;

  /// Optional tint drawn behind a checked (but not mated) king. `null`
  /// (default) means no in-check tint is rendered — matches 3.0.0.
  final Color? kingCheckColor;

  /// Default colour for the [HintArrow] when no per-arrow colour is given.
  /// Default: `Color(0x9932CD32)` (lime green, alpha ~60%) — visually
  /// distinct from the amber default of [ChessArrow].
  final Color hintArrowColor;

  /// Colour of the drag-legal ring (thickened border around the
  /// legal-destination hint on the square under the drag pointer).
  final Color dragLegalRingColor;

  /// Translucent fill painted on a non-source, non-legal square under the
  /// drag pointer.
  final Color dragIllegalTintColor;

  /// The 3.0.0 default palette. `lightSquareColor == 0xFFEBECD0`,
  /// `darkSquareColor == 0xFF739552`.
  static const BoardTheme classicGreen = BoardTheme();

  /// A traditional wooden-board palette.
  static const BoardTheme brown = BoardTheme(
    lightSquareColor: Color(0xFFF0D9B5),
    darkSquareColor: Color(0xFFB58863),
  );

  /// A cool blue palette.
  static const BoardTheme blue = BoardTheme(
    lightSquareColor: Color(0xFFDEE3E6),
    darkSquareColor: Color(0xFF8CA2AD),
  );

  /// A violet palette.
  static const BoardTheme purple = BoardTheme(
    lightSquareColor: Color(0xFFE8E3F3),
    darkSquareColor: Color(0xFF8476B5),
  );

  /// A high-contrast greyscale palette.
  static const BoardTheme monochrome = BoardTheme(
    lightSquareColor: Color(0xFFEEEEEE),
    darkSquareColor: Color(0xFF606060),
  );

  /// Returns a copy of this theme with the named fields replaced.
  ///
  /// The two nullable fields ([coordinateLabelColor] and [kingCheckColor])
  /// use a private `_unset` sentinel so callers can explicitly set them to
  /// `null`. Omitting the argument leaves the field unchanged.
  ///
  /// Example:
  /// ```dart
  /// // Explicitly set coordinateLabelColor to null:
  /// theme.copyWith(coordinateLabelColor: null)
  /// // Leave coordinateLabelColor unchanged:
  /// theme.copyWith(/* no coordinateLabelColor arg */)
  /// ```
  BoardTheme copyWith({
    Color? lightSquareColor,
    Color? darkSquareColor,
    Color? selectionColor,
    Color? lastMoveHighlightColor,
    Color? legalDestinationColor,
    Object? coordinateLabelColor = _unset,
    Color? kingCheckmateColor,
    Object? kingCheckColor = _unset,
    Color? hintArrowColor,
    Color? dragLegalRingColor,
    Color? dragIllegalTintColor,
  }) {
    return BoardTheme(
      lightSquareColor: lightSquareColor ?? this.lightSquareColor,
      darkSquareColor: darkSquareColor ?? this.darkSquareColor,
      selectionColor: selectionColor ?? this.selectionColor,
      lastMoveHighlightColor:
          lastMoveHighlightColor ?? this.lastMoveHighlightColor,
      legalDestinationColor:
          legalDestinationColor ?? this.legalDestinationColor,
      coordinateLabelColor: identical(coordinateLabelColor, _unset)
          ? this.coordinateLabelColor
          : coordinateLabelColor as Color?,
      kingCheckmateColor: kingCheckmateColor ?? this.kingCheckmateColor,
      kingCheckColor: identical(kingCheckColor, _unset)
          ? this.kingCheckColor
          : kingCheckColor as Color?,
      hintArrowColor: hintArrowColor ?? this.hintArrowColor,
      dragLegalRingColor: dragLegalRingColor ?? this.dragLegalRingColor,
      dragIllegalTintColor: dragIllegalTintColor ?? this.dragIllegalTintColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoardTheme &&
        other.lightSquareColor == lightSquareColor &&
        other.darkSquareColor == darkSquareColor &&
        other.selectionColor == selectionColor &&
        other.lastMoveHighlightColor == lastMoveHighlightColor &&
        other.legalDestinationColor == legalDestinationColor &&
        other.coordinateLabelColor == coordinateLabelColor &&
        other.kingCheckmateColor == kingCheckmateColor &&
        other.kingCheckColor == kingCheckColor &&
        other.hintArrowColor == hintArrowColor &&
        other.dragLegalRingColor == dragLegalRingColor &&
        other.dragIllegalTintColor == dragIllegalTintColor;
  }

  @override
  int get hashCode => Object.hash(
        lightSquareColor,
        darkSquareColor,
        selectionColor,
        lastMoveHighlightColor,
        legalDestinationColor,
        coordinateLabelColor,
        kingCheckmateColor,
        kingCheckColor,
        hintArrowColor,
        dragLegalRingColor,
        dragIllegalTintColor,
      );
}
