# Chess Board UX Enhancements Feature Design

## Overview

`advanced_chess_board` 3.0.0 shipped a strict-analyse-clean, dartdoc-complete,
test-covered chess board widget. This spec extends it with six additive,
opt-in UX capabilities — pluggable board themes, pluggable piece sets, an
outside-gutter / hidden coordinate mode, a silent-by-default sound-pack
interface, a visually distinct hint arrow channel, and a live legality
indicator on the square under the drag pointer.

Every change is additive. When a 3.0.0 consumer upgrades without opting into
any new parameter, the board renders pixel-identical to 3.0.0, with
identical sounds (none) and identical ARIA labels. The target release is
**3.1.0** — a minor bump. No preservation clause (P1–P27 in
`requirements.md`) is regressed.

## Glossary

- **BoardTheme** — new public value type bundling every `Color` the board
  paints: light/dark squares, selection overlay, last-move highlight,
  legal-destination hint, coordinate label (nullable), mated-king tint,
  in-check tint (nullable), hint-arrow colour, drag-legal ring, drag-illegal
  tint. Const constructor, value equality over all fields, `copyWith`, five
  named preset getters.
- **PieceSet** — new public abstract class with a single method
  `ImageProvider imageFor(PlayerColor, chess.PieceType)`. The default
  `PieceSet.chessDotCom` wraps the 12 `assets/pieces/*.png` bundled by 3.0.0.
- **CoordinateLabels** — new public enum with exactly three values: `inside`
  (current 3.0.0 behaviour), `outside` (labels in gutters outside the 8×8
  grid), `none` (no labels anywhere, no gutter space).
- **SoundEvent** — new public enum over move classifications: `move`,
  `capture`, `check`, `castle`, `promote`, `gameEnd`.
- **SoundPack** — new public abstract class with one method
  `Future<void> play(SoundEvent event)`. Implementations are free to
  debounce, overlap, swallow, or sequence events.
- **SilentSoundPack** — default concrete `SoundPack` whose `play` returns an
  already-resolved `Future<void>`. Zero audio assets, zero plugin
  dependencies, zero platform channels.
- **HintArrow** — new public value type (separate from `ChessArrow`) with
  `startSquare`, `endSquare`, optional `duration`. Rendered with distinct
  colour AND distinct geometry (dashed shaft + stroke-only outlined
  triangle). Auto-dismisses on next move or on duration elapsed.
- **Drag-legal ring** — thickened-border variant of `HighlightOverlay`
  rendered on the square currently under the drag pointer when that square
  is a legal destination. Painted in `boardTheme.dragLegalRingColor` and
  stacked above the existing hint.
- **Drag-illegal tint** — translucent fill painted on the square currently
  under the drag pointer when that square is NOT a legal destination and is
  NOT the drag source. Painted in `boardTheme.dragIllegalTintColor`.
- **Move classification** — the result of the priority-ordered function
  `classifyMove(verboseMove, controllerSnapshotAfter)` that maps to one
  `SoundEvent`. Priority (highest first): `gameEnd` > `promote` > `castle` >
  `check` > `capture` > `move`.
- **Gutter** — a strip of logical pixels outside the 8×8 playing grid,
  reserved for rank or file labels when `coordinates == outside`. Width
  equals `max(kMinLabelFontSize * 2, squareSize * 0.36)` as a rule of thumb
  — exact formula in "Rendering / Layout Strategy".
- **Exported public surface** — the set of symbols re-exported from
  `lib/advanced_chess_board.dart`. Grows in 3.1.0 from four symbols to
  eleven (the four existing plus `BoardTheme`, `PieceSet`,
  `CoordinateLabels`, `SoundEvent`, `SoundPack`, `SilentSoundPack`,
  `HintArrow`).

## Proposed Public API

Every new symbol lives under `lib/src/` and is re-exported from the barrel.
Signatures below are the authoritative contract — the Tasks phase
implements them verbatim.

### `BoardTheme` (`lib/src/theme/board_theme.dart`)

```dart
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
  });

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}

// Sentinel used by [BoardTheme.copyWith] to distinguish
// "leave this nullable field untouched" from "set it to null".
const Object _unset = Object();
```

**Rationale — legacy-wins resolution.** The chosen resolution strategy is a
widget-level `.resolve({legacyLight, legacyDark, legacyMateColor})` helper
that returns an "effective theme" used for every paint call:

```dart
BoardTheme get _effectiveTheme => widget.boardTheme.copyWith(
      lightSquareColor: widget.lightSquareColor,            // non-null always
      darkSquareColor: widget.darkSquareColor,              // non-null always
      kingCheckmateColor: widget.kingBackgroundColorOnCheckmate
          ?? widget.boardTheme.kingCheckmateColor,
    );
```

The `lightSquareColor` and `darkSquareColor` parameters are *non-nullable*
with 3.0.0 default values already equal to `BoardTheme.classicGreen`, so
passing an explicit 3.0.0 default is indistinguishable from passing nothing
— and that is correct: "passing the 3.0.0 default" IS what 3.0.0 consumers
do, and the effective theme remains classicGreen. Only `kingCheckmateColor`
uses `??` because `kingBackgroundColorOnCheckmate` is nullable.

**Alternative considered**: introspect "was this parameter actually passed
by the consumer?" via a sentinel default. Rejected — sentinels on `Color`
parameters break const-constructibility of `AdvancedChessBoard` and would
require breaking the 3.0.0 parameter signatures. The `copyWith`-based
resolution is non-breaking, const-safe, and produces identical output to
3.0.0 when the consumer passes only 3.0.0 parameters.

### `PieceSet` (`lib/src/piece_set/piece_set.dart`)

