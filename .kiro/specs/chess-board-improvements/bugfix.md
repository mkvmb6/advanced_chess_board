# Bugfix Requirements Document

## Introduction

The `advanced_chess_board` package (v2.3.0) is a published Flutter package offering a customizable chess board widget with piece drag-and-drop, arrows, FEN loading, and a controller-based API. A deep audit uncovered a cluster of defects that collectively prevent the package from meeting the quality bar expected of a 2.x pub.dev library:

- **Correctness defects**: a broken `ChangeNotifier` that only fires the last-registered listener, an inverted `CustomPainter.shouldRepaint` that suppresses arrow updates, a `dispose` ordering bug, and a fragile SAN-substring check that misidentifies legal destination squares.
- **API defects**: consumers are forced to call `addListener(setState)` themselves because the widget does not rebuild on controller changes; public symbols live in deep `lib/<subfolder>/…` paths with no barrel export; the `ChessBoardController` surface is thin and inconsistent, leaking the underlying `chess` package.
- **UX / rendering defects**: redundant `setState` on no-op interactions, empty `Container()` placeholders, pieces re-decoded every rebuild, hard-coded promotion dialog sizing, oversized drag feedback on small screens, missing move animations and accessibility semantics.
- **Testing gap**: `test/advanced_chess_board_test.dart` contains only `void main() {}`, so none of the above is regression-guarded.
- **Packaging / documentation gaps**: missing pub.dev metadata (`repository`, `issue_tracker`, `topics`, `platforms`), a version-mismatched `flutter_lints` in `example/`, a weak `analysis_options.yaml`, undated `CHANGELOG.md` with no breaking-change notes, README drift (promises an already-shipped feature), no dartdoc on public classes.

This bugfix treats the package as a single behavioural unit: the "bug condition" is any input — user interaction, controller invocation, `pub get` resolution, `flutter analyze` run, test execution, or pub.dev score check — for which the current package produces an incorrect, surprising, or sub-standard result as enumerated below. The fix must eliminate every listed defect while preserving all currently-correct behaviour (legal moves, captures, castling, promotions, FEN rendering, arrow geometry, custom colours, orientation flipping).

The Chess.com piece-image licensing concern is explicitly out of scope for this spec.

## Bug Analysis

### Current Behavior (Defect)

The following describes what the package currently does wrong, grouped by concern. Each clause is a distinct triggering condition and observable incorrect behaviour.

**Critical correctness bugs (ChangeNotifier, painter, dispose, move validation, example resolution)**

1.1 WHEN two or more callers call `ChessBoardController.addListener(...)` on the same controller THEN the controller stores only the most recently registered callback in its private `VoidCallback? _listener` field and silently drops all earlier listeners, so subsequent moves notify at most one listener.

1.2 WHEN any code calls `notifyListeners()` on `ChessBoardController` (inherited from `ChangeNotifier`) THEN no registered callback fires, because `addListener` never delegates to `super.addListener` and `_notifyListeners` only invokes the single stored `_listener`.

1.3 WHEN `ChessBoardController.dispose()` is invoked THEN `super.dispose()` runs before `_listener = null`, which is the wrong order for `ChangeNotifier` subclasses and risks assertion failures or use-after-dispose in debug mode.

1.4 WHEN the `arrows` list passed to `AdvancedChessBoard` changes (add, remove, reorder, recolour, or swap squares) THEN `ArrowPainter.shouldRepaint` returns `false` for every differing case and `true` only when the lists are equal, so the canvas never repaints to reflect new arrows.

1.5 WHEN only `boardOrientation` changes but the arrow list is unchanged THEN `ArrowPainter.shouldRepaint` returns `true` (because the equal-list branch falls through to `return true`) yet for identical arrows repainting is wasted, AND when orientation changes alongside equal arrows the painter does not treat orientation as part of its identity at all.

1.6 WHEN a player has a legal move from square `X` and `_isSquarePartOfValidMoves` tests a candidate destination `Y` using `move.contains(Y)` against SAN strings returned by `game.moves({squareKey: X})` THEN squares whose algebraic name appears as a substring of an unrelated SAN move (e.g. square `"a1"` matching `"Ra1xb1"`, or `"b1"` matching `"Nb1-c3"`) are incorrectly highlighted and accepted as drop targets.

1.7 WHEN a consumer runs `flutter pub get` inside `example/` THEN pub resolution pulls `flutter_lints: ^4.0.0` for the example while the library at `../` requires `flutter_lints: ^5.0.0`, causing version-resolution friction and inconsistent lint behaviour between package and example.

