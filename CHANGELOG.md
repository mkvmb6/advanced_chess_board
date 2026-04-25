## 3.0.0 — 2026-04-19

### Breaking changes
- `ChessBoardController.isCheckmate()` is now a getter. Migrate call sites
  from `controller.isCheckmate()` to `controller.isCheckmate`.
- Implementation files moved under `lib/src/`. Importing from deep paths
  (e.g. `package:advanced_chess_board/chess_board_controller.dart`) no longer
  works. Use the single top-level import
  `package:advanced_chess_board/advanced_chess_board.dart`, which now re-exports
  `AdvancedChessBoard`, `ChessBoardController`, `ChessArrow`, and `PlayerColor`.

### Fixes
- `ChessBoardController` now correctly supports multiple listeners
  (previously only the most recently registered callback fired).
- `ArrowPainter.shouldRepaint` no longer suppresses repaints when the arrow
  list or board orientation changes.
- Destination-square highlighting uses the `chess` engine's verbose moves and
  no longer mis-identifies squares whose name is a substring of a SAN token.
- `dispose` ordering in the controller follows the `ChangeNotifier` contract.

### Additions
- Controller getters: `isInCheck`, `isStalemate`, `isDraw`, `isGameOver`,
  `history`, `pgn`, `moveCount`.
- Automatic widget rebuild on controller notifications; no need for the
  consumer to call `controller.addListener(setState)`.
- Move animations on tap and programmatic moves (configurable via
  `moveAnimationDuration`).
- `Semantics` wrappers on squares and pieces for screen-reader support.

### Polish
- Dead-code returns removed; strict-casts / strict-inference / strict-raw-types
  enabled and all public members carry dartdoc.
- Promotion dialog piece size follows the current board square size.
- Drag feedback is clamped on narrow screens.
- File/rank labels have a minimum font size floor.
- Board layout uses `Column` of `Row`s — no scrollable viewport.
- Piece images are `precacheImage`'d on the first `didChangeDependencies`.

## 2.3.0 — 2025-03-11

- Chess piece is scaled while dragging.
- Checkmated king is highlighted with customisable colour (default red).

## 2.2.0 — 2025-01-28

- Added parameter to call controller methods without notifying listeners.

## 2.1.1 — 2024-12-15

- Changed colours of file and rank text to inverted colours of squares.

## 2.1.0 — 2024-11-02

- Squares related to last-played move are highlighted by default.

## 2.0.0 — 2024-10-10

- **Breaking**: `playerToMove` renamed to `playerColor` on `ChessBoardController`.
  The same rename applies to the `boardOrientation` values on
  `AdvancedChessBoard`. Migrate by replacing every `playerToMove` read on the
  controller with `playerColor`, and every `PlayerToMove.white`/`black` enum
  reference used as a `boardOrientation` with `PlayerColor.white`/`black`.
- Added arrows (`arrows:` parameter on `AdvancedChessBoard`).

## 1.2.1 — 2024-08-20

- Renamed `playerToMove` to `playerColor` (see 2.0.0 for migration).

## 1.2.0 — 2024-07-30

- Added `playerToMove` on the controller.

## 1.1.1 — 2024-06-15

- Minor layout fixes.

## 1.1.0 — 2024-05-22

- Fixed listener not firing on moves.

## 1.0.3 — 2024-04-08

- Updated `flutter_lints` to `^5.0.0`.

## 1.0.2 — 2024-03-12

- Added `enableMoves` parameter.

## 1.0.1 — 2024-02-28

- Removed unused `chess_vectors_flutter` dependency.

## 1.0.0 — 2024-02-10

- Initial release of advanced_chess_board.