```dart
/// An immutable mapping from `(PlayerColor, chess.PieceType)` to an
/// [ImageProvider] — i.e. a swappable piece set.
///
/// The default [PieceSet.chessDotCom] wraps the 12 `assets/pieces/*.png`
/// files bundled with this package. Consumers can subclass [PieceSet] to
/// point at their own assets, or use [PieceSet.fromAssetMap] for the
/// common case of a 12-entry asset map.
@immutable
abstract class PieceSet {
  /// Base const constructor; subclasses MUST provide one too so the
  /// top-level default value can be const.
  const PieceSet();

  /// Returns the [ImageProvider] for a piece of [color] and [type].
  ///
  /// Called once per rendered piece per build — cheap implementations
  /// (returning a cached `const AssetImage(...)`) are strongly preferred.
  ImageProvider imageFor(PlayerColor color, chess.PieceType type);

  /// The bundled Chess.com-sourced PNG set shipped since 1.0.0.
  /// Default value for [AdvancedChessBoard.pieceSet].
  static const PieceSet chessDotCom = _ChessDotComPieceSet();

  /// Convenience constructor building a [PieceSet] from a 12-entry
  /// `Map<(PlayerColor, chess.PieceType), ImageProvider>`.
  ///
  /// Throws [ArgumentError] when any of the 12 `(color, type)` keys is
  /// absent.
  const factory PieceSet.fromAssetMap(
    Map<({PlayerColor color, chess.PieceType type}), ImageProvider> map,
  ) = _MapBackedPieceSet;
}
```

Concrete `_ChessDotComPieceSet` has a private const constructor and a
switch-over-`(color, type)` returning `const AssetImage(path, package:
packageName)`. Two instances of `_ChessDotComPieceSet()` are const-identical
so value equality is satisfied automatically by Dart const canonicalisation.

`_MapBackedPieceSet` stores the map unmodified, implements `imageFor` as a
lookup, and implements `==` / `hashCode` over the 12 map entries (iterating
in a canonical `(color, type)` order) so that two sets built from equal maps
compare equal for `didUpdateWidget` swap detection.

**Rationale — abstract class with `imageFor` vs twelve fields.** The
abstract-class approach wins on three axes: (1) it admits procedural
implementations (e.g. a SVG-rendered set where `imageFor` returns a
`MemoryImage` computed on demand), (2) it keeps const-constructibility
cheap for the default wrapper, and (3) it allows the
`public_member_api_docs` lint to check that the single `imageFor` method
has a doc comment instead of requiring twelve individual field comments on
every implementation. Value equality is preserved by the default const
subclass (trivial) and the map-backed subclass (defined explicitly).

### `CoordinateLabels` (`lib/src/coordinates/coordinate_labels.dart`)

```dart
/// How rank/file coordinate labels are rendered on [AdvancedChessBoard].
enum CoordinateLabels {
  /// Labels overlaid inside the corner squares of the playing grid —
  /// the 3.0.0 default. See [ChessSquare] for exact positioning.
  inside,

  /// Labels rendered in gutters OUTSIDE the 8×8 playing grid (left-edge
  /// for ranks, bottom-edge for files). The playing grid still honours
  /// `AspectRatio(1)`; the gutters consume additional horizontal /
  /// vertical space.
  outside,

  /// No rank or file labels rendered anywhere. No gutter space allocated.
  none,
}
```

### `SoundEvent` (`lib/src/sound/sound_event.dart`)

```dart
/// Classification of a successful move for audio feedback.
///
/// The [AdvancedChessBoard] emits exactly one event per successful move,
/// picking the highest-priority classification that applies:
/// `gameEnd` > `promote` > `castle` > `check` > `capture` > `move`.
enum SoundEvent {
  /// A quiet move that is not a capture, check, castle, promotion, or
  /// game-ending move.
  move,

  /// A capture that is not also a check, castle, promotion, or game end.
  capture,

  /// A move that delivers check but is not mate, promotion, or castle.
  check,

  /// Kingside or queenside castling.
  castle,

  /// A pawn promotion (with or without capture).
  promote,

  /// A move that ends the game — checkmate, stalemate, draw-by-rule, or
  /// insufficient material.
  gameEnd,
}
```

### `SoundPack` and `SilentSoundPack` (`lib/src/sound/sound_pack.dart`)

```dart
/// Plug-in interface for move sound effects.
///
/// The library ships no audio assets and depends on no audio plugin.
/// Consumers pass a subclass that routes [SoundEvent]s to their preferred
/// audio stack (for example, `package:audioplayers` or
/// `package:just_audio`). Thrown errors are caught and logged via
/// `debugPrint` — they do not propagate to the board's rebuild cycle.
abstract class SoundPack {
  /// Base const constructor.
  const SoundPack();

  /// Invoked exactly once per successful move. Implementations may return
  /// immediately (fire-and-forget) or `await` loading / playback —
  /// [AdvancedChessBoard] does not await the returned future.
  Future<void> play(SoundEvent event);
}

/// Default [SoundPack]: `play` returns immediately without touching any
/// audio plugin or platform channel.
class SilentSoundPack extends SoundPack {
  /// Creates a [SilentSoundPack].
  const SilentSoundPack();

  @override
  Future<void> play(SoundEvent event) => Future<void>.value();
}
```

### `HintArrow` (`lib/src/hint/hint_arrow.dart`)

```dart
/// An engine-supplied / app-supplied single-shot move suggestion, rendered
/// with a visually distinct style from user-drawn [ChessArrow]s and
/// auto-dismissed on the next successful move.
///
/// Concretely distinct treatment:
/// - Colour: [BoardTheme.hintArrowColor] (lime green default) instead of
///   the amber default of [ChessArrow].
/// - Geometry: a DASHED shaft (6 px on / 4 px off, scaled by `blockSize`)
///   and a STROKE-ONLY outlined arrowhead (thin border, no fill) instead
///   of the solid line + filled equilateral triangle of [ChessArrow].
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
  bool operator ==(Object other);

  @override
  int get hashCode;
}
```

### `AdvancedChessBoard` additions

```dart
class AdvancedChessBoard extends StatefulWidget {
  const AdvancedChessBoard({
    super.key,
    required this.controller,
    this.lightSquareColor = const Color(0xFFEBECD0),
    this.darkSquareColor = const Color(0xFF739552),
    this.initialFEN,
    this.boardOrientation = PlayerColor.white,
    this.enableMoves = true,
    this.highlightLastMove = true,
    this.arrows = const <ChessArrow>[],
    this.kingBackgroundColorOnCheckmate,
    this.moveAnimationDuration = kDefaultMoveAnimationDuration,
    // NEW in 3.1.0 — every parameter below is additive and opt-in.
    this.boardTheme = BoardTheme.classicGreen,
    this.pieceSet = PieceSet.chessDotCom,
    this.coordinates = CoordinateLabels.inside,
    this.soundPack = const SilentSoundPack(),
    this.hintArrow,
  });

  // ... existing fields unchanged ...

  /// Colour bundle used for every square, overlay, label, and tint.
  /// Legacy per-colour parameters (`lightSquareColor`, `darkSquareColor`,
  /// `kingBackgroundColorOnCheckmate`) take precedence over the
  /// corresponding fields on [boardTheme] when explicitly passed.
  final BoardTheme boardTheme;

  /// Piece image provider. Default is [PieceSet.chessDotCom] — the 12
  /// bundled Chess.com-sourced PNGs.
  final PieceSet pieceSet;

  /// Coordinate-label rendering mode. Default [CoordinateLabels.inside]
  /// matches 3.0.0.
  final CoordinateLabels coordinates;

  /// Audio hook. Default [SilentSoundPack] produces no sound.
  final SoundPack soundPack;

  /// Optional engine/app-supplied suggestion arrow, rendered on top of
  /// [arrows] and auto-dismissed on the next successful move.
  final HintArrow? hintArrow;
}
```

### Barrel additions (`lib/advanced_chess_board.dart`)

```dart
export 'src/advanced_chess_board.dart' show AdvancedChessBoard;
export 'src/chess_board_controller.dart' show ChessBoardController;
export 'src/coordinates/coordinate_labels.dart' show CoordinateLabels;
export 'src/hint/hint_arrow.dart' show HintArrow;
export 'src/models/chess_arrow.dart' show ChessArrow;
export 'src/models/enums.dart' show PlayerColor;
export 'src/piece_set/piece_set.dart' show PieceSet;
export 'src/sound/sound_event.dart' show SoundEvent;
export 'src/sound/sound_pack.dart' show SilentSoundPack, SoundPack;
export 'src/theme/board_theme.dart' show BoardTheme;
```

## Implementation

Organised by capability. Each subsection lists new files, modified files,
and precise hooks.

### 1. BoardTheme

**New file**: `lib/src/theme/board_theme.dart` — contains `BoardTheme`,
its five preset const getters, `copyWith`, `==`, and `hashCode` verbatim
per the API above.

**Modified file**: `lib/src/advanced_chess_board.dart`
- Add `final BoardTheme boardTheme` field with default
  `BoardTheme.classicGreen`.
- Add a private `BoardTheme get _effectiveTheme` getter implementing the
  legacy-wins resolution via `copyWith` as shown above.
- Replace every reference to `widget.lightSquareColor` /
  `widget.darkSquareColor` in `_buildChessBoard` with
  `_effectiveTheme.lightSquareColor` / `_effectiveTheme.darkSquareColor`.
- Replace `const Color(0x9BFFEB3B)` (selection overlay) with
  `_effectiveTheme.selectionColor`.
- Replace `const Color(0x80FFEB3B)` (last-move highlight) with
  `_effectiveTheme.lastMoveHighlightColor`.
- Replace the hard-coded `Colors.black12.withAlpha(75)` / `withAlpha(100)`
  passed down to `HighlightOverlay` — extend `HighlightOverlay` with a
  `Color color` field and feed it `_effectiveTheme.legalDestinationColor`.
- Replace `widget.kingBackgroundColorOnCheckmate ?? const Color(0x9BF44336)`
  with `_effectiveTheme.kingCheckmateColor` (the legacy parameter folds in
  via `copyWith` at the top of `_effectiveTheme`).
- Thread `_effectiveTheme.coordinateLabelColor` down to `ChessSquare` and
  to the new `_CoordinateGutter` widget.
- Thread `_effectiveTheme.kingCheckColor` into `_buildCheckmateKingOverlay`
  — rename it to `_buildKingStateOverlay` and branch on `in_checkmate` vs
  `in_check` (the `kingCheckColor == null` case is a no-op, matching 3.0.0).

**Modified file**: `lib/src/widgets/highlight_overlay.dart`
- Add `final Color color;` required field (no default — forces the caller
  to thread the effective theme colour; this keeps the 3.0.0 colour
  pinned via the preset).
- Replace the two hard-coded `Colors.black12.withAlpha(...)` with `color`
  (the ring uses `color.withAlpha(75)`, the dot uses `color.withAlpha(100)`,
  preserving the 3.0.0 alphas as derived shades of the theme's base colour).

### 2. PieceSet

**New file**: `lib/src/piece_set/piece_set.dart` — `PieceSet` abstract
class, `_ChessDotComPieceSet` (const, delegates to `PieceImages`
constants), `_MapBackedPieceSet` (stores the 12-entry map, implements
`imageFor`, `==`, `hashCode`).

**Modified file**: `lib/src/utils/utils.dart`
- Replace the 12-branch `getChessPieceWidget(chess.Piece)` with
  `Widget buildPieceWidget(chess.Piece piece, PieceSet set)` that returns
  `Image(image: set.imageFor(color, type), fit: BoxFit.contain)`.
- Keep the original `getChessPieceWidget` for backward-safety of internal
  callers that have not been migrated — but ALL internal callers ARE
  migrated in this spec, so the original is deleted.

**Modified file**: `lib/src/widgets/chess_piece_widget.dart`
- Add `final PieceSet pieceSet;` required field.
- Replace `getChessPieceWidget(piece)` with `buildPieceWidget(piece, pieceSet)`.
- Thread `pieceSet` from every construction site.

**Modified file**: `lib/src/advanced_chess_board.dart`
- Add `final PieceSet pieceSet;` field defaulting to `PieceSet.chessDotCom`.
- Thread `widget.pieceSet` into every `ChessPieceWidget` (board squares,
  `Draggable.feedback`, `childWhenDragging` is `SizedBox.shrink` so no
  change, promotion dialog, move-animation layer).
- Replace the `didChangeDependencies` precache loop with:
  ```dart
  void _precacheActivePieceSet() {
    for (final color in PlayerColor.values) {
      for (final type in const <chess.PieceType>[
        chess.PieceType.KING, chess.PieceType.QUEEN, chess.PieceType.ROOK,
        chess.PieceType.BISHOP, chess.PieceType.KNIGHT, chess.PieceType.PAWN,
      ]) {
        precacheImage(widget.pieceSet.imageFor(color, type), context);
      }
    }
  }
  ```
- Call `_precacheActivePieceSet()` in `didChangeDependencies` (gated by
  `_precached`) AND in `didUpdateWidget` when
  `old.pieceSet != widget.pieceSet` (then reset `_precached = true` and
  force a rebuild via `setState`).

**Modified file**: `lib/src/widgets/move_animation_layer.dart`
- Add `final PieceSet pieceSet;` required field.
- Thread it to the `ChessPieceWidget` inside.

### 3. CoordinateLabels

**New file**: `lib/src/coordinates/coordinate_labels.dart` — the enum plus
an internal helper widget `_CoordinateGutter` (see
"Rendering / Layout Strategy").

**Modified file**: `lib/src/widgets/chess_square.dart`
- Add `final CoordinateLabels coordinates;` field.
- Replace the existing `_shouldRankBeRendered` / `_shouldFileBeRendered`
  logic so inside labels render ONLY when `coordinates ==
  CoordinateLabels.inside` (otherwise: no inside label).
- Add `final Color? labelColor;` field. When `null`, derive from
  inverted square colour exactly as 3.0.0 does; when non-null, use it.

**Modified file**: `lib/src/advanced_chess_board.dart`
- Add `final CoordinateLabels coordinates;` field defaulting to
  `CoordinateLabels.inside`.
- In `build()`, branch the rendered tree on `widget.coordinates`:
  - `inside` → today's tree (unchanged).
  - `outside` → a `Row` of `[rank gutter, Column([file gutter top? no,
    playing grid via AspectRatio(1), file gutter bottom])]`. Detailed
    layout in "Rendering / Layout Strategy".
  - `none` → today's tree but `ChessSquare` rendered without labels (the
    `CoordinateLabels` field wired through forces the inside-label
    `if` to be false).

### 4. SoundPack + classification

**New file**: `lib/src/sound/sound_event.dart` — the enum.

**New file**: `lib/src/sound/sound_pack.dart` — `SoundPack`,
`SilentSoundPack`.

**New file**: `lib/src/sound/move_classifier.dart` — pure function:
```dart
/// Classifies [move] (a verbose move map from `chess.generate_moves` or
/// the result of `chess.Chess.history.last`) into a [SoundEvent], using
/// the priority order documented on [SoundEvent].
SoundEvent classifySoundEvent({
  required Move verboseMove,
  required bool isGameOverAfter,
  required bool isInCheckAfter,
});
```

**Modified file**: `lib/src/advanced_chess_board.dart`
- Add `final SoundPack soundPack;` field defaulting to
  `const SilentSoundPack()`.
- Hook inside `_makeMove(from, to, squareSize)` AFTER the controller's
  `makeMove(...)` returns `true`. Exact control flow:
  ```dart
  final accepted = widget.controller.makeMove(from: from, to: to,
      promotion: promotion);
  if (accepted) {
    final last = _game.history.last.move; // chess.Move, verbose
    final event = classifySoundEvent(
      verboseMove: last,
      isGameOverAfter: widget.controller.isGameOver,
      isInCheckAfter: widget.controller.isInCheck,
    );
    _firePlay(event);
  }
  ```
  where `_firePlay` wraps the call in a `try/catch` and a
  `.catchError((err, st) => debugPrint('SoundPack.play threw: $err'))` so
  both synchronous and asynchronous throws are swallowed.
- `_makeMove` is only called from tap / programmatic / drag-drop paths —
  NOT from `controller.undo`, `controller.resetBoard`,
  `controller.loadGameFromFEN`. No audio hook is added to those paths.
  (The controller is a pure data object — it has no `SoundPack`. The
  widget is the only place audio fires.)
- `controller.makeMove(..., notify: false)`: the widget never calls
  `controller.makeMove` with `notify: false` itself — ALL widget-driven
  moves use the default `notify: true`. When a consumer directly calls
  `controller.makeMove(from, to, notify: false)` from their own code, the
  widget does not observe that move except via the next listener fan-out
  (which is suppressed). No `_makeMove` runs, no audio fires. Requirement
  4.13 is satisfied by construction.

### 5. HintArrow

**New file**: `lib/src/hint/hint_arrow.dart` — the value type.

**New file**: `lib/src/hint/hint_arrow_painter.dart` — a new
`CustomPainter` that paints ONE `HintArrow` with dashed shaft + outlined
arrowhead. Accepts `(HintArrow? arrow, BoardTheme theme, PlayerColor
orientation)`. Uses the same square-to-canvas mapping as `ArrowPainter`.

**Modified file**: `lib/src/advanced_chess_board.dart`
- Add `final HintArrow? hintArrow;` field.
- Add state: `HintArrow? _activeHint; Timer? _hintTimer;`.
- In `initState` and `didUpdateWidget`, reconcile `_activeHint` with
  `widget.hintArrow` (by value equality):
  - If `widget.hintArrow` is null and `_activeHint` is not, clear and
    cancel the timer.
  - If `widget.hintArrow` is not null and `_activeHint != widget.hintArrow`,
    assign, cancel the old timer, and if `widget.hintArrow!.duration !=
    null` start a new one that sets `_activeHint = null` on fire.
- In `_makeMove`, after `accepted == true`, add:
  `setState(() { _activeHint = null; _hintTimer?.cancel(); });`. This runs
  on the next frame (the `setState` is inside a post-`makeMove` branch
  that already schedules a rebuild).
- In the `Stack` inside the `ListenableBuilder.builder`, add:
  ```dart
  if (_activeHint != null)
    IgnorePointer(
      child: CustomPaint(
        painter: HintArrowPainter(_activeHint!, _effectiveTheme,
            widget.boardOrientation),
        child: const SizedBox.expand(),
      ),
    ),
  ```
  ordered AFTER the user-arrow `CustomPaint` so the hint paints on top
  (Requirement 5.2).
- `dispose` cancels `_hintTimer`.

### 6. Drag legality indicator

**Modified file**: `lib/src/advanced_chess_board.dart`
- Add state: `String? _dragOverSquare;` (the square currently under the
  pointer during an active drag, `null` when no drag or when pointer is
  in the gutter).
- Wire `DragTarget<String>` for EACH square with both `onWillAcceptWithDetails`
  AND `onMove` / `onLeave`:
  - `DragTarget`'s builder signature is `(ctx, candidateData, rejectedData)`.
    A square is "under the pointer with a legal drop" iff
    `candidateData.isNotEmpty`.
  - A square is "under the pointer with an illegal drop" iff
    `rejectedData.isNotEmpty`.
  - Flutter's `DragTarget` populates these lists via the
    `onWillAcceptWithDetails` predicate on every hover — so the existing
    `onWillAcceptWithDetails: (d) => _isLegalDestination(d.data, square)`
    call ALREADY drives `candidateData` vs `rejectedData` without any new
    pointer tracking. This is the key insight — no `Listener` overlay, no
    parent-state bubbling needed. Each `DragTarget.builder` inspects its
    own candidate/rejected lists and paints the appropriate indicator.
- In the builder, compute:
  ```dart
  final isDragSource = _isPieceDragging && square == _selectedSquare;
  final isDragLegalHover =
      widget.enableMoves && candidateData.isNotEmpty && !isDragSource;
  final isDragIllegalHover =
      widget.enableMoves && rejectedData.isNotEmpty && !isDragSource;
  ```
  `_selectedSquare` is already set to the drag source in
  `onDragStarted` (existing code path).
- Layer the two new overlays into the square `Stack`:
  ```dart
  // ... existing layers: base square, selection, mate tint,
  // HighlightOverlay (legal-destination hint), last-move highlight ...
  if (isDragLegalHover)                              // NEW (above hint)
    _DragLegalRing(color: _effectiveTheme.dragLegalRingColor,
                   squareSize: squareSize),
  if (isDragIllegalHover)                            // NEW (above bg,
    Positioned.fill(                                 //      below piece)
      child: ColoredBox(color: _effectiveTheme.dragIllegalTintColor),
    ),
  // ... piece layer (always last) ...
  ```
  Ordering details in "Rendering / Layout Strategy" below.
- `_DragLegalRing` is a small private stateless widget building a
  `Container` with a `BoxDecoration(shape: circle, border: Border.all(
  color: color, width: squareSize * 0.1))` sized to `squareSize * 0.98`
  (matching `HighlightOverlay`'s circle diameter). It draws on top of
  `HighlightOverlay` so both are visible — the legal-destination hint
  dot/ring stays, and the drag-legal ring adds a distinct
  thick-coloured border around the `0.98 * squareSize` footprint.
- `enableMoves: false` gates BOTH indicators off at the computation site —
  Requirement 6.8 is enforced by the conjunction above.

### 7. Barrel

**Modified file**: `lib/advanced_chess_board.dart` — add the seven new
exports listed in "Proposed Public API → Barrel additions".

### 8. Version / changelog / README

**Modified file**: `pubspec.yaml` — `version: 3.1.0`.

**Modified file**: `CHANGELOG.md` — prepend a `## 3.1.0 — YYYY-MM-DD`
entry (body drafted in "Migration / Release Notes").

**Modified file**: `README.md` — see "Migration / Release Notes".

### 9. Example tour

**Modified file**: `example/lib/main.dart` — extend the existing demo with
toggles / knobs that each exercise one new capability:

1. A `DropdownButton<BoardTheme>` switching across the five presets —
   exercises Requirement 1.
2. A `DropdownButton<PieceSet>` offering `PieceSet.chessDotCom` and a
   second toy `PieceSet.fromAssetMap(...)` demonstrating asset overrides —
   exercises Requirement 2.
3. A `SegmentedButton<CoordinateLabels>` switching inside / outside /
   none — exercises Requirement 3.
4. A small in-app `DebugSoundPack` (`extends SoundPack`) whose `play`
   calls `debugPrint('sound: $event')` — exercises Requirement 4 without
   bundling audio. The example README lists `audioplayers` as the
   recommended real-world implementation.
5. A "Show hint: Nf3" button setting
   `hintArrow: const HintArrow(startSquare: 'g1', endSquare: 'f3',
   duration: Duration(seconds: 4))` — exercises Requirement 5.
6. Drag indicator — no toggle; it's visible by default whenever the user
   drags a piece. The example README points at it.

## Rendering / Layout Strategy

### Outside coordinates layout

**Decision: nested `Row` + `Column` with dedicated gutter widgets**
(rejected alternatives: `Table` — does not compose with `AspectRatio(1)`
on the playing grid; `CustomMultiChildLayout` — overkill for a static
9-row × 9-column layout).

ASCII of the `CoordinateLabels.outside` layout, `boardOrientation ==
white`:

```
+---+---------------------------+
| 8 |                           |
| 7 |                           |
| 6 |                           |
| 5 |   AspectRatio(1) child    |
| 4 |   = Column of 8 Rows      |
| 3 |   (the 8×8 playing grid)  |
| 2 |                           |
| 1 |                           |
+---+---------------------------+
|   | a   b   c   d   e   f   g   h |
+---+---------------------------+
```

Widget tree:

```dart
Widget _buildWithOutsideGutter(double squareSize) {
  final gutterSize = math.max(kMinLabelFontSize * 2, squareSize * 0.36);
  final ranks = widget.boardOrientation == PlayerColor.white
      ? const <String>['8','7','6','5','4','3','2','1']
      : const <String>['1','2','3','4','5','6','7','8'];
  final filesOrdered = widget.boardOrientation == PlayerColor.white
      ? files
      : files.reversed.toList(growable: false);
  return Row(children: [
    SizedBox(
      width: gutterSize,
      child: Column(
        children: ranks.map((r) =>
          Expanded(child: Center(child: _gutterLabel(r)))).toList(),
      ),
    ),
    Expanded(
      child: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: _buildChessBoard(squareSize),
            ),
          ),
          SizedBox(
            height: gutterSize,
            child: Row(
              children: filesOrdered.map((f) =>
                Expanded(child: Center(child: _gutterLabel(f)))).toList(),
            ),
          ),
        ],
      ),
    ),
  ]);
}
```

Key properties of this layout:
- `AspectRatio(1)` wraps the PLAYING GRID, preserving Preservation P21 for
  the board. The enclosing `Row` is NOT 1:1 overall.
- The rank gutter is a fixed-width `SizedBox`; the playing grid is
  `Expanded` so it consumes all remaining horizontal space. The
  file gutter is a fixed-height `SizedBox` below the grid.
- `kMinLabelFontSize` floor is enforced via `_gutterLabel` computing
  `fontSize: math.max(kMinLabelFontSize, squareSize * 0.18)` exactly like
  inside labels (Requirement 3.9 + Preservation P19).
- Orientation reversal is handled by the two list literals above
  (Requirement 3.6).

**`CoordinateLabels.none`**: no wrapper; just
`AspectRatio(1, child: _buildChessBoard(squareSize))` with
`ChessSquare.coordinates == none` suppressing inside labels.

**`CoordinateLabels.inside`**: unchanged from 3.0.0 —
`AspectRatio(1, child: _buildChessBoard(squareSize))`, and `ChessSquare`
still renders corner-placed labels (the `if (isRankRendered)` and
`if (isFileRendered)` branches fire only when `coordinates == inside`).

### Drag indicator overlay stacking

`Stack` order inside `_buildSquareWithDragTarget`, bottom to top (painter
order):

```
1. ChessSquare                   (base colour + inside label if any)
2. Selection overlay             (translucent yellow on selected square)
3. King mate/check tint          (red on mated king; themed check tint)
4. HighlightOverlay              (legal-destination dot or ring)
5. Drag-legal ring               NEW — above HighlightOverlay (Req 6.6)
6. Drag-illegal tint             NEW — translucent red fill (Req 6.2)
7. Last-move highlight           (if not selected)
8. Piece (Draggable)             (always top of this square's stack)
```

**Why drag-illegal is at layer 6 (above last-move, below piece)**: a
captured piece should remain visible through the tint (Requirement 6.7 —
"below any piece currently rendered"). The last-move highlight is a
yellow translucent fill that is semantically weaker than the illegal-tint
in this transient state, so painting the tint above it is acceptable; the
square under the pointer is rarely also a recent last-move square in
practice, and when it is, the drag is in-progress and the last-move
highlight is not the primary affordance.

**Why drag-legal ring is at layer 5 (above HighlightOverlay)**: Requirement
6.6 — the drag-legal ring emphasises the existing hint rather than hiding
it, so both must be visible. Painting the ring on top with a thicker
border achieves the emphasis.

### Hint arrow painter geometry

The painter draws ONE `HintArrow` with the same square-to-canvas mapping
as `ArrowPainter` (reuse `getIndexFromSquare` via a shared static helper
in `lib/src/utils/arrow_geometry.dart` — a new file extracted from
`arrow_painter.dart` so both painters share the mapping without
cross-import). Geometry differences from `ArrowPainter`:

- **Shaft**: drawn as a manual dash pattern. Dash length `= blockSize *
  0.15`, gap length `= blockSize * 0.10`. Implemented by walking the
  parameterised line from `adjustedSource` to `strokeDest` and emitting
  `drawLine` segments at `[0, d, 2(d+g), 2(d+g)+d, ...]`.
- **Arrowhead**: same three vertices as `ArrowPainter` (tip + two base
  points) but drawn with `PaintingStyle.stroke`:
  ```dart
  final headPaint = Paint()
    ..color = color
    ..strokeWidth = blockSize * 0.06
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;
  canvas.drawPath(trianglePath, headPaint); // stroke-only, no fill
  ```
- **Stroke width**: `blockSize * 0.12` vs `ArrowPainter`'s `blockSize *
  0.16` — thinner shaft contributes to the visual distinction.
- **Colour**: `_effectiveTheme.hintArrowColor` (lime green default).

`shouldRepaint` returns `true` iff any of `(arrow, theme.hintArrowColor,
orientation)` differs from the old painter.

## Sound classification algorithm

The classifier is a pure function over `(verboseMove, isGameOverAfter,
isInCheckAfter)`. The verbose move's `flags` field is a string containing
zero or more of:

| Flag char | Meaning                            |
|-----------|------------------------------------|
| `'n'`     | non-capture quiet move             |
| `'b'`     | pawn jumps two squares             |
| `'e'`     | en-passant capture                 |
| `'c'`     | standard capture                   |
| `'p'`     | pawn promotion                     |
| `'k'`     | kingside castling                  |
| `'q'`     | queenside castling                 |

(Source: `package:chess/chess.dart` move flags — same constants used by
3.0.0's `generate_moves` call.)

Pseudocode:

```dart
SoundEvent classifySoundEvent({
  required chess.Move verboseMove,
  required bool isGameOverAfter,
  required bool isInCheckAfter,
}) {
  final flags = verboseMove.flags;

  // 1. gameEnd — highest priority. Game-over covers checkmate, stalemate,
  //    threefold repetition, 50-move rule, and insufficient material.
  if (isGameOverAfter) return SoundEvent.gameEnd;

  // 2. promote — pawn promotion (with or without capture).
  if (flags.contains('p')) return SoundEvent.promote;

  // 3. castle — either side.
  if (flags.contains('k') || flags.contains('q')) return SoundEvent.castle;

  // 4. check — move delivered check but not mate / promotion / castle.
  if (isInCheckAfter) return SoundEvent.check;

  // 5. capture — covers standard captures AND en-passant.
  if (flags.contains('c') || flags.contains('e')) return SoundEvent.capture;

  // 6. move — quiet move. Fallback.
  return SoundEvent.move;
}
```

Invocation site, exact control flow inside `_makeMove`:

```dart
Future<bool> _makeMove(String from, String to, double squareSize) async {
  final promotion = _isPromotionMove(from, to)
      ? pieceTypeToString(await _showPromotionDialog(context, squareSize))
      : null;
  final movingPiece = _game.get(from);
  final shouldAnimate = !_suppressNextAnimation
      && widget.moveAnimationDuration > Duration.zero
      && movingPiece != null;
  _suppressNextAnimation = false;

  final accepted = widget.controller
      .makeMove(from: from, to: to, promotion: promotion);

  if (accepted) {
    // NEW in 3.1.0 — classification and audio dispatch.
    final last = _game.history.last.move;
    final event = classifySoundEvent(
      verboseMove: last,
      isGameOverAfter: widget.controller.isGameOver,
      isInCheckAfter: widget.controller.isInCheck,
    );
    _firePlay(event);

    // NEW in 3.1.0 — dismiss any active hint on any successful move.
    if (_activeHint != null) {
      setState(() {
        _activeHint = null;
        _hintTimer?.cancel();
      });
    }

    if (shouldAnimate) {
      setState(() {
        _animatingMove = _InFlightMove(from, to, movingPiece);
      });
    }
  }
  return accepted;
}

void _firePlay(SoundEvent event) {
  try {
    // Fire-and-forget; errors surface through the returned Future.
    widget.soundPack.play(event).catchError((Object err, StackTrace st) {
      debugPrint('SoundPack.play($event) threw asynchronously: $err');
    });
  } catch (err) {
    debugPrint('SoundPack.play($event) threw synchronously: $err');
  }
}
```

This single call site satisfies Requirements 4.5–4.14:
- 4.5 priority order: encoded in the `if` chain.
- 4.6 `gameEnd`: the first branch short-circuits.
- 4.7 `promote`: branch 2.
- 4.8 `castle`: branch 3.
- 4.9 `check`: branch 4.
- 4.10 `capture`: branch 5.
- 4.11 `move`: fallback.
- 4.12 no-audio on `undo` / `reset` / `loadFEN`: `_makeMove` is the only
  caller of the audio hook, and undo/reset/loadFEN do not go through it.
- 4.13 no-audio on `notify: false`: external `notify: false` moves never
  enter `_makeMove`; when they trigger a rebuild via some OTHER
  controller notify, `_makeMove` still hasn't run.
- 4.14 thrown errors: `_firePlay`'s `try`/`catchError` swallows both sync
  and async throws via `debugPrint`.

## Correctness Properties


*A property is a characteristic or behaviour that should hold true across
all valid executions of a system — essentially, a formal statement about
what the system should do. Properties serve as the bridge between
human-readable specifications and machine-verifiable correctness
guarantees.*

The properties below split into two families:

- **P1.x — New-feature behaviour.** Universally-quantified invariants of
  the 3.1.0 capabilities. Each P1.x maps to one or more acceptance
  criteria from Requirements 1–10.
- **P2.x — Preservation.** Universally-quantified invariants asserting
  that 3.0.0 behaviour (P1–P27 in `requirements.md`) continues to hold
  when any 3.1.0 parameter is also passed. Each P2.x maps to one or more
  Preservation clauses.

### New-feature properties

**P1.1 Value-type equality contract.**
*For any* two instances of `BoardTheme` / `PieceSet` / `HintArrow`
constructed with field-equal inputs, `==` returns `true` and `hashCode`
is equal; for any pair constructed with any single differing field, `==`
returns `false`.
**Validates: Requirements 1.1, 2.1, 5.1**

**P1.2 `BoardTheme.copyWith` preserves unreplaced fields.**
*For any* `BoardTheme t` and any single field replacement
`{fieldName: newValue}`, `t.copyWith(fieldName: newValue)` returns a
theme whose `fieldName` equals `newValue` and whose every other field
equals `t`'s.
**Validates: Requirement 1.8**

**P1.3 Effective-theme resolution.**
*For any* `BoardTheme theme` and any optional legacy overrides
`(legacyLight, legacyDark, legacyMate)`, the `_effectiveTheme` used for
paint satisfies:
- `effective.lightSquareColor == legacyLight ?? theme.lightSquareColor`
- `effective.darkSquareColor == legacyDark ?? theme.darkSquareColor`
- `effective.kingCheckmateColor == legacyMate ?? theme.kingCheckmateColor`
- for every other field `f`, `effective.f == theme.f`.
**Validates: Requirements 1.5, 1.6**

**P1.4 `classicGreen` pins 3.0.0 palette.**
`BoardTheme.classicGreen.lightSquareColor == const Color(0xFFEBECD0)`
AND `BoardTheme.classicGreen.darkSquareColor == const Color(0xFF739552)`;
with no `boardTheme` and no legacy colour parameters passed,
`_effectiveTheme == BoardTheme.classicGreen`.
**Validates: Requirements 1.4, 1.7**

**P1.5 Preset pairwise distinctness.**
*For any* two distinct preset names in
`{classicGreen, brown, blue, purple, monochrome}`, the presets are not
`==`.
**Validates: Requirement 1.3**

**P1.6 `PieceSet.chessDotCom` resolves to bundled assets.**
*For any* `(PlayerColor color, chess.PieceType type)`,
`PieceSet.chessDotCom.imageFor(color, type)` equals
`const AssetImage(assetPath, package: packageName)` where `assetPath` is
the `PieceImages` constant corresponding to `(color, type)`.
**Validates: Requirements 2.2, 2.3**

**P1.7 Custom `PieceSet` drives every rendered piece.**
*For any* custom `PieceSet set` and any reachable position, every
`ChessPieceWidget` in the pumped tree (board squares, `Draggable.feedback`,
promotion dialog, `MoveAnimationLayer`) references `set` via its
`pieceSet` field, and no `ImageProvider` not produced by `set.imageFor`
is used for a piece.
**Validates: Requirements 2.4, 2.5**

**P1.8 Active `PieceSet` precached on mount and on swap.**
*For any* `PieceSet set`, after the first `didChangeDependencies`, all 12
`set.imageFor(color, type)` providers are present in `imageCache`;
additionally, *for any* `(oldSet, newSet)` with `oldSet != newSet`, after
a `didUpdateWidget` swap all 12 providers of `newSet` are added to
`imageCache` and the next rebuild renders pieces using `newSet`.
**Validates: Requirements 2.6, 2.7; Preservation P22**

**P1.9 Inside labels on orientation-appropriate edge.**
*For any* `square ∈ {a1..h8}` and any `orientation ∈ {white, black}`,
when `coordinates == inside` the square renders a rank label iff
`square.file == (orientation == white ? 'a' : 'h')` AND renders a file
label iff `square.rank == (orientation == white ? '1' : '8')`.
**Validates: Requirements 3.3, 3.4**

**P1.10 Outside gutters disjoint from playing grid.**
*For any* `squareSize ∈ (0, 1000]` and any `orientation`, with
`coordinates == outside`, the union of gutter paint rectangles does NOT
intersect the playing-grid paint rectangle, and no `ChessSquare` paint
region overlaps any gutter label paint region.
**Validates: Requirement 3.5**

**P1.11 Outside orientation reverses gutter order.**
*For any* gutter index `i ∈ [0, 7]`, with `coordinates == outside`:
- The rank-gutter label at position `i` equals
  `orientation == white ? (8 - i).toString() : (i + 1).toString()`.
- The file-gutter label at position `i` equals
  `orientation == white ? files[i] : files[7 - i]`.
**Validates: Requirement 3.6**

**P1.12 `AspectRatio(1)` wraps playing grid only.**
*For any* `BoxConstraints`, with `coordinates == outside`, the `RenderBox`
of the rendered 8×8 grid has `size.width == size.height` (within
rounding); the enclosing `Row` is NOT required to be 1:1.
**Validates: Requirement 3.7**

**P1.13 `coordinates == none` renders no labels, allocates no gutter.**
*For any* `orientation` and any `squareSize`, with `coordinates == none`,
no `Text` widget in the board subtree has a label matching `^[a-h]$` or
`^[1-8]$`, AND no gutter-sized `SizedBox` is emitted in the widget tree.
**Validates: Requirement 3.8**

**P1.14 Label font size floor.**
*For any* `squareSize ∈ (0, 1000]` and any `coordinates ∈ {inside,
outside}`, every rendered coordinate label's `fontSize` equals
`math.max(kMinLabelFontSize, squareSize * 0.18)`.
**Validates: Requirement 3.9; Preservation P19**

**P1.15 Narrow-board no-overflow.**
*For any* `boxWidth ∈ [16, 2 * kMinLabelFontSize * 8]` and `coordinates
== outside`, pumping the board throws no layout-overflow exception; every
rendered label's `fontSize >= kMinLabelFontSize`.
**Validates: Requirement 3.10**

**P1.16 Sound classification priority order.**
*For any* reachable `chess.Chess` position `P` and any legal move `M`,
`classifySoundEvent(verboseMove: M, isGameOverAfter: isGameOverAfter(P,M),
isInCheckAfter: isInCheckAfter(P,M))` returns the single highest-priority
event per the ordering `gameEnd > promote > castle > check > capture >
move`. Equivalently: the returned event equals the first matching clause
in the classifier's `if`-chain (gameEnd → promote → castle → check →
capture → move).
**Validates: Requirements 4.5, 4.6, 4.7, 4.8, 4.9, 4.10, 4.11**

**P1.17 No audio on `undo` / `reset` / `loadGameFromFEN`.**
*For any* sequence of `controller.undo()`, `controller.resetBoard()`,
`controller.loadGameFromFEN(...)` calls on a mounted board with a
counting `SoundPack`, the counter stays at its pre-sequence value.
**Validates: Requirement 4.12**

**P1.18 No audio on `makeMove(..., notify: false)`.**
*For any* reachable position and any legal move played via
`controller.makeMove(..., notify: false)` on a mounted board with a
counting `SoundPack`, the counter stays at its pre-call value.
**Validates: Requirement 4.13**

**P1.19 Thrown errors swallowed.**
*For any* `SoundEvent` and any throwing `SoundPack` (synchronous `throw`
inside `play`, or `Future.error(...)`), playing a move on a mounted board
completes without exception propagating to the caller AND the widget's
next `build` runs normally.
**Validates: Requirement 4.14**

**P1.20 Silent default.**
*For any* `AdvancedChessBoard` constructed without passing `soundPack:`,
`widget.soundPack` is identity-equal to `const SilentSoundPack()` and
every `SoundEvent` passed to `widget.soundPack.play(e)` returns an
already-resolved `Future<void>` with no audio side effect.
**Validates: Requirements 4.3, 4.4**

**P1.21 Hint painted above user arrows.**
*For any* non-null `HintArrow` and any `arrows` list, in the
`ListenableBuilder`'s `Stack` the `HintArrowPainter`'s `CustomPaint`
child index is strictly greater than the `ArrowPainter`'s.
**Validates: Requirement 5.2**

**P1.22 Hint arrow visually distinct.**
*For any* `HintArrow`, any `BoardTheme theme`, and any `orientation`, the
paint trace emitted by `HintArrowPainter` satisfies ALL of:
- every shaft `drawLine` / path segment paint uses colour
  `theme.hintArrowColor`;
- the arrowhead `drawPath` paint has `style == PaintingStyle.stroke`
  (not `fill`);
- the shaft consists of at least two non-contiguous `drawLine` segments
  (dashing);
none of which holds for a `ChessArrow` painted by `ArrowPainter`.
**Validates: Requirement 5.3**

**P1.23 Hint auto-dismiss on next successful move.**
*For any* non-null `HintArrow` and any legal move, after the move is
accepted via tap / drag / `controller.makeMove`, the next pumped frame
contains no `HintArrowPainter`.
**Validates: Requirement 5.4**

**P1.24 Hint auto-dismiss after `duration` elapses.**
*For any* `HintArrow` with `duration: d` where `d > Duration.zero`, after
`FakeAsync` advances `d + epsilon` without any move being made, the next
pumped frame contains no `HintArrowPainter`.
**Validates: Requirement 5.5**

**P1.25 Hint replace-with-reset.**
*For any* two non-null `HintArrow` values `a != b` both with `duration:
d`, pumping `a`, advancing `d/2`, then rebuilding with `b`, advancing
another `d/2` — `b` is still rendered; advancing a further `d/2` — `b`
is dismissed. (Timer reset is observable because `a` would have
dismissed at total elapsed `d`, yet `b` persists past `d`.)
**Validates: Requirement 5.6**

**P1.26 Hint dismiss on null.**
*For any* mounted board with an active hint, rebuilding with `hintArrow:
null` dismisses the hint on the next pumped frame.
**Validates: Requirement 5.7**

**P1.27 Hint does not mutate `arrows` list.**
*For any* list `L` passed as `arrows:` and any sequence of hint state
transitions (show, tick, replace, dismiss), `L` is unmodified: same
length, same reference-identical elements.
**Validates: Requirement 5.8**

**P1.28 Drag indicator classification.**
*For any* mounted board with `enableMoves: true`, any drag source
`source ∈ squares`, and any square `s` currently under the drag pointer:
- `s == source` → no drag-legal ring, no drag-illegal tint on `s`;
- `s != source ∧ _isLegalDestination(source, s)` → drag-legal ring on
  `s`, no drag-illegal tint on `s`;
- `s != source ∧ ¬_isLegalDestination(source, s)` → drag-illegal tint on
  `s`, no drag-legal ring on `s`.
For every square `t` NOT currently under the pointer, neither indicator
is rendered on `t`.
**Validates: Requirements 6.1, 6.2, 6.3, 6.4**

**P1.29 Drag indicators cleared on drag end.**
*For any* drag termination (drop on a square, drop off-board, pointer
cancel / lift), the next pumped frame contains zero drag-legal rings and
zero drag-illegal tints across all 64 squares.
**Validates: Requirement 6.5**

**P1.30 Drag-legal ring layered above `HighlightOverlay`.**
*For any* hover over a legal destination square during a drag, in that
square's `Stack` the drag-legal ring's child index is strictly greater
than the `HighlightOverlay`'s — both are visible.
**Validates: Requirement 6.6**

**P1.31 Drag-illegal tint layered between background and piece.**
*For any* hover over a non-source non-legal square with a piece during a
drag, in that square's `Stack` the drag-illegal tint's child index is
strictly greater than the `ChessSquare` background's AND strictly less
than the `ChessPieceWidget`'s index.
**Validates: Requirement 6.7**

**P1.32 `enableMoves: false` gates indicators off.**
*For any* attempted drag and any square `s`, with `enableMoves: false`
neither drag-legal ring nor drag-illegal tint is rendered on `s`.
**Validates: Requirement 6.8**

### Preservation properties

**P2.1 3.0.0 chess-rule correctness preserved under 3.1.0 parameters.**
*For any* sequence of tap / drag / programmatic moves on a mounted board
constructed with any combination of 3.1.0 parameters, the resulting
`controller.fen`, `controller.playerColor`, `controller.history`, and
`controller.pgn` equal the values the same sequence would produce on a
mounted board with no 3.1.0 parameters set. Promotion dialog still offers
queen / rook / bishop / knight and defaults to queen. Illegal moves are
still rejected via `onWillAcceptWithDetails` returning `false`.
**Validates: Preservation P1, P2, P3, P4**

**P2.2 Controller semantics preserved.**
*For any* `notify: false` mutation, zero listener fan-outs. `controller.game`
continues to return the underlying `chess.Chess`. `isCheckmate`,
`isInCheck`, `isStalemate`, `isDraw`, `isGameOver`, `history`, `pgn`,
`moveCount` values are identical to those a 3.0.0 controller yields for
the same position sequence. `ListenableBuilder` subscription still
auto-swaps on `didUpdateWidget(controller)` — no consumer-side
`addListener(setState)` is required. Swapping the controller clears
`_selectedSquare`, `_legalMoves`, `_animatingMove`, and `_activeHint`.
**Validates: Preservation P5, P6, P7, P8, P9**

**P2.3 `enableMoves: false` render-only preserved under 3.1.0 parameters.**
*For any* board constructed with `enableMoves: false` and any combination
of `boardTheme`, `pieceSet`, `coordinates`, `soundPack`, `hintArrow`,
tapping or dragging any square does NOT mutate game state, does NOT fire
any `SoundPack.play`, and does NOT render a drag-legal ring or
drag-illegal tint (the last is P1.32; this property pins the compound
behaviour under a single `enableMoves:false` gate).
**Validates: Preservation P10**

**P2.4 Last-move highlight, selection, legal-destination hint preserved.**
*For any* move just played and any mounted board, the from-square and
to-square are tinted with `_effectiveTheme.lastMoveHighlightColor` (unless
the selected square equals one of them — single-highlight rule).
Tap-to-select-then-tap-to-deselect still works; `HighlightOverlay` still
renders a small dot on empty legal destinations and a hollow ring on
legal captures, with colours derived from
`_effectiveTheme.legalDestinationColor`.
**Validates: Preservation P11, P12**

**P2.5 Drag-drop moves and `ArrowPainter` geometry preserved.**
*For any* drag-drop move and any legal drop, `controller.fen` advances
as a 3.0.0 board's would. *For any* `ChessArrow` list, the `ArrowPainter`
still draws the main line + equilateral-triangle arrowhead using
`sourceThreshold = blockSize * 0.35`,
`destinationThreshold = blockSize * 0.272`,
`arrowheadSideLength = blockSize * 0.2`, and `strokeWidth = blockSize *
0.16`, with default colour `Colors.amber.withAlpha(128)`. Orientation
flip still reverses the square-to-canvas mapping.
**Validates: Preservation P13, P14, P15**

**P2.6 Checkmate tint + in-check tint.**
*For any* mated king and any board, the mated king's square is tinted
with `widget.kingBackgroundColorOnCheckmate ??
_effectiveTheme.kingCheckmateColor` (default `Color(0x9BF44336)`).
Additionally, *for any* in-check-but-not-mate position, the king's
square is tinted with `_effectiveTheme.kingCheckColor` iff it is
non-null (default `null` — no tint — matches 3.0.0).
**Validates: Preservation P16**

**P2.7 Move animation preserved under 3.1.0 parameters.**
*For any* tap or programmatic move with `moveAnimationDuration >
Duration.zero`, a `MoveAnimationLayer` is inserted into the `Stack` and
animates the moving piece from source to destination — regardless of any
3.1.0 parameter values. Drag-drop moves still skip the animation via
`_suppressNextAnimation`. `Duration.zero` still skips the animation.
**Validates: Preservation P17, P18**

**P2.8 Drag feedback clamping preserved.**
*For any* `squareSize`, the `Draggable.feedback` width equals
`math.min(squareSize * kMaxFeedbackScale, squareSize +
kMaxFeedbackOverflowPx)` — identical to 3.0.0.
**Validates: Preservation P20**

**P2.9 Column-of-Rows grid preserved.**
*For any* `coordinates` mode, the 8×8 playing grid is a `Column` of 8
`Row`s of 8 `SizedBox` children — no `GridView`, no `Scrollable`.
(For `outside`, the `Column` is wrapped by a `Row` + outer `Column`
containing the gutters; the inner grid structure is unchanged.)
**Validates: Preservation P21**

**P2.10 Semantics labels preserved.**
*For any* square `s` with piece `p` (or empty) and any `pieceSet`, the
`ChessSquare`'s `Semantics` node label equals `"$s, ${pieceSemanticsLabel(p)}"`,
and `ChessPieceWidget`'s `Semantics` label equals
`pieceSemanticsLabel(piece)`.
**Validates: Preservation P23**

**P2.11 3.0.0 public API surface preserved.**
The four symbols `AdvancedChessBoard`, `ChessBoardController`,
`ChessArrow`, `PlayerColor` are still re-exported from
`lib/advanced_chess_board.dart`. Every 3.0.0 parameter on
`AdvancedChessBoard` (`controller`, `lightSquareColor`, `darkSquareColor`,
`initialFEN`, `boardOrientation`, `enableMoves`, `highlightLastMove`,
`arrows`, `kingBackgroundColorOnCheckmate`, `moveAnimationDuration`)
still exists with its 3.0.0 name, type, and default value.
**Validates: Preservation P24, P25**

**P2.12 3.0.0 test suite and PBTs unchanged.**
*For any* test file under `test/` that existed in 3.0.0, the file is
byte-identical after 3.1.0 ships; running `flutter test` against
3.1.0-built sources reports every 3.0.0 test as passing, and every
glados-driven 3.0.0 property reports the same "runs OK" result.
**Validates: Preservation P26, P27**

## Error Handling

### `SoundPack.play` failures

Guaranteed non-propagating, per Requirement 4.14. The exact handling:

```dart
void _firePlay(SoundEvent event) {
  try {
    widget.soundPack.play(event).catchError((Object err, StackTrace st) {
      debugPrint('SoundPack.play($event) threw asynchronously: $err');
    });
  } catch (err) {
    debugPrint('SoundPack.play($event) threw synchronously: $err');
  }
}
```

Two distinct catch sites:
- Synchronous `throw` inside `play` before returning a `Future` is caught
  by the outer `try`/`catch`.
- `Future`-based failure (the returned `Future` completes with an error)
  is caught by `.catchError((err, st) => debugPrint(...))`.

No retry, no user-facing error surface, no controller mutation — audio is
a purely side-effecting output channel.

### `HintArrow` with unknown / malformed square names

`HintArrow.startSquare` and `endSquare` are typed `String`. There is no
validator in the value type itself (Requirement 10 precludes adding a
parser). `HintArrowPainter`'s square-to-canvas mapping delegates to the
same `getIndexFromSquare` helper used by `ArrowPainter`; malformed square
strings result in out-of-bounds `row` / `col` values and the arrow
renders off-canvas (invisible). This matches 3.0.0's tolerance for
malformed `ChessArrow` inputs — no exception thrown, no crash. The
behaviour is documented on `HintArrow.startSquare` / `endSquare`.

### `BoardTheme.copyWith` with `null` on nullable fields

`coordinateLabelColor` and `kingCheckColor` are nullable. The `copyWith`
uses a private `_unset` sentinel so consumers can explicitly null them:

```dart
theme.copyWith(coordinateLabelColor: null)           // explicit null wins
theme.copyWith(/* no coordinateLabelColor arg */)    // unchanged
```

No runtime error path — both paths produce a valid `BoardTheme`.

### `PieceSet.fromAssetMap` with a missing key

`_MapBackedPieceSet` validates at construction time:

```dart
const factory PieceSet.fromAssetMap(Map<...> map) = _MapBackedPieceSet;
// inside _MapBackedPieceSet:
_MapBackedPieceSet._(this._map) : assert(_map.length == 12, ...);
```

Dart's `assert` only fires in debug mode. To guarantee the invariant in
release mode, the non-const construction path calls
`ArgumentError.checkNotNull` for every `(color, type)` key — keeping the
factory const-safe when all 12 entries are const-inlined, and throwing an
`ArgumentError` at construction time otherwise.

### `didUpdateWidget` asset-swap race

When `pieceSet` is swapped mid-build, `precacheImage` is kicked off
asynchronously. During the brief window before the new assets resolve,
the first frame MAY flash an empty piece tile. The same window exists in
3.0.0 on first mount — `precacheImage` does not block layout. No new
error handling is needed; the behaviour is documented.

### Drag-indicator repaint overhead

`DragTarget`'s `candidateData` / `rejectedData` change triggers a rebuild
of that single `DragTarget.builder` — the existing 3.0.0 paint cost of a
tile is unaffected when NOT hovered (the new conditionals compile to
constant-time `if`s). No throttling needed; the observed paint cost in
the drag path is one extra `Container` per frame per hovered tile. If
future benchmarks reveal cost, a `RepaintBoundary` around the 8×8 grid
is the escape hatch.

## Testing Strategy

Tests are added under new directories alongside the existing 3.0.0 test
tree. No 3.0.0 test file is modified (Preservation P26).

```
test/
├── theme/                                  NEW
│   ├── board_theme_equality_test.dart      P1.1 (BoardTheme slice)
│   ├── board_theme_copywith_test.dart      P1.2
│   ├── board_theme_presets_test.dart       P1.4, P1.5
│   └── effective_theme_test.dart           P1.3
├── piece_set/                              NEW
│   ├── piece_set_equality_test.dart        P1.1 (PieceSet slice)
│   ├── piece_set_chessdotcom_test.dart     P1.6
│   ├── piece_set_custom_render_test.dart   P1.7
│   └── piece_set_precache_test.dart        P1.8
├── coordinates/                            NEW
│   ├── inside_labels_test.dart             P1.9
│   ├── outside_layout_test.dart            P1.10, P1.11, P1.12
│   ├── none_labels_test.dart               P1.13
│   ├── label_font_floor_test.dart          P1.14
│   └── narrow_board_test.dart              P1.15
├── sound/                                  NEW
│   ├── classifier_priority_test.dart       P1.16 (PBT)
│   ├── classifier_examples_test.dart       P1.16 (example fallback cases)
│   ├── silent_default_test.dart            P1.20
│   ├── no_audio_on_undo_reset_load_test.dart P1.17
│   ├── no_audio_on_notify_false_test.dart  P1.18
│   └── throwing_pack_test.dart             P1.19
├── hint_arrow/                             NEW
│   ├── hint_arrow_equality_test.dart       P1.1 (HintArrow slice)
│   ├── hint_painter_layer_test.dart        P1.21
│   ├── hint_visual_distinct_test.dart      P1.22
│   ├── hint_dismiss_on_move_test.dart      P1.23
│   ├── hint_dismiss_on_duration_test.dart  P1.24 (FakeAsync)
│   ├── hint_replace_reset_test.dart        P1.25 (FakeAsync)
│   ├── hint_dismiss_on_null_test.dart      P1.26
│   └── hint_does_not_mutate_arrows_test.dart P1.27
├── drag_indicator/                         NEW
│   ├── classification_test.dart            P1.28
│   ├── clear_on_end_test.dart              P1.29
│   ├── layer_order_test.dart               P1.30, P1.31
│   └── disabled_moves_test.dart            P1.32
├── properties/
│   ├── generators.dart                     EXTEND with board_theme,
│   │                                       piece_set, hint_arrow,
│   │                                       sound_event generators
│   ├── new_feature_properties_test.dart    NEW — P1.x glados wrappers
│   └── preservation_properties_test.dart   NEW — P2.x glados wrappers
└── (every 3.0.0 directory/file — UNMODIFIED)
```

### Test style per property family

**Value-equality (P1.1, P1.2).** Pure-data PBTs using `glados`:

```dart
Glados2<Color, Color>().test('BoardTheme == respects all fields', (a, b) {
  final t1 = BoardTheme(lightSquareColor: a);
  final t2 = BoardTheme(lightSquareColor: a);
  final t3 = BoardTheme(lightSquareColor: b);
  expect(t1 == t2, isTrue);
  expect(t1.hashCode, t2.hashCode);
  expect(t1 == t3, a == b);
});
```

Each of `BoardTheme`, `PieceSet`, `HintArrow` gets one such test.

**Effective-theme resolution (P1.3).** PBT generates `(theme, optional
legacyLight, optional legacyDark, optional legacyMate)`; pumps
`AdvancedChessBoard(...)`; reads `_effectiveTheme` via a widget-test
escape hatch (a package-internal helper exposed behind a
`@visibleForTesting` annotation); asserts the resolution formula.

**Layout (P1.9–P1.15).** Widget tests using `flutter_test`.
`BoxConstraints` varied via `pumpWidget(MediaQuery(data:
MediaQueryData(size: ...), child: ...))`. Gutter disjointness
(P1.10) asserted by finding `RenderBox` globals via `RenderBox.localToGlobal`
and computing rect intersections.

**Sound classification (P1.16).** The classifier is a pure function — a
perfect PBT target. Generator: random reachable `chess.Chess` positions
via 0–40 random legal moves from start, then pick a random legal move.
Oracle: the classifier's `if`-chain directly. Assertion: for each
generated `(position, move)`, the classifier's output equals the
expected event computed from an independent oracle (plain-English `if`
table) — the two must agree on all 100+ iterations.

**Sound hook suppression (P1.17, P1.18).** Widget PBTs with a counting
`SoundPack`:

```dart
class _CountingSoundPack extends SoundPack {
  int count = 0;
  @override Future<void> play(SoundEvent e) async => count += 1;
}
```

Drive random sequences of `undo/reset/loadFEN` OR `makeMove(...,
notify:false)`; assert counter unchanged.

**Sound hook error resilience (P1.19).** Widget PBT with a throwing
`SoundPack`; pump random moves; assert no exception reaches the tester
and the next frame renders.

**Hint timing (P1.24, P1.25).** `FakeAsync` tests under `fake_async:
^1.3.1` (new `dev_dependency`). The timer-reset invariant in P1.25 is
only observable with a fake clock — a real clock would be flaky.

**Drag indicator (P1.28, P1.29, P1.32).** Widget tests using
`WidgetTester.startGesture` / `moveBy` / `up` to simulate a drag.
`candidateData` / `rejectedData` propagation is observable through the
rebuilt `DragTarget.builder`; the new private `_DragLegalRing` /
`_DragIllegalTint` widgets are asserted via `find.byType(_DragLegalRing)`.

**Preservation (P2.x).** Each P2.x is a widget test pumping the board
with a random 3.1.0-parameter combination AND asserting the same
invariant the 3.0.0 equivalent test asserts. Key trick: reuse the 3.0.0
test's oracle helpers directly. For example, P2.1 runs random move
sequences on two boards (one with 3.1.0 params set to non-defaults, one
with all defaults) and asserts the two controllers have identical FENs
after each move.

### New vs preservation PBT split

| Property | Type | Iterations |
|----------|------|------------|
| P1.1–P1.2 (value equality, copyWith) | Pure-data PBT (glados) | 100 |
| P1.3 (effective theme) | Widget PBT (glados + flutter_test) | 100 |
| P1.4 (classicGreen pins 3.0.0) | Example snapshot | 1 |
| P1.5 (preset distinctness) | Example | 1 |
| P1.6 (chessDotCom asset mapping) | Example over 12-entry domain | 12 |
| P1.7 (custom set drives every render) | Widget PBT | 100 |
| P1.8 (precache on mount + swap) | Widget PBT | 100 |
| P1.9 (inside labels) | Example over 64-square × 2-orientation | 128 |
| P1.10–P1.12 (outside layout) | Widget PBT | 100 |
| P1.13 (none labels) | Example | 1 |
| P1.14 (font floor) | Widget PBT over squareSize | 100 |
| P1.15 (narrow no-overflow) | Widget PBT edge case | 100 |
| P1.16 (sound priority) | Pure PBT | 200 |
| P1.17 (no audio undo/reset/load) | Widget PBT | 100 |
| P1.18 (no audio notify:false) | Widget PBT | 100 |
| P1.19 (throwing swallow) | Widget PBT | 50 |
| P1.20 (silent default) | Example | 1 |
| P1.21 (hint above arrows) | Widget PBT | 50 |
| P1.22 (hint visually distinct) | Unit PBT on painter trace | 100 |
| P1.23 (dismiss on move) | Widget PBT | 100 |
| P1.24–P1.25 (duration, replace-reset) | FakeAsync widget PBT | 50 |
| P1.26 (dismiss on null) | Widget example | 1 |
| P1.27 (no mutation of arrows) | Widget PBT | 100 |
| P1.28 (drag classification) | Widget PBT | 100 |
| P1.29 (clear on end) | Widget PBT | 50 |
| P1.30–P1.31 (layer order) | Widget PBT | 50 |
| P1.32 (disabled gates) | Widget PBT | 50 |
| P2.1–P2.2 (chess rules + controller) | Widget PBT | 100 |
| P2.3 (enableMoves:false under new params) | Widget PBT | 100 |
| P2.4–P2.5 (renderers preserved) | Widget PBT | 100 |
| P2.6 (mate/check tint) | Widget PBT | 50 |
| P2.7 (move animation under new params) | Widget PBT | 50 |
| P2.8 (drag clamp preserved) | Widget PBT | 50 |
| P2.9 (Column-of-Rows preserved) | Widget PBT | 50 |
| P2.10 (semantics preserved) | Widget PBT | 50 |
| P2.11 (API surface preserved) | Example (compile-time) | 1 |
| P2.12 (3.0.0 tests unchanged) | CI check on file hashes | 1 |

Each PBT's header comment carries the tag:

```dart
// Feature: chess-board-ux-enhancements, Property P1.16:
// For any reachable position and any legal move, classifySoundEvent
// returns the priority-ordered event per
// gameEnd > promote > castle > check > capture > move.
```

### Generators

Additions to `test/properties/generators.dart`:

```dart
extension UxAnyExtension on Any {
  Generator<BoardTheme> get boardTheme;                  // random Colors
  Generator<PieceSet> get pieceSet;                      // chessDotCom +
                                                         //   fromAssetMap
                                                         //   of fake assets
  Generator<CoordinateLabels> get coordinateLabels;
  Generator<SoundEvent> get soundEvent;
  Generator<HintArrow> get hintArrow;
  Generator<chess.Move> get legalMoveFromRandomPosition; // (position, move)
}
```

Reuse the existing `any.chessFen` generator for position seeding.

### Integration smoke

The example app's tour (toggles for each capability) is driven by an
`integration_test` that clicks every knob and asserts the resulting
board state. This is 1 smoke test per capability — 6 smoke tests total —
reaffirming the new parameters wire through end-to-end.

## Migration / Release Notes

### `CHANGELOG.md` — new 3.1.0 entry (prepended)

```markdown
## 3.1.0 — YYYY-MM-DD