**Controller / widget coupling and state synchronisation**

1.8 WHEN a consumer places `AdvancedChessBoard` in a widget tree with only `controller: myController` and does not also register `controller.addListener(() => setState(() {}))` in their own `State` THEN the board does not rebuild after `controller.makeMove`, `controller.undo`, `controller.resetBoard`, or `controller.loadGameFromFEN`, and the UI appears frozen even though `game` state has advanced.

1.9 WHEN the widget's `initState` stores `game = widget.controller.game` THEN later controller swaps via `didUpdateWidget` are not handled and `_AdvancedChessBoardState.game` remains bound to the original controller.

**Dead code, weak typing, thin API**

1.10 WHEN `getChessPieceWidget` in `lib/utils/utils.dart` returns after its exhaustive white/black + piece-type switches THEN the trailing `return const Text("No piece found")` is unreachable dead code flagged by the analyser.

1.11 WHEN `pieceTypeToString` in `lib/utils/utils.dart` returns after its exhaustive `PieceType` switch THEN the trailing `return "q"` is unreachable dead code flagged by the analyser.

1.12 WHEN `_getPieceImageWidget(final assetPath)` is called THEN `assetPath` is untyped (implicit `dynamic`), so callers can pass any value and the analyser cannot enforce `String`.

1.13 WHEN a consumer needs common chess state beyond `fen`, `playerColor`, `isCheckmate()`, `makeMove`, `undo`, `resetBoard`, `loadGameFromFEN` — for example `isInCheck`, `isStalemate`, `isDraw`, `isGameOver`, move `history`, `pgn`, or `moveCount` — THEN `ChessBoardController` exposes no getter and the consumer must reach into the underlying `controller.game`, leaking the `chess` package through the public API.

1.14 WHEN the controller mixes `isCheckmate()` (method) with `fen` / `playerColor` (getters) for read-only boolean state THEN the API is inconsistent and a breaking rename is required to converge on getters.

**Public API surface and export hygiene**

1.15 WHEN a consumer wants to use `ChessBoardController`, `ChessArrow`, or `PlayerColor` THEN they must import from deep paths (`package:advanced_chess_board/chess_board_controller.dart`, `package:advanced_chess_board/models/chess_arrow.dart`, `package:advanced_chess_board/models/enums.dart`), because `lib/advanced_chess_board.dart` declares `library;` but exports nothing.

1.16 WHEN internal files live directly under `lib/` (`constants/`, `utils/`, `widgets/`, `models/`, `chess_board_controller.dart`) with no `lib/src/` layer THEN all of them are part of the public import surface and any refactor is a breaking change.

**Rendering / UX defects**

1.17 WHEN `enableMoves` is `false` AND the user taps any square THEN `_handleTap` calls `setState` at its end even though it early-returned without mutating state, forcing an unnecessary rebuild.

1.18 WHEN the user taps an empty square with no piece selected THEN `_handleTap` calls `setState` at its end even though `selectedSquare` and `legalMoves` are unchanged.

1.19 WHEN `_buildLastMoveHighlight(square)` is invoked for a square that is neither `lastMove.fromAlgebraic` nor `lastMove.toAlgebraic` THEN it returns a bare `Container()` (non-shrinking, zero-sized but still layout-participating) instead of `SizedBox.shrink()` or being conditionally omitted.

1.20 WHEN the last-move square is also the currently selected square THEN both the yellow `_buildSelectedPieceOverlay` (alpha 155) and the yellow `_buildLastMoveHighlight` (alpha 128) stack on top of each other, producing a double-intensity highlight.

1.21 WHEN `_buildCheckmateKingOverlay` returns a coloured `Container` for the mated king THEN it is placed in the `Stack` before `_buildPiece`, so the king piece draws on top of the red tint — acceptable visually, but the overlay never masks the piece (documented as preserved behaviour in section 3).

1.22 WHEN the board builds 64 squares THEN it uses `GridView.builder` with `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8)` for a known-fixed 8×8 grid, introducing a scrollable viewport and slower layout than a `Column` of `Row`s or a `Table`.

1.23 WHEN `_buildPiece` rebuilds a square THEN `Image.asset(...)` inside `getChessPieceWidget` re-decodes the piece PNG every rebuild because no `precacheImage` runs in `didChangeDependencies`.

1.24 WHEN `_showPromotionDialog` opens THEN it hard-codes `squareSize: 60` for the four candidate pieces, ignoring the actual board square size and rendering tiny pieces on large boards or oversize pieces on small ones.

