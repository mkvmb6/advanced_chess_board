# Requirements Document

## Introduction

`advanced_chess_board` shipped `3.0.0` on 2026-04-19 as a strict-analyse-clean,
dartdoc-complete, test-covered chess board widget. This spec extends the
`3.0.0` widget with a set of additive UX and customisation capabilities —
pluggable board/piece themes, an outside-gutter / hidden coordinate mode,
an opt-in sound-pack abstraction, a distinct "hint" arrow style, and a
live legality indicator on the square under the drag pointer.

Six capabilities are in scope:

1. **Board themes** — a `BoardTheme` value type packaging every colour the
   board paints (light / dark squares, last-move highlight, selection,
   legal-destination hint, coordinate label, mated-king tint), plus a
   curated set of presets. Consumers pass either a preset or a custom
   `BoardTheme`. Current defaults stay pixel-identical.
2. **Piece themes / piece sets** — a `PieceSet` abstraction owning the 12
   asset paths (per `(PlayerColor, chess.PieceType)`). Default continues to
   be the bundled Chess.com-sourced set (`PieceSet.chessDotCom`). Consumers
   can supply custom `AssetImage` sets without forking the package.
3. **Square coordinates toggle** — a `CoordinateLabels` enum with modes
   `inside` (current), `outside` (rendered in a gutter outside the 8×8
   grid), and `none` (no labels). Orientation-awareness and the
   `kMinLabelFontSize` floor from 3.0.0 are preserved.
4. **Move sound effects** — an opt-in `SoundPack` interface with callbacks
   per move classification (`move`, `capture`, `check`, `castle`, `promote`,
   `gameEnd`). The default is `SilentSoundPack` — zero runtime dependency,
   no bundled audio. Consumers plug in their own implementation, typically
   backed by `package:audioplayers` or similar in their app layer.
5. **Hint arrows** — an orthogonal "hint" arrow channel (`hintArrow:`
   parameter) rendered with a visually distinct style from user-supplied
   `arrows`, and auto-dismissed on the next move or after an optional
   duration. The existing `arrows:` list and `ChessArrow` geometry are
   untouched.
6. **Move legality indicator while dragging** — during an active drag, the
   square currently under the pointer receives a distinct visual
   treatment: a thicker ring on the legal-destination hint when the
   pointer is on a legal square, and an illegal-tint overlay when it is
   not. The existing legal-destination dot/ring for all legal squares and
   the non-drag selection overlay are preserved.

Premoves are tracked in a separate spec (`chess-board-premoves`) and are
intentionally excluded here.

All changes are additive and opt-in. Default behaviour of `3.0.0` stays
pixel-identical — the target release is `3.1.0`.

## Glossary

- **AdvancedChessBoard**: The main widget from `lib/src/advanced_chess_board.dart`.
- **ChessBoardController**: The `ChangeNotifier` from `lib/src/chess_board_controller.dart`.
- **ChessArrow**: Existing public value type in `lib/src/models/chess_arrow.dart`.
- **PlayerColor**: Existing public enum (`white`, `black`).
- **PieceSet**: New public value type describing how to fetch the
  `ImageProvider` for a given `(PlayerColor, chess.PieceType)`. The default
  `PieceSet.chessDotCom` wraps the current `assets/pieces/*.png` bundle.
- **BoardTheme**: New public value type bundling every colour the board
  paints (light square, dark square, selection overlay, last-move highlight,
  legal-destination hint, coordinate label, mated-king tint, hint-arrow
  colour, drag-legal ring, drag-illegal tint).
- **CoordinateLabels**: New public enum with values `inside`, `outside`, `none`.
- **SoundEvent**: New public enum over move classifications:
  `move`, `capture`, `check`, `castle`, `promote`, `gameEnd`.
- **SoundPack**: New public interface with a single method
  `Future<void> play(SoundEvent event)`. Implementations are free to
  debounce, overlap, or ignore events.
- **SilentSoundPack**: Default `SoundPack` implementation whose `play`
  returns immediately. Bundled with the library, zero audio assets, zero
  plugin dependencies.
- **HintArrow**: New public value type (or a `kind`-tagged `ChessArrow`
  subtype) representing a single engine / app-supplied suggestion arrow,
  visually distinct from user-drawn arrows.