### Additions
- `BoardTheme` value type bundling every paintable colour, with
  `BoardTheme.classicGreen` (default), `.brown`, `.blue`, `.purple`,
  `.monochrome` presets and a `copyWith`. Pass via the new
  `AdvancedChessBoard(boardTheme: ...)` parameter. Legacy
  `lightSquareColor` / `darkSquareColor` / `kingBackgroundColorOnCheckmate`
  continue to work and take precedence when explicitly passed.
- `PieceSet` abstraction with a single `imageFor(PlayerColor,
  chess.PieceType)` lookup and a `PieceSet.fromAssetMap(...)` convenience
  factory. Default `PieceSet.chessDotCom` wraps the bundled pieces. Pass
  via the new `AdvancedChessBoard(pieceSet: ...)` parameter.
- `CoordinateLabels` enum with `inside` (default, 3.0.0 behaviour),
  `outside` (labels in gutters outside the 8×8 playing grid), and `none`
  (no labels, no gutter). Pass via the new `AdvancedChessBoard(coordinates:
  ...)` parameter. The `AspectRatio(1)` contract still applies to the
  playing grid in every mode.
- `SoundEvent` / `SoundPack` interface and `SilentSoundPack` default for
  move audio. Priority-ordered classification:
  `gameEnd > promote > castle > check > capture > move`. No bundled audio,
  no plugin dependency added — consumers plug in their own backend (e.g.
  `package:audioplayers`). Pass via the new
  `AdvancedChessBoard(soundPack: ...)` parameter.