1.25 WHEN a piece is moved by tap or drag THEN no animation interpolates its position; the piece teleports to its destination on the next rebuild.

1.26 WHEN the board renders on a narrow screen AND a piece is dragged THEN `dragFeedbackScaleFactor = 1.15` is applied unconditionally, producing drag feedback larger than the square itself and clipping off neighbouring squares.

**Accessibility and internationalisation**

1.27 WHEN a screen reader traverses the board THEN neither `ChessSquare` nor `ChessPieceWidget` is wrapped in `Semantics`, so users hear no square coordinates, piece identity, or move affordances.

1.28 WHEN the board is sized small (e.g. compact layout, phone portrait) THEN file/rank labels use `fontSize: squareSize * 0.18` with no floor, producing text below readable minimum on small boards.

**Testing**

1.29 WHEN `flutter test` runs THEN `test/advanced_chess_board_test.dart` contains only `void main() {}` and exercises zero behaviour: no controller tests, no widget tests, no painter tests, no property-based invariants.

**Packaging and repository hygiene**

1.30 WHEN pub.dev scores the package THEN `pubspec.yaml` omits `repository`, `issue_tracker`, `topics`, `platforms`, and `screenshots`, costing score points and discovery metadata.

1.31 WHEN `CHANGELOG.md` is inspected THEN entries lack dates and the `2.0.0` breaking rename (`playerToMove` → `playerColor`) is under-described with no migration note.

1.32 WHEN a reader opens `README.md` THEN it still says "Support for drawing arrow will be added in upcoming release" even though arrows shipped in `2.0.0`, and it lacks a parameter reference table, FEN/flip/listener examples, and a known-limitations section.

**Documentation**

1.33 WHEN a consumer uses `flutter pub publish --dry-run` or reads the dartdoc THEN public classes (`AdvancedChessBoard`, `ChessBoardController`, `ChessArrow`, `PlayerColor`) have no `///` comments, reducing pub.dev documentation score and IDE help-text value.

**Linting**

1.34 WHEN `flutter analyze` runs THEN `analysis_options.yaml` only includes `package:flutter_lints/flutter.yaml` with no `analyzer: language: strict-casts/strict-inference/strict-raw-types` block and no additional `linter: rules:` (e.g. `prefer_const_constructors`, `public_member_api_docs`, `always_declare_return_types`, `avoid_dynamic_calls`), letting the above weak-typing and dead-code smells compile cleanly.

### Expected Behavior (Correct)

Each clause describes the correct behaviour for the same triggering condition as the matching `1.X` clause above.

**Critical correctness bugs**

2.1 WHEN two or more callers call `ChessBoardController.addListener(...)` on the same controller THEN the controller SHALL register every callback via the inherited `ChangeNotifier.addListener`, and SHALL NOT override `addListener`, so all registered listeners fire on every notification.

2.2 WHEN any code calls `notifyListeners()` on `ChessBoardController` — whether internal state-change paths (`makeMove`, `undo`, `resetBoard`, `loadGameFromFEN`) or external callers — THEN every currently-registered listener SHALL be invoked exactly once, using the inherited `ChangeNotifier` plumbing; the private `_listener` field and `_notifyListeners()` helper SHALL be removed.

2.3 WHEN `ChessBoardController.dispose()` is invoked THEN the controller SHALL release its own resources first and call `super.dispose()` LAST, matching Flutter's `ChangeNotifier.dispose` contract.

2.4 WHEN the `arrows` list passed to `AdvancedChessBoard` changes in any way (length, order, per-arrow `startSquare`/`endSquare`/`color`) THEN `ArrowPainter.shouldRepaint` SHALL return `true`, causing the canvas to repaint; the method SHALL return `false` only when the new and old painters are semantically equal.

2.5 WHEN `boardOrientation` changes between the old and new painter THEN `ArrowPainter.shouldRepaint` SHALL return `true` because arrow coordinates depend on orientation; when both arrows and orientation are unchanged, it SHALL return `false`.

2.6 WHEN `_isSquarePartOfValidMoves` (or its replacement) tests whether a destination `Y` is reachable from square `X` THEN it SHALL query verbose moves via `game.moves({squareKey: X, verbose: true})` and compare the resulting map's `to` field (and promotion/castle flags) exactly, so only genuine destination squares are highlighted and accepted as drop targets; castling short/long continue to highlight `g1`/`c1`/`g8`/`c8` correctly.

