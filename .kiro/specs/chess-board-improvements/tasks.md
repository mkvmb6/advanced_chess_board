# Implementation Plan

> **Bugfix**: `advanced_chess_board` 2.3.0 → 3.0.0 hardening.
> Each task references the `§2.x` / `§3.x` clauses from `bugfix.md` it validates, and the `P1.x` / `P2.x` property IDs from `design.md` it satisfies.
> Property-based testing (glados) is preferred wherever the input space is continuous.

- [x] 1. Write bug condition exploration tests (BEFORE any fix lands)
  - **Property 1: Bug Condition** - Compound Defect Reproduction Across 13 Exploration Cases
  - **CRITICAL**: Every test in this task MUST FAIL on unfixed `main` — failure confirms the bug condition exists.
  - **DO NOT attempt to fix the tests or the code when they fail here — failures are the desired signal.**
  - **NOTE**: These tests encode the expected behaviour and will validate the fix when they flip to passing after implementation (Task 13 re-runs them as fix tests).
  - **GOAL**: Surface concrete counterexamples for every clause in `bugfix.md §1.1–§1.34` that is mechanically testable.
  - **Scoped PBT approach**: For deterministic defects (dead code, inverted painter logic, GridView presence, SAN substring against a fixed position, empty test file, missing semantics, missing metadata) scope to the concrete failing case; for continuous defects (listener count, random FEN, random squareSize) use a seeded PBT generator.
  - Add `glados: ^1.1.6` under `dev_dependencies` in the library `pubspec.yaml` (test-only, reverted if Task 2 decides against it).
  - Create the test harness directory tree: `test/controller/`, `test/painter/`, `test/widget/`, `test/packaging/`, `test/api/`, `test/properties/`.
  - Replace the stub `test/advanced_chess_board_test.dart` with a thin index file that `import`s each sub-test file so `flutter test` discovers them.
  - Write the following 13 exploration test cases, one per defect cluster listed in `design.md` "Exploratory Bug Condition Checking":
    1. `test/controller/exploration_listener_fanout_test.dart` — **§1.1, §1.2**. PBT `prop_multi_listener_fanout_fails_on_unfixed`: for `n ∈ [2, 10]` listeners, register all `n`, call `controller.makeMove(from: 'e2', to: 'e4')`, assert every listener's counter == 1. **Expected counterexample**: only the most recently registered listener fires; counters `[0, 0, …, 0, 1]`.
    2. `test/controller/exploration_dispose_ordering_test.dart` — **§1.3**. Instantiate controller, register a listener, call `dispose()`, then attempt `controller.makeMove`; assert no `FlutterError` about disposed `ChangeNotifier`. **Expected counterexample**: assertion error thrown in debug mode because `super.dispose()` ran before `_listener = null`.
    3. `test/painter/exploration_arrow_repaint_test.dart` — **§1.4**. Build `ArrowPainter(arrowsA, PlayerColor.white)` and `ArrowPainter(arrowsA + ChessArrow(startSquare: 'h1', endSquare: 'h8'), PlayerColor.white)`; assert `shouldRepaint(old)` returns `true`. **Expected counterexample**: returns `false`.
    4. `test/painter/exploration_orientation_repaint_test.dart` — **§1.5**. Build `ArrowPainter(arrowsA, PlayerColor.white)` and `ArrowPainter(arrowsA, PlayerColor.black)`; assert `shouldRepaint(old)` returns `true`. **Expected counterexample**: orientation is not part of equality — the fall-through semantics either miss the orientation change or always return true regardless.
    5. `test/painter/exploration_san_substring_test.dart` — **§1.6**. Load FEN `r3k3/8/8/8/8/8/8/R3K3 w - - 0 1`, from square `a1`. Replicate the current `_isSquarePartOfValidMoves` logic in the test against the SAN list; assert that candidate square `"a"` (not a valid chess square — used as a sentinel) or a square whose algebraic name is a substring of a SAN token is **not** accepted. Also construct a position with `Ra1xb1` and show that `"a1"` being probed incorrectly matches via `move.contains("a1")`. **Expected counterexample**: substring match returns `true` for a non-destination.
    6. `test/widget/exploration_widget_non_rebuild_test.dart` — **§1.8**. Pump `AdvancedChessBoard(controller: c)` with no external `addListener(setState)` wrapping. Call `c.makeMove(from: 'e2', to: 'e4')`, `tester.pumpAndSettle()`, then `find.byKey(Key('square_e2'))` and `find.byKey(Key('square_e4'))` (or inspect piece image paths on those squares). Assert the pawn image moved from e2 to e4. **Expected counterexample**: pawn still appears on e2 because the widget never rebuilt.
    7. `test/widget/exploration_noop_tap_rebuild_test.dart` — **§1.17, §1.18**. Pump board with `enableMoves: false`; wrap in a rebuild counter (`StatefulBuilder` that increments a counter on every build); tap any square; assert counter unchanged. Repeat with `enableMoves: true`, `selectedSquare == null`, tap empty `e4`; assert counter unchanged. **Expected counterexample**: counter increments on both scenarios.
    8. `test/widget/exploration_last_move_placeholder_test.dart` — **§1.19**. After `c.makeMove(from: 'e2', to: 'e4')`, pump; then `find.byWidgetPredicate((w) => w is Container && (w.color == Colors.yellow.withAlpha(128) || (w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color == Colors.yellow.withAlpha(128))))`; assert count == 2. Separately, `find.byWidgetPredicate((w) => w is Container && w.color == null && w.decoration == null && w.child == null)` inside the board tree; assert count == 0. **Expected counterexample**: many empty `Container()` placeholders present.
    9. `test/widget/exploration_gridview_present_test.dart` — **§1.22**. Pump board; assert `find.byType(GridView)` evaluates to empty. **Expected counterexample**: one `GridView` found.
    10. `test/widget/exploration_drag_scale_test.dart` — **§1.26**. Pump board constrained to 200 px wide (squareSize = 25). Start a drag on `e2`, capture the feedback widget via `find.descendant(of: find.byType(Draggable<String>), matching: find.byType(SizedBox)).evaluate().first`; measure its width. Assert `width ≤ 25 + 8`. **Expected counterexample**: width ≈ 29 (≥ 28.75 via unconditional 1.15 scale).
    11. `test/widget/exploration_missing_semantics_test.dart` — **§1.27**. Pump board; `tester.getSemantics(find.byType(ChessSquare).first)`. Assert a non-null semantics label matching `/^[a-h][1-8], (empty|(white|black) (pawn|rook|knight|bishop|queen|king))$/`. **Expected counterexample**: no `Semantics` node; `getSemantics` throws or returns a default-labelled node.
    12. `test/packaging/exploration_strict_analyse_test.dart` — **§1.10, §1.11, §1.12, §1.34**. Write a shell-out test (using `Process.run`) that: (a) writes the target strict `analysis_options.yaml` from `design.md §11` into a temp file path; (b) invokes `flutter analyze --fatal-warnings --fatal-infos --options=<tempPath>` on the unfixed tree; (c) asserts non-zero exit with diagnostics mentioning dead code (`return const Text("No piece found")`, `return "q";`), dynamic param (`assetPath`), and missing dartdoc. **Expected counterexample**: analyse reports issues; test passes (in the exploration sense — i.e. confirms the bug exists).
    13. `test/packaging/exploration_empty_test_file_test.dart` — **§1.29**. `File('test/advanced_chess_board_test.dart').readAsStringSync().trim()`; assert the body contains at least one `test(` or `testWidgets(` invocation. **Expected counterexample**: file body is only `void main() {}`.
  - Run `flutter test --reporter expanded` against the unfixed code.
  - **EXPECTED OUTCOME**: Every exploration test FAILS (this is correct — each failure confirms its clause's bug).
  - Document the exact counterexample output for each failure in a comment block at the top of each exploration file (first line of counterexample as observed). The implementing agent must not attempt to "fix" these failures — they are the success criterion of this task.
  - Mark this task complete when all 13 exploration tests are written, executed on unfixed code, and their failures captured as comments.
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.8, 1.10, 1.11, 1.12, 1.17, 1.18, 1.19, 1.22, 1.26, 1.27, 1.29, 1.34_


- [x] 2. Strict analyser + example lint parity + pubspec metadata foundation
  - Update `analysis_options.yaml` with the strict block from `design.md §11`: `include: package:flutter_lints/flutter.yaml`; `analyzer.language.strict-casts/strict-inference/strict-raw-types: true`; `analyzer.errors.missing_required_param/missing_return: error`; `analyzer.errors.todo: ignore`; the full `linter.rules` list (`always_declare_return_types`, `avoid_dynamic_calls`, `avoid_returning_null_for_future`, `prefer_const_constructors`, `prefer_const_constructors_in_immutables`, `prefer_const_declarations`, `prefer_const_literals_to_create_immutables`, `prefer_final_locals`, `public_member_api_docs`, `sort_constructors_first`, `unnecessary_lambdas`, `unnecessary_null_checks`, `use_super_parameters`).
  - Bump `example/pubspec.yaml` `dev_dependencies.flutter_lints` from `^4.0.0` to `^5.0.0` (resolve via `flutter pub get` in `example/`).
  - Update top-level `pubspec.yaml`:
    - Bump `version: 2.3.0` → `version: 3.0.0`.
    - Add `repository: "https://github.com/mkvmb6/advanced_chess_board"`.
    - Add `issue_tracker: "https://github.com/mkvmb6/advanced_chess_board/issues"`.
    - Add `topics: [chess, board, game, widget]`.
    - Add `platforms:` block enumerating `android`, `ios`, `linux`, `macos`, `web`, `windows` (each as an empty map).
    - Add `glados: ^1.1.6` to `dev_dependencies` (required for PBT tasks downstream).
    - Do NOT add the `screenshots:` block here — deferred to optional Task 16.2 so the image paths can be verified separately.
  - Run `flutter pub get` at the repo root and in `example/`; confirm resolution is clean.
  - **NOTE**: Running `flutter analyze` here will legitimately report many errors — that's fine. They are systematically resolved by Tasks 3–12. Do not attempt to silence them.
  - _Requirements: 2.7, 2.30, 2.34_
  - _Validates: P1.18, P1.21, P1.23_

- [x] 3. Reorganise source under `lib/src/` and add barrel exports
  - **Goal**: Move every implementation file under `lib/src/` and replace `lib/advanced_chess_board.dart` with a pure barrel. The package stays buildable because `smartRelocate` rewrites cross-file imports.
  - **ORDER MATTERS**: Perform the 11 moves in dependency order (leaves first, widget last) to minimise transient breakage. Run `flutter analyze` after each move to confirm imports are still resolved.

  - [x] 3.1 Move leaf model and constants files
    - `smartRelocate` `lib/constants/global_constants.dart` → `lib/src/constants/global_constants.dart`.
    - `smartRelocate` `lib/constants/image_constants.dart` → `lib/src/constants/image_constants.dart`.
    - `smartRelocate` `lib/models/chess_arrow.dart` → `lib/src/models/chess_arrow.dart`.
    - `smartRelocate` `lib/models/enums.dart` → `lib/src/models/enums.dart`.
    - Delete the now-empty `lib/constants/` and `lib/models/` directories.

  - [x] 3.2 Move utils
    - `smartRelocate` `lib/utils/arrow_painter.dart` → `lib/src/utils/arrow_painter.dart`.
    - `smartRelocate` `lib/utils/utils.dart` → `lib/src/utils/utils.dart`.
    - Delete the empty `lib/utils/` directory.

  - [x] 3.3 Move widgets
    - `smartRelocate` `lib/widgets/chess_piece_widget.dart` → `lib/src/widgets/chess_piece_widget.dart`.
    - `smartRelocate` `lib/widgets/chess_square.dart` → `lib/src/widgets/chess_square.dart`.
    - `smartRelocate` `lib/widgets/highlight_overlay.dart` → `lib/src/widgets/highlight_overlay.dart`.
    - Delete the empty `lib/widgets/` directory.

  - [x] 3.4 Move controller and board widget implementation, then introduce barrel
    - `smartRelocate` `lib/chess_board_controller.dart` → `lib/src/chess_board_controller.dart`.
    - The existing `lib/advanced_chess_board.dart` currently holds both the `library;` stub and the widget implementation — split it:
      - `smartRelocate` `lib/advanced_chess_board.dart` → `lib/src/advanced_chess_board.dart`.
      - Create a new `lib/advanced_chess_board.dart` containing only:
        ```dart
        /// Advanced Chess Board — a customizable Flutter chess-board widget with
        /// drag/drop, arrows, FEN loading, and a ChangeNotifier-based controller.
        library;

        export 'src/advanced_chess_board.dart' show AdvancedChessBoard;
        export 'src/chess_board_controller.dart' show ChessBoardController;
        export 'src/models/chess_arrow.dart' show ChessArrow;
        export 'src/models/enums.dart' show PlayerColor;
        ```
    - Run `flutter analyze`; confirm all internal `package:advanced_chess_board/...` imports have been rewritten to relative `../` paths by `smartRelocate`, or convert any remaining public-path imports inside `lib/src/` to relative imports manually.

  - [x] 3.5 Verify the barrel resolves all four public symbols
    - Add `test/api/barrel_imports_test.dart` that imports only `package:advanced_chess_board/advanced_chess_board.dart` and references `AdvancedChessBoard`, `ChessBoardController`, `ChessArrow`, `PlayerColor` in `void main()` (a compile-only test — `expect(ChessBoardController, isA<Type>())`). If this test compiles and runs, the barrel is complete.
  - _Bug_Condition: isBugCondition(input) where input matches §1.15 (deep import required) or §1.16 (all files are public surface)_
  - _Expected_Behavior: expectedBehavior(result) per §2.15, §2.16 — single barrel re-exports the four public symbols, all other files under `lib/src/`_
  - _Preservation: §3.19 — top-level import `package:advanced_chess_board/advanced_chess_board.dart` still resolves for existing consumers; §3.20 — pubspec remains valid_
  - _Requirements: 2.15, 2.16, 3.19_
  - _Validates: P1.22_

- [x] 4. Repair `ChessBoardController` (listener plumbing, dispose, new getters, dartdoc)

  - [x] 4.1 Remove listener shadowing and dispose inversion
    - In `lib/src/chess_board_controller.dart`, delete the `VoidCallback? _listener` field.
    - Delete the override of `addListener`.
    - Delete the private `_notifyListeners()` helper.
    - Replace every existing call to `_notifyListeners()` inside `makeMove`, `undo`, `resetBoard`, `loadGameFromFEN` with the inherited `notifyListeners()` (still gated by the `notify: true` flag).
    - Either remove the `dispose()` override entirely (preferred — `ChangeNotifier.dispose` is sufficient) OR keep it and ensure `super.dispose()` is the LAST statement in the body. Document the choice with `///`.

  - [x] 4.2 Convert `isCheckmate()` method to `isCheckmate` getter and add new getters
    - Replace `bool isCheckmate() => game.in_checkmate;` with `bool get isCheckmate => _game.in_checkmate;`.
    - Add the following getters (each with a `///` doc comment as required by `public_member_api_docs`):
      - `bool get isInCheck => _game.in_check;`
      - `bool get isStalemate => _game.in_stalemate;`
      - `bool get isDraw => _game.in_draw;`
      - `bool get isGameOver => _game.game_over;`
      - `List<chess.State> get history => List.unmodifiable(_game.history);`
      - `String get pgn => _game.pgn();`
      - `int get moveCount => _game.history.length;`
    - Keep the `game` getter as the documented escape hatch (§3.11) — add a `///` noting "Prefer the typed getters above; this stays for advanced use cases."

  - [x] 4.3 Add dartdoc to every public member of the controller
    - Class-level doc.
    - Constructor doc.
    - Each existing getter (`fen`, `playerColor`, `game`).
    - Each new getter from 4.2.
    - Each method (`makeMove`, `undo`, `resetBoard`, `loadGameFromFEN`) including `notify` flag semantics.

  - [x] 4.4 Update all internal usages of the old API
    - `grepSearch` for `isCheckmate()` across `lib/src/` and `example/` and rewrite call sites to `isCheckmate`.
    - Confirm `flutter analyze` reports no errors originating from `chess_board_controller.dart` (other lint failures from other files are expected at this stage).
  - _Bug_Condition: isBugCondition(input) for §1.1, §1.2, §1.3, §1.13, §1.14 — multi-listener registration, notify call, dispose ordering, missing getters, method/getter inconsistency_
  - _Expected_Behavior: expectedBehavior(result) per §2.1, §2.2, §2.3, §2.13, §2.14 — inherited `ChangeNotifier` plumbing fires every listener exactly once; dispose calls `super.dispose()` last; full getter surface available; `isCheckmate` is a getter_
  - _Preservation: §3.6–§3.11 — illegal-move rejection, FEN round-trip, undo, reset, `notify: false`, `controller.game` escape hatch unchanged_
  - _Requirements: 2.1, 2.2, 2.3, 2.13, 2.14, 2.33, 3.6, 3.7, 3.8, 3.9, 3.10, 3.11_
  - _Validates: P1.1, P1.2, P1.5, P2.1–P2.5, P2.11_

- [x] 5. Fix `ArrowPainter.shouldRepaint` logic and include `boardOrientation` in equality
  - In `lib/src/utils/arrow_painter.dart`, rewrite `shouldRepaint` exactly as in `design.md §1`:
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
  - Confirm `ChessArrow` has a correct `==` / `hashCode` implementation (value equality over `startSquare`, `endSquare`, `color`). If missing, add both via `operator ==` override and `hashCode` getter. Add dartdoc to the class, constructor, and each field (required by `public_member_api_docs`).
  - Add a sanity example test to `test/painter/arrow_painter_test.dart` covering: (a) equal painters → `shouldRepaint == false`; (b) length-different → `true`; (c) color-different → `true`; (d) orientation-different → `true`.
  - _Bug_Condition: isBugCondition(input) for §1.4 (arrow list change) and §1.5 (orientation change)_
  - _Expected_Behavior: expectedBehavior(result) per §2.4, §2.5 — repaint iff arrows or orientation differ semantically_
  - _Preservation: §3.16 — arrow geometry, default colour `Colors.amber.withAlpha(128)`, equilateral-triangle arrowhead sized from `blockSize` remain unchanged; §3.4 — orientation-dependent drawing unchanged_
  - _Requirements: 2.4, 2.5, 3.16_
  - _Validates: P1.3, P2.6_

- [x] 6. Replace SAN-substring move validation with verbose-moves helper
  - In `lib/src/advanced_chess_board.dart` (post-reorg):
    - Delete the existing `_isSquarePartOfValidMoves(Set<String> moves, String square)` helper and all special-case branches for `"O-O"` / `"O-O-O"` SAN strings.
    - Rewrite `_setSelectedSquareAndFindLegalMoves(square)` to populate `legalMoves` as a `Set<String>` of destination squares via verbose generation:
      ```dart
      legalMoves = {
        for (final m in game.generate_moves({'square': square}))
          m.toAlgebraic,
      };
      ```
    - Rewrite callers (drag target acceptance, tap-to-move, highlight predicate) to use `legalMoves.contains(targetSquare)` directly — no substring checks anywhere.
    - Add `_isLegalDestination(String from, String to)` as an explicit helper so tests can drive it:
      ```dart
      bool _isLegalDestination(String from, String to) {
        for (final m in game.generate_moves({'square': from})) {
          if (m.toAlgebraic == to) return true;
        }
        return false;
      }
      ```
  - Verify castling continues to work: `generate_moves({'square': 'e1'})` from the starting-castle FEN `r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1` must include moves with `toAlgebraic == 'g1'` and `toAlgebraic == 'c1'`.
  - _Bug_Condition: isBugCondition(input) for §1.6 — substring match misidentifies destinations_
  - _Expected_Behavior: expectedBehavior(result) per §2.6 — verbose-move destination oracle; castling via `flags`, not SAN strings_
  - _Preservation: §3.1 (legal moves including castling/en passant), §3.14 (tap-to-select highlights), §3.15 (drag-to-legal-square accepts, illegal rejected)_
  - _Requirements: 2.6, 3.1, 3.14, 3.15_
  - _Validates: P1.4, P2.4_

- [x] 7. Wire `AdvancedChessBoard` to rebuild on controller changes and handle controller swap

  - [x] 7.1 Wrap board in `ListenableBuilder(listenable: widget.controller, …)`
    - In `lib/src/advanced_chess_board.dart`, remove the `late chess.Chess game;` field and the `game = widget.controller.game;` line in `initState`.
    - Inside the `LayoutBuilder` builder, wrap the top-level `Stack` (containing the `_buildChessBoard` grid + arrow `CustomPaint`) in `ListenableBuilder(listenable: widget.controller, builder: (context, _) { final game = widget.controller.game; return Stack(...); })`.
    - Anywhere `game` is referenced inside the inner builder, use the local rebound `game` (not a cached field).

  - [x] 7.2 Implement `didUpdateWidget` controller swap
    - Override `didUpdateWidget(covariant AdvancedChessBoard old)` and in it:
      - Call `super.didUpdateWidget(old)`.
      - If `old.controller != widget.controller`, trigger a `setState(() {})` so the `ListenableBuilder` rebuilds with the new `listenable` identity. No manual `addListener` / `removeListener` is needed — `ListenableBuilder` auto-swaps on identity change.
      - Also reset local selection state: `selectedSquare = null; legalMoves = {};` so stale selection doesn't leak across the swap.

  - [x] 7.3 Remove any now-dead `addListener(setState)` patterns the old `initState` installed
    - `grepSearch` the widget state for `addListener(`; remove the explicit subscription the old code relied on (if present). The `ListenableBuilder` is the single subscription point.
  - _Bug_Condition: isBugCondition(input) for §1.8 (widget with only `controller:`, no external subscription) and §1.9 (controller swap across `didUpdateWidget`)_
  - _Expected_Behavior: expectedBehavior(result) per §2.8, §2.9 — widget self-subscribes; controller swap resubscribes and rebinds `game`_
  - _Preservation: §3.1 (move flow), §3.10 (`notify: false` suppression), §3.12 (`enableMoves: false`)_
  - _Requirements: 2.8, 2.9, 3.1, 3.10, 3.12_
  - _Validates: P1.6, P1.7_

- [x] 8. Clean dead code and weak typing in `utils.dart`
  - In `lib/src/utils/utils.dart`:
    - Remove the trailing `return const Text("No piece found");` from `getChessPieceWidget` — the exhaustive switch satisfies the return-path analysis once strict-inference is on.
    - Remove the trailing `return "q";` from `pieceTypeToString` — same reasoning.
    - Change `_getPieceImageWidget(final assetPath)` to `Widget _getPieceImageWidget(String assetPath)` so the analyser enforces the type.
    - Add `///` dartdoc to every public top-level function / constant in the file (required by `public_member_api_docs`).
  - Run `flutter analyze` scoped to `lib/src/utils/utils.dart`; confirm zero diagnostics from this file.
  - _Bug_Condition: isBugCondition(input) for §1.10, §1.11, §1.12 — dead-code returns and untyped `assetPath`_
  - _Expected_Behavior: expectedBehavior(result) per §2.10, §2.11, §2.12 — unreachable returns removed, `assetPath` typed as `String`_
  - _Preservation: §3.1, §3.2 — piece rendering and promotion dialog contents unchanged_
  - _Requirements: 2.10, 2.11, 2.12_
  - _Validates: P1.21_

- [x] 9. Rendering / UX fixes in `AdvancedChessBoard`

  - [x] 9.1 Guarded `setState` in `_handleTap`
    - Add an early-return `if (!widget.enableMoves) return;` BEFORE any `setState`.
    - Add an early-return `if (selectedSquare == null && game.get(square) == null) return;` BEFORE any `setState` on the "tap empty square" branch.
    - Move every remaining `setState` invocation so it only runs on actual state mutations (selection change, legal-moves recomputation, move made, move undone).

  - [x] 9.2 `SizedBox.shrink()` for off-last-move squares
    - In `_buildLastMoveHighlight(String square)`:
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

  - [x] 9.3 Single highlight when selected == last-move square
    - Wrap the last-move overlay insertion so it's skipped when `square == selectedSquare`. Concretely, inside the `Stack` children list, gate the last-move highlight with `if (square != selectedSquare) _buildLastMoveHighlight(square),`. Selection overlay retains priority; no double alpha-blend occurs.

  - [x] 9.4 Column-of-Rows board layout (replace `GridView.builder`)
    - Replace `_buildChessBoard(squareSize)`'s `GridView.builder(...)` with the `Column(mainAxisSize: min, children: List.generate(8, (row) => Row(mainAxisSize: min, children: List.generate(8, (col) => SizedBox(width: squareSize, height: squareSize, child: _buildSquareWithDragTarget(...))))))` form exactly as in `design.md §6 point 5`.
    - Compute `rank` and `file` based on `widget.boardOrientation` (white: `rank = (7 - row) + 1`, `file = files[col]`; black: `rank = row + 1`, `file = files[7 - col]`).
    - `isLight = (row + col).isEven`.

  - [x] 9.5 `precacheImage` in `didChangeDependencies`
    - Add a `bool _precached = false;` state field.
    - Override `didChangeDependencies()`:
      ```dart
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
    - Declare `_allPieceAssetPaths` as a `const` top-level list in `lib/src/constants/image_constants.dart` (or assemble from the existing `PieceImages` constants) enumerating all 12 asset paths.

  - [x] 9.6 Dynamic promotion dialog square size
    - Change `_showPromotionDialog` signature to `Future<chess.PieceType> _showPromotionDialog(BuildContext context, double squareSize)`.
    - Pass the current `squareSize` from the enclosing `LayoutBuilder` / `ListenableBuilder` scope through `_makeMove(from, to)` into `_showPromotionDialog`.
    - In the dialog body, replace the hard-coded `squareSize: 60` with the passed-in `squareSize`.

  - [x] 9.7 Clamped drag feedback on narrow screens
    - Add package-private constants in `lib/src/constants/global_constants.dart`:
      ```dart
      const double kMaxFeedbackScale = 1.15;
      const double kMaxFeedbackOverflowPx = 8.0;
      ```
    - Add a helper `double _dragFeedbackSize(double squareSize) { final scaled = squareSize * kMaxFeedbackScale; final clamped = squareSize + kMaxFeedbackOverflowPx; return scaled < clamped ? scaled : clamped; }`.
    - Use `_dragFeedbackSize(squareSize)` as the width/height of the `Draggable.feedback` widget instead of `squareSize * 1.15`.
  - _Bug_Condition: isBugCondition(input) for §1.17, §1.18, §1.19, §1.20, §1.22, §1.23, §1.24, §1.26_
  - _Expected_Behavior: expectedBehavior(result) per §2.17, §2.18, §2.19, §2.20, §2.22, §2.23, §2.24, §2.26_
  - _Preservation: §3.3 (checkmate tint), §3.4 (orientation labels), §3.5 (custom colours + inverted label colour), §3.13 (last-move yellow on from+to), §3.14 (select/deselect + highlights), §3.15 (drag-accept/reject)_
  - _Requirements: 2.17, 2.18, 2.19, 2.20, 2.22, 2.23, 2.24, 2.26, 3.3, 3.4, 3.5, 3.13, 3.14, 3.15_
  - _Validates: P1.8, P1.9, P1.10, P1.11, P1.12, P1.13, P1.15, P2.7, P2.9, P2.10_


- [x] 10. Move animation overlay layer

  - [x] 10.1 Add `moveAnimationDuration` parameter to `AdvancedChessBoard`
    - Add a new final field `final Duration moveAnimationDuration;` with default `Duration(milliseconds: 150)`.
    - Add to the constructor with `this.moveAnimationDuration = const Duration(milliseconds: 150)` and dartdoc explaining "Duration of the AnimatedPositioned transition that runs on tap and programmatic moves. Drag-drop moves do not animate (the `Draggable.feedback` already follows the pointer). Set `Duration.zero` to disable."

  - [x] 10.2 Implement `_MoveAnimationLayer` widget
    - Create `lib/src/widgets/move_animation_layer.dart` containing a private `_MoveAnimationLayer extends StatefulWidget` that accepts: the in-flight move (`from`, `to`, piece asset path), `squareSize`, `orientation`, `duration`, and `onComplete` callback.
    - The state uses `AnimatedPositioned` inside a `Stack`-sized layer matching the board; the piece interpolates from the `from` square's (x, y) to the `to` square's (x, y) over `duration`, then fires `onComplete` which clears the animating move.
    - Export the layer ONLY from `lib/src/widgets/`; it is NOT re-exported from the barrel.

  - [x] 10.3 Wire animation trigger in `AdvancedChessBoard` state
    - Add private state `_InFlightMove? _animatingMove;` and `bool _suppressNextAnimation = false;`.
    - In the main builder, add the layer conditionally inside the top-level `Stack`:
      ```dart
      if (_animatingMove != null)
        _MoveAnimationLayer(
          move: _animatingMove!,
          squareSize: squareSize,
          orientation: widget.boardOrientation,
          duration: widget.moveAnimationDuration,
          onComplete: () => setState(() => _animatingMove = null),
        ),
      ```
    - In `_makeMove(from, to)`: if `_suppressNextAnimation` is `false` AND `widget.moveAnimationDuration > Duration.zero`, set `_animatingMove = _InFlightMove(from, to, movingPieceAsset)` BEFORE committing the engine move so the overlay reads the pre-move piece location; then commit the move; then clear `_suppressNextAnimation = false`. If `_suppressNextAnimation` is `true`, simply commit and clear the flag.
    - In the `DragTarget.onAcceptWithDetails` callback, set `_suppressNextAnimation = true` before invoking `_makeMove(...)`.
  - _Bug_Condition: isBugCondition(input) for §1.25 — no animation on tap/programmatic moves_
  - _Expected_Behavior: expectedBehavior(result) per §2.25 — moving piece animates via AnimatedPositioned over configurable `moveAnimationDuration` for tap + programmatic moves; drag-drop path skips animation_
  - _Preservation: §3.1 (move mutates state correctly regardless of animation), §3.15 (drag path unchanged semantically)_
  - _Requirements: 2.25, 3.1, 3.15_
  - _Validates: P1.14_

- [x] 11. Accessibility — `Semantics` wrappers and minimum label font floor

  - [x] 11.1 Wrap `ChessSquare` in `Semantics`
    - In `lib/src/widgets/chess_square.dart`, compute `pieceDescription` as `"white pawn"` / `"black knight"` / `"empty"` based on the piece on the square (or empty).
    - Wrap the outermost `Container` / layout widget in `Semantics(label: '$square, $pieceDescription', button: onTap != null, child: …)`.

  - [x] 11.2 Wrap `ChessPieceWidget` in `Semantics`
    - In `lib/src/widgets/chess_piece_widget.dart`, compute `pieceLabel` (same descriptive format).
    - Wrap the `Image.asset(...)` in `Semantics(label: pieceLabel, button: isBoardEnabled, child: …)` where `isBoardEnabled` is passed from the parent.

  - [x] 11.3 Add minimum label font size floor
    - In `lib/src/constants/global_constants.dart`, add `const double kMinLabelFontSize = 9.0;` with a `///` doc comment.
    - In `ChessSquare._buildTextWidget` (or wherever the rank/file label font size is computed), replace `fontSize: squareSize * 0.18` with `fontSize: math.max(kMinLabelFontSize, squareSize * 0.18)` and add `import 'dart:math' as math;` at the top of the file.
  - _Bug_Condition: isBugCondition(input) for §1.27 (no semantics) and §1.28 (no font floor)_
  - _Expected_Behavior: expectedBehavior(result) per §2.27, §2.28_
  - _Preservation: §3.1, §3.4, §3.5 — game behaviour and label placement/colour unchanged_
  - _Requirements: 2.27, 2.28_
  - _Validates: P1.16, P1.17_

- [x] 12. Add dartdoc to all remaining public classes/members (satisfy `public_member_api_docs`)
  - `grepSearch` inside `lib/src/` for public class declarations (`^class `, `^enum `) and public top-level functions/getters without a preceding `///`.
  - For each of the following, add purpose + parameter + default-value documentation:
    - `AdvancedChessBoard` class + every constructor parameter (`controller`, `boardOrientation`, `lightSquareColor`, `darkSquareColor`, `kingBackgroundColorOnCheckmate`, `initialFEN`, `enableMoves`, `highlightLastMove`, `arrows`, `moveAnimationDuration`, `dragFeedbackScaleFactor` if still exposed, plus any others already present).
    - `ChessArrow` class + constructor + fields (`startSquare`, `endSquare`, `color`, default `Colors.amber.withAlpha(128)`).
    - `PlayerColor` enum + `white` and `black` values.
    - Any public helper constants still exported from the barrel.
    - Library-level doc at the top of `lib/advanced_chess_board.dart` (already added in Task 3.4; re-verify).
  - Run `flutter analyze --fatal-infos` on the library; confirm zero `public_member_api_docs` violations remain.
  - _Bug_Condition: isBugCondition(input) for §1.33 — missing dartdoc on public symbols_
  - _Expected_Behavior: expectedBehavior(result) per §2.33 — every public symbol carries `///` documentation_
  - _Preservation: §3.20 — pubspec remains valid; documented public API behaves identically_
  - _Requirements: 2.33_
  - _Validates: P1.21_

- [x] 13. Build out full testing harness and convert exploration tests to fix tests
  - **CONTEXT**: The 13 exploration tests from Task 1 should now PASS against the fixed code (because Tasks 2–12 eliminated the bug conditions). The exploration comments explaining "this fails on unfixed code" stay as historical context, but the assertions become fix tests.

  - [x] 13.1 Re-run the Task 1 exploration tests against fixed code
    - **Property 1: Expected Behavior** - All 13 Defect Clusters Resolved
    - **IMPORTANT**: Re-run the SAME tests from Task 1 — do NOT write new tests here.
    - `flutter test test/controller/ test/painter/ test/widget/ test/packaging/` — every exploration test must now PASS.
    - **EXPECTED OUTCOME**: All 13 exploration tests PASS (confirms each clause's bug is fixed).
    - _Requirements: Expected Behavior across §2.1–§2.34; Correctness Properties P1.1–P1.23 from design.md_

  - [x] 13.2 Add unit tests for controller contracts
    - `test/controller/controller_basic_test.dart`:
      - Starting FEN equals `chess.DEFAULT_POSITION` / `rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1`.
      - `makeMove(from:'e2', to:'e4')` returns `true` and advances FEN.
      - `makeMove(from:'e2', to:'e5')` returns `false` and does not mutate FEN.
      - `undo()` on empty history is a no-op.
      - `resetBoard()` is idempotent.
      - `loadGameFromFEN(valid)` succeeds; `loadGameFromFEN(malformed)` either rejects or safely handles (follow the current contract — encode whichever of the two is observed as the expectation).
      - `notify: false` flag suppresses listener calls; `notify: true` fires.
      - Dispose ordering contract test from Task 1 (lifted here if you'd rather keep it in `controller/`).

  - [x] 13.3 Add property-based tests
    - `test/properties/controller_properties_test.dart`:
      - `prop_multi_listener_fanout` — P1.1, covers §2.1, §2.2. Uses `Glados<int>(any.int.map((n) => 1 + n.abs() % 10))` for listener count; registers n listeners, invokes makeMove, asserts every counter == 1.
      - `prop_controller_getters_match_game` — P1.5, covers §2.13. Uses `any.chessFen` generator; for each random FEN, asserts `c.isInCheck == c.game.in_check` etc. for all 7 new getters.
      - `prop_notify_false_suppresses` — P2.5, covers §3.10. For any random legal move, `makeMove(..., notify: false)` → zero listener invocations.
    - `test/painter/arrow_painter_properties_test.dart`:
      - `prop_shouldRepaint_iff_semantic_change` — P1.3, covers §2.4, §2.5. Uses `any.listOf(any.chessArrow)` + `any.boardOrientation`; asserts `shouldRepaint` returns `true` iff arrows list or orientation differs.
    - `test/properties/move_validation_properties_test.dart`:
      - `prop_verbose_moves_is_destination_oracle` — P1.4, covers §2.6. For any random reachable position and any `(from, to)` pair, the `_isLegalDestination(from, to)` helper's result equals `game.generate_moves({'square': from}).any((m) => m.toAlgebraic == to)`.
    - Generators file `test/properties/generators.dart` exposing (per design.md §8):
      - `any.chessFen` — seeded random FEN by playing 0–40 random legal moves from the start.
      - `any.chessSquare` — `{a..h} × {1..8}`.
      - `any.chessArrow` — random `(from, to, color)` with color from a small palette.
      - `any.boardOrientation` — `PlayerColor.white | PlayerColor.black`.
      - `any.squareSize` — `double` in `[24, 256]`.

  - [x] 13.4 Add widget tests
    - `test/widget/board_rebuild_test.dart` — P1.6, P1.7; covers §2.8, §2.9. Pump widget with controller A, call `A.makeMove`, assert rebuild; swap to controller B via `pumpWidget` with a new `AdvancedChessBoard(controller: B)`, call `B.makeMove`, assert rebuild driven by B and not A (call `A.makeMove` after swap, assert no rebuild).
    - `test/widget/board_layout_test.dart` — P1.11; covers §2.22. Pump board; `find.byType(GridView)` is empty; `find.byType(Row).evaluate().length >= 8`.
    - `test/widget/tap_drag_test.dart` — P1.8, P1.9, P1.10; covers §2.17–§2.20.
    - `test/widget/promotion_dialog_test.dart` — P1.13; covers §2.24. Parametrise over `squareSize ∈ {28, 64, 96, 128}` (discrete example set suffices), trigger a promotion, assert dialog piece `SizedBox.width == squareSize ± 0.5`.
    - `test/widget/animation_test.dart` — P1.14; covers §2.25. Trigger a tap move, use `tester.pump(Duration(milliseconds: 75))` at 50% of the default 150 ms duration, assert piece widget position is between `from` and `to` (use `tester.getTopLeft(find.byType(ChessPieceWidget))` on the animating piece). Trigger a drag-drop move, assert no intermediate animated frame (`_animatingMove` stays null via widget-state peek OR the piece appears at destination immediately after `pumpAndSettle(Duration.zero)`).
    - `test/widget/accessibility_test.dart` — P1.16, P1.17; covers §2.27, §2.28.

  - [x] 13.5 Add packaging tests
    - `test/packaging/pubspec_metadata_test.dart` — P1.18. Parse `pubspec.yaml` via `package:yaml`; assert non-empty `repository`, `issue_tracker`, `topics`, `platforms`.
    - `test/packaging/changelog_format_test.dart` — P1.19. Read `CHANGELOG.md`; every release header matches `RegExp(r'^## \d+\.\d+\.\d+ — \d{4}-\d{2}(-\d{2})?$', multiLine: true)` (month or full date per design.md acceptance).
    - `test/packaging/readme_content_test.dart` — P1.20. Read `README.md`; assert does NOT contain `"arrow will be added"`; assert contains a markdown table header (`|` pipe delimiters) at least once; assert contains at least three of the new controller getter names (`isInCheck`, `isStalemate`, `isGameOver`, `history`, `pgn`, `moveCount`).
  - _Bug_Condition: isBugCondition(input) for §1.29 — empty test file with zero behaviour coverage_
  - _Expected_Behavior: expectedBehavior(result) per §2.29 — unit tests, widget tests, painter tests, property-based tests all present and passing_
  - _Preservation: §3.17 — previously-clean analyse paths stay clean_
  - _Requirements: 2.29, 3.17_
  - _Validates: P1.1, P1.3, P1.4, P1.5, P1.6, P1.7, P1.8, P1.9, P1.10, P1.11, P1.13, P1.14, P1.16, P1.17, P1.18, P1.19, P1.20_

- [x] 14. Preservation tests (¬C(X) behaviour unchanged)
  - **Property 2: Preservation** - Non-Buggy Input Space Unchanged
  - **IMPORTANT**: Follow observation-first methodology. Each preservation test captures a behaviour that was working on the UNFIXED code; it must continue to pass on the FIXED code.
  - **Procedure for each property**: (a) before Task 2 lands, optionally run the property once against unfixed `main` to confirm the baseline passes; (b) after Tasks 2–13 land, the same property must still pass on fixed code.
  - **Why PBT here**: preservation is a universal ("for all non-buggy inputs") statement. Random generation surfaces edge cases manual examples miss.
  - Add the following preservation PBTs, each in `test/properties/preservation_test.dart`:
    - `prop_fen_roundtrip` — P2.1, covers §3.7. For any random FEN `F` produced by `any.chessFen`: `controller.loadGameFromFEN(F); controller.fen == canonicalise(F)` where `canonicalise` is the engine's own normalisation.
    - `prop_move_undo_identity` — P2.2, covers §3.8. For any reachable position `P` and any legal move `m` from `P`: `fenOf(P) == fenOf(P.makeMove(m).undo())`.
    - `prop_illegal_move_rejected` — P2.4, covers §3.6, §3.15. For any illegal `(from, to)` (generated by picking random `from`, then random `to ∉ legalDestinations(from)`): `makeMove` returns `false`, `fen` is unchanged.
    - `prop_notify_false_suppresses` — P2.5, covers §3.10. For any random mutating call with `notify: false`, zero listener invocations occur.
    - `prop_arrow_geometry_preserved` — P2.6, covers §3.16. For any `(from, to, orientation)` triple, the computed line start/end and arrowhead vertices from the fixed `ArrowPainter` match the pre-fix formulas to within `1e-6`. Capture the pre-fix formulas as a test fixture during exploration.
    - `prop_checkmate_tint_preserved` — P2.7, covers §3.3. Load a known mate FEN (e.g. `rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3` — Fool's Mate); assert the mated-king square renders a widget whose colour is `Colors.red.withAlpha(155)` and the king piece widget renders on top of it.
    - `prop_enable_moves_false_is_render_only` — P2.8, covers §3.12. Pump with `enableMoves: false`; for any generated square tap and drag attempt, FEN unchanged; selection unchanged.
    - `prop_escape_hatch_preserved` — P2.11, covers §3.11. `identical(controller.game, controller.game)` across arbitrary mutation sequences.
    - `prop_top_level_import_still_resolves` — P2.12, covers §3.19. The compile-only test in `test/api/barrel_imports_test.dart` (added in Task 3.5) is this property — re-run it.
  - **EXPECTED OUTCOME**: All preservation tests PASS on fixed code (no regressions).
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10, 3.11, 3.12, 3.13, 3.14, 3.15, 3.16, 3.17, 3.18, 3.19, 3.20_
  - _Validates: P2.1, P2.2, P2.4, P2.5, P2.6, P2.7, P2.8, P2.11, P2.12, P2.13_

- [ ] 15. Example-app integration tests
  - **OPTIONAL** — marked optional because `integration_test` adds CI complexity (spins up a simulator/device) and is covered at the API level by Task 13's widget tests. Skip if CI cannot run `integration_test`.
  - Add `example/integration_test/app_smoke_test.dart` exercising:
    - Boot the example app; assert the three demo arrows (e2-e4, e7-e5, g1-f3 red) are painted (inspect the `CustomPaint` widget tree for three `ChessArrow` instances via a test-only key on the board).
    - Tap "Flip"; assert board orientation changed (e.g. file `a` label moves from the left edge to the right edge — detect via `find.text('a')` position).
    - Tap e2 then e4; assert FEN advances.
    - Drag e7 to e5; assert FEN advances.
    - Tap "Undo"; assert FEN rewinds.
    - Tap "Load Fen" with a mate-in-1 FEN; assert the board displays that FEN's pieces.
    - Swap controllers at the app root; assert subsequent moves on the new controller update the widget and moves on the old controller do not.
  - Add `integration_test` under `example/dev_dependencies` if missing.
  - _Bug_Condition: isBugCondition(input) for §1.8 (widget freeze), §1.25 (no animation)_
  - _Expected_Behavior: expectedBehavior(result) per §2.8, §2.25 — end-to-end user flows work_
  - _Preservation: §3.18 — example app buttons and demo arrows keep working_
  - _Requirements: 2.8, 2.25, 3.18_
  - _Validates: P1.6, P1.7, P1.14_

- [x] 16. Update `CHANGELOG.md` — 3.0.0 entry + ISO-8601 dates on all prior releases

  - [x] 16.1 Add the 3.0.0 entry at the top
    - Copy the 3.0.0 block verbatim from `design.md §9` into `CHANGELOG.md`, with today's date filled in as `## 3.0.0 — YYYY-MM-DD` (use the date the release tag is created; if unknown at this task's execution time, use the current UTC date).
    - Sections: Breaking changes (isCheckmate getter, lib/src/ reorganisation), Fixes (listener fan-out, ArrowPainter repaint, verbose-move destinations, dispose ordering), Additions (new controller getters, auto-rebuild, move animations, Semantics), Polish (dead code, strict lints, dartdoc, dynamic promotion sizing, clamped drag feedback, label font floor, Column-of-Rows layout, precacheImage).

  - [x] 16.2 Backfill ISO-8601 dates on all prior releases
    - Apply the dates from `design.md §9` release table: `2.3.0 — 2025-03-11`, `2.2.0 — 2025-01-28`, `2.1.1 — 2024-12-15`, `2.1.0 — 2024-11-02`, `2.0.0 — 2024-10-10`, `1.2.1 — 2024-08-20`, `1.2.0 — 2024-07-30`, `1.1.1 — 2024-06-15`, `1.1.0 — 2024-05-22`, `1.0.3 — 2024-04-08`, `1.0.2 — 2024-03-12`, `1.0.1 — 2024-02-28`, `1.0.0 — 2024-02-10`.
    - **NOTE**: `design.md` flags these as placeholders pending real git-tag dates. If real tag dates are available via `git tag -l --format='%(refname:short) %(creatordate:short)'`, prefer those; otherwise use the design.md defaults. The preservation property `prop_changelog_dates_iso` accepts any ISO-8601 month or day.

  - [x] 16.3 Re-describe 2.0.0 breaking rename
    - Expand the 2.0.0 entry to include the `playerToMove` → `playerColor` rename with a 2–3 line migration note so the `CHANGELOG.md` is self-sufficient for consumers upgrading from 1.x.
  - _Bug_Condition: isBugCondition(input) for §1.31 — undated CHANGELOG with under-described 2.0.0 break_
  - _Expected_Behavior: expectedBehavior(result) per §2.31 — every release header ISO-8601 dated; 2.0.0 migration explicit; 3.0.0 documents isCheckmate rename_
  - _Preservation: §3.20 — packaging validity_
  - _Requirements: 2.31_
  - _Validates: P1.19_

- [x] 17. Update `README.md` — remove stale line, add reference tables + examples + migration note

  - [x] 17.1 Remove stale content and add badges
    - Delete the sentence "Support for drawing arrow will be added in upcoming release."
    - Add pub version + license badges at the top (keep any that already work; do not fabricate CI badges for non-existent workflows).

  - [x] 17.2 Add parameter reference table for `AdvancedChessBoard`
    - Columns: Parameter | Type | Default | Description. Rows for every constructor parameter listed in `design.md §9` (controller, boardOrientation, lightSquareColor, darkSquareColor, kingBackgroundColorOnCheckmate, initialFEN, enableMoves, highlightLastMove, arrows, moveAnimationDuration).

  - [x] 17.3 Add getter reference table for `ChessBoardController`
    - Columns: Getter | Type | Description. Rows: `fen`, `playerColor`, `isInCheck`, `isCheckmate`, `isStalemate`, `isDraw`, `isGameOver`, `history`, `pgn`, `moveCount`, `game`.

  - [x] 17.4 Add worked examples
    - Minimal install + import snippet (barrel only).
    - Drawing arrows example (e2-e4, e7-e5, g1-f3 red).
    - Loading a FEN.
    - Flipping orientation.
    - Subscribing to controller notifications (note: widget auto-rebuilds; listener subscription is only needed for consumer-side side effects).
    - Running a move programmatically via `controller.makeMove`.

  - [x] 17.5 Add migration + known-limitations sections
    - "Migrating to 3.0.0" pointing at CHANGELOG 3.0.0 and listing the two breaking changes inline.
    - "Known limitations": no built-in clock; piece theming requires forking `assets/pieces/`.
  - _Bug_Condition: isBugCondition(input) for §1.32 — stale README, no reference tables, missing examples_
  - _Expected_Behavior: expectedBehavior(result) per §2.32 — parameter table, getter table, worked examples, migration note, known-limitations all present_
  - _Preservation: §3.20 — documentation is additive_
  - _Requirements: 2.32_
  - _Validates: P1.20_

- [ ] 18. Final validation — zero-warning analyse, full test run, and optional screenshots block

  - [x] 18.1 Run `flutter analyze --fatal-warnings --fatal-infos`
    - Execute at the repo root AND in `example/`.
    - **EXPECTED OUTCOME**: exit 0 with zero errors, zero warnings, zero infos.
    - If any diagnostic remains, fix the root cause (do NOT add `// ignore:` suppressions unless the rule is categorically wrong for a specific line — and in that case document why in a `///` comment).

  - [x] 18.2 Run the full test suite
    - `flutter test --reporter expanded` at the repo root.
    - All 13 exploration tests from Task 1 must PASS (they were designed to fail on unfixed code and pass on fixed code).
    - All preservation tests from Task 14 must PASS.
    - All unit / property / widget / packaging tests from Task 13 must PASS.
    - If Task 15 was implemented: `cd example && flutter test integration_test`.

  - [x] 18.3 Run `flutter pub publish --dry-run`
    - Execute at the repo root.
    - **EXPECTED OUTCOME**: no warnings about missing metadata or undocumented public members; the package is ready for pub.dev upload.
    - Report any pub.dev score deductions flagged by the dry run.

  - [ ] 18.4 Add `screenshots:` block to `pubspec.yaml`
    - **OPTIONAL** — skip unless the PNGs at `images/advancedChessBoardSS1.png` and `images/advancedChessBoardSS2.png` exist and have been visually reviewed for the 3.0.0 release. Broken image paths cause pub.dev score deductions, so don't ship this speculatively.
    - Append under `pubspec.yaml`:
      ```yaml
      screenshots:
        - description: "Default chess board layout"
          path: images/advancedChessBoardSS1.png
        - description: "Chess board with arrows and highlights"
          path: images/advancedChessBoardSS2.png
      ```
    - Re-run `flutter pub publish --dry-run` and confirm no image-path warnings.

  - [ ] 18.5 Generate golden widget tests for pixel-level preservation
    - **OPTIONAL** — goldens are fiddly across Flutter versions / platforms. Skip unless the preservation claims around arrow geometry, checkmate tint, and `enableMoves: false` rendering require pixel-exact verification beyond the numeric tests in Task 14.
    - If implemented: generate goldens against the CURRENT (fixed) code state as the baseline, since the unfixed code is no longer available by this task. The PBTs in Task 14 already cover the semantic preservation claims; goldens only add pixel-level guardrails for future refactors.
    - Use `matchesGoldenFile('goldens/default_board.png')` etc.; check baseline PNGs into `test/goldens/`.
  - _Requirements: 2.34, 3.17, 3.20_
  - _Validates: P1.21, all P1.x and P2.x via the full-suite run_

- [x] 19. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
  - Confirm `flutter analyze --fatal-warnings --fatal-infos` exits 0 both at the repo root and in `example/`.
  - Confirm `flutter test` exits 0 with no skipped tests other than any explicitly tagged `skip:` for reasons documented in-test.
  - Confirm `flutter pub publish --dry-run` reports no metadata / documentation deductions.
  - Confirm the 13 exploration tests from Task 1 now PASS on fixed code (they encoded the expected behaviour; their flip from FAIL → PASS is the fix-test signal).
  - Confirm all preservation tests from Task 14 still PASS (no regressions).