- `HintArrow` value type for engine / hint-API suggestion arrows, rendered
  with a dashed shaft and stroke-only outlined arrowhead in the new
  `BoardTheme.hintArrowColor`. Auto-dismisses on the next successful
  move, or after an optional `Duration`. Pass via the new
  `AdvancedChessBoard(hintArrow: ...)` parameter.
- Live legality indicator during drag: a drag-legal ring appears on
  legal-destination squares currently under the pointer; a drag-illegal
  tint appears on non-source non-legal squares. Gated off when
  `enableMoves: false`.

### Polish
- `HighlightOverlay` colour now threads through `BoardTheme.legalDestinationColor`
  — the default remains pixel-identical to 3.0.0.
- `AdvancedChessBoard` now re-precaches the active `PieceSet`'s 12
  `ImageProvider`s on `didUpdateWidget` when `pieceSet` changes.
- New `BoardTheme.kingCheckColor` (default `null` — no tint, matches
  3.0.0) makes in-check highlighting themable without a breaking change.
```

The `YYYY-MM-DD` placeholder is replaced with the actual publish date at
release time; the `changelog_format_test` regex allows any ISO-8601 date.

### `README.md` additions

New subsections under "Features":

1. **Theming** — worked example setting `boardTheme: BoardTheme.brown`.
   Links to the five presets, shows a `copyWith` example.
2. **Piece sets** — worked example swapping `pieceSet:
   PieceSet.fromAssetMap({...})`. Points at the package's bundled
   `assets/pieces/` directory for the default.
3. **Coordinates** — worked example toggling `coordinates:
   CoordinateLabels.outside`. Screenshot reference.
4. **Sound effects** — skeleton `SoundPack` subclass wrapping a
   hypothetical `audioplayers` call. Makes the "no bundled audio" stance
   explicit.
5. **Hint arrows** — worked example showing an engine-suggested move
   arrow with `duration: Duration(seconds: 4)`.
6. **Drag legality indicator** — screenshot + one paragraph explaining
   that the indicator fires automatically when drags are enabled.

The existing "Known limitations" section is edited to:
- REMOVE the sentence: "Piece theming currently requires forking the
  `assets/pieces/` directory." (Requirement 8.5.)
- ADD: "Premoves are tracked in a separate spec
  (`chess-board-premoves`) and are not yet available." (For discoverability.)

### `pubspec.yaml`

```yaml
version: 3.1.0
```

(Single-line change; every other key stays as in 3.0.0.)

New `dev_dependencies` entry:

```yaml
  fake_async: ^1.3.1  # for hint-arrow duration-timing PBTs