2.7 WHEN a consumer runs `flutter pub get` inside `example/` THEN `example/pubspec.yaml` SHALL specify `flutter_lints: ^5.0.0` (matching the library) so resolution is clean and lints are consistent across package and example.

**Controller / widget coupling**

2.8 WHEN a consumer places `AdvancedChessBoard` with only `controller: myController` THEN the widget SHALL internally subscribe to the controller (e.g. via `ListenableBuilder` or `AnimatedBuilder`) and rebuild automatically on controller notifications, with no `addListener(setState)` required in the consumer's `State`.

2.9 WHEN `widget.controller` is replaced across a `didUpdateWidget` call THEN the widget SHALL unsubscribe from the old controller and subscribe to the new one, and SHALL rebind its internal `game` reference to `widget.controller.game`.

**Dead code, weak typing, thin API**

2.10 WHEN `getChessPieceWidget` handles all `Color` × `PieceType` combinations via exhaustive switches THEN the unreachable `return const Text("No piece found")` SHALL be removed (exhaustiveness alone SHALL satisfy the return-path requirement).

2.11 WHEN `pieceTypeToString` handles all `PieceType` values via an exhaustive switch THEN the unreachable `return "q"` SHALL be removed.

2.12 WHEN `_getPieceImageWidget` is declared THEN its `assetPath` parameter SHALL be typed as `String`.

2.13 WHEN a consumer needs common chess state THEN `ChessBoardController` SHALL expose, as getters, at least: `isInCheck`, `isCheckmate`, `isStalemate`, `isDraw`, `isGameOver`, `history` (immutable view), `pgn`, `moveCount`, in addition to the existing `fen` and `playerColor`, so consumers do not need to reach into `controller.game`.

2.14 WHEN read-only boolean state is exposed THEN the controller SHALL use getters consistently; `isCheckmate()` SHALL be replaced by `isCheckmate` getter, and the `CHANGELOG.md` SHALL document this as a breaking change in the new major version.

**Public API surface and export hygiene**

2.15 WHEN a consumer imports `package:advanced_chess_board/advanced_chess_board.dart` THEN they SHALL gain access to `AdvancedChessBoard`, `ChessBoardController`, `ChessArrow`, and `PlayerColor` through a barrel export, with no need to reach into sub-paths.

2.16 WHEN the package is reorganised THEN all implementation files (`constants/`, `utils/`, `widgets/`, `models/`, `chess_board_controller.dart`) SHALL move under `lib/src/`, and only the intended public symbols SHALL be re-exported from `lib/advanced_chess_board.dart`.

**Rendering / UX**

2.17 WHEN `enableMoves` is `false` AND the user taps any square THEN `_handleTap` SHALL early-return without calling `setState`.

2.18 WHEN the user taps an empty square with no piece selected THEN `_handleTap` SHALL return without calling `setState`.

2.19 WHEN `_buildLastMoveHighlight(square)` is invoked for a square outside the last move THEN it SHALL return `SizedBox.shrink()` (or the overlay SHALL be conditionally added to the `Stack` so no widget is emitted at all).

2.20 WHEN the last-move square is also the currently selected square THEN the widget SHALL draw only one highlight (the selection overlay takes precedence), avoiding double alpha-blending.

2.21 WHEN a king is checkmated THEN the checkmate tint SHALL continue to render behind the king piece (existing visual); this clause exists to pin current behaviour while explicitly permitting non-regressive visual tweaks inside `design.md`.

2.22 WHEN the board builds 64 squares THEN it SHALL use a fixed layout (`Column` of eight `Row`s of eight children, or a `Table`) rather than `GridView.builder`, eliminating scroll semantics and improving layout predictability.

2.23 WHEN `AdvancedChessBoard.didChangeDependencies` runs for the first time THEN all 12 piece images SHALL be `precacheImage`'d against the current `BuildContext`, so piece rebuilds do not re-decode the PNGs.

2.24 WHEN `_showPromotionDialog` opens THEN the dialog pieces SHALL be sized as a function of the current `squareSize` (e.g. the same `squareSize` used by the board tiles), not a hard-coded `60`.

2.25 WHEN a move is made (by tap or drag) THEN the moving piece SHALL animate to its destination (e.g. `AnimatedPositioned` or `AnimatedSwitcher`) over a short, configurable duration, with a sensible default.