- **Drag-legal ring**: The thicker-border variant of the legal-destination
  hint rendered on the square under the drag pointer.
- **Drag-illegal tint**: The overlay painted on the square under the drag
  pointer when that square is NOT a legal destination for the piece being
  dragged.
- **Exported public surface**: The set of symbols re-exported from
  `lib/advanced_chess_board.dart` (currently `AdvancedChessBoard`,
  `ChessBoardController`, `ChessArrow`, `PlayerColor`).

## Requirements

### Requirement 1: BoardTheme value type

**User Story:** As a Flutter consumer, I want to pass a `BoardTheme` preset
or a custom theme to `AdvancedChessBoard`, so that I can restyle every
colour the board paints with one value instead of threading many `Color`
parameters through my app.

#### Acceptance Criteria

1. THE `BoardTheme` value type SHALL be a public class exported from
   `lib/advanced_chess_board.dart` with `const` constructor and value
   equality (`==` / `hashCode`) over all fields.
2. THE `BoardTheme` value type SHALL carry, at minimum, the following
   fields: `lightSquareColor`, `darkSquareColor`, `selectionColor`,
   `lastMoveHighlightColor`, `legalDestinationColor`, `coordinateLabelColor`
   (nullable — when `null`, label colour SHALL be derived from the
   inverted square colour as in 3.0.0), `kingCheckmateColor`, `kingCheckColor`
   (nullable — when `null`, no in-check tint is rendered), `hintArrowColor`,
   `dragLegalRingColor`, and `dragIllegalTintColor`.
3. THE `BoardTheme` value type SHALL expose at least the following
   presets as public static getters: `BoardTheme.classicGreen`,
   `BoardTheme.brown`, `BoardTheme.blue`, `BoardTheme.purple`,
   `BoardTheme.monochrome`.
4. THE `BoardTheme.classicGreen` preset SHALL use `lightSquareColor:
   Color(0xFFEBECD0)`, `darkSquareColor: Color(0xFF739552)`, matching the
   3.0.0 defaults bit-for-bit.
5. WHEN a consumer passes `boardTheme: someTheme` to
   `AdvancedChessBoard` AND does NOT pass the legacy `lightSquareColor` /
   `darkSquareColor` / `kingBackgroundColorOnCheckmate` parameters, THEN
   THE `AdvancedChessBoard` SHALL paint every square, overlay, label, and
   tint using `someTheme`.
6. WHEN a consumer passes both `boardTheme: someTheme` AND one or more of
   the legacy per-colour parameters (`lightSquareColor`,
   `darkSquareColor`, `kingBackgroundColorOnCheckmate`), THEN THE
   `AdvancedChessBoard` SHALL let the legacy per-colour parameter win for
   exactly the overridden fields and SHALL fall back to `someTheme` for
   all other colours.
7. WHEN a consumer passes NO `boardTheme` AND NO legacy per-colour
   parameters, THEN THE `AdvancedChessBoard` SHALL render with the same
   colours as 3.0.0 (pixel-identical).
8. THE `BoardTheme` value type SHALL provide a `copyWith(...)` method
   returning a new `BoardTheme` with the named fields replaced.
9. THE `BoardTheme` value type and every public member SHALL carry
   dartdoc comments.

### Requirement 2: PieceSet abstraction

**User Story:** As a Flutter consumer, I want to swap the bundled
Chess.com PNGs for a different piece set (Staunton, Neo, Chess24, or my
own assets) without forking the package, so that my app's board matches
my brand.

#### Acceptance Criteria

1. THE `PieceSet` value type SHALL be a public class exported from
   `lib/advanced_chess_board.dart` with `const` constructor and value
   equality (`==` / `hashCode`).
2. THE `PieceSet` value type SHALL expose a lookup method
   `ImageProvider imageFor(PlayerColor color, chess.PieceType type)`
   returning the `ImageProvider` for the given `(color, type)` pair.
3. THE default `PieceSet.chessDotCom` preset SHALL resolve to the 12
   `assets/pieces/*.png` asset paths currently bundled with the library,
   with `package: 'advanced_chess_board'`.
