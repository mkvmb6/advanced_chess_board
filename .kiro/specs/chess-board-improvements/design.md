# Chess Board Improvements Bugfix Design

## Overview

`advanced_chess_board` 2.3.0 is functionally close but carries a cluster of correctness, API, UX, a11y, testing and packaging defects. This design reshapes the package into a 3.0.0 release that is correct, idiomatic Flutter, strict-lint-clean, property-tested, and pub.dev-friendly, while preserving all currently-correct chess behaviour (see `bugfix.md` section 3).

The fix is organised by concern, not per clause. Each workstream below maps to one or more corrective clauses in `bugfix.md` (referenced as `§2.x`). The design is forward-looking — it specifies the target shape, not the current shape.

Version bump: **2.3.0 → 3.0.0** (breaking: `isCheckmate()` → `isCheckmate`, file moves under `lib/src/`). Consumers importing only the top-level barrel `package:advanced_chess_board/advanced_chess_board.dart` experience no import-level break.

## Glossary

- **Bug_Condition (C)**: The union of all trigger conditions enumerated in `bugfix.md §1.1–§1.34`. The package exhibits the bug condition on any input where the defective behaviour described there surfaces.
- **Property (P)**: The package satisfies the corrective behaviour described in `bugfix.md §2.1–§2.34` for that same input.
- **Preservation**: The behaviours in `bugfix.md §3.1–§3.20` continue to hold byte-for-byte after the fix.
- **Controller**: `ChessBoardController`, the public facade that wraps a `chess.Chess` instance and is a `ChangeNotifier`.
- **Barrel**: `lib/advanced_chess_board.dart` — the single public import surface after reorganisation.
- **Verbose move**: A legal move in map form as returned by `chess.Chess.moves({'square': X, 'verbose': true})` with fields `from`, `to`, `flags`, `piece`, `promotion`, etc. Used as the oracle for legal destinations.
- **Exploration test**: A test run against **unfixed** code to reproduce a bug condition and validate the root cause.
- **Fix test**: A test run against **fixed** code proving the bug condition is eliminated.
- **Preservation test**: A property-based test proving `¬C(X) ⇒ F(X) == F'(X)` for all non-bug inputs.

## Bug Details

### Bug Condition

The package exhibits a compound bug condition: any input (interactive, API, static-analysis, or packaging) for which the behaviours enumerated in `bugfix.md §1.1–§1.34` occur. The forward-looking formalisation below states the condition the **fixed** implementation must satisfy.

**Formal Specification:**

```
FUNCTION isBugCondition(input)
  INPUT: input of type PackageInput
         (one of: ControllerCall, WidgetInteraction, PaintCall,
                  StaticAnalysis, PubMetadataCheck, DocCheck, TestRun)
  OUTPUT: boolean

  // Any one of the defective trigger conditions listed in bugfix.md §1.x holds.
  RETURN (exists k in 1..34 such that triggerCondition_k(input) holds)
END FUNCTION

FUNCTION expectedBehavior(result)
  // For every clause k whose trigger held on the input, the behaviour in
  // bugfix.md §2.k is observed.
  RETURN (for all k in 1..34 such that triggerCondition_k(input):
            observedBehavior(result) matches expectedClause_k)
END FUNCTION
```

### Examples

- **Listener drop (§1.1)**: two calls to `controller.addListener(...)` then `controller.makeMove(...)` — only the second listener fires. Expected: both fire.
- **SAN substring (§1.6)**: from `b1` with knight available, `moves({'square':'b1'})` returns `['Nb1-c3','Nb1-a3']` (SAN variants); the current `move.contains('a1')` matches on `"a"`-bearing strings via substring search. Expected: an explicit `verbose: true` lookup compares `m['to'] == target`.
- **Arrow painter (§1.4)**: swap `arrows` list by adding a new `ChessArrow(...)`; canvas does not repaint. Expected: repaint fires.
- **Consumer boilerplate (§1.8)**: `AdvancedChessBoard(controller: c)` without `c.addListener(setState)` — UI does not update after `c.makeMove`. Expected: widget self-subscribes.
- **Drag scale clip (§1.26)**: on a 200 px board (square ≈ 25 px), dragging scales feedback to ≈ 29 px and clips neighbours. Expected: clamped.
- **Dead code (§1.10)**: `flutter analyze` with strict rules flags the trailing `return const Text("No piece found")`. Expected: removed; analyse clean.

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors** (mirroring `bugfix.md §3.1–§3.20`):

- All legal move generation, execution, undo, reset, FEN round-trip (`§3.1, §3.7–§3.9`).
- Promotion dialog options and queen default (`§3.2`).
- Checkmate tint rendering (`§3.3`).
- Orientation-dependent coordinate label placement and arrow drawing (`§3.4`).
- Custom `lightSquareColor` / `darkSquareColor` and inverted label colour (`§3.5`).
- Illegal-move rejection (`§3.6, §3.15`).
- `notify: false` suppresses listener notifications (`§3.10`).
- `controller.game` escape hatch (`§3.11`).
- `enableMoves: false` render-only mode (`§3.12`).
- Last-move yellow tint on `from`/`to` (`§3.13`).
- Tap-to-select, tap-same-to-deselect, highlight dots and rings (`§3.14`).
- Arrow geometry (line + equilateral triangle), default colour `Colors.amber.withAlpha(128)` (`§3.16`).
- Example app buttons (Flip / Undo / Load Fen) and the three demo arrows (`§3.18`).
- Existing top-level barrel import keeps resolving for consumers that already imported only `package:advanced_chess_board/advanced_chess_board.dart` (`§3.19`).
- Existing `pubspec.yaml` keys remain valid (`§3.20`).

**Scope:**
All inputs that do NOT match any clause in `bugfix.md §1.1–§1.34` remain untouched:
- Mouse click and keyboard input flows unrelated to the defects above.
- Existing chess-rule edge cases (en passant, castling, promotion) — new tests codify them but the behaviour is already correct.
- Any consumer relying on `controller.game` directly.

Actual corrective behaviour is defined in **Correctness Properties** (Property 1 family). This section only pins what must NOT change.

## Hypothesized Root Cause

The defects share a small number of underlying causes. Each root cause maps to multiple clauses.