2.26 WHEN a piece is dragged on a narrow screen THEN `dragFeedbackScaleFactor` SHALL be clamped so the feedback widget never exceeds the board width / 8 by more than a small, bounded amount (e.g. `min(1.15, maxSafeScale)`).

**Accessibility and internationalisation**

2.27 WHEN a screen reader traverses the board THEN each `ChessSquare` SHALL be wrapped in `Semantics` with a label like "e4, white pawn" (or "e4, empty") and each draggable `ChessPieceWidget` SHALL expose a semantic label and, where appropriate, the `button` / `draggable` traits.

2.28 WHEN the board is sized small THEN file/rank label font size SHALL be `max(minimumReadable, squareSize * 0.18)` where `minimumReadable` is a package-level constant (e.g. 8–10 logical pixels).

**Testing**

2.29 WHEN `flutter test` runs THEN `test/advanced_chess_board_test.dart` (and additional test files as needed) SHALL contain:
 - Unit tests for `ChessBoardController`: `makeMove` accepts legal moves and rejects illegal moves; `undo` reverses the last move; `loadGameFromFEN` accepts valid FEN and rejects (or safely handles) malformed FEN; `playerColor` flips after each move; `notify: false` does NOT fire listeners; `notify: true` does.
 - Widget tests for `AdvancedChessBoard`: pump the widget, tap an e2 pawn then e4 and assert the FEN advances; drag-and-drop an e2 pawn to e4 and assert the same; an illegal target does not advance FEN; promotion dialog appears on a promoting move and returns the chosen piece.
 - Painter tests for `ArrowPainter.shouldRepaint`: returns `true` when arrows differ in length, content, order, or colour, or when `boardOrientation` differs; returns `false` for semantically equal painters.
 - Property-based tests (using `package:test` with a property-testing helper such as `glados` or hand-rolled generators) covering:
   - `loadGameFromFEN(F); controller.fen == F` for any round-trippable FEN in the starting-distance set.
   - `makeMove(m); undo(); fenBefore == fenAfter` for any legal move `m` from a random legal position.
   - Notification invariants: every successful `makeMove`/`undo`/`resetBoard`/`loadGameFromFEN` with `notify: true` fires exactly one listener notification per registered listener; with `notify: false` it fires zero.

**Packaging and repository hygiene**

2.30 WHEN pub.dev scores the package THEN `pubspec.yaml` SHALL declare `repository`, `issue_tracker`, `topics` (e.g. `chess`, `board`, `game`, `widget`), `platforms` (the set actually supported), and — if feasible — `screenshots` pointing at the `images/` assets, so pub.dev awards the corresponding metadata points.

2.31 WHEN `CHANGELOG.md` is inspected THEN every release entry SHALL have an ISO-8601 date or year-month, and `2.0.0` SHALL explicitly describe the breaking `playerToMove` → `playerColor` rename with migration notes; the new release SHALL also note the `isCheckmate()` → `isCheckmate` rename as breaking.

2.32 WHEN a reader opens `README.md` THEN the "arrow will be added" line SHALL be removed, a parameter reference table SHALL document every `AdvancedChessBoard` and `ChessBoardController` parameter/getter, and worked examples SHALL cover: drawing arrows, loading a FEN, flipping orientation, subscribing to controller notifications, and known limitations (e.g. no built-in clock, piece theming constraints).

**Documentation**

2.33 WHEN dartdoc is generated THEN `AdvancedChessBoard`, `ChessBoardController`, `ChessArrow`, `PlayerColor`, and every public member on those types SHALL carry `///` doc comments explaining purpose, parameters, and (where relevant) default values.

**Linting**