4. WHEN a consumer does NOT pass a `pieceSet:` parameter to
   `AdvancedChessBoard`, THEN THE `AdvancedChessBoard` SHALL render pieces
   using `PieceSet.chessDotCom` (pixel-identical to 3.0.0).
5. WHEN a consumer passes `pieceSet: someCustomSet` to
   `AdvancedChessBoard`, THEN every piece on the board, every piece in
   the promotion dialog, every `Draggable.feedback`, and every piece in
   the move-animation overlay SHALL render using `someCustomSet`.
6. WHEN `AdvancedChessBoard.didChangeDependencies` first runs, THEN THE
   `AdvancedChessBoard` SHALL `precacheImage` every `ImageProvider`
   returned by the active `PieceSet` for all 12 `(color, type)` pairs,
   preserving the precache behaviour introduced in 3.0.0.
7. WHEN the `pieceSet:` parameter is swapped across a `didUpdateWidget`
   call, THEN THE `AdvancedChessBoard` SHALL `precacheImage` the 12
   `ImageProvider`s of the new set and SHALL rebuild so that the board
   paints with the new set.
8. THE `PieceSet` value type and every public member SHALL carry dartdoc
   comments.

### Requirement 3: Square coordinates toggle

**User Story:** As a Flutter consumer, I want to show coordinate labels
outside the grid (in a gutter) or hide them entirely, so that the board
better fits my app's layout — for example, a compact analysis board or a
board with external ranks/files rendered by my own UI.

#### Acceptance Criteria

1. THE `CoordinateLabels` enum SHALL be a public enum exported from
   `lib/advanced_chess_board.dart` with exactly three values:
   `CoordinateLabels.inside`, `CoordinateLabels.outside`,
   `CoordinateLabels.none`.
2. WHEN a consumer does NOT pass a `coordinates:` parameter to
   `AdvancedChessBoard`, THEN THE `AdvancedChessBoard` SHALL default to
   `CoordinateLabels.inside` and render labels inside the corner squares
   exactly as in 3.0.0.
3. WHEN a consumer passes `coordinates: CoordinateLabels.inside` AND
   `boardOrientation: PlayerColor.white`, THEN THE `AdvancedChessBoard`
   SHALL render rank labels on the `a` file (top-left of each a-file
   square) and file labels on rank `1` (bottom-right of each rank-1
   square), identical to 3.0.0.
4. WHEN a consumer passes `coordinates: CoordinateLabels.inside` AND
   `boardOrientation: PlayerColor.black`, THEN THE `AdvancedChessBoard`
   SHALL render rank labels on the `h` file and file labels on rank `8`,
   identical to 3.0.0.
5. WHEN a consumer passes `coordinates: CoordinateLabels.outside`, THEN
   THE `AdvancedChessBoard` SHALL render rank labels in a left-edge
   gutter and file labels in a bottom-edge gutter, outside the 8×8 grid,
   without overlapping any square.
6. WHILE `coordinates: CoordinateLabels.outside` AND `boardOrientation:
   PlayerColor.black`, THE `AdvancedChessBoard` SHALL render the rank
   gutter labels in descending order (1 at top, 8 at bottom) and the
   file gutter labels in descending file order (h at left, a at right),
   matching the flipped board.
7. WHEN a consumer passes `coordinates: CoordinateLabels.outside`, THEN
   THE `AdvancedChessBoard` SHALL preserve its `AspectRatio(1)` contract
   for the 8×8 playing grid by allocating gutter space outside the square
   board region (the board + gutters is NOT required to be 1:1 — only
   the playing grid is).
8. WHEN a consumer passes `coordinates: CoordinateLabels.none`, THEN THE
   `AdvancedChessBoard` SHALL render no rank or file labels anywhere, and
   SHALL NOT allocate any gutter space.
9. THE `AdvancedChessBoard` SHALL use the `kMinLabelFontSize` floor from
   `lib/src/constants/global_constants.dart` for both `inside` and
   `outside` label rendering.
10. IF the rendered board width is smaller than `8 * kMinLabelFontSize *
    2` AND `coordinates: CoordinateLabels.outside`, THEN THE
    `AdvancedChessBoard` SHALL continue to render labels at the
    `kMinLabelFontSize` floor (no smaller) and SHALL NOT throw a layout
    overflow error.