1. **Shadowed `ChangeNotifier` plumbing** (`§1.1, §1.2, §1.3`): `ChessBoardController` overrides `addListener` to store a single `VoidCallback?`, never delegates to `super`, and disposes in the wrong order. Replacing the override with inherited `ChangeNotifier` behaviour fixes all three.
2. **Inverted boolean logic in `CustomPainter.shouldRepaint`** (`§1.4, §1.5`): the method returns `false` on inequality and `true` on equality, and ignores `boardOrientation`. Correct the logic and include orientation in equality.
3. **String-based SAN matching** (`§1.6`): SAN strings contain the destination square as a substring of larger tokens. The `chess` package's `verbose: true` option returns structured `from/to/flags`; using that eliminates false positives and handles castling via flags (`k`/`q`) rather than special-cased `"O-O"`/`"O-O-O"` strings.
4. **Missing widget-level subscription** (`§1.8, §1.9`): the widget binds `game` in `initState` and never listens. Wrapping `_buildChessBoard` in `ListenableBuilder(listenable: widget.controller)` plus `didUpdateWidget` unsubscribe/rebind fixes both.
5. **Lax static analysis** (`§1.10–§1.12, §1.33, §1.34`): the default `flutter_lints` profile permits dead code, raw `dynamic`, and undocumented public members. Strict-casts / strict-inference / strict-raw-types plus `public_member_api_docs` surface these for removal.
6. **Thin controller API leaking `chess`** (`§1.13, §1.14`): consumers reach into `controller.game` because first-class getters are missing. Promoting common chess state to the controller, and switching `isCheckmate()` to a getter, restores consistency.
7. **Public import sprawl** (`§1.15, §1.16`): every file lives directly under `lib/`. Moving implementation under `lib/src/` and re-exporting only the public API through the barrel cleans the surface.
8. **Imperative `setState` and defensive placeholders** (`§1.17–§1.21, §1.22, §1.23`): tap handling and last-move highlighting over-rebuild and emit `Container()` placeholders. Guarding early returns, using `SizedBox.shrink`, and caching piece images in `didChangeDependencies` removes waste; `Column`-of-`Row`s replaces the unnecessary `GridView`.
9. **Hard-coded sizes and missing animation** (`§1.24–§1.26`): promotion dialog and drag feedback use magic numbers and nothing interpolates piece positions. Passing `squareSize` through and using `AnimatedPositioned` on an overlay layer fixes these.
10. **Missing a11y/i18n hooks** (`§1.27, §1.28`): no `Semantics` wrappers and no font floor. Straightforward additions.
11. **Missing tests, metadata, docs** (`§1.29–§1.34`): purely additive — new tests, pub.dev keys, dartdoc, strict analyser config.

## Correctness Properties

These properties are the single source of truth for PBT traceability. Each property is validated by one or more tests in the testing strategy section.

Property 1: Bug Condition — Correct behaviour across all corrective clauses

_For any_ input where the bug condition holds (any of `bugfix.md §1.1–§1.34` triggers), the fixed package SHALL exhibit the corresponding behaviour in `bugfix.md §2.1–§2.34`.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 2.10, 2.11, 2.12, 2.13, 2.14, 2.15, 2.16, 2.17, 2.18, 2.19, 2.20, 2.22, 2.23, 2.24, 2.25, 2.26, 2.27, 2.28, 2.29, 2.30, 2.31, 2.32, 2.33, 2.34**

Property 1 decomposes into the following executable sub-properties. Each P1.x is exercised by a named PBT or example test.

- **P1.1 Multi-listener fan-out.** _For any_ `n ∈ [1,10]` listeners attached to a single controller, every mutation with `notify: true` invokes each listener exactly once. **Validates: 2.1, 2.2**
- **P1.2 Dispose ordering.** _For_ any sequence of `addListener → mutation → dispose`, dispose completes without throwing and `super.dispose()` runs last. **Validates: 2.3**
- **P1.3 Arrow painter repaint iff semantic change.** _For any_ pair `(old, new)` of `ArrowPainter` states, `shouldRepaint(old)` returns `true` iff `old.arrows ≠ new.arrows` OR `old.orientation ≠ new.orientation`. **Validates: 2.4, 2.5**
- **P1.4 Verbose-move destination oracle.** _For any_ random reachable `chess.Chess` position, any source square `X` with at least one legal move, and any candidate destination `Y ∈ {a1..h8}`: `_isLegalDestination(game, X, Y)` returns `true` iff there exists a verbose move `m` with `m.from == X ∧ m.to == Y`. Castling targets (`g1`, `c1`, `g8`, `c8`) are matched via the verbose `flags` (`k`/`q`), not via SAN string comparison. **Validates: 2.6**
- **P1.5 Controller getter oracle parity.** _For any_ random reachable position, each new controller getter (`isInCheck`, `isCheckmate`, `isStalemate`, `isDraw`, `isGameOver`, `history`, `pgn`, `moveCount`) equals its underlying `controller.game` source of truth. **Validates: 2.13, 2.14**
- **P1.6 Widget auto-rebuild on controller mutation.** For a widget pumped with only `controller: c` (no external `addListener(setState)`), every successful mutation via `c` triggers a rebuild of `AdvancedChessBoard`. **Validates: 2.8**
- **P1.7 Controller swap via didUpdateWidget.** When `widget.controller` is replaced, the widget unsubscribes from the old controller and subscribes to the new; mutations on the old controller no longer rebuild, mutations on the new controller do. **Validates: 2.9**
- **P1.8 No redundant setState on no-op tap.** _For any_ square `s`: tapping `s` with `enableMoves == false` OR tapping an empty square `s` with `selectedSquare == null` does NOT increment the widget rebuild counter. **Validates: 2.17, 2.18**
- **P1.9 Last-move highlight absent off-move.** _For any_ move `m` just played and any square `s ∉ {m.from, m.to}`: the last-move highlight slot for `s` is `SizedBox.shrink` (or not present in the `Stack`). **Validates: 2.19**
- **P1.10 Single highlight on selected = last-move.** When selected square equals a last-move square, exactly one yellow overlay renders. **Validates: 2.20**
- **P1.11 No scrollable viewport in board layout.** The rendered board tree contains no `GridView` / `Scrollable` and contains 8 `Row` widgets of 8 children each. **Validates: 2.22**
- **P1.12 Piece images precached.** After first `didChangeDependencies`, all 12 piece asset providers resolve synchronously on subsequent rebuilds (no intermediate frame with empty piece). **Validates: 2.23**
- **P1.13 Dynamic promotion dialog size.** _For any_ rendered `squareSize ∈ [24, 128]`, the promotion dialog piece widget's width equals `squareSize` (within rounding). **Validates: 2.24**
- **P1.14 Move animation fires on tap/programmatic moves only.** After a tap move or `controller.makeMove(...)`, an `AnimatedPositioned` transition is observable on the moving piece; after a drag-drop move, no transition is observable (piece appears at destination immediately). **Validates: 2.25**
- **P1.15 Clamped drag feedback.** _For any_ `boardWidth ∈ [160, 1600]` with `squareSize = boardWidth / 8`, the rendered drag feedback widget's width satisfies `feedbackWidth ≤ squareSize * maxFeedbackScale` with `maxFeedbackScale ≤ 1.15` AND `feedbackWidth ≤ squareSize + maxFeedbackOverflowPx`. **Validates: 2.26**
- **P1.16 Semantics labels per square.** _For any_ square `s` with piece `p` (or empty), there is a `Semantics` node whose `label` matches the format `"{s}, {pieceDescription}"` or `"{s}, empty"`, and for draggable pieces the node carries the `button` trait. **Validates: 2.27**
- **P1.17 Minimum label font size.** _For any_ `squareSize ∈ (0, 1000]`, the coordinate label `TextStyle.fontSize` equals `max(minLabelFontSize, squareSize * 0.18)` with `minLabelFontSize == 9`. **Validates: 2.28**
- **P1.18 Pub.dev metadata present.** Parsing `pubspec.yaml` yields non-empty `repository`, `issue_tracker`, `topics`, `platforms`. **Validates: 2.30**
- **P1.19 Dated CHANGELOG.** Every release header in `CHANGELOG.md` matches `/^## \d+\.\d+\.\d+ — \d{4}-\d{2}-\d{2}$/`. **Validates: 2.31**
- **P1.20 README refresh.** `README.md` contains a parameter reference table, contains no "arrow will be added" sentence, and references `ChessBoardController` getters. **Validates: 2.32**
- **P1.21 Strict analyse clean.** `flutter analyze` exits 0 with the new `analysis_options.yaml`. **Validates: 2.10, 2.11, 2.12, 2.33, 2.34**
- **P1.22 Barrel resolves public API.** A compile-time test file that imports only `package:advanced_chess_board/advanced_chess_board.dart` references `AdvancedChessBoard`, `ChessBoardController`, `ChessArrow`, `PlayerColor` without error. **Validates: 2.15, 2.16**
- **P1.23 Example flutter_lints version parity.** `example/pubspec.yaml` declares `flutter_lints: ^5.0.0`. **Validates: 2.7**