2.34 WHEN `flutter analyze` runs THEN `analysis_options.yaml` SHALL enable:
 - `analyzer:` block with `language: strict-casts: true`, `strict-inference: true`, `strict-raw-types: true`;
 - `linter:` rules including at least `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `always_declare_return_types`, `avoid_dynamic_calls`, and `public_member_api_docs`;
 - `flutter analyze` SHALL pass with zero errors and zero warnings after the fix is applied.

### Unchanged Behavior (Regression Prevention)

These are the behaviours that currently work and MUST continue to work after the fix. They correspond to `¬C(X)` in the bug-condition methodology.

**Chess-rule correctness**

3.1 WHEN a player makes a legal non-promotion move on a standard 8×8 board (pawn push, piece development, capture, en passant, castling short, castling long) via `controller.makeMove` or via tap/drag THEN the system SHALL CONTINUE TO update game state correctly, advance `controller.fen`, flip `controller.playerColor`, and reflect the move on screen.

3.2 WHEN a pawn reaches the promotion rank (`8` for white, `1` for black) THEN the system SHALL CONTINUE TO show a promotion dialog offering queen / rook / bishop / knight, and SHALL CONTINUE TO default to queen when the dialog is dismissed.

3.3 WHEN `game.in_checkmate` becomes `true` THEN the mated king's square SHALL CONTINUE TO be tinted with `kingBackgroundColorOnCheckmate` (defaulting to `Colors.red.withAlpha(155)`).

3.4 WHEN the board is rendered with `boardOrientation: PlayerColor.white` or `PlayerColor.black` THEN file/rank coordinates SHALL CONTINUE TO be placed correctly (rank column on file `a` for white, on file `h` for black; file row on rank `1` for white, on rank `8` for black) and arrows SHALL CONTINUE TO be drawn relative to the selected orientation.

3.5 WHEN `lightSquareColor` / `darkSquareColor` are customised THEN the board SHALL CONTINUE TO render with those colours and the file/rank label colour SHALL CONTINUE TO use the inverted colour (existing behaviour from 2.1.1).

**Controller semantics**

3.6 WHEN `controller.makeMove(from: a, to: b)` is called with an illegal move THEN the system SHALL CONTINUE TO return `false` without mutating game state.

3.7 WHEN `controller.loadGameFromFEN(validFen)` is called with a legal FEN THEN the system SHALL CONTINUE TO load that position, and `controller.fen` SHALL CONTINUE TO return a FEN that round-trips to the same position.

3.8 WHEN `controller.undo()` is called immediately after a successful `makeMove` THEN the system SHALL CONTINUE TO restore the previous position (same FEN as before the move).

3.9 WHEN `controller.resetBoard()` is called THEN the system SHALL CONTINUE TO restore the standard starting position.

3.10 WHEN any mutating controller method is called with `notify: false` THEN the system SHALL CONTINUE TO suppress listener notifications for that call (this behaviour, introduced in 2.2.0, is preserved even though the underlying notification mechanism is being repaired).

3.11 WHEN `controller.game` is accessed THEN it SHALL CONTINUE TO return the underlying `chess.Chess` object (the `game` getter stays as an escape hatch, even though new first-class getters reduce the need for it).

**Widget behaviour**

3.12 WHEN `enableMoves: false` is set THEN the board SHALL CONTINUE TO render normally, SHALL CONTINUE TO refuse all tap / drag interactions, and SHALL CONTINUE TO display pieces without grab cursors.

3.13 WHEN `highlightLastMove: true` (the default) and at least one move has been played THEN the from-square and to-square SHALL CONTINUE TO be tinted yellow.

3.14 WHEN the user taps a piece of the side to move THEN legal destination squares SHALL CONTINUE TO be highlighted with the `HighlightOverlay` (small dot on empty squares, hollow ring on squares with pieces), AND tapping the same square again SHALL CONTINUE TO deselect.

3.15 WHEN the user drags a piece and drops it on a legal square THEN the move SHALL CONTINUE TO be made; dropping on an illegal square SHALL CONTINUE TO leave state unchanged.

3.16 WHEN `arrows: [...]` is passed THEN each `ChessArrow` SHALL CONTINUE TO be drawn as a line plus equilateral-triangle arrowhead sized from `blockSize`, respecting its `color` (default `Colors.amber.withAlpha(128)`).

**Existing passing tests and tooling**

3.17 WHEN `flutter analyze` runs on code paths unrelated to the new strict rules THEN previously-clean code SHALL CONTINUE TO pass.

3.18 WHEN the example app is run THEN the "Flip", "Undo", and "Load Fen" buttons SHALL CONTINUE TO work, and the three demo arrows (e2-e4, e7-e5, g1-f3 red) SHALL CONTINUE TO render at startup.

3.19 WHEN any consumer that imported via the deep paths (`package:advanced_chess_board/chess_board_controller.dart`, etc.) upgrades THEN — because the file reorganisation is a breaking change covered in section 2.16 — the `CHANGELOG.md` SHALL document a migration, but for consumers that already used only the top-level `package:advanced_chess_board/advanced_chess_board.dart` import the imported symbols SHALL CONTINUE TO resolve (after the barrel export is added).

3.20 WHEN `pubspec.yaml` is parsed THEN the existing `name`, `description`, `version`, `homepage`, `environment`, `dependencies`, `dev_dependencies`, and asset declarations SHALL CONTINUE TO be valid; new metadata fields are additive only.