### Requirement 4: SoundPack interface and default

**User Story:** As a Flutter consumer, I want to hook sound effects into
moves, captures, checks, castles, promotions, and game endings — without
the library bundling audio assets or pulling an audio plugin — so that I
can ship a chess app with audio while keeping the library
dependency-light.

#### Acceptance Criteria

1. THE `SoundEvent` enum SHALL be a public enum exported from
   `lib/advanced_chess_board.dart` with exactly six values:
   `SoundEvent.move`, `SoundEvent.capture`, `SoundEvent.check`,
   `SoundEvent.castle`, `SoundEvent.promote`, `SoundEvent.gameEnd`.
2. THE `SoundPack` interface SHALL be a public abstract class exported
   from `lib/advanced_chess_board.dart` with a single abstract method
   `Future<void> play(SoundEvent event)`.
3. THE `SilentSoundPack` SHALL be a public concrete implementation of
   `SoundPack` whose `play` method returns an already-resolved `Future`
   without invoking any audio plugin, without decoding any audio asset,
   and without triggering any platform channel.
4. WHEN a consumer does NOT pass a `soundPack:` parameter to
   `AdvancedChessBoard`, THEN THE `AdvancedChessBoard` SHALL use
   `SilentSoundPack` and SHALL produce no audio.
5. WHEN a consumer passes `soundPack: somePack` to `AdvancedChessBoard`
   AND a successful move is made via tap, drag-drop, or
   `controller.makeMove(...)`, THEN THE `AdvancedChessBoard` SHALL invoke
   `somePack.play(e)` with exactly one `SoundEvent` `e` per successful
   move, classified in this priority order (highest first):
   `gameEnd` > `promote` > `castle` > `check` > `capture` > `move`.
6. WHEN the opponent is mated on the move (i.e. after the move,
   `controller.isGameOver == true`), THEN THE `AdvancedChessBoard` SHALL
   invoke `somePack.play(SoundEvent.gameEnd)` (and SHALL NOT also emit
   `check`, `capture`, or `move` for the same ply).
7. WHEN a move is a pawn promotion, THEN THE `AdvancedChessBoard` SHALL
   invoke `somePack.play(SoundEvent.promote)` (instead of `move`,
   `capture`, or `check`).
8. WHEN a move is castling short or long, THEN THE `AdvancedChessBoard`
   SHALL invoke `somePack.play(SoundEvent.castle)` (instead of `move`,
   `capture`, or `check`).
9. WHEN a move delivers check (post-move `controller.isInCheck == true`)
   but is NOT mate / promotion / castle, THEN THE `AdvancedChessBoard`
   SHALL invoke `somePack.play(SoundEvent.check)`.
10. WHEN a move is a capture but is NOT mate / promotion / castle /
    check, THEN THE `AdvancedChessBoard` SHALL invoke
    `somePack.play(SoundEvent.capture)`.
11. WHEN a move is a quiet move (not mate, promotion, castle, check, or
    capture), THEN THE `AdvancedChessBoard` SHALL invoke
    `somePack.play(SoundEvent.move)`.
12. WHEN `controller.undo()`, `controller.resetBoard()`, or
    `controller.loadGameFromFEN(...)` is invoked, THEN THE
    `AdvancedChessBoard` SHALL NOT invoke any `SoundPack.play(...)`
    callback.
13. WHEN `controller.makeMove(..., notify: false)` is invoked, THEN THE
    `AdvancedChessBoard` SHALL NOT invoke any `SoundPack.play(...)`
    callback for that move (silent mutation is a consumer batching
    primitive and must not leak audio, matching the listener-suppression
    contract from 3.0.0).
14. IF the `SoundPack.play(...)` implementation throws (synchronously or
    asynchronously), THEN THE `AdvancedChessBoard` SHALL catch the error,
    log it via `debugPrint`, and continue without propagating the error
    to the controller or rebuild cycle.
15. THE `SoundEvent`, `SoundPack`, and `SilentSoundPack` public types
    SHALL carry dartdoc comments explaining classification priority and
    the "no bundled audio" stance.

### Requirement 5: Hint arrows