Property 2: Preservation — Unchanged behaviour outside the bug condition

_For any_ input where the bug condition does NOT hold (`bugfix.md §3.1–§3.20`), the fixed package SHALL produce the same observable result as the pre-fix package, preserving all chess-rule correctness, controller semantics, render behaviour, packaging validity, and example-app demo behaviour listed in `bugfix.md §3`.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10, 3.11, 3.12, 3.13, 3.14, 3.15, 3.16, 3.17, 3.18, 3.19, 3.20**

Property 2 decomposes into:

- **P2.1 FEN round-trip.** `loadGameFromFEN(F); controller.fen == canonicalise(F)` for any valid FEN. **Validates: 3.7**
- **P2.2 Move/undo identity.** For any legal move `m` from any reachable position `P`: `fen(P) == fen(P.makeMove(m).undo())`. **Validates: 3.8**
- **P2.3 Reset is starting position.** `resetBoard(); controller.fen == STARTING_FEN`. **Validates: 3.9**
- **P2.4 Illegal move rejection.** For any illegal `(from, to)` on any reachable position, `makeMove` returns `false` and `fen` is unchanged. **Validates: 3.6, 3.15**
- **P2.5 `notify: false` suppression.** For any mutating call with `notify: false`, zero listener invocations occur. **Validates: 3.10**
- **P2.6 Arrow default geometry and colour.** `ChessArrow(startSquare: a, endSquare: b)` has `color == Colors.amber.withAlpha(128)`, and `ArrowPainter` renders a main line plus equilateral triangle arrowhead sized from `blockSize`. **Validates: 3.16**
- **P2.7 Checkmate tint preserved.** In a mate position, the mated-king square renders a container with colour `kingBackgroundColorOnCheckmate ?? Colors.red.withAlpha(155)` behind the king piece. **Validates: 3.3**
- **P2.8 enableMoves=false is render-only.** Taps and drags do not mutate state; piece cursor is `basic`. **Validates: 3.12**
- **P2.9 Last-move yellow on from+to.** After a move, both `from` and `to` squares carry the yellow last-move tint (alpha 128). **Validates: 3.13**
- **P2.10 Select/deselect legal-move highlights.** Tapping own piece highlights legal destinations with `HighlightOverlay`; tapping same square deselects. **Validates: 3.14**
- **P2.11 Escape hatch remains.** `controller.game` continues to return the underlying `chess.Chess`. **Validates: 3.11**
- **P2.12 Top-level import still resolves.** Pre-3.0.0 consumers importing `package:advanced_chess_board/advanced_chess_board.dart` and referring to `AdvancedChessBoard` still compile. **Validates: 3.19**
- **P2.13 Pubspec additive validity.** All pre-existing `pubspec.yaml` keys (`name`, `version`, `dependencies`, asset list, etc.) remain valid; 3.0.0 only adds keys. **Validates: 3.20**

## Fix Implementation

### Changes Required

Organised by concern. Each subsection lists the files touched and the specific change.

### 1. Correctness fixes in existing files (§2.1–§2.7)

**File**: `lib/src/chess_board_controller.dart` (moved from `lib/chess_board_controller.dart`)

**Function / state**: `ChessBoardController` class body.

1. **Delete listener shadowing** (§2.1, §2.2):
   - Remove `VoidCallback? _listener`.
   - Remove the overrides of `addListener`.
   - Remove the private `_notifyListeners()` helper.
   - Replace every call to `_notifyListeners()` with `notifyListeners()` from `ChangeNotifier`.