```

No new runtime dependency — preserving Requirement 4's "dependency-light"
stance.

## Out of Scope

The following are explicitly NOT covered by this spec:

- **Premoves.** Tracked in `chess-board-premoves`. A premove is a move
  queued by the side-NOT-to-move that auto-executes when the other side
  moves. Premoves interact with `DragTarget` legality and the sound-pack
  classification in non-obvious ways, so they are isolated to their own
  spec.
- **Chess engine integration.** `HintArrow` accepts a pre-computed
  `(startSquare, endSquare)` pair. Running a real engine (Stockfish,
  Leela, etc.) to PRODUCE hints is the consumer's responsibility. No
  engine dependency, no `EngineAdapter` abstraction, no async analysis
  API are added in this spec.
- **PGN import / export.** `ChessBoardController.pgn` already exists
  (read-only, 3.0.0). A `loadGameFromPGN(String pgn)` setter, a PGN
  tags editor, and bidirectional PGN serialisation are not added.
  (Adding any of these would require a PGN parser — Requirement 10
  explicitly defers parser additions to their own spec.)
- **Multiplayer primitives.** No network transport, no WebSocket
  adapter, no `RemoteController`. The package stays single-device.
  Consumers who need multiplayer wire up their transport against the
  existing `ChessBoardController` (which already exposes `fen`, `makeMove`,
  `history`, `pgn`).
- **Clock / timer.** No chess clock, no time-control UI, no
  `TimeControl` value type.
- **Opening book / annotations.** No NAG (Numeric Annotation Glyph)
  support, no opening name rendering, no comment rendering between moves.
- **Piece animation customisation.** `moveAnimationDuration` stays the
  single knob. No easing-curve parameter, no per-piece animation
  overrides, no capture-fade effect.
- **Sound assets / audio plugin.** The library ships no `.mp3` / `.wav`
  / `.ogg` files and depends on no audio plugin (Requirement 4). The
  example app uses `debugPrint` as the demo backend.
- **Web-specific piece sets (SVG).** `PieceSet.imageFor` returns an
  `ImageProvider` — SVG support requires a `SvgImage` provider (e.g.
  `flutter_svg`), which is a consumer dependency choice. The library
  stays PNG-based.
- **Theme persistence.** No `BoardTheme.toJson` / `fromJson` — again
  requires a parser (Requirement 10).