**User Story:** As a Flutter consumer integrating a chess engine or hint
API, I want to show the engine's suggested move as a visually distinct
arrow that auto-dismisses on the next move, so that the suggestion does
not get confused with user-drawn analysis arrows.

#### Acceptance Criteria

1. THE `HintArrow` value type SHALL be a public class exported from
   `lib/advanced_chess_board.dart` with `const` constructor, value
   equality, and at minimum the fields `startSquare` (String,
   algebraic), `endSquare` (String, algebraic), and optional `duration`
   (`Duration?`; when null, the arrow persists until the next move).
2. WHEN a consumer passes `hintArrow: someHint` to `AdvancedChessBoard`
   AND `someHint` is non-null, THEN THE `AdvancedChessBoard` SHALL
   render exactly one hint arrow from `someHint.startSquare` to
   `someHint.endSquare` above every user-supplied arrow in `arrows:`.
3. THE rendered hint arrow SHALL be visually distinct from every
   `ChessArrow` in the `arrows:` list, with at least two distinguishing
   attributes: a different default colour (`boardTheme.hintArrowColor`)
   AND a different geometry (e.g. dashed line, thinner stroke, or
   outlined arrowhead — design document picks the specific treatment).
4. WHEN a successful move is made via tap, drag-drop, or
   `controller.makeMove(...)` AND a hint arrow is currently rendered,
   THEN THE `AdvancedChessBoard` SHALL dismiss the hint arrow (cease
   rendering it) on the next frame.
5. WHERE `hintArrow.duration` is non-null, THE `AdvancedChessBoard`
   SHALL dismiss the hint arrow after `hintArrow.duration` elapses from
   its first render, even if no move has been made.
6. WHEN the consumer rebuilds `AdvancedChessBoard` with a different
   non-null `hintArrow:` value (by value equality) before the previous
   hint has dismissed, THEN THE `AdvancedChessBoard` SHALL replace the
   currently-rendered hint with the new one and reset any active
   duration timer.
7. WHEN the consumer rebuilds `AdvancedChessBoard` with `hintArrow: null`,
   THEN THE `AdvancedChessBoard` SHALL dismiss any currently-rendered
   hint arrow on the next frame.
8. THE hint arrow SHALL NOT mutate the `arrows:` list the consumer
   passed in (the consumer's user-drawn arrow list SHALL be rendered
   unchanged).
9. THE `HintArrow` value type and every public member SHALL carry
   dartdoc comments.

### Requirement 6: Move legality indicator while dragging

**User Story:** As a chess player using the board on a touch device, I
want the square under my finger during a drag to clearly indicate
whether dropping there is a legal move, so that I don't accidentally
release on an illegal square and have my piece snap back.

#### Acceptance Criteria

1. WHILE a piece is being dragged AND the drag pointer is over a square
   that IS a legal destination for the dragged piece, THE
   `AdvancedChessBoard` SHALL render the drag-legal ring on that square
   (a thickened-border variant of the existing legal-destination hint)
   using `boardTheme.dragLegalRingColor`.
2. WHILE a piece is being dragged AND the drag pointer is over a square
   that is NOT a legal destination for the dragged piece AND is NOT the
   source square, THE `AdvancedChessBoard` SHALL render the
   drag-illegal tint overlay on that square using
   `boardTheme.dragIllegalTintColor`.
3. WHILE a piece is being dragged AND the drag pointer is over the
   source square, THE `AdvancedChessBoard` SHALL NOT render either the
   drag-legal ring or the drag-illegal tint (no indication that the
   source square is "illegal" since releasing there is simply a cancel).
4. WHEN the drag pointer moves from one square to another, THEN THE
   `AdvancedChessBoard` SHALL remove the drag-legal ring or
   drag-illegal tint from the previous square on the next frame and
   render the appropriate indicator on the new square.
5. WHEN the drag ends (drop, cancel, or pointer lift) THE
   `AdvancedChessBoard` SHALL remove every drag-legal ring and
   drag-illegal tint from all squares on the next frame.
6. THE drag-legal ring SHALL be layered above the existing
   legal-destination hint overlay from 3.0.0 so that both are visible
   (the existing small dot / hollow ring is not hidden — it is
   visually emphasised).