2. **Correct dispose ordering** (§2.3):
   - Keep an explicit `dispose()` only if there is controller-owned state to release (there is none beyond `ChangeNotifier`'s internal list). If overridden, call `super.dispose()` **last**.

3. **Promote `isCheckmate()` to a getter and add new getters** (§2.13, §2.14):
   - `bool get isCheckmate => game.in_checkmate;`
   - `bool get isInCheck => game.in_check;`
   - `bool get isStalemate => game.in_stalemate;`
   - `bool get isDraw => game.in_draw;`
   - `bool get isGameOver => game.game_over;`
   - `List<State> get history => List.unmodifiable(game.history);` — returns an unmodifiable view; the element type stays `chess.State` so the leak of the `chess` type is explicit and documented, while `List.unmodifiable` prevents mutation.
   - `String get pgn => game.pgn();`
   - `int get moveCount => game.history.length;`

**File**: `lib/src/utils/arrow_painter.dart`

1. **Rewrite `shouldRepaint`** (§2.4, §2.5):

   ```dart
   @override
   bool shouldRepaint(covariant ArrowPainter old) {
     if (old.boardOrientation != boardOrientation) return true;
     if (old.arrows.length != arrows.length) return true;
     for (var i = 0; i < arrows.length; i++) {
       if (arrows[i] != old.arrows[i]) return true;
     }
     return false;
   }
   ```

**File**: `lib/src/advanced_chess_board.dart`

1. **Replace `_isSquarePartOfValidMoves` with a verbose-moves helper** (§2.6):

   ```dart
   bool _isLegalDestination(String from, String to) {
     final verbose = game.generate_moves({'square': from});
     for (final m in verbose) {
       if (m.toAlgebraic == to) return true;
     }
     return false;
   }
   ```

   Castling (`O-O`, `O-O-O`) keeps working automatically because `generate_moves` returns the actual king destination square (`g1`/`c1`/`g8`/`c8`) in `m.toAlgebraic`; the special-cased SAN strings `"O-O"`/`"O-O-O"` are removed.

   Rename `legalMoves` from `Set<String>` (SAN) to `Set<String>` (of `to` squares), populated via:

   ```dart
   void _setSelectedSquareAndFindLegalMoves(String square) {
     selectedSquare = square;
     legalMoves = {
       for (final m in game.generate_moves({'square': square}))
         m.toAlgebraic,
     };
   }
   ```

   Callers compare `legalMoves.contains(square)` directly (no substring matching).

**File**: `example/pubspec.yaml`

1. **Bump `flutter_lints`** (§2.7): `flutter_lints: ^5.0.0` under `dev_dependencies`.

### 2. Controller/widget coupling (§2.8, §2.9)

**File**: `lib/src/advanced_chess_board.dart`

1. **Self-subscribe via `ListenableBuilder`** (§2.8):
   - Wrap the inner `Stack` returned by `LayoutBuilder.builder` in `ListenableBuilder(listenable: widget.controller, builder: (_, __) => ...)`.
   - Rebinding `game` every build: `final game = widget.controller.game;` inside the builder.
   - Remove the `late chess.Chess game;` field and `game = widget.controller.game` in `initState`.

2. **Handle controller swap in `didUpdateWidget`** (§2.9):
   - No explicit `addListener` is needed because `ListenableBuilder` manages subscription. But if direct subscription is chosen instead (e.g. for finer `setState` control), add:

     ```dart
     @override
     void didUpdateWidget(covariant AdvancedChessBoard old) {
       super.didUpdateWidget(old);
       if (old.controller != widget.controller) {
         // ListenableBuilder swap happens automatically because the listenable
         // reference changes each build; no manual resubscribe needed.
       }
     }
     ```

   The design picks `ListenableBuilder` because it auto-swaps subscriptions when the `listenable` identity changes, eliminating the manual unsubscribe/resubscribe dance.

### 3. Dead code, typing, API hygiene (§2.10–§2.14)

**File**: `lib/src/utils/utils.dart`

1. Delete the trailing `return const Text("No piece found");` from `getChessPieceWidget` (§2.10).
2. Delete the trailing `return "q";` from `pieceTypeToString` (§2.11).
3. Type the private helper signature (§2.12): `Widget _getPieceImageWidget(String assetPath) { ... }`.

Exhaustive switch coverage over `chess.Color` × `PieceType` and `PieceType` respectively satisfies the return-path requirement once strict-inference is on.

### 4. Public API reorganisation (§2.15, §2.16)

**Target `lib/` layout after reorganisation:**

```
lib/
├── advanced_chess_board.dart        # barrel; only this file is public
└── src/
    ├── advanced_chess_board.dart    # AdvancedChessBoard widget
    ├── chess_board_controller.dart  # ChessBoardController
    ├── constants/
    │   ├── global_constants.dart
    │   └── image_constants.dart
    ├── models/
    │   ├── chess_arrow.dart         # ChessArrow
    │   └── enums.dart               # PlayerColor
    ├── utils/
    │   ├── arrow_painter.dart
    │   └── utils.dart
    └── widgets/
        ├── chess_piece_widget.dart
        ├── chess_square.dart
        └── highlight_overlay.dart
```

**File moves (atomic, via smartRelocate so cross-file imports update automatically):**

| From | To |
|------|----|
| `lib/advanced_chess_board.dart` (widget impl) | `lib/src/advanced_chess_board.dart` |
| `lib/chess_board_controller.dart` | `lib/src/chess_board_controller.dart` |
| `lib/constants/global_constants.dart` | `lib/src/constants/global_constants.dart` |
| `lib/constants/image_constants.dart` | `lib/src/constants/image_constants.dart` |
| `lib/models/chess_arrow.dart` | `lib/src/models/chess_arrow.dart` |
| `lib/models/enums.dart` | `lib/src/models/enums.dart` |
| `lib/utils/arrow_painter.dart` | `lib/src/utils/arrow_painter.dart` |
| `lib/utils/utils.dart` | `lib/src/utils/utils.dart` |
| `lib/widgets/chess_piece_widget.dart` | `lib/src/widgets/chess_piece_widget.dart` |
| `lib/widgets/chess_square.dart` | `lib/src/widgets/chess_square.dart` |
| `lib/widgets/highlight_overlay.dart` | `lib/src/widgets/highlight_overlay.dart` |

**New barrel `lib/advanced_chess_board.dart`:**

```dart
/// Advanced Chess Board — a customizable Flutter chess-board widget with
/// drag/drop, arrows, FEN loading, and a ChangeNotifier-based controller.
library;

export 'src/advanced_chess_board.dart' show AdvancedChessBoard;
export 'src/chess_board_controller.dart' show ChessBoardController;
export 'src/models/chess_arrow.dart' show ChessArrow;
export 'src/models/enums.dart' show PlayerColor;
```

Internal files under `lib/src/` import each other with relative paths (e.g. `import '../models/enums.dart';`); they are not publicly importable by design.

### 5. New `ChessBoardController` public API (§2.13, §2.14)

```dart
class ChessBoardController extends ChangeNotifier {
  final chess.Chess _game = chess.Chess();

  /// Escape hatch to the underlying `chess` engine. Prefer the typed getters
  /// below; this stays for advanced use cases.
  chess.Chess get game => _game;

  /// Current FEN of the position.
  String get fen => _game.fen;

  /// Side to move.
  PlayerColor get playerColor =>
      _game.turn == chess.Color.WHITE ? PlayerColor.white : PlayerColor.black;

  /// True when the side to move is in check.
  bool get isInCheck => _game.in_check;

  /// True when the side to move is checkmated.
  bool get isCheckmate => _game.in_checkmate;

  /// True when the position is stalemate.
  bool get isStalemate => _game.in_stalemate;

  /// True when the position is drawn by rule (50-move, 3-fold, insufficient
  /// material, or stalemate).
  bool get isDraw => _game.in_draw;

  /// True when the game has ended by any rule.
  bool get isGameOver => _game.game_over;

  /// Unmodifiable view of the move history (chess.State objects).
  List<chess.State> get history => List.unmodifiable(_game.history);

  /// Standard PGN of the game so far.
  String get pgn => _game.pgn();

  /// Number of plies played.
  int get moveCount => _game.history.length;

  /// Reset to starting position. Fires listeners unless `notify: false`.
  void resetBoard({bool notify = true}) { ... }

  /// Attempt a move. Returns true on success. Fires listeners on success
  /// unless `notify: false`.
  bool makeMove({
    required String from,
    required String to,
    String? promotion,
    bool notify = true,
  }) { ... }

  /// Undo the last move. Fires listeners unless `notify: false`.
  void undo({bool notify = true}) { ... }

  /// Load a FEN. Fires listeners unless `notify: false`.
  void loadGameFromFEN(String fen, {bool notify = true}) { ... }
}
```

**Backwards-compatibility story for `isCheckmate()` → `isCheckmate`:**

This is a breaking change. The design does **not** provide a deprecated forwarding method because:

- The rename lines up the controller with the getter-style API of `fen`, `playerColor`, etc.
- Keeping a deprecated `bool isCheckmate()` alongside a `bool get isCheckmate` produces a name clash; Dart disallows a method and a getter with the same name on the same class.
- 3.0.0 is already breaking due to the `lib/src/` reorganisation, so this rename is batched into the same bump.

Migration documented in `CHANGELOG.md` under `## 3.0.0 — YYYY-MM-DD`:

```
- BREAKING: `ChessBoardController.isCheckmate()` is now a getter — rename
  call sites from `controller.isCheckmate()` to `controller.isCheckmate`.
- BREAKING: internal implementation moved to `lib/src/`. If you were
  importing deep paths like `package:advanced_chess_board/chess_board_controller.dart`,
  switch to `package:advanced_chess_board/advanced_chess_board.dart`.
```

### 6. Rendering / UX (§2.17–§2.26)

**File**: `lib/src/advanced_chess_board.dart`

1. **Guarded `setState` in `_handleTap`** (§2.17, §2.18):

   ```dart
   Future<void> _handleTap(String square) async {
     if (!widget.enableMoves) return;                     // §2.17: no setState
     final tappedPiece = game.get(square);
     if (selectedSquare == null && tappedPiece == null) { // §2.18: no setState
       return;
     }
     // ... existing branching; setState only on state mutations
   }
   ```

2. **`SizedBox.shrink` for off-last-move** (§2.19):

   ```dart
   Widget _buildLastMoveHighlight(String square) {
     if (game.history.isEmpty) return const SizedBox.shrink();
     final lastMove = game.history.last.move;
     if (square == lastMove.fromAlgebraic || square == lastMove.toAlgebraic) {
       return ColoredBox(color: Colors.yellow.withAlpha(128));
     }
     return const SizedBox.shrink();
   }
   ```

3. **Single highlight when selected == last-move** (§2.20): gate the last-move overlay on `square != selectedSquare`.

4. **Checkmate tint preservation** (§2.21): no change beyond the off-last-move cleanup; order inside the `Stack` stays (tint below, piece above).

5. **Column-of-Rows layout** (§2.22):

   ```dart
   Widget _buildChessBoard(double squareSize) {
     return Column(
       mainAxisSize: MainAxisSize.min,
       children: List.generate(8, (row) {
         return Row(
           mainAxisSize: MainAxisSize.min,
           children: List.generate(8, (col) {
             final rank = widget.boardOrientation == PlayerColor.white
                 ? (7 - row) + 1 : row + 1;
             final file = widget.boardOrientation == PlayerColor.white
                 ? files[col] : files[7 - col];
             final square = '$file$rank';
             final isLight = (row + col).isEven;
             return SizedBox(
               width: squareSize, height: squareSize,
               child: _buildSquareWithDragTarget(
                 square,
                 isLight ? widget.lightSquareColor : widget.darkSquareColor,
                 isLight ? widget.darkSquareColor : widget.lightSquareColor,
                 squareSize,
               ),
             );
           }),
         );
       }),
     );
   }
   ```

6. **`precacheImage` in `didChangeDependencies`** (§2.23):

   ```dart
   bool _precached = false;

   @override
   void didChangeDependencies() {
     super.didChangeDependencies();
     if (_precached) return;
     _precached = true;
     for (final asset in _allPieceAssetPaths) {
       precacheImage(AssetImage(asset, package: packageName), context);
     }
   }
   ```

   `_allPieceAssetPaths` is a `const` list of the 12 constants in `PieceImages`.

7. **Dynamic promotion dialog size** (§2.24):

   ```dart
   Future<chess.PieceType> _showPromotionDialog(
     BuildContext context, double squareSize,
   ) async { /* squareSize now comes from LayoutBuilder, not 60 */ }
   ```

   Call site in `_makeMove(from, to)` passes the current `squareSize` captured by the enclosing builder.

8. **Move animations — AnimatedPositioned on an overlay layer** (§2.25):

   **Decision: AnimatedPositioned on an overlay `Stack` layer above the 8×8 grid.** Rationale:
   - `AnimatedSwitcher` per square cross-fades old ↔ new piece, which looks wrong for a chess move (it does not convey translation).
   - `AnimatedPositioned` inside a single board-sized `Stack` supports true (x, y) interpolation for exactly the moving piece.
   - A board-sized overlay layer decouples the animation from the square grid's layout — the grid below can be a dumb `Column`-of-`Row`s and never rebuilds per frame during animation.

   Sketch:

   ```dart
   Stack(children: [
     _buildChessBoard(squareSize),                      // dumb grid
     if (_animatingMove != null)                        // one overlay layer
       _MoveAnimationLayer(
         move: _animatingMove!,                         // from,to,piece
         squareSize: squareSize,
         orientation: widget.boardOrientation,
         duration: widget.moveAnimationDuration,        // new param, default 150ms
         onComplete: () => setState(() => _animatingMove = null),
       ),
     IgnorePointer(                                     // arrows unchanged
       child: CustomPaint(
         painter: ArrowPainter(widget.arrows, widget.boardOrientation),
         child: const SizedBox.expand(),
       ),
     ),
   ]);
   ```

   **Drag interaction exclusion**: the animation only fires when `_makeMove` is called from a tap path or a direct `controller.makeMove(...)`. The drag-drop path already interpolates visually via `Draggable.feedback` following the pointer, so animating again on drop would produce a double-motion. Implementation: a boolean `_suppressNextAnimation` set to `true` in the `DragTarget.onAcceptWithDetails` callback and cleared after the next `makeMove`.

9. **Clamped drag scale** (§2.26):

   ```dart
   static const _maxFeedbackScale = 1.15;
   static const _maxFeedbackOverflowPx = 8.0;

   double _dragFeedbackSize(double squareSize) {
     final scaled = squareSize * _maxFeedbackScale;
     final clamped = squareSize + _maxFeedbackOverflowPx;
     return scaled < clamped ? scaled : clamped;
   }
   ```

   Used at the `feedback:` parameter of the `Draggable`.

### 7. Accessibility and i18n (§2.27, §2.28)

**File**: `lib/src/widgets/chess_square.dart` and `lib/src/widgets/chess_piece_widget.dart`

1. **Semantics wrapping** (§2.27):
   - `ChessSquare` wraps its `Container` in `Semantics(label: '$square, $pieceDescription', button: onTap != null, child: ...)` where `pieceDescription` is `"white pawn"`/`"black knight"`/`"empty"`.
   - `ChessPieceWidget` adds `Semantics(label: pieceLabel, button: isBoardEnabled, child: ...)`; when rendered inside a `Draggable`, the outer wrapper carries the draggable affordance announcement.

2. **Minimum label font size** (§2.28):
   - Add `const double minLabelFontSize = 9.0;` to `lib/src/constants/global_constants.dart`.
   - In `ChessSquare._buildTextWidget`, compute `fontSize: max(minLabelFontSize, squareSize * 0.18)` via `dart:math`.

### 8. Property-based testing harness (§2.29)

**Dependency choice.** `glados` is preferred for Dart PBT because it integrates natively with `package:test`, ships generators and shrinkers, and reports counterexamples in the standard format. It is **not** currently a dependency and is **not** required to land this fix — but the tests are cleaner with it.

**Decision**: add `glados: ^1.1.6` (or the latest 1.x) under `dev_dependencies`. If adding a dev-dependency is rejected later, the fallback is hand-rolled generators using `package:test` + `dart:math`'s `Random(seed)` with an explicit `numRuns` constant and a deterministic seed per test; shrinking becomes manual binary-halving of the failing input list.

**Harness layout:**

```
test/
├── advanced_chess_board_test.dart         # thin index; no logic
├── controller/
│   ├── controller_basic_test.dart         # unit/example
│   ├── controller_properties_test.dart    # PBT
│   └── notification_properties_test.dart  # PBT
├── painter/
│   └── arrow_painter_test.dart            # property + examples
├── widget/
│   ├── board_rebuild_test.dart            # widget test (§2.8, §2.9)
│   ├── board_layout_test.dart             # §2.22, §2.27
│   ├── tap_drag_test.dart                 # §2.17, §2.18, §2.19, §2.20
│   ├── promotion_dialog_test.dart         # §2.24
│   └── animation_test.dart                # §2.25
├── packaging/
│   ├── pubspec_metadata_test.dart         # §2.30
│   ├── changelog_format_test.dart         # §2.31
│   └── readme_content_test.dart           # §2.32
└── api/
    └── barrel_imports_test.dart           # §2.15, §2.16
```

**Property name index** (each name is an executable test ID):

| PBT name | Covers | Property |
|----------|--------|----------|
| `prop_multi_listener_fanout` | 2.1, 2.2 | P1.1 |
| `prop_shouldRepaint_iff_semantic_change` | 2.4, 2.5 | P1.3 |
| `prop_verbose_moves_is_destination_oracle` | 2.6 | P1.4 |
| `prop_controller_getters_match_game` | 2.13 | P1.5 |
| `prop_no_rebuild_on_noop_tap` | 2.17, 2.18 | P1.8 |
| `prop_drag_feedback_is_clamped` | 2.26 | P1.15 |
| `prop_square_has_semantics_label` | 2.27 | P1.16 |
| `prop_label_font_has_floor` | 2.28 | P1.17 |
| `prop_fen_roundtrip` | 3.7 | P2.1 |
| `prop_move_undo_identity` | 3.8 | P2.2 |
| `prop_illegal_move_rejected` | 3.6, 3.15 | P2.4 |
| `prop_notify_false_suppresses` | 3.10 | P2.5 |

**Generators** (using `glados`):

- `any.chessFen` — random reachable positions by playing 0–40 random legal moves from the start and emitting the resulting FEN. Seeded.
- `any.chessSquare` — `{a..h} × {1..8}`.
- `any.chessArrow` — random `(from, to, color)`; `color` from a small palette.
- `any.boardOrientation` — `PlayerColor.white | PlayerColor.black`.
- `any.squareSize` — `double` in `[24, 256]` via `any.double.map((x) => 24 + x.abs() % 232)`.

### 9. Packaging / metadata (§2.30–§2.32)

**File**: `pubspec.yaml` — additive changes:

```yaml
name: advanced_chess_board
description: "A modern looking chess board with advanced features like highlighting move possibilities, drag-drop pieces, drawing arrows, and a ChangeNotifier-based controller."
version: 3.0.0
homepage: "https://github.com/mkvmb6/advanced_chess_board"
repository: "https://github.com/mkvmb6/advanced_chess_board"
issue_tracker: "https://github.com/mkvmb6/advanced_chess_board/issues"
topics:
  - chess
  - board
  - game
  - widget
platforms:
  android:
  ios:
  linux:
  macos:
  web:
  windows:
screenshots:
  - description: "Default chess board layout"
    path: images/advancedChessBoardSS1.png
  - description: "Chess board with arrows and highlights"
    path: images/advancedChessBoardSS2.png

environment:
  sdk: ^3.5.4
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter
  chess: ^0.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  glados: ^1.1.6

flutter:
  assets:
    - assets/pieces/
```

**File**: `CHANGELOG.md` — dated release headers, migration notes, and the new 3.0.0 entry at the top:

```markdown
## 3.0.0 — YYYY-MM-DD

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
- **Breaking**: `playerToMove` renamed to `playerColor`; also used internally
  by `boardOrientation`. Migrate by replacing `playerToMove` with
  `playerColor` on both the controller read and `boardOrientation` values.
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
- Initial release.
```

Dates for existing releases are placeholders pending real git-tag dates; the property test `prop_changelog_dates_iso` accepts any ISO-8601 month or day on each header.

**File**: `README.md` — rewrite outline:

- Remove "Support for drawing arrow will be added in upcoming release."
- Add badges: pub version, likes, Flutter favorites (if granted), CI status.
- Getting started: install → minimal example (copy from `example/lib/main.dart`).
- Parameter reference table for `AdvancedChessBoard`: `controller`, `boardOrientation`, `lightSquareColor`, `darkSquareColor`, `kingBackgroundColorOnCheckmate`, `initialFEN`, `enableMoves`, `highlightLastMove`, `arrows`, `moveAnimationDuration`.
- Getter reference table for `ChessBoardController`: `fen`, `playerColor`, `isInCheck`, `isCheckmate`, `isStalemate`, `isDraw`, `isGameOver`, `history`, `pgn`, `moveCount`, `game`.
- Worked examples: drawing arrows, loading a FEN, flipping orientation, subscribing to controller changes, running a move programmatically.
- Known limitations: no built-in clock; piece theming requires forking the `assets/pieces/` directory.
- Migration note pointing at CHANGELOG 3.0.0.

### 10. Documentation (§2.33)

Every public symbol gets `///` doc comments covering purpose, parameters, and defaults:
- `AdvancedChessBoard` class + every constructor parameter.
- `ChessBoardController` class + every getter + every method.
- `ChessArrow` class + constructor + fields.
- `PlayerColor` enum + each value.
- Barrel library-level comment.

The `public_member_api_docs` lint (added in §2.34) enforces this at CI time.

### 11. Lint configuration (§2.34)

**File**: `analysis_options.yaml` (replaces current contents):

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_required_param: error
    missing_return: error
    todo: ignore

linter:
  rules:
    - always_declare_return_types
    - avoid_dynamic_calls
    - avoid_returning_null_for_future
    - prefer_const_constructors
    - prefer_const_constructors_in_immutables
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_final_locals
    - public_member_api_docs
    - sort_constructors_first
    - unnecessary_lambdas
    - unnecessary_null_checks
    - use_super_parameters
```

`flutter analyze` must exit 0 after all code changes land. The CI step for this is `flutter analyze --fatal-warnings --fatal-infos`.

## Testing Strategy

### Validation Approach

Two phases:

1. **Exploration** — before any fix code lands, write tests that reproduce each defect on the unfixed code. A failing test here confirms the root-cause analysis; a passing test falsifies it and forces re-hypothesis.
2. **Fix + preservation** — after the fix lands, every exploration test flips to passing, and new preservation PBTs prove that the non-bug input space is unchanged.

### Exploratory Bug Condition Checking

**Goal**: reproduce each `bugfix.md §1.x` defect on unfixed code and confirm the hypothesised root cause.

**Test Plan**: run against the current `main` branch (unfixed) before any code change.

**Test Cases** (each is expected to FAIL on unfixed code):

1. **Listener fan-out exploration** (§1.1, §1.2). Register two listeners, call `makeMove`, assert both increment. Will fail: only the second listener fires.
2. **Dispose ordering exploration** (§1.3). Instantiate controller, call `dispose()`, then interact — assert no assertion error. May fail in debug mode.
3. **Arrow repaint exploration** (§1.4). Create `ArrowPainter(A, orient)` and `ArrowPainter(A + extra, orient)`; assert `shouldRepaint` returns `true`. Will fail: returns `false`.
4. **Orientation repaint exploration** (§1.5). Two painters with identical `arrows` but different `boardOrientation`; assert `shouldRepaint` returns `true`. Will fail: current impl returns `true` for equal arrows regardless of orientation via the fall-through, but the orientation field isn't part of the equality test.
5. **SAN substring exploration** (§1.6). Seed a position where `moves({'square':'b1'})` contains `Nb1-a3` (SAN includes `a3`); then query `_isSquarePartOfValidMoves(validMoves, 'a3')` — current impl returns `true` for `a3` but also — critically — for `a1` because `Nb1-a3.contains("a1")` is false in this exact case, but for a position producing SAN `Ra1xb1` probing `"a1"` returns `true` when it should return `false` if there's no move to `a1`. Use a constructed position (`r3k3/8/8/8/8/8/8/R3K3 w - - 0 1`) to expose.
6. **Widget non-rebuild exploration** (§1.8). Pump board with only `controller:`. Call `controller.makeMove`, `pumpAndSettle`. Assert the piece moved in the tree. Will fail: no rebuild.
7. **Tap setState exploration** (§1.17, §1.18). Pump board with `enableMoves: false`, count rebuilds via a `RenderBox` spy, tap a square, assert counter unchanged. Will fail: extra `setState`.
8. **Last-move empty Container exploration** (§1.19). After e2-e4, dump the widget tree and find all `Container(color: yellow128)` — assert exactly 2. Will fail: extra empty `Container()`s present as children of every other square.
9. **GridView exploration** (§1.22). Pump board, assert `find.byType(GridView)` is empty. Will fail.
10. **Drag scale exploration** (§1.26). Pump board with a 200 px wide constraint, start a drag, measure feedback size. Will fail: feedback > `squareSize`.
11. **Missing semantics exploration** (§1.27). Pump board, call `tester.getSemantics(find.byType(ChessSquare).first)`, assert label is the formatted coordinate string. Will fail: no Semantics node.
12. **Analyse exploration** (§1.10, §1.11, §1.12, §1.34). Run `flutter analyze` with the new strict `analysis_options.yaml` on the unfixed code; assert non-zero exit. Will fail (in the exploration sense — i.e. analyse reports issues).
13. **Empty test file exploration** (§1.29). Assert `test/advanced_chess_board_test.dart` has a non-trivial body. Will fail: currently `void main() {}`.

**Expected Counterexamples**:

- §1.1/1.2: first listener never fires after the second is registered.
- §1.4: differing arrow lists yet `shouldRepaint == false`.
- §1.6: destinations that are mere substrings of SAN tokens pass the "legal destination" check.
- §1.8: widget frozen despite advancing FEN.

### Fix Checking

**Goal**: verify that for all inputs where the bug condition holds, the fixed package produces the corrective behaviour from `bugfix.md §2.x`.

**Pseudocode:**

```
FOR ALL input WHERE isBugCondition(input) DO
  result := fixedPackage(input)
  ASSERT expectedBehavior(result)  // per matching §2.k
END FOR
```

Concrete instantiations of this loop:

- Every PBT listed in the property name index above runs against fixed code and must pass.
- Every example test (dispose ordering, barrel imports, changelog dates, pub metadata) runs against fixed code and must pass.
- `flutter analyze` exits 0.

### Preservation Checking

**Goal**: verify that for all inputs where the bug condition does NOT hold, the fixed package produces the same observable result as the pre-fix package.

**Pseudocode:**

```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT originalPackage(input) == fixedPackage(input)
END FOR
```

Because "the original package" is not available as a library at test time, preservation is enforced via **invariant oracles** captured from the unfixed behaviour and encoded as fixed expectations:

- FEN round-trip, move/undo identity, illegal-move rejection, `notify: false` suppression: use the `chess` engine as oracle (the fixed code delegates to it, so equivalence to the oracle is equivalence to the unfixed behaviour for these inputs).
- Arrow geometry, default colour, checkmate tint, `highlightLastMove`, select/deselect, `enableMoves: false` render-only, `controller.game` escape hatch: golden widget tests capturing the pre-fix render output on the baseline scenarios in `example/lib/main.dart` and on a checkmate FEN. These golden files are generated once on unfixed code and checked into `test/goldens/`.

**Testing Approach**: property-based testing is used for preservation wherever the input space is continuous (random FENs, random move sequences, random square sizes, random listener counts). Golden tests cover pixel-level rendering preservation.

**Test Plan**: generate preservation goldens against current `main` (unfixed); then implement the fix; then run all preservation tests green.

**Test Cases**:

1. **Legal move preservation**: `prop_fen_roundtrip`, `prop_move_undo_identity`, `prop_illegal_move_rejected` — run against unfixed code to record expected invariants (they already pass because the bug is not in chess-rule generation), then run against fixed code.
2. **Notification-suppression preservation**: `prop_notify_false_suppresses` — was working, must keep working.
3. **Rendering preservation**: golden tests for the three example-app arrows, default board layout, mate highlight, `enableMoves: false` state.
4. **Arrow geometry preservation**: numeric test asserting adjusted-source, adjusted-dest, and arrowhead vertices match the pre-fix formulas to within float precision for a fixed set of (from, to, orientation) triples.
5. **Escape-hatch preservation**: `controller.game` identity — same `chess.Chess` instance across a controller's lifetime.

### Unit Tests

Unit tests (non-property) for discrete contracts:

- `controller_basic_test.dart`: starting FEN, makeMove return value semantics, undo on empty history, resetBoard idempotence, `notify: false` flag, dispose ordering.
- `arrow_painter_test.dart` (example section): shouldRepaint on three manually constructed pairs (equal, length-diff, color-diff).
- `packaging/*`: pubspec keys present, CHANGELOG header format, README content presence.

### Property-Based Tests

Indexed above. To restate the backbone:

- `prop_multi_listener_fanout` — listeners fan-out for all `n ∈ [1,10]`.
- `prop_shouldRepaint_iff_semantic_change` — painter repaint iff arrow-list-or-orientation-differs.
- `prop_verbose_moves_is_destination_oracle` — destination check matches `chess.generate_moves`.
- `prop_controller_getters_match_game` — every getter agrees with the underlying `Chess`.
- `prop_no_rebuild_on_noop_tap` — counter stays flat on no-op taps.
- `prop_drag_feedback_is_clamped` — feedback width bounded for any `boardWidth`.
- `prop_square_has_semantics_label` — all 64 squares carry the formatted label.
- `prop_label_font_has_floor` — font size respects `minLabelFontSize` floor.
- `prop_fen_roundtrip` — preservation.
- `prop_move_undo_identity` — preservation.
- `prop_illegal_move_rejected` — preservation.
- `prop_notify_false_suppresses` — preservation.

### Integration Tests

- `example/` app smoke test via `flutter_test` + `integration_test`: boot the example, assert the three demo arrows render, click Flip and assert orientation flipped, click Undo after pumping a move, click Load Fen and assert the widget shows the target position.
- End-to-end tap move: tap e2 then e4, assert FEN advances and the move animation completes inside the configured duration.
- End-to-end drag move: drag e2 → e4, assert FEN advances and **no** AnimatedPositioned transition fires (drag-drop should not animate).
- Controller swap integration: mount the widget with controller A, push a new tree with controller B, make a move on B, assert widget reflects B's state and is indifferent to subsequent moves on A.