7. THE drag-illegal tint SHALL be layered above the square background
   but below any piece currently rendered on that square, so that
   captured-piece silhouettes remain visible under the tint.
8. IF `enableMoves` is `false`, THEN the drag-legal ring and
   drag-illegal tint SHALL NOT be rendered under any circumstance
   (drags are already rejected — no legality feedback is warranted).

### Requirement 7: Public API surface and barrel exports

**User Story:** As a Flutter consumer, I want the new public types to be
available from the single top-level import
`package:advanced_chess_board/advanced_chess_board.dart`, so that I do
not have to reach into `lib/src/` paths.

#### Acceptance Criteria

1. THE `lib/advanced_chess_board.dart` barrel SHALL re-export every new
   public type introduced by this spec: `BoardTheme`, `PieceSet`,
   `CoordinateLabels`, `SoundEvent`, `SoundPack`, `SilentSoundPack`,
   `HintArrow`.
2. THE `lib/advanced_chess_board.dart` barrel SHALL CONTINUE to
   re-export `AdvancedChessBoard`, `ChessBoardController`, `ChessArrow`,
   and `PlayerColor` exactly as in 3.0.0.
3. Every implementation file added by this spec SHALL live under
   `lib/src/`.
4. No new symbol introduced by this spec SHALL be exported from
   `lib/advanced_chess_board.dart` without carrying dartdoc comments on
   every public member (preserving the `public_member_api_docs` lint
   clean pass from 3.0.0).

### Requirement 8: Versioning and release notes

**User Story:** As a Flutter consumer on `3.0.0`, I want the upgrade to
be non-breaking when I do not opt into any of the new features, so that
`flutter pub upgrade` is safe.

#### Acceptance Criteria

1. WHEN the new version is published, THE `pubspec.yaml` SHALL set
   `version: 3.1.0`.
2. THE `CHANGELOG.md` SHALL gain a `3.1.0 — YYYY-MM-DD` entry with the
   release date in ISO-8601 format and sections for "Additions" (every
   new public type and parameter) and "Polish" (any non-breaking
   refinements introduced by this spec).
3. IF any default visual or behavioural change from 3.0.0 is introduced
   by this spec (for example, a colour shift in a preset, a font-size
   change, a sound firing by default), THEN the version SHALL be
   bumped to `4.0.0` instead of `3.1.0` and the `CHANGELOG.md` SHALL
   document the breaking change with a migration note — this clause is
   an escape hatch: the spec is designed so the branch is NOT taken.
4. THE `README.md` SHALL gain a "Theming", "Piece sets", "Coordinates",
   "Sound effects", "Hint arrows", and "Drag legality indicator"
   subsection (or equivalent) under a new or extended "Features"
   section, with at least one minimal worked example per capability.
5. THE `README.md` SHALL update the "Known limitations" section to
   remove "Piece theming currently requires forking the
   `assets/pieces/` directory" (now addressed by Requirement 2).

### Requirement 9: Analysis, lints, and dartdoc

**User Story:** As a maintainer, I want every strict-analyse check that
3.0.0 passes to continue passing, so that pub.dev score and developer
ergonomics do not regress.

#### Acceptance Criteria

1. WHEN `flutter analyze --fatal-warnings --fatal-infos` is run at the
   repo root, THEN it SHALL exit 0.
2. WHEN `flutter analyze --fatal-warnings --fatal-infos` is run in
   `example/`, THEN it SHALL exit 0.
3. THE `public_member_api_docs` lint (enabled in 3.0.0's
   `analysis_options.yaml`) SHALL emit zero violations across every new
   public symbol introduced by this spec.
4. THE `strict-casts`, `strict-inference`, and `strict-raw-types`
   analyser options enabled in 3.0.0 SHALL CONTINUE to pass on every
   source file in `lib/` and `example/`.

### Requirement 10: Parser-free implementation

**User Story:** As a maintainer, I want to avoid introducing new parsers
or serializers into the library, so that I do not have to carry the
PBT-style round-trip testing burden for a feature that does not require
them.

#### Acceptance Criteria

1. THE implementation of this spec SHALL NOT introduce any new parser or
   serializer (no FEN variant parsing, no sound-pack config parsing, no
   piece-set manifest parsing, no theme serialisation).
2. IF a future iteration introduces theme serialisation or piece-set
   manifest files, THEN that work SHALL be scoped to its own spec and
   SHALL include a round-trip property (parse → print → parse) per the
   package's correctness-property approach.

## Preservation Requirements

These clauses pin 3.0.0 behaviour that this spec MUST NOT regress. Each
corresponds to behaviour an `advanced_chess_board` 3.0.0 consumer
currently relies on.

### Chess-rule correctness (inherited from 3.0.0)

P1. WHEN a player makes a legal non-promotion move (pawn push, piece
development, capture, en passant, castling short, castling long) via
`controller.makeMove` or via tap/drag, THE `AdvancedChessBoard` SHALL
CONTINUE to update game state correctly, advance `controller.fen`, flip
`controller.playerColor`, and reflect the move on screen.

P2. WHEN a pawn reaches the promotion rank (`8` for white, `1` for
black), THE `AdvancedChessBoard` SHALL CONTINUE to show a promotion
dialog offering queen / rook / bishop / knight, and SHALL CONTINUE to
default to queen when the dialog is dismissed.

P3. WHEN `controller.makeMove(from: a, to: b)` is called with an illegal
move, THE `ChessBoardController` SHALL CONTINUE to return `false`
without mutating game state.

P4. WHEN the drag target's `onWillAcceptWithDetails` is invoked for a
destination square, THE `AdvancedChessBoard` SHALL CONTINUE to reject
illegal destinations (returning `false` so `onAcceptWithDetails` does
not fire).

### Controller semantics (inherited from 3.0.0)

P5. WHEN `controller.makeMove(..., notify: false)`, `controller.undo(notify:
false)`, `controller.resetBoard(notify: false)`, or
`controller.loadGameFromFEN(..., notify: false)` is invoked, THE
`ChessBoardController` SHALL CONTINUE to suppress listener
notifications for that call.

P6. WHEN `controller.game` is accessed, THE `ChessBoardController` SHALL
CONTINUE to return the underlying `chess.Chess` object as an escape
hatch.

P7. WHEN `controller.isCheckmate`, `controller.isInCheck`,
`controller.isStalemate`, `controller.isDraw`, `controller.isGameOver`,
`controller.history`, `controller.pgn`, and `controller.moveCount` are
read, THE `ChessBoardController` SHALL CONTINUE to return the same
values as in 3.0.0 for the same underlying position.

P8. WHEN the `AdvancedChessBoard` widget is mounted with a controller,
THE `AdvancedChessBoard` SHALL CONTINUE to internally subscribe via
`ListenableBuilder` and rebuild on controller notifications — no
consumer-side `controller.addListener(setState)` SHALL be required.

P9. WHEN `widget.controller` is replaced across a `didUpdateWidget` call,
THE `AdvancedChessBoard` SHALL CONTINUE to unsubscribe from the old
controller, subscribe to the new one, and clear the internal selection
/ legal-move / animation state.

### Rendering behaviour (inherited from 3.0.0)

P10. WHEN `enableMoves: false` is set, THE `AdvancedChessBoard` SHALL
CONTINUE to render normally, refuse all tap/drag interactions, and
display pieces without grab cursors.

P11. WHEN `highlightLastMove: true` (the default) and at least one move
has been played, THE `AdvancedChessBoard` SHALL CONTINUE to tint the
from-square and to-square using the last-move highlight colour.

P12. WHEN the user taps a piece of the side to move, THE
`AdvancedChessBoard` SHALL CONTINUE to highlight legal destination
squares with the `HighlightOverlay` (small dot on empty squares, hollow
ring on squares with pieces), AND tapping the same square again SHALL
CONTINUE to deselect.

P13. WHEN the user drags a piece and drops it on a legal square, THE
`AdvancedChessBoard` SHALL CONTINUE to make the move; dropping on an
illegal square SHALL CONTINUE to leave state unchanged.

P14. WHEN `arrows: [...]` is passed with user-drawn `ChessArrow`s, THE
`ArrowPainter` SHALL CONTINUE to draw each arrow as a line plus
equilateral-triangle arrowhead sized from `blockSize`, respecting its
`color` (default `Colors.amber.withAlpha(128)`), including the
`sourceThreshold = blockSize * 0.35`, `destinationThreshold = blockSize
* 0.272`, and `arrowheadSideLength = blockSize * 0.2` geometry from
3.0.0.

P15. WHEN `boardOrientation` is `PlayerColor.white` or `PlayerColor.black`,
THE `ArrowPainter` SHALL CONTINUE to map squares to orientation-adjusted
coordinates, and arrows SHALL flip with the board.

P16. WHEN a king is checkmated, THE `AdvancedChessBoard` SHALL CONTINUE
to tint the mated king's square using either the legacy
`kingBackgroundColorOnCheckmate` parameter (if passed) or
`boardTheme.kingCheckmateColor` (defaulting to `Colors.red.withAlpha(155)`).

P17. WHEN a move is made via tap or programmatic API, THE
`AdvancedChessBoard` SHALL CONTINUE to animate the moving piece via the
`MoveAnimationLayer` for `moveAnimationDuration`; drag-drop moves SHALL
CONTINUE to skip the animation (the `Draggable.feedback` already
follows the pointer).

P18. WHEN `moveAnimationDuration: Duration.zero` is passed, THE
`AdvancedChessBoard` SHALL CONTINUE to skip the animation.

P19. WHEN file/rank labels are rendered at `squareSize * 0.18`, THE
`AdvancedChessBoard` SHALL CONTINUE to enforce a
`max(kMinLabelFontSize, squareSize * 0.18)` floor so labels stay
readable on small boards.

P20. WHEN a piece is dragged on a narrow screen, THE `AdvancedChessBoard`
SHALL CONTINUE to clamp `Draggable.feedback` size to at most
`min(squareSize * kMaxFeedbackScale, squareSize + kMaxFeedbackOverflowPx)`.

P21. WHEN the board builds 64 squares, THE `AdvancedChessBoard` SHALL
CONTINUE to use a `Column` of 8 `Row`s (no `GridView`, no scroll
viewport).

P22. WHEN the board first builds, THE `AdvancedChessBoard` SHALL CONTINUE
to `precacheImage` every piece asset once in `didChangeDependencies`
(the set of assets precached is the active `PieceSet`'s 12
`ImageProvider`s — see Requirement 2 — but the one-shot precache
contract from 3.0.0 is preserved).

### Accessibility (inherited from 3.0.0)

P23. WHEN a screen reader traverses the board, each `ChessSquare` SHALL
CONTINUE to be wrapped in a `Semantics` node with a label like
`"e4, white pawn"` or `"e4, empty"`, and each `ChessPieceWidget` SHALL
CONTINUE to expose its piece description via `Semantics`.

### API surface stability (inherited from 3.0.0)

P24. The four existing public symbols — `AdvancedChessBoard`,
`ChessBoardController`, `ChessArrow`, `PlayerColor` — SHALL CONTINUE
to be re-exported from `lib/advanced_chess_board.dart`, with no deep
imports required.

P25. The following existing `AdvancedChessBoard` parameters SHALL
CONTINUE to exist with their 3.0.0 names, types, and default values:
`controller`, `lightSquareColor` (default `Color(0xFFEBECD0)`),
`darkSquareColor` (default `Color(0xFF739552)`), `initialFEN` (default
`null`), `boardOrientation` (default `PlayerColor.white`), `enableMoves`
(default `true`), `highlightLastMove` (default `true`), `arrows`
(default `const []`), `kingBackgroundColorOnCheckmate` (default `null`),
`moveAnimationDuration` (default `kDefaultMoveAnimationDuration`).
Consumers passing these parameters SHALL CONTINUE to see the same
behaviour as 3.0.0.

### Testing (inherited from 3.0.0)

P26. WHEN `flutter test` runs, every existing 3.0.0 test
(`test/controller/...`, `test/painter/...`, `test/widget/...`,
`test/packaging/...`, `test/api/...`, `test/properties/...`) SHALL
CONTINUE to pass unchanged. New tests added for this spec SHALL NOT
modify or delete any 3.0.0 test file.

P27. WHEN property-based tests run via `glados`, the existing 3.0.0
properties (legal-move round-trip, FEN round-trip, listener-notify
invariant, painter repaint correctness, etc.) SHALL CONTINUE to pass
unchanged.
