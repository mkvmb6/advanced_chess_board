# Implementation Plan

> **Feature**: `advanced_chess_board` 3.0.0 → 3.1.0 additive UX enhancements.
> Target release: 3.1.0. Additive and non-breaking — no preservation clause (P1–P27 in `requirements.md`) may regress.
> Each leaf task references the requirements clauses (`1.5`, `2.6`, …) it satisfies and the correctness properties (`P1.x`, `P2.x`) it validates; preservation references (`P1`–`P27` from `requirements.md → Preservation Requirements`) are added where relevant.
> Property-based testing (`glados`) is preferred wherever the input space is continuous. Ordering honours the capability dependency chain: foundations → shared plumbing → `BoardTheme` → `PieceSet` → `CoordinateLabels` → `SoundPack` → `HintArrow` → drag indicator → tests → preservation → example / CHANGELOG / README → final validation.

## Overview

Implement six additive capabilities on top of the 3.0.0 board:

1. **`BoardTheme`** — value type bundling every paintable `Color`, five presets, `copyWith` with `_unset` sentinel for nullable fields.sssssssssssss
2. **`PieceSet`** — abstract image-provider plug-in; default `PieceSet.chessDotCom` wraps the bundled PNGs; `PieceSet.fromAssetMap(...)` convenience factory.
3. **`CoordinateLabels`** — `inside` (3.0.0 default), `outside` (labels in gutters), `none` (no labels, no gutter).
4. **`SoundPack` + `SoundEvent`** — opt-in audio hook, silent by default. Priority-ordered classifier (`gameEnd > promote > castle > check > capture > move`). Zero bundled audio, zero plugin dependency.
5. **`HintArrow`** — engine/app suggestion arrow, visually distinct from `ChessArrow` (dashed shaft + stroke-only outlined arrowhead in lime green). Auto-dismisses on next successful move or after an optional `Duration`.
6. **Drag-legality indicator** — thickened ring on the legal-destination square currently under the drag pointer; translucent red tint on non-source, non-legal squares. Gated off by `enableMoves: false`.

Every change is opt-in. Default behaviour of 3.0.0 stays pixel-identical (Preservation P1–P27, P1.4, P2.1–P2.12).

## Tasks

- [x] 1. Foundations — version bump, dev dep, directory skeleton
  - Update `pubspec.yaml`: change `version: 3.0.0` → `version: 3.1.0` (single-line edit; keep every other key).
  - Update `dev_dependencies` in `pubspec.yaml`: add `fake_async: ^1.3.1` (needed for hint-duration PBTs in Task 8.10 / 8.11). No new runtime dependency — preserving Requirement 4's "dependency-light" stance.
  - Create the new source directory skeleton (empty directories are fine; tasks below populate them):
    - `lib/src/theme/`
    - `lib/src/piece_set/`
    - `lib/src/coordinates/`
    - `lib/src/sound/`
    - `lib/src/hint/`
  - Create the new test directory skeleton:
    - `test/theme/`
    - `test/piece_set/`
    - `test/coordinates/`
    - `test/sound/`
    - `test/hint_arrow/`
    - `test/drag_indicator/`
  - Run `flutter pub get` at the repo root AND in `example/` — confirm resolution is clean (no version-solver errors).
  - **NOTE**: `flutter analyze` at this point will still be clean because no code has been added yet; the only change is a version number, a dev dep, and empty folders.
  - _Requirements: 8.1_
  - _Preservation: P25 (existing parameters untouched)_

- [x] 2. Extract shared square-to-canvas helper into `arrow_geometry.dart`
  - Create `lib/src/utils/arrow_geometry.dart` containing the `getIndexFromSquare(String square, PlayerColor orientation)` helper currently embedded as an instance method in `lib/src/utils/arrow_painter.dart`. Signature:
    ```dart
    /// Maps an algebraic [square] (e.g. `"e4"`) to a `(row, col)` index pair
    /// in the board's visual coordinate space, accounting for [orientation].
    (int, int) getIndexFromSquare(String square, PlayerColor orientation);
    ```
    Include dartdoc identical in intent to the 3.0.0 inline version.
  - Modify `lib/src/utils/arrow_painter.dart`: remove the instance method `getIndexFromSquare`; import the new helper; rewrite the `paint` method to call `getIndexFromSquare(arrow.startSquare, boardOrientation)` as a top-level function. No geometry change. No visible behaviour change — `shouldRepaint` and painter output are byte-identical.
  - Run `flutter analyze --fatal-warnings --fatal-infos` at the repo root; confirm zero diagnostics.
  - _Requirements: (none directly — structural refactor prerequisite for Task 8.2)_
  - _Preservation: P14, P15 (`ArrowPainter` geometry + orientation mapping unchanged)_
  - _Validates: P2.5 (ArrowPainter geometry preserved)_

- [x] 3. `BoardTheme` value type
  - **Goal**: Add the `BoardTheme` value type, its five preset getters, `copyWith`, `==` / `hashCode`. Consumer-facing — no integration into `AdvancedChessBoard` yet (that happens in Task 4).

  - [x] 3.1 Create `lib/src/theme/board_theme.dart`
    - Copy the `BoardTheme` API verbatim from `design.md → Proposed Public API → BoardTheme`. Concretely:
      - `@immutable class BoardTheme` with `const` constructor taking 11 named parameters: `lightSquareColor`, `darkSquareColor`, `selectionColor`, `lastMoveHighlightColor`, `legalDestinationColor`, `coordinateLabelColor` (nullable), `kingCheckmateColor`, `kingCheckColor` (nullable), `hintArrowColor`, `dragLegalRingColor`, `dragIllegalTintColor`. Defaults match 3.0.0 exactly:
        - `lightSquareColor = const Color(0xFFEBECD0)`
        - `darkSquareColor = const Color(0xFF739552)`
        - `selectionColor = const Color(0x9BFFEB3B)`
        - `lastMoveHighlightColor = const Color(0x80FFEB3B)`
        - `legalDestinationColor = const Color(0x40000000)`
        - `coordinateLabelColor = null`
        - `kingCheckmateColor = const Color(0x9BF44336)`
        - `kingCheckColor = null`
        - `hintArrowColor = const Color(0x9932CD32)`
        - `dragLegalRingColor = const Color(0xA0FFFFFF)`
        - `dragIllegalTintColor = const Color(0x40F44336)`
      - Five preset `static const BoardTheme` getters: `classicGreen` (`const BoardTheme()`), `brown` (`0xFFF0D9B5` / `0xFFB58863`), `blue` (`0xFFDEE3E6` / `0xFF8CA2AD`), `purple` (`0xFFE8E3F3` / `0xFF8476B5`), `monochrome` (`0xFFEEEEEE` / `0xFF606060`).
      - `BoardTheme copyWith({...})` with the `_unset` sentinel pattern on `coordinateLabelColor` and `kingCheckColor` (the two nullable fields) so that callers can explicitly set them to `null`. Declare `const Object _unset = Object();` at file scope (private — single `_` prefix, file-local).
      - `operator ==` and `hashCode` over all 11 fields (use `Object.hash` for the hashCode).
    - Every public member (class, constructor, every field, every preset getter, `copyWith`) carries a `///` dartdoc comment — `public_member_api_docs` must stay clean.
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.8, 1.9_
  - _Validates: P1.1 (value equality slice), P1.2 (copyWith)_

  - [x] 3.2 `test/theme/board_theme_equality_test.dart`
    - PBT slice for `BoardTheme`. Uses `any.boardTheme` (added in Task 15) or inline `Glados2<Color, Color>`.
    - Property header comment:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.1:
      // BoardTheme's `==` / `hashCode` respect all 11 fields — equal inputs
      // compare equal and have equal hashes; any single differing field
      // flips equality to false.
      ```
    - Assertions:
      - For field-equal inputs, `t1 == t2` is true AND `t1.hashCode == t2.hashCode`.
      - For each of the 11 fields individually, constructing two themes differing only in that field asserts `t1 != t2`.
    - _Validates: P1.1 (BoardTheme slice)_
    - _Requirements: 1.1_

  - [x] 3.3 `test/theme/board_theme_copywith_test.dart`
    - PBT: for any `BoardTheme t` and any single-field replacement, `t.copyWith(fieldName: newValue)` returns a theme whose `fieldName == newValue` and every other field equals `t`'s.
    - Example subcase: `t.copyWith(coordinateLabelColor: null)` explicitly assigns `null` (tests the `_unset` sentinel path); `t.copyWith(/* no arg */)` leaves `coordinateLabelColor` equal to `t.coordinateLabelColor`.
    - _Validates: P1.2_
    - _Requirements: 1.8_

  - [x] 3.4 `test/theme/board_theme_presets_test.dart`
    - Example assertion (P1.4): `BoardTheme.classicGreen.lightSquareColor == const Color(0xFFEBECD0)` AND `BoardTheme.classicGreen.darkSquareColor == const Color(0xFF739552)` — pins the 3.0.0 palette bit-for-bit.
    - Example assertion (P1.5): for every pair of distinct preset names in `{classicGreen, brown, blue, purple, monochrome}`, the two presets are not `==`. Iterate across `C(5, 2) = 10` pairs.
    - _Validates: P1.4, P1.5_
    - _Requirements: 1.3, 1.4_

- [x] 4. Thread `_effectiveTheme` through `AdvancedChessBoard` + extend `HighlightOverlay`
  - **Goal**: Wire the new `boardTheme` parameter into every paint site in `AdvancedChessBoard`, with legacy-wins resolution, and extend `HighlightOverlay` to accept a themed `Color`. No other capability depends on paint colours yet — this task is the single gate that lights up all the new theming seams.

  - [x] 4.1 Extend `HighlightOverlay` with a `Color color` required field
    - In `lib/src/widgets/highlight_overlay.dart`: add `final Color color;` as a required named field (no default — forces caller to thread the effective theme colour so the 3.0.0 shade is pinned via the preset).
    - Replace `Colors.black12.withAlpha(75)` (ring border) with `color.withAlpha(75)`.
    - Replace `Colors.black12.withAlpha(100)` (dot fill) with `color.withAlpha(100)`.
    - When called with `BoardTheme.classicGreen.legalDestinationColor == Color(0x40000000)`, `color.withAlpha(75)` and `color.withAlpha(100)` must produce the same ARGB values the 3.0.0 hard-coded call produced — verify in 4.3's widget PBT.
    - _Requirements: 1.5_
    - _Preservation: P12_
    - _Validates: P2.4 (legal-destination hint preserved)_

  - [x] 4.2 Modify `lib/src/advanced_chess_board.dart` — add `boardTheme` field, `_effectiveTheme` getter, thread every paint site
    - Add the new constructor parameter: `this.boardTheme = BoardTheme.classicGreen` (const default).
    - Add the final field: `final BoardTheme boardTheme;` with full dartdoc explaining the legacy-wins resolution and pointing at the class-level docs.
    - Add a private getter implementing the legacy-wins resolution:
      ```dart
      BoardTheme get _effectiveTheme => widget.boardTheme.copyWith(
            lightSquareColor: widget.lightSquareColor,
            darkSquareColor: widget.darkSquareColor,
            kingCheckmateColor: widget.kingBackgroundColorOnCheckmate ??
                widget.boardTheme.kingCheckmateColor,
          );
      ```
      Rationale: `lightSquareColor` and `darkSquareColor` are non-nullable with 3.0.0 defaults already equal to `BoardTheme.classicGreen` — passing the 3.0.0 default is indistinguishable from passing nothing, and that is correct (see design.md rationale).
    - Replace every hard-coded colour in `_buildChessBoard`, `_buildSquareWithDragTarget`, `_buildCheckmateKingOverlay` (renamed in the next sub-task), and the `ChessSquare`/`HighlightOverlay` construction sites:
      - `widget.lightSquareColor` / `widget.darkSquareColor` → `_effectiveTheme.lightSquareColor` / `_effectiveTheme.darkSquareColor`.
      - `Color(0x9BFFEB3B)` (selection) → `_effectiveTheme.selectionColor`.
      - `Color(0x80FFEB3B)` (last-move) → `_effectiveTheme.lastMoveHighlightColor`.
      - Pass `color: _effectiveTheme.legalDestinationColor` to every `HighlightOverlay(...)` construction.
      - `widget.kingBackgroundColorOnCheckmate ?? const Color(0x9BF44336)` → `_effectiveTheme.kingCheckmateColor` (the legacy parameter folds into `_effectiveTheme` at the top of the getter).
    - Rename `_buildCheckmateKingOverlay` → `_buildKingStateOverlay(chess.Piece piece)` and branch on `in_checkmate` vs `in_check`:
      ```dart
      Widget _buildKingStateOverlay(chess.Piece piece) {
        if (piece.type != chess.PieceType.KING || piece.color != _game.turn) {
          return const SizedBox.shrink();
        }
        if (_game.in_checkmate) {
          return Positioned.fill(
            child: ColoredBox(color: _effectiveTheme.kingCheckmateColor),
          );
        }
        if (_game.in_check && _effectiveTheme.kingCheckColor != null) {
          return Positioned.fill(
            child: ColoredBox(color: _effectiveTheme.kingCheckColor!),
          );
        }
        return const SizedBox.shrink();
      }
      ```
      The `_effectiveTheme.kingCheckColor == null` branch is a no-op, matching 3.0.0 (no in-check tint).
    - Thread `_effectiveTheme.coordinateLabelColor` into every `ChessSquare(...)` call as the new `labelColor` field (Task 6.2 adds the field — wiring is a stub until then, but the theme colour must flow).
    - _Requirements: 1.2, 1.5, 1.6, 1.7_
    - _Preservation: P11, P12, P16, P25_
    - _Validates: P1.3, P1.4_

  - [x] 4.3 `test/theme/effective_theme_test.dart`
    - Widget PBT over `(theme, legacyLight, legacyDark, legacyMate)` tuples (use `any.boardTheme` from Task 15, plus nullable `legacy*` colours).
    - Property header comment:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.3:
      // _effectiveTheme = theme.copyWith(
      //   lightSquareColor: legacyLight ?? theme.lightSquareColor,
      //   darkSquareColor:  legacyDark  ?? theme.darkSquareColor,
      //   kingCheckmateColor: legacyMate ?? theme.kingCheckmateColor,
      // ); every other field passes through from `theme` untouched.
      ```
    - To observe `_effectiveTheme` from tests, add a `@visibleForTesting` package-internal static helper `effectiveThemeOf(AdvancedChessBoardState s)` (or equivalent) and import `package:flutter/foundation.dart`'s `@visibleForTesting` annotation. The helper returns the state's current `_effectiveTheme`.
    - Pump an `AdvancedChessBoard` with random `boardTheme`, random legacy overrides (sometimes null, sometimes set), and read the effective theme; assert the resolution formula on every one of the 11 fields.
    - Also assert P1.4 fallthrough: with `boardTheme = BoardTheme.classicGreen` and no legacy overrides, `_effectiveTheme == BoardTheme.classicGreen`.
    - _Validates: P1.3, P1.4_
    - _Requirements: 1.5, 1.6, 1.7_

  - [x] 4.4 Analyser hygiene checkpoint
    - Run `flutter analyze --fatal-warnings --fatal-infos` at the repo root.
    - Run `flutter analyze --fatal-warnings --fatal-infos` in `example/` (no example changes yet — this is the no-op baseline).
    - Both must exit 0 with zero errors, zero warnings, zero infos. Fix the root cause of any diagnostic (e.g. missing dartdoc, `strict-inference` failures) before proceeding. Do NOT add `// ignore:` suppressions.
    - _Requirements: 9.1, 9.2, 9.3, 9.4_
    - _Preservation: P25, P26_

- [x] 5. `PieceSet` abstraction
  - **Goal**: Introduce the `PieceSet` plug-in, migrate every piece render site off the 12-branch `getChessPieceWidget` helper, and preserve the `didChangeDependencies` precache contract (Preservation P22) while extending it to handle `didUpdateWidget` swaps.

  - [x] 5.1 Create `lib/src/piece_set/piece_set.dart`
    - Copy the `PieceSet` API verbatim from `design.md → Proposed Public API → PieceSet`. Concretely:
      - `@immutable abstract class PieceSet` with a `const PieceSet()` base constructor.
      - Single abstract method: `ImageProvider imageFor(PlayerColor color, chess.PieceType type)` with dartdoc explaining the "called once per rendered piece per build — cache aggressively" contract.
      - `static const PieceSet chessDotCom = _ChessDotComPieceSet();` — the default.
      - `const factory PieceSet.fromAssetMap(Map<({PlayerColor color, chess.PieceType type}), ImageProvider> map) = _MapBackedPieceSet;`.
    - Add `_ChessDotComPieceSet` as a private subclass with a `const _ChessDotComPieceSet();` constructor; `imageFor` switches over `(color, type)` and returns `const AssetImage(path, package: packageName)` where `path` is the corresponding `PieceImages` constant from `lib/src/constants/image_constants.dart`. Two instances are const-canonicalised so `==` is trivially true across constructions.
    - Add `_MapBackedPieceSet` as a private subclass storing the passed-in map. Implement:
      - `const _MapBackedPieceSet(this._map) : assert(_map.length == 12, '...');` — the debug-mode guard.
      - A non-const runtime guard path that throws `ArgumentError` when any of the 12 `(color, type)` keys is absent (iterate over `PlayerColor.values × chess.PieceType.values` minus the `chess.PieceType.NONE` sentinel if present).
      - `imageFor` as a `_map[(color: color, type: type)]!` lookup.
      - `==` / `hashCode` over the 12 map entries iterating in a canonical `(color, type)` order (e.g. `[(white, PAWN), (white, KNIGHT), …, (black, KING)]`) so equal maps compare equal for the `didUpdateWidget` swap check in Task 5.5.
    - Every public member (class, `imageFor`, `chessDotCom`, `fromAssetMap`) carries dartdoc.
    - _Requirements: 2.1, 2.2, 2.3, 2.8_
    - _Validates: P1.1 (PieceSet slice), P1.6_

  - [x] 5.2 Replace `getChessPieceWidget` with `buildPieceWidget(chess.Piece, PieceSet)`
    - In `lib/src/utils/utils.dart`:
      - Delete the 12-branch `Widget getChessPieceWidget(chess.Piece chessPiece)` function and its private `_getPieceImageWidget(String assetPath)` helper entirely.
      - Add `Widget buildPieceWidget(chess.Piece piece, PieceSet set)` that returns `Image(image: set.imageFor(playerColorOf(piece.color), piece.type), fit: BoxFit.contain)` where `playerColorOf` maps `chess.Color.WHITE → PlayerColor.white` and `chess.Color.BLACK → PlayerColor.black`.
      - Add a private `PlayerColor _playerColorOf(chess.Color c)` helper with the trivial mapping; dartdoc on `buildPieceWidget` explaining the abstraction swap.
      - `pieceTypeToString(final PieceType pieceType)` stays unchanged.
      - `pieceSemanticsLabel(final Piece? piece)` stays unchanged.
    - _Requirements: 2.2, 2.4, 2.5_
    - _Validates: P1.7_

  - [x] 5.3 Thread `PieceSet` through every piece render site
    - `lib/src/widgets/chess_piece_widget.dart`:
      - Add `final PieceSet pieceSet;` required field.
      - Replace `getChessPieceWidget(piece)` in `build()` with `buildPieceWidget(piece, pieceSet)`.
    - `lib/src/widgets/move_animation_layer.dart`:
      - Add `final PieceSet pieceSet;` required field.
      - Pass it to the inner `ChessPieceWidget(...)`.
    - `lib/src/advanced_chess_board.dart`:
      - In every construction site of `ChessPieceWidget(...)` (the `_buildPiece(...)` method, the `Draggable.feedback:` field, the `MoveAnimationLayer(...)` construction, and the promotion dialog's `ChessPieceWidget` list) — add `pieceSet: widget.pieceSet`.
      - `Draggable.childWhenDragging: const SizedBox.shrink()` stays unchanged — no piece rendered.
    - _Requirements: 2.5_
    - _Preservation: P23 (Semantics label derivation is unchanged — `pieceSemanticsLabel(piece)` still produces `"white pawn"` etc.)_
    - _Validates: P1.7, P2.10_

  - [x] 5.4 Add `pieceSet` parameter + default to `AdvancedChessBoard`
    - In `lib/src/advanced_chess_board.dart` constructor, add `this.pieceSet = PieceSet.chessDotCom`.
    - Add `final PieceSet pieceSet;` field with full dartdoc.
    - _Requirements: 2.4_
    - _Preservation: P25 (no removal of existing parameters)_

  - [x] 5.5 Wire precache across mount and `didUpdateWidget` swaps
    - Replace the existing `didChangeDependencies` precache loop with a helper:
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
    - `didChangeDependencies`: preserve the `if (_precached) return;` gate; call `_precacheActivePieceSet()` on first run; then set `_precached = true`.
    - `didUpdateWidget(old)`: if `old.pieceSet != widget.pieceSet`, call `_precacheActivePieceSet()` (unconditionally — a swap forces a fresh precache) and trigger a `setState(() {})` so the next build uses the new `ImageProvider`s. Leave `_precached = true` so we don't double-precache on the next `didChangeDependencies`.
    - Remove the `kAllPieceAssetPaths` constant if no other consumer references it (`grepSearch` first); otherwise leave it as a historical reference. The new precache path goes through `PieceSet.imageFor`, not the hard-coded list.
    - _Requirements: 2.6, 2.7_
    - _Preservation: P22_
    - _Validates: P1.8_

  - [x] 5.6 `test/piece_set/piece_set_equality_test.dart`
    - PBT slice for `PieceSet` equality. Two `PieceSet.chessDotCom` are `==`. Two `PieceSet.fromAssetMap(m)` with map-equal `m` compare `==`. Any single-entry difference flips to `!=`.
    - Property header comment:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.1:
      // PieceSet's `==` / `hashCode` respect the 12 `(color, type) → ImageProvider`
      // entries of the set; reference-equal const subclasses compare equal;
      // map-backed sets compare equal iff the 12 entries are map-equal.
      ```
    - _Validates: P1.1 (PieceSet slice)_
    - _Requirements: 2.1_

  - [x] 5.7 `test/piece_set/piece_set_chessdotcom_test.dart`
    - Example test over the 12-entry `(PlayerColor, chess.PieceType)` domain. Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.6:
      // PieceSet.chessDotCom.imageFor(color, type) equals
      // const AssetImage(PieceImages.<...>, package: 'advanced_chess_board')
      // for every one of the 12 (color, type) pairs.
      ```
    - For each of the 12 pairs, assert `PieceSet.chessDotCom.imageFor(color, type)` compares `==` to the expected `AssetImage(path, package: 'advanced_chess_board')` (or assert the `AssetImage.keyName` / `package` fields if `==` is not const-canonicalised).
    - _Validates: P1.6_
    - _Requirements: 2.2, 2.3_

  - [x] 5.8 `test/piece_set/piece_set_custom_render_test.dart`
    - Widget PBT: pump an `AdvancedChessBoard` with a custom `PieceSet.fromAssetMap(...)` that maps every entry to a `MemoryImage(kTransparentImageBytes)`. Assert every `ChessPieceWidget` in the rendered tree (board squares, `Draggable.feedback` during a simulated drag, promotion dialog after triggering a promotion, `MoveAnimationLayer` during a tap move) references the custom set — specifically, `find.byType(Image)` should only surface instances whose `image` property is a `MemoryImage` matching the custom map.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.7:
      // For any custom PieceSet, every ChessPieceWidget rendered by the
      // board references that set via widget.pieceSet; no ImageProvider
      // outside the set's `imageFor` output is used.
      ```
    - _Validates: P1.7_
    - _Requirements: 2.4, 2.5_

  - [x] 5.9 `test/piece_set/piece_set_precache_test.dart`
    - Widget PBT: pump the board; after `tester.pumpAndSettle()`, inspect `PaintingBinding.instance.imageCache` and assert all 12 providers of the active set are present (use `imageCache.containsKey(provider.obtainKey(configuration))` for each of the 12).
    - Part 2: `pumpWidget` with a DIFFERENT `PieceSet` (via `fromAssetMap(...)`); after `pumpAndSettle()`, assert the 12 providers of the NEW set are also in the cache AND the board rebuilt (e.g. a `find.byWidgetPredicate((w) => w is Image && w.image == newSet.imageFor(...))` returns matches).
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.8:
      // Active PieceSet is precached on first didChangeDependencies; swapping
      // pieceSet across didUpdateWidget precaches the new set's 12 providers
      // and the next build renders with the new set.
      ```
    - _Validates: P1.8; Preservation P22_
    - _Requirements: 2.6, 2.7_

- [x] 6. `CoordinateLabels` enum + `inside` / `outside` / `none` wiring
  - **Goal**: Introduce the `CoordinateLabels` enum, teach `ChessSquare` to suppress inside labels when asked, build the outside-gutter layout via a new `_CoordinateGutter` helper, and branch the board build on the mode. Preserves the `AspectRatio(1)` contract on the playing grid and the `kMinLabelFontSize` floor.

  - [x] 6.1 Create `lib/src/coordinates/coordinate_labels.dart`
    - Public enum with exactly three values: `inside`, `outside`, `none`. Dartdoc on the enum and each value per `design.md`.
    - In the same file or a sibling file, add the private `_CoordinateGutter` widget signature (concrete implementation arrives in 6.3):
      ```dart
      /// A gutter strip (rank or file) used when CoordinateLabels.outside is active.
      class _CoordinateGutter extends StatelessWidget { ... }
      ```
      Keep `_CoordinateGutter` file-local to whichever file uses it (most naturally `lib/src/advanced_chess_board.dart` or a sibling under `lib/src/coordinates/`). The enum itself is the only public symbol in this file.
    - _Requirements: 3.1_

  - [x] 6.2 Modify `lib/src/widgets/chess_square.dart` — add `coordinates` and `labelColor` fields, suppress inside labels off-mode
    - Add `final CoordinateLabels coordinates;` required field (default at construction sites — not on the class — so that the type is pinned by whoever builds the tree; this matches the existing required-field convention for `ChessSquare`).
    - Add `final Color? labelColor;` optional nullable field. When non-null, the label uses that colour at alpha 200; when null, fall back to the 3.0.0 behaviour of `invertColor.withAlpha(200)`.
    - Gate the `if (isRankRendered)` and `if (isFileRendered)` emission on `coordinates == CoordinateLabels.inside`. When `coordinates != inside`, neither label renders inside the square — even on the a-file / 1st-rank edges.
    - Preserve the `math.max(kMinLabelFontSize, squareSize * 0.18)` floor unchanged (Preservation P19).
    - _Requirements: 3.2, 3.3, 3.4, 3.9_
    - _Preservation: P19, P23 (Semantics wrapper unchanged)_
    - _Validates: P1.9, P1.14_

  - [x] 6.3 Implement `_CoordinateGutter` and the outside-mode layout helper
    - Inside `lib/src/advanced_chess_board.dart` (or a co-located file under `lib/src/coordinates/`) add the private `_CoordinateGutter` widget: parameters `{Axis axis, List<String> labels, double gutterSize, double squareSize, Color? labelColor}`. Renders a `Column` (when `axis == vertical`) or `Row` (when `axis == horizontal`) of `Expanded(child: Center(child: Text(l, style: TextStyle(fontSize: math.max(kMinLabelFontSize, squareSize * 0.18), color: (labelColor ?? Theme.of(context)... /* match inside-label 3.0.0 rule */).withAlpha(200))))`. The label-colour derivation matches the inside-label rule so `coordinateLabelColor: null` yields visually consistent gutters.
    - Implement the outside layout exactly per `design.md → Rendering / Layout Strategy → Outside coordinates layout`:
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
          SizedBox(width: gutterSize,
              child: _CoordinateGutter(axis: Axis.vertical, labels: ranks,
                  gutterSize: gutterSize, squareSize: squareSize,
                  labelColor: _effectiveTheme.coordinateLabelColor)),
          Expanded(child: Column(children: [
            Expanded(child: AspectRatio(aspectRatio: 1,
                child: _buildChessBoard(squareSize))),
            SizedBox(height: gutterSize,
                child: _CoordinateGutter(axis: Axis.horizontal,
                    labels: filesOrdered, gutterSize: gutterSize,
                    squareSize: squareSize,
                    labelColor: _effectiveTheme.coordinateLabelColor)),
          ])),
        ]);
      }
      ```
    - The `AspectRatio(aspectRatio: 1)` wraps ONLY the playing grid; the enclosing `Row` is NOT 1:1 (Requirement 3.7, Preservation P21).
    - _Requirements: 3.5, 3.6, 3.7, 3.9, 3.10_
    - _Preservation: P19, P21_
    - _Validates: P1.10, P1.11, P1.12, P1.14, P1.15_

  - [x] 6.4 Branch the `build()` method on `widget.coordinates`
    - In `AdvancedChessBoardState.build()` (inside the `LayoutBuilder.builder`), add a branch:
      ```dart
      final child = switch (widget.coordinates) {
        CoordinateLabels.inside  => AspectRatio(aspectRatio: 1,
            child: _buildChessBoard(squareSize)),
        CoordinateLabels.outside => _buildWithOutsideGutter(squareSize),
        CoordinateLabels.none    => AspectRatio(aspectRatio: 1,
            child: _buildChessBoard(squareSize)),
      };
      ```
      and wrap `child` in the `ListenableBuilder` + `Stack` stack that already exists. The `inside` and `none` branches differ only in whether `ChessSquare.coordinates` passes `inside` (label visible) or `none` (label suppressed — 6.2 handles the branch inside the square).
    - Also add the parameter + default: `this.coordinates = CoordinateLabels.inside` on the constructor; `final CoordinateLabels coordinates;` field with full dartdoc.
    - _Requirements: 3.1, 3.2, 3.8_
    - _Preservation: P21_

  - [x] 6.5 `test/coordinates/inside_labels_test.dart`
    - Example over the 64-square × 2-orientation domain (128 cases). For each `(square, orientation)`:
      - With `coordinates == inside` and the given orientation, pump a board; find the `ChessSquare` for `square`; assert a rank `Text` renders iff `square[0] == (orientation == white ? 'a' : 'h')` and a file `Text` renders iff `square[1] == (orientation == white ? '1' : '8')`.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.9:
      // Inside labels render only on the a/h file and 1/8 rank edges,
      // orientation-appropriate.
      ```
    - _Validates: P1.9_
    - _Requirements: 3.3, 3.4_

  - [x] 6.6 `test/coordinates/outside_layout_test.dart`
    - Three assertions, shared setup: pump `AdvancedChessBoard(coordinates: CoordinateLabels.outside, boardOrientation: …)` under a fixed constraint (e.g. 512 px).
    - **P1.10 assertion**: find each of the 8 rank-gutter `Text` widgets and each of the 8 file-gutter `Text` widgets; for every pair, assert their rendered `Rect` (`tester.getRect(find.byWidget(w))`) does NOT intersect the playing-grid `Rect` (`tester.getRect(find.byType(Column).first)` — the Column of Rows that is the playing grid). Similarly, assert no `ChessSquare`'s rect intersects any gutter label rect.
    - **P1.11 assertion**: parametrise over `orientation ∈ {white, black}`. For white: rank gutter reads `['8','7','6','5','4','3','2','1']` top-to-bottom; file gutter reads `['a','b',...,'h']` left-to-right. For black: rank gutter reads `['1','2',...,'8']`; file gutter reads `['h','g',...,'a']`. Collect gutter `Text`s via `find.descendant(of: find.byType(_CoordinateGutter), matching: find.byType(Text))` and assert the ordered text list.
    - **P1.12 assertion**: `tester.getRect(find.byType(Column).first).width == tester.getRect(find.byType(Column).first).height` (the playing grid is square). The enclosing `Row`'s width is NOT required to equal its height.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Properties P1.10, P1.11, P1.12:
      // Outside gutters are disjoint from the playing grid; orientation
      // reverses gutter label order; AspectRatio(1) wraps the playing grid only.
      ```
    - _Validates: P1.10, P1.11, P1.12; Preservation P21_
    - _Requirements: 3.5, 3.6, 3.7_

  - [x] 6.7 `test/coordinates/none_labels_test.dart`
    - Example: pump with `coordinates: CoordinateLabels.none`; assert `find.byWidgetPredicate((w) => w is Text && RegExp(r'^[a-h]$|^[1-8]$').hasMatch((w.data ?? "")))` evaluates to zero matches; assert `find.byType(_CoordinateGutter)` is also empty (no gutter allocated).
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.13:
      // CoordinateLabels.none renders no [a-h] or [1-8] single-letter labels
      // and allocates no gutter SizedBox.
      ```
    - _Validates: P1.13_
    - _Requirements: 3.8_

  - [x] 6.8 `test/coordinates/label_font_floor_test.dart`
    - Widget PBT over `squareSize ∈ (0, 1000]`. For each generated `squareSize`, pump with `coordinates: CoordinateLabels.inside` AND separately with `coordinates: CoordinateLabels.outside`; for every rendered coordinate label, assert `fontSize == math.max(kMinLabelFontSize, squareSize * 0.18)`.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.14:
      // Every rendered coordinate label (inside or outside) has
      // fontSize == max(kMinLabelFontSize, squareSize * 0.18).
      ```
    - _Validates: P1.14; Preservation P19_
    - _Requirements: 3.9_

  - [x] 6.9 `test/coordinates/narrow_board_test.dart`
    - Widget PBT over `boxWidth ∈ [16, 2 * kMinLabelFontSize * 8]` (i.e. [16, 144]). Pump with `coordinates: CoordinateLabels.outside` at each width; assert no `FlutterError` is raised by the tester (check `tester.takeException() == null` after `pumpAndSettle`); assert every gutter label's `fontSize >= kMinLabelFontSize`.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.15:
      // Outside mode does not overflow for boxWidth in [16, 144];
      // label fontSize >= kMinLabelFontSize.
      ```
    - _Validates: P1.15_
    - _Requirements: 3.10_

- [x] 7. `SoundEvent` / `SoundPack` / `SilentSoundPack` + classifier + hook
  - **Goal**: Introduce the silent-by-default audio abstraction and wire a single invocation site inside `_makeMove(...)`. No bundled audio, no new runtime dependency.

  - [x] 7.1 Create `lib/src/sound/sound_event.dart`
    - Public enum `SoundEvent` with exactly the six values per `design.md`: `move`, `capture`, `check`, `castle`, `promote`, `gameEnd`. Dartdoc on the enum explains the priority order; each value carries a one-line doc.
    - _Requirements: 4.1, 4.15_

  - [x] 7.2 Create `lib/src/sound/sound_pack.dart`
    - Public abstract class `SoundPack` with `const SoundPack();` constructor and a single abstract method `Future<void> play(SoundEvent event)`.
    - Public concrete class `SilentSoundPack extends SoundPack` with `const SilentSoundPack();` constructor and `Future<void> play(SoundEvent event) => Future<void>.value();`. Zero audio assets, zero plugin dependencies, zero platform channels.
    - Both classes and the `play` method carry dartdoc referencing the "no bundled audio" stance and the error-swallowing contract from Requirement 4.14.
    - _Requirements: 4.2, 4.3, 4.15_
    - _Validates: P1.20_

  - [x] 7.3 Create `lib/src/sound/move_classifier.dart`
    - Pure function `SoundEvent classifySoundEvent({required chess.Move verboseMove, required bool isGameOverAfter, required bool isInCheckAfter})` implemented per the pseudocode in `design.md → Sound classification algorithm`:
      ```dart
      SoundEvent classifySoundEvent({
        required chess.Move verboseMove,
        required bool isGameOverAfter,
        required bool isInCheckAfter,
      }) {
        final flags = verboseMove.flags;
        if (isGameOverAfter) return SoundEvent.gameEnd;
        if (flags.contains('p')) return SoundEvent.promote;
        if (flags.contains('k') || flags.contains('q')) return SoundEvent.castle;
        if (isInCheckAfter) return SoundEvent.check;
        if (flags.contains('c') || flags.contains('e')) return SoundEvent.capture;
        return SoundEvent.move;
      }
      ```
    - Function-level dartdoc documents the six flag characters used (`n`, `b`, `e`, `c`, `p`, `k`, `q`) as a reference table.
    - _Requirements: 4.5, 4.6, 4.7, 4.8, 4.9, 4.10, 4.11_
    - _Validates: P1.16_

  - [x] 7.4 Add `soundPack` parameter to `AdvancedChessBoard`
    - Constructor: `this.soundPack = const SilentSoundPack()`.
    - Field: `final SoundPack soundPack;` with full dartdoc (default `SilentSoundPack` — no audio; pass a custom subclass to hook an audio backend).
    - _Requirements: 4.4_
    - _Preservation: P25_
    - _Validates: P1.20_

  - [x] 7.5 Add `_firePlay(SoundEvent event)` helper
    - Private method on `_AdvancedChessBoardState`:
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
    - Both the synchronous `throw` (outer `try`/`catch`) and the async `Future.error` (`.catchError`) paths log via `debugPrint` and swallow — Requirement 4.14 is enforced here and NOWHERE else (so the test in 7.12 can peg this method).
    - _Requirements: 4.14_
    - _Validates: P1.19_

  - [x] 7.6 Wire the hook inside `_makeMove(...)` after `controller.makeMove(...)` returns `true`
    - Inside `_makeMove(from, to, squareSize)` in `lib/src/advanced_chess_board.dart`, AFTER `widget.controller.makeMove(from: from, to: to, promotion: promotion)` returns `accepted == true` AND BEFORE the existing animation-trigger `setState`, insert:
      ```dart
      final last = _game.history.last.move;
      final event = classifySoundEvent(
        verboseMove: last,
        isGameOverAfter: widget.controller.isGameOver,
        isInCheckAfter: widget.controller.isInCheck,
      );
      _firePlay(event);
      ```
    - `_makeMove` is the ONLY caller of `_firePlay` — the widget never calls `controller.makeMove(..., notify: false)` itself, and `_makeMove` is not triggered by `controller.undo` / `resetBoard` / `loadGameFromFEN`. This satisfies Requirements 4.12 and 4.13 by construction.
    - _Requirements: 4.5, 4.6, 4.7, 4.8, 4.9, 4.10, 4.11, 4.12, 4.13_
    - _Preservation: P1, P5_
    - _Validates: P1.16, P1.17, P1.18_

  - [x] 7.7 `test/sound/classifier_priority_test.dart`
    - PBT over `(chess.Chess position, legal move)` pairs, generated by `any.chessFen` then picking a random legal move from that position (requires `any.legalMoveFromRandomPosition` from Task 15). For each `(position, move)`, make the move on a cloned `chess.Chess`; compute an independent oracle via a plain-English `if`-table (same priority order) against the verbose move's `flags` and the post-move `in_check` / `game_over` booleans; assert `classifySoundEvent(...)` returns the same event as the oracle.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.16:
      // For any reachable position and any legal move, classifySoundEvent
      // returns the highest-priority event per
      // gameEnd > promote > castle > check > capture > move.
      ```
    - _Validates: P1.16_
    - _Requirements: 4.5, 4.6, 4.7, 4.8, 4.9, 4.10, 4.11_

  - [x] 7.8 `test/sound/classifier_examples_test.dart`
    - Hand-written example cases that pin the six branches individually (fallback for cases PBT generation is unlikely to hit reliably):
      - `move`: white pawn push `e2-e4` from starting FEN.
      - `capture`: white pawn captures black pawn from FEN `rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2` via `e4xd5`.
      - `check`: white plays `Qh5+` from FEN `rnbqkbnr/ppp2ppp/8/3pp3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2` (or similar — ensure the move delivers check without being mate/capture/promotion/castle).
      - `castle`: white castles kingside from FEN `r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1`.
      - `promote`: white pawn promotes to queen from FEN `8/P7/8/8/8/8/8/4k2K w - - 0 1` via `a7-a8=Q`.
      - `gameEnd`: Fool's Mate — white plays `f3`, black plays `e5`, white plays `g4`, black plays `Qh4#`. After the mate move, `isGameOverAfter == true`.
    - Each case: make the move on a `chess.Chess` instance; read `history.last.move` as the verbose move; assert `classifySoundEvent(...)` returns the expected `SoundEvent`.
    - _Validates: P1.16 (fallback)_
    - _Requirements: 4.5–4.11_

  - [x] 7.9 `test/sound/silent_default_test.dart`
    - Example: pump `AdvancedChessBoard(controller: c)` with NO `soundPack:` argument. Use a `@visibleForTesting` accessor (add one on the widget's state class — e.g. `SoundPack get debugSoundPack => widget.soundPack`) or assert via `widget.soundPack.runtimeType == SilentSoundPack`. Confirm `identical(widget.soundPack, const SilentSoundPack()) == true` (const canonicalisation).
    - Second assertion: `widget.soundPack.play(SoundEvent.move)` returns an already-resolved `Future<void>`; use `expect(widget.soundPack.play(SoundEvent.move), completes)` or drive `await` and assert no side effect (no exception thrown, no debugPrint captured via `debugPrint = (msg, {int? wrapWidth}) { ... }` override).
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.20:
      // Default AdvancedChessBoard uses const SilentSoundPack; play(e)
      // returns an already-resolved Future<void> with no side effect.
      ```
    - _Validates: P1.20_
    - _Requirements: 4.3, 4.4_

  - [x] 7.10 `test/sound/no_audio_on_undo_reset_load_test.dart`
    - Widget PBT: pump board with a `_CountingSoundPack` that increments a counter on `play(...)`. Drive random sequences of `controller.undo()`, `controller.resetBoard()`, `controller.loadGameFromFEN(...)` (all varied across `notify: true` and `notify: false`). After each sequence, assert the counter equals its pre-sequence value (zero increments).
    - `_CountingSoundPack`:
      ```dart
      class _CountingSoundPack extends SoundPack {
        const _CountingSoundPack(this.counter);
        final _Counter counter;
        @override
        Future<void> play(SoundEvent e) async { counter.value += 1; }
      }
      ```
      Use a mutable `_Counter` wrapper since `_CountingSoundPack` must stay `const`-compatible (an `int` field would prevent `const`; a reference-typed wrapper lets the counter mutate without breaking const).
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.17:
      // Controller undo/reset/loadGameFromFEN never fires SoundPack.play.
      ```
    - _Validates: P1.17_
    - _Requirements: 4.12_

  - [x] 7.11 `test/sound/no_audio_on_notify_false_test.dart`
    - Widget PBT: pump board with `_CountingSoundPack`. For each random legal move, invoke `controller.makeMove(from: ..., to: ..., notify: false)` directly on the controller (bypassing the widget's tap/drag paths). Assert counter stays zero.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.18:
      // controller.makeMove(..., notify: false) never fires SoundPack.play,
      // because notify-false moves don't flow through _makeMove.
      ```
    - _Validates: P1.18_
    - _Requirements: 4.13_

  - [x] 7.12 `test/sound/throwing_pack_test.dart`
    - Widget PBT: pump with a `_ThrowingSoundPack` that alternates between synchronous `throw StateError('boom')` and async `Future.error(StateError('boom'))`. Drive random legal moves via tap / drag / programmatic paths. Assert:
      - `tester.takeException() == null` after every pump — no exception escapes.
      - The next frame builds normally (`find.byType(AdvancedChessBoard)` still resolves).
      - Optionally capture `debugPrint` output and assert both the sync and async error messages are logged.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.19:
      // Sync or async throws from SoundPack.play are swallowed; the board's
      // next build runs normally and no exception propagates to the tester.
      ```
    - _Validates: P1.19_
    - _Requirements: 4.14_

- [x] 8. `HintArrow` + `HintArrowPainter` + widget wiring
  - **Goal**: Introduce the hint arrow channel, its distinct painter (dashed shaft + stroke-only outlined arrowhead), and reconcile its lifecycle with `hintArrow:` parameter changes and `_makeMove` completion.

  - [x] 8.1 Create `lib/src/hint/hint_arrow.dart`
    - `@immutable class HintArrow` with `const` constructor: `const HintArrow({required this.startSquare, required this.endSquare, this.duration})`.
    - Fields: `final String startSquare;`, `final String endSquare;`, `final Duration? duration;`.
    - `operator ==` and `hashCode` over all three fields (`Object.hash(startSquare, endSquare, duration)`).
    - Full dartdoc per `design.md` covering: the algebraic-square input format, the "persist until next move" semantics when `duration == null`, the "auto-dismiss after duration elapses" semantics otherwise, and the note that malformed square strings render off-canvas (no validator — Requirement 10).
    - _Requirements: 5.1, 5.9_
    - _Validates: P1.1 (HintArrow slice)_

  - [x] 8.2 Create `lib/src/hint/hint_arrow_painter.dart`
    - `class HintArrowPainter extends CustomPainter` with constructor `HintArrowPainter(this.arrow, this.theme, this.orientation)` — takes a single `HintArrow arrow`, a `BoardTheme theme`, and a `PlayerColor orientation`.
    - `paint(Canvas canvas, Size size)`:
      - Import and use `getIndexFromSquare(square, orientation)` from `lib/src/utils/arrow_geometry.dart` (extracted in Task 2).
      - Compute `blockSize = size.width / 8`; source/dest centres as in `ArrowPainter`.
      - Shaft: draw a manual dash pattern from `adjustedSourceX/Y` to `strokeDestX/Y`. Dash length `= blockSize * 0.15`, gap length `= blockSize * 0.10`. Walk `t ∈ [0, totalLength]` emitting `canvas.drawLine` segments at `[0, d, d+g, 2d+g, 2d+2g, ...]` until exhaustion. Stroke width `blockSize * 0.12` (thinner than `ArrowPainter`'s `0.16`).
      - Arrowhead: compute the three vertices exactly like `ArrowPainter` (tip + two base points separated by `pi/3` around the tip); draw via `canvas.drawPath(trianglePath, headPaint)` where `headPaint.style = PaintingStyle.stroke`, `headPaint.strokeWidth = blockSize * 0.06`, `headPaint.strokeJoin = StrokeJoin.round`. No fill.
      - Colour: `theme.hintArrowColor` for both shaft and head paints.
    - `shouldRepaint(covariant HintArrowPainter old)`: returns `true` iff any of `(arrow, theme.hintArrowColor, orientation)` differs.
    - _Requirements: 5.3_
    - _Validates: P1.22_

  - [x] 8.3 Add `hintArrow` parameter to `AdvancedChessBoard`
    - Constructor: `this.hintArrow` (nullable, no default — `null` is the default).
    - Field: `final HintArrow? hintArrow;` with full dartdoc.
    - _Requirements: 5.2_
    - _Preservation: P25_

  - [x] 8.4 Add `_activeHint` / `_hintTimer` state and reconciliation
    - `_AdvancedChessBoardState` gains:
      - `HintArrow? _activeHint;`
      - `Timer? _hintTimer;`
    - Import `dart:async` for `Timer`.
    - Add a private helper `_reconcileHint(HintArrow? next)`:
      ```dart
      void _reconcileHint(HintArrow? next) {
        if (next == null) {
          if (_activeHint != null) {
            setState(() { _activeHint = null; _hintTimer?.cancel(); _hintTimer = null; });
          }
          return;
        }
        if (_activeHint == next) return; // same value — leave timer running
        _hintTimer?.cancel();
        _hintTimer = null;
        setState(() { _activeHint = next; });
        if (next.duration != null) {
          _hintTimer = Timer(next.duration!, () {
            if (!mounted) return;
            setState(() { _activeHint = null; _hintTimer = null; });
          });
        }
      }
      ```
    - Call `_reconcileHint(widget.hintArrow)` at the end of `initState()` (AFTER the existing `initialFEN` load).
    - In `didUpdateWidget(old)`, call `_reconcileHint(widget.hintArrow)` (after the existing controller-swap logic; the swap also resets `_activeHint` — extend the controller-swap branch to add `_activeHint = null; _hintTimer?.cancel(); _hintTimer = null;` before reconciling).
    - In `_makeMove(...)`, AFTER `accepted == true` AND AFTER the `_firePlay(event)` from Task 7.6, add:
      ```dart
      if (_activeHint != null) {
        setState(() {
          _activeHint = null;
          _hintTimer?.cancel();
          _hintTimer = null;
        });
      }
      ```
    - Override `dispose()` to cancel the timer: `_hintTimer?.cancel();` before `super.dispose();`.
    - _Requirements: 5.4, 5.5, 5.6, 5.7_
    - _Preservation: P9 (controller swap clears hint state too)_
    - _Validates: P1.23, P1.24, P1.25, P1.26_

  - [x] 8.5 Insert hint painter into the `Stack` after the user-arrow `CustomPaint`
    - Inside the `ListenableBuilder.builder`'s `Stack` in `build()`, AFTER the existing `IgnorePointer(child: CustomPaint(painter: ArrowPainter(widget.arrows, widget.boardOrientation), ...))` entry, add:
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
    - Ordering is significant: the hint `CustomPaint` must be a strictly later child of the `Stack` than the user-arrow `CustomPaint` so the hint paints on top (Requirement 5.2 + P1.21).
    - _Requirements: 5.2_
    - _Validates: P1.21_

  - [x] 8.6 `test/hint_arrow/hint_arrow_equality_test.dart`
    - PBT slice for `HintArrow`. Pair-up via `any.hintArrow` (Task 15). Assert `==` and `hashCode` respect `startSquare`, `endSquare`, `duration` — equal inputs compare equal; any single differing field flips `!=`.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.1:
      // HintArrow's `==` / `hashCode` respect all three fields.
      ```
    - _Validates: P1.1 (HintArrow slice)_
    - _Requirements: 5.1_

  - [x] 8.7 `test/hint_arrow/hint_painter_layer_test.dart`
    - Widget PBT: for a random non-null `HintArrow` and a random `arrows: [...]` list, pump the board and traverse the `Stack` inside the `ListenableBuilder`; assert the `CustomPaint` whose painter is `HintArrowPainter` has a strictly greater child index than the `CustomPaint` whose painter is `ArrowPainter`.
    - Use `find.descendant(of: find.byType(ListenableBuilder), matching: find.byType(CustomPaint))` and inspect the `Element`'s children order.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.21:
      // HintArrowPainter's CustomPaint child index > ArrowPainter's child
      // index in the ListenableBuilder's Stack.
      ```
    - _Validates: P1.21_
    - _Requirements: 5.2_

  - [x] 8.8 `test/hint_arrow/hint_visual_distinct_test.dart`
    - Paint-trace unit PBT: instantiate `HintArrowPainter(arrow, theme, orientation)` over random inputs; drive `paint(canvas, size)` against a `RecordingCanvas` (or Flutter's `TestRecordingCanvas` helper); inspect the recorded commands.
    - Assertions:
      - Every shaft `drawLine` / `drawPath` emits a `Paint` with `color == theme.hintArrowColor`.
      - The arrowhead `drawPath` emits a `Paint` with `style == PaintingStyle.stroke` (NOT `fill`).
      - The shaft consists of ≥ 2 non-contiguous `drawLine` segments (dashing — the gap between segment N's end and segment N+1's start is `>= blockSize * 0.05`).
    - Symmetric assertion for `ArrowPainter` on the same `(arrow, orientation)` input: `drawPath` for the arrowhead uses `PaintingStyle.fill` (default). The shaft is a single `drawLine`. The assertions in the bullet above do NOT hold for `ArrowPainter` — distinctness pinned.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.22:
      // HintArrowPainter paints with hintArrowColor, stroke-only arrowhead,
      // and dashed (>=2 disjoint segments) shaft — none of which hold for
      // ArrowPainter.
      ```
    - _Validates: P1.22_
    - _Requirements: 5.3_

  - [x] 8.9 `test/hint_arrow/hint_dismiss_on_move_test.dart`
    - Widget PBT: pump with `hintArrow: const HintArrow(startSquare: 'g1', endSquare: 'f3')`; assert `find.byType(CustomPaint)` contains a `HintArrowPainter`; drive any legal move (tap, drag, or programmatic `controller.makeMove(...)`); `tester.pumpAndSettle()`; assert `find.byWidgetPredicate((w) => w is CustomPaint && w.painter is HintArrowPainter)` is empty.
    - Repeat across the three move paths.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.23:
      // After any successful tap/drag/programmatic move, no HintArrowPainter
      // appears in the next pumped frame.
      ```
    - _Validates: P1.23_
    - _Requirements: 5.4_

  - [x] 8.10 `test/hint_arrow/hint_dismiss_on_duration_test.dart`
    - Uses `package:fake_async`. Inside `FakeAsync().run((async) { ... })`: pump the board with `hintArrow: const HintArrow(startSquare: 'g1', endSquare: 'f3', duration: Duration(seconds: 2))`. Advance `1999 ms`; pump; assert hint is still rendered. Advance an additional `2 ms` (total `2001 ms > 2000 ms`); pump; assert no `HintArrowPainter` in the tree.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.24:
      // HintArrow auto-dismisses after duration + epsilon under FakeAsync.
      ```
    - _Validates: P1.24_
    - _Requirements: 5.5_

  - [x] 8.11 `test/hint_arrow/hint_replace_reset_test.dart`
    - `FakeAsync` PBT: pump `hintArrow: a` with `a.duration = Duration(seconds: 2)`. Advance `1000 ms`. Rebuild widget with `hintArrow: b != a`, same `duration`. Advance `1000 ms` — `b` would have dismissed if the timer had NOT reset (total elapsed from `a`'s start is `2000 ms`). Assert `b` is still rendered. Advance another `1100 ms` — `b`'s timer (reset on replacement) has now elapsed; assert no `HintArrowPainter`.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.25:
      // Replacing hintArrow before the previous dismissed resets the timer.
      // b persists past a's dismiss time, and dismisses b.duration after
      // b was set.
      ```
    - _Validates: P1.25_
    - _Requirements: 5.6_

  - [x] 8.12 `test/hint_arrow/hint_dismiss_on_null_test.dart`
    - Example widget test: pump with `hintArrow: const HintArrow(startSquare: 'g1', endSquare: 'f3')`; assert hint rendered. `pumpWidget` with `hintArrow: null`; assert no `HintArrowPainter` after the next frame.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.26:
      // Setting hintArrow to null dismisses the active hint on the next frame.
      ```
    - _Validates: P1.26_
    - _Requirements: 5.7_

  - [x] 8.13 `test/hint_arrow/hint_does_not_mutate_arrows_test.dart`
    - Widget PBT: pass a `final List<ChessArrow> arrows = [...]` literal; pump; drive a sequence of hint transitions (show, tick, replace, dismiss, re-show); after each step assert `identical(arrows, widget.arrows) == true` AND `arrows.length` AND each element is reference-identical to the original (`identical(arrows[i], original[i])`).
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.27:
      // The `arrows:` list passed to AdvancedChessBoard is never mutated by
      // any hint-arrow lifecycle transition.
      ```
    - _Validates: P1.27_
    - _Requirements: 5.8_

- [x] 9. Drag legality indicator
  - **Goal**: Paint a thickened ring on legal-destination squares under the drag pointer and a translucent red tint on non-source non-legal squares. Gate off when `enableMoves: false`. Keep the 3.0.0 `HighlightOverlay` visible underneath — the ring emphasises, not replaces.

  - [x] 9.1 Add private `_DragLegalRing` widget
    - In `lib/src/advanced_chess_board.dart` (or a sibling file under `lib/src/widgets/` if it stays there), add:
      ```dart
      class _DragLegalRing extends StatelessWidget {
        const _DragLegalRing({required this.color, required this.squareSize});
        final Color color;
        final double squareSize;
        @override
        Widget build(BuildContext context) {
          final circleSize = squareSize * 0.98;
          return Align(
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: squareSize * 0.1),
              ),
            ),
          );
        }
      }
      ```
    - The drag-illegal tint is intentionally NOT factored into a widget — it is a `Positioned.fill(child: ColoredBox(color: _effectiveTheme.dragIllegalTintColor))` emitted directly in the square's `Stack`.
    - _Requirements: 6.1_

  - [x] 9.2 Modify `_buildSquareWithDragTarget` to inspect `candidateData` / `rejectedData` and insert the layers
    - Inside the `DragTarget<String>.builder` callback, rename the positional args from `(ctx, _, __)` to `(ctx, candidateData, rejectedData)`.
    - Compute the three flags:
      ```dart
      final isDragSource = _isPieceDragging && square == _selectedSquare;
      final isDragLegalHover =
          widget.enableMoves && candidateData.isNotEmpty && !isDragSource;
      final isDragIllegalHover =
          widget.enableMoves && rejectedData.isNotEmpty && !isDragSource;
      ```
      `_selectedSquare` is already set to the drag source in `onDragStarted` — no additional state is needed.
    - Insert the two new layers into the square's `Stack` at the positions pinned by `design.md → Rendering / Layout Strategy → Drag indicator overlay stacking`:
      ```
      1. ChessSquare                   (base colour + inside label if any)
      2. Selection overlay             (translucent yellow on selected square)
      3. King mate/check tint          (red on mated king; themed check tint)
      4. HighlightOverlay              (legal-destination dot or ring)
      5. Drag-legal ring               NEW — above HighlightOverlay
      6. Drag-illegal tint             NEW — above bg, below piece
      7. Last-move highlight           (if not selected)
      8. Piece (Draggable)             (always top of this square's stack)
      ```
      Concretely, after the existing `if (isLegalTarget) HighlightOverlay(...)` insertion, add:
      ```dart
      if (isDragLegalHover)
        _DragLegalRing(
          color: _effectiveTheme.dragLegalRingColor,
          squareSize: squareSize,
        ),
      if (isDragIllegalHover)
        Positioned.fill(
          child: ColoredBox(color: _effectiveTheme.dragIllegalTintColor),
        ),
      ```
      BEFORE the `if (showLastMoveHighlight)` layer and BEFORE the `if (hasPiece) _buildPiece(...)` layer. Double-check the resulting `Stack` children order matches the numbered list above — Task 9.6 pins it with a widget PBT.
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.6, 6.7_
    - _Validates: P1.28, P1.30, P1.31_

  - [x] 9.3 Gate on `widget.enableMoves`
    - The `isDragLegalHover` and `isDragIllegalHover` flags already conjoin `widget.enableMoves` — when `enableMoves: false`, both are `false`, and neither layer is inserted. Additionally, the existing `Draggable(maxSimultaneousDrags: widget.enableMoves ? null : 0)` already prevents drags from starting, so `candidateData` / `rejectedData` never populate.
    - No additional code change here — this is an assertion about the logic from 9.2. Task 9.7 tests the gate.
    - _Requirements: 6.8_
    - _Preservation: P10_
    - _Validates: P1.32_

  - [x] 9.4 `test/drag_indicator/classification_test.dart`
    - Widget PBT over `(source square, hover square)` pairs during a simulated drag. Use `tester.startGesture(...)` + `moveBy(...)` to position the pointer over `hover`; pump; then for each of the three cases:
      - `hover == source`: assert `find.descendant(of: find.byKey(squareKey(hover)), matching: find.byType(_DragLegalRing))` is empty AND no `ColoredBox(color: theme.dragIllegalTintColor)` under that square.
      - `hover != source ∧ isLegal(source → hover)`: assert `_DragLegalRing` is present in that square; no drag-illegal tint.
      - `hover != source ∧ ¬isLegal(source → hover)`: assert drag-illegal tint `ColoredBox` is present in that square; no `_DragLegalRing`.
    - For every square `t` NOT under the pointer, assert neither indicator is rendered.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.28:
      // Drag-legal ring and drag-illegal tint appear iff the hover square is
      // non-source and legality of (source → hover) matches the indicator.
      ```
    - _Validates: P1.28_
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [x] 9.5 `test/drag_indicator/clear_on_end_test.dart`
    - Widget PBT: start a drag, move the pointer to a non-source square, assert either indicator is rendered somewhere; release via `gesture.up()` (drop on a legal square, on an illegal square, and off-board in three subcases); `tester.pumpAndSettle()`; assert zero `_DragLegalRing` and zero matching drag-illegal `ColoredBox` across all 64 squares.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.29:
      // Every drag termination (drop, cancel, off-board) clears every
      // drag-legal ring and drag-illegal tint on the next pumped frame.
      ```
    - _Validates: P1.29_
    - _Requirements: 6.5_

  - [x] 9.6 `test/drag_indicator/layer_order_test.dart`
    - Widget PBT: trigger a hover over a legal destination square; inspect the `Stack` inside that square's `DragTarget.builder`; assert the `_DragLegalRing`'s child index is strictly greater than the `HighlightOverlay`'s child index in the same `Stack` (P1.30 — both remain visible).
    - Second assertion (P1.31): trigger a hover over a non-source non-legal square WITH a piece; inspect that square's `Stack`; assert the drag-illegal-tint `ColoredBox`'s child index is strictly greater than the `ChessSquare` background's index AND strictly less than the `ChessPieceWidget`'s index (so the piece silhouette shows through the tint).
    - Use `find.descendant(of: find.byType(Stack), matching: find.byType(X)).evaluate().first` to get `Element`s and compare `parent.slot` or iterate the parent `Stack`'s children slot-by-slot.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Properties P1.30, P1.31:
      // Drag-legal ring layered above HighlightOverlay; drag-illegal tint
      // layered between ChessSquare background and ChessPieceWidget.
      ```
    - _Validates: P1.30, P1.31_
    - _Requirements: 6.6, 6.7_

  - [x] 9.7 `test/drag_indicator/disabled_moves_test.dart`
    - Widget PBT: pump with `enableMoves: false`. Attempt any drag (`tester.startGesture(...)` + `moveBy(...)`). Assert `Draggable.maxSimultaneousDrags == 0` prevents drag start AND that across all 64 squares, `find.byType(_DragLegalRing)` and the illegal-tint `ColoredBox` are both absent at every pumped frame throughout the attempted gesture.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P1.32:
      // enableMoves: false gates drag-legal ring AND drag-illegal tint off
      // unconditionally.
      ```
    - _Validates: P1.32_
    - _Requirements: 6.8_
    - _Preservation: P10_

- [x] 10. Barrel exports
  - **Goal**: Make every new public type reachable from the single top-level import `package:advanced_chess_board/advanced_chess_board.dart`.

  - [x] 10.1 Update `lib/advanced_chess_board.dart` barrel
    - Add the seven new export lines to the existing barrel (keep the four 3.0.0 lines unchanged):
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
      (Note: re-exports are in alphabetical import-path order to match 3.0.0's convention.)
    - The top-level `library;` docstring stays unchanged.
    - _Requirements: 7.1, 7.2, 7.3, 7.4_
    - _Preservation: P24_

  - [x] 10.2 `test/api/barrel_imports_3_1_test.dart`
    - Compile-only test: import ONLY `package:advanced_chess_board/advanced_chess_board.dart` and reference every newly exported public symbol in `void main() { … }`:
      ```dart
      void main() {
        test('3.1.0 barrel re-exports every new public symbol', () {
          expect(BoardTheme, isA<Type>());
          expect(PieceSet, isA<Type>());
          expect(CoordinateLabels, isA<Type>());
          expect(SoundEvent, isA<Type>());
          expect(SoundPack, isA<Type>());
          expect(SilentSoundPack, isA<Type>());
          expect(HintArrow, isA<Type>());
          // Sanity that the 3.0.0 symbols are still there (P2.11 slice).
          expect(AdvancedChessBoard, isA<Type>());
          expect(ChessBoardController, isA<Type>());
          expect(ChessArrow, isA<Type>());
          expect(PlayerColor, isA<Type>());
        });
      }
      ```
    - If this test compiles, the barrel is complete. If any symbol is missing from the barrel, the test file fails to compile (fast failure).
    - _Requirements: 7.1, 7.2_
    - _Preservation: P24_
    - _Validates: P2.11 slice_

- [x] 11. Preservation PBTs (P2.x)
  - **Goal**: One PBT per preservation property, each asserting that 3.0.0 behaviour is unchanged under arbitrary 3.1.0 parameter combinations. These are the guard-rail tests that prevent the 3.1.0 release from silently regressing 3.0.0 contracts (Preservation P1–P27, Correctness P2.1–P2.12).

  - [x] 11.1 `test/properties/preservation_chess_rules_test.dart` — P2.1
    - Widget PBT: for any random sequence of tap / drag / programmatic moves and any random 3.1.0 parameter combination (`boardTheme`, `pieceSet`, `coordinates`, `soundPack`, `hintArrow` all randomised via Task 15 generators), pump two mounted boards — one with the 3.1.0 parameters set, one with no 3.1.0 parameters — driving the same move sequence on both; after each move assert `controllerA.fen == controllerB.fen`, `playerColor`, `history.map((s) => s.move.toAlgebraic)`, `pgn` are equal.
    - Also pin: promotion dialog still offers queen / rook / bishop / knight and defaults to queen when dismissed (pump a promotion, find the dialog, assert the four `ChessPieceWidget`s represent those types; dismiss via `Navigator.pop`; assert `history.last.move.promotion == 'q'` or equivalent).
    - Also pin: illegal moves are rejected via `onWillAcceptWithDetails: false` (simulate a drag to an illegal square; assert FEN unchanged).
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P2.1:
      // 3.0.0 chess-rule correctness (moves, promotion, illegal rejection)
      // is preserved under any 3.1.0 parameter combination.
      ```
    - _Validates: P2.1; Preservation P1, P2, P3, P4_
    - _Requirements: 8.1, 8.3_

  - [x] 11.2 `test/properties/preservation_controller_semantics_test.dart` — P2.2
    - Widget PBT: driving random `notify: false` mutations on a mounted board asserts zero listener fan-outs (attach a counter via `controller.addListener(() => counter.value++)`).
    - Assert `identical(controller.game, controller.game) == true` across arbitrary mutation sequences.
    - Assert every typed getter (`isCheckmate`, `isInCheck`, `isStalemate`, `isDraw`, `isGameOver`, `history`, `pgn`, `moveCount`) returns the same values a 3.0.0 controller returns for the same position sequence (oracle: parallel `chess.Chess` instance driven by the same move list).
    - `ListenableBuilder` auto-subscription: pump board, make a move via `controller.makeMove(...)`, assert board rebuilt (inspect piece image paths on `from` / `to` squares) without any consumer-side `addListener(setState)`.
    - Controller swap via `didUpdateWidget`: pump with controller A, start a drag to set `_selectedSquare`, pump with controller B, assert `_selectedSquare == null`, `_legalMoves == {}`, `_animatingMove == null`, AND `_activeHint == null` via `@visibleForTesting` accessors.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P2.2:
      // Controller semantics (notify:false, game escape hatch, typed getters,
      // ListenableBuilder auto-swap, state reset on controller swap) are
      // preserved under 3.1.0.
      ```
    - _Validates: P2.2; Preservation P5, P6, P7, P8, P9_
    - _Requirements: 8.1, 8.3_

  - [x] 11.3 `test/properties/preservation_enable_moves_false_test.dart` — P2.3
    - Widget PBT: pump with `enableMoves: false` AND random combinations of `boardTheme`, `pieceSet`, `coordinates`, `soundPack` (use `_CountingSoundPack`), `hintArrow`. For any random tap or drag attempt: FEN unchanged; selection unchanged; counter stays zero (no `SoundPack.play`); no drag-legal ring, no drag-illegal tint visible anywhere.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P2.3:
      // enableMoves: false is render-only under every 3.1.0 parameter
      // combination — no move, no audio, no drag indicator.
      ```
    - _Validates: P2.3; Preservation P10_
    - _Requirements: 8.1, 8.3_

  - [x] 11.4 `test/properties/preservation_highlights_test.dart` — P2.4
    - Widget PBT: after a random legal move, assert the from-square and to-square are tinted with `_effectiveTheme.lastMoveHighlightColor` (via `find.byWidgetPredicate` for the `ColoredBox`). When the selected square equals one of them (tap-to-select then move), only one highlight is painted (single-highlight rule).
    - For tap-to-select-then-deselect: tap a piece → legal-destination hints rendered; tap the same square again → hints cleared.
    - `HighlightOverlay`: on empty legal targets, a small dot (diameter `squareSize * 0.3`); on targets with a piece (capture), a hollow ring (diameter `squareSize * 0.98`). Both use colours derived from `_effectiveTheme.legalDestinationColor`.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P2.4:
      // Last-move highlight, selection overlay, tap-to-deselect, and the
      // HighlightOverlay dot/ring style are preserved under 3.1.0.
      ```
    - _Validates: P2.4; Preservation P11, P12_
    - _Requirements: 8.1, 8.3_

  - [x] 11.5 `test/properties/preservation_drag_and_arrow_test.dart` — P2.5
    - Widget PBT: for any random drag-drop on a legal destination square, assert `controller.fen` advances as a 3.0.0 board's would (parallel `chess.Chess` oracle). For any random `ChessArrow` list and orientation, drive `ArrowPainter` against a `RecordingCanvas`; assert the recorded `drawLine` uses `strokeWidth == blockSize * 0.16`, the `drawPath` is an equilateral triangle with side `blockSize * 0.2`, and the adjusted-source / adjusted-dest offsets match `blockSize * 0.35` / `blockSize * 0.272` respectively. Orientation flip reverses the square-to-canvas mapping as expected.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P2.5:
      // Drag-drop moves advance FEN identically to 3.0.0; ArrowPainter
      // geometry (line+arrowhead dimensions, colour, orientation mapping)
      // is unchanged.
      ```
    - _Validates: P2.5; Preservation P13, P14, P15_
    - _Requirements: 8.1, 8.3_

  - [x] 11.6 `test/properties/preservation_mate_check_tint_test.dart` — P2.6
    - Example + PBT: load Fool's Mate FEN (`rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3` or a canonical mate position); pump with default parameters; assert the mated king's square renders a `ColoredBox(color: Color(0x9BF44336))` AND the king `ChessPieceWidget` renders on top. Repeat with `kingBackgroundColorOnCheckmate: customRed`; assert the legacy parameter wins (`ColoredBox(color: customRed)`).
    - PBT on in-check-but-not-mate positions: pump with `boardTheme: theme.copyWith(kingCheckColor: orange)`; assert the checked king's square renders `ColoredBox(color: orange)`. With `kingCheckColor: null` (default), assert NO in-check tint — preserves 3.0.0.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P2.6:
      // Mated-king tint uses legacy kingBackgroundColorOnCheckmate if passed,
      // else _effectiveTheme.kingCheckmateColor; in-check tint fires only
      // when kingCheckColor is non-null (default null preserves 3.0.0).
      ```
    - _Validates: P2.6; Preservation P16_
    - _Requirements: 8.1, 8.3_

  - [x] 11.7 `test/properties/preservation_move_animation_test.dart` — P2.7
    - Widget PBT: for random tap / programmatic moves with `moveAnimationDuration > Duration.zero` (randomly chosen from `{50ms, 150ms, 300ms}`) and random 3.1.0 parameters: assert a `MoveAnimationLayer` is inserted into the top-level `Stack` during the animation; at `tester.pump(duration * 0.5)`, the animating piece's `Offset` is between `from` and `to`; after `tester.pump(duration)`, the layer is gone. Drag-drop moves never insert a `MoveAnimationLayer` (the existing `_suppressNextAnimation` flag path).
    - With `moveAnimationDuration: Duration.zero`, no layer inserted regardless of move path.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P2.7:
      // Tap/programmatic moves still animate via MoveAnimationLayer under any
      // 3.1.0 parameter combination; drag-drop moves still skip animation;
      // Duration.zero disables the animation.
      ```
    - _Validates: P2.7; Preservation P17, P18_
    - _Requirements: 8.1, 8.3_

  - [x] 11.8 `test/properties/preservation_drag_feedback_clamp_test.dart` — P2.8
    - Widget PBT over `squareSize ∈ (0, 1000]`. For each generated size, pump the board, start a drag on an occupied square, measure the `Draggable.feedback` `SizedBox` dimensions; assert `width == math.min(squareSize * kMaxFeedbackScale, squareSize + kMaxFeedbackOverflowPx)` AND `height == width`.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P2.8:
      // Draggable.feedback width = min(squareSize * kMaxFeedbackScale,
      //                                squareSize + kMaxFeedbackOverflowPx),
      // preserved from 3.0.0.
      ```
    - _Validates: P2.8; Preservation P20_
    - _Requirements: 8.1, 8.3_

  - [x] 11.9 `test/properties/preservation_column_of_rows_test.dart` — P2.9
    - Widget PBT over `coordinates ∈ {inside, outside, none}` and random 3.1.0 parameters: pump the board; assert `find.byType(GridView)` is empty (no `GridView`, no `Scrollable`); assert `find.byType(Row).evaluate().length >= 8` (at least 8 rows for the playing grid; in `outside` mode, one additional `Row` for the file-gutter).
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P2.9:
      // The 8×8 playing grid is built as a Column of 8 Rows of 8 SizedBox
      // children — no GridView, no Scrollable — in every coordinates mode.
      ```
    - _Validates: P2.9; Preservation P21_
    - _Requirements: 8.1, 8.3_

  - [x] 11.10 `test/properties/preservation_semantics_test.dart` — P2.10
    - Widget PBT: for any square `s` with piece `p` (or empty) and any `pieceSet`, assert the `ChessSquare`'s `Semantics` node label equals `"$s, ${pieceSemanticsLabel(p)}"`. Assert every `ChessPieceWidget`'s `Semantics` label equals `pieceSemanticsLabel(piece)` AND `button == isBoardEnabled`.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P2.10:
      // Semantics labels on ChessSquare and ChessPieceWidget are preserved
      // under any PieceSet — label derivation still uses pieceSemanticsLabel.
      ```
    - _Validates: P2.10; Preservation P23_
    - _Requirements: 8.1, 8.3_

  - [x] 11.11 `test/properties/preservation_public_api_surface_test.dart` — P2.11
    - Compile-only test (already partially present in Task 10.2; this is the expanded version):
      - Verify every 3.0.0 `AdvancedChessBoard` constructor parameter keeps its 3.0.0 name, type, and default value by inspecting a minimal `const AdvancedChessBoard(controller: c)` expression compiles. Test the 10 3.0.0 parameters by passing `null` / default-equivalent values (`controller`, `lightSquareColor`, `darkSquareColor`, `initialFEN`, `boardOrientation`, `enableMoves`, `highlightLastMove`, `arrows`, `kingBackgroundColorOnCheckmate`, `moveAnimationDuration`).
      - Verify every `ChessBoardController` getter and method listed in `requirements.md → Preservation P7` exists by reading each (e.g. `c.fen`, `c.playerColor`, `c.isInCheck`, `c.isCheckmate`, ...). If any is removed or renamed, the file fails to compile.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P2.11:
      // The 3.0.0 public API surface (parameter names, types, defaults;
      // controller getter set) is preserved in 3.1.0.
      ```
    - _Validates: P2.11; Preservation P24, P25_
    - _Requirements: 8.1, 8.3_

  - [x] 11.12 `test/properties/preservation_3_0_0_suite_unchanged_test.dart` — P2.12
    - CI check: compute SHA-256 hashes of every test file that existed in 3.0.0 (enumerate via a checked-in `test/.3_0_0_manifest.txt` or via `git ls-tree` at the 3.0.0 tag — prefer the manifest for reproducibility). Compare against a pinned list of expected hashes captured at 3.0.0 release time. Any file modification in the 3.0.0 test tree fails the test.
    - If the 3.0.0 manifest is unavailable at implementation time, create it in this task: enumerate every file under `test/` that predates 3.1.0 work, record SHA-256 → manifest, commit manifest with this task; the assertion then reads manifest and verifies.
    - Also: running `flutter test test/controller test/painter test/widget test/packaging test/api test/properties` (the 3.0.0 directories) passes unchanged. Use a subprocess call via `Process.run('flutter', ['test', ...])` inside this test, or delegate to the Task 16.2 full-suite run.
    - Property header:
      ```dart
      // Feature: chess-board-ux-enhancements, Property P2.12:
      // Every 3.0.0 test file is byte-identical after 3.1.0 ships; running
      // the 3.0.0 test tree under 3.1.0 passes unchanged.
      ```
    - _Validates: P2.12; Preservation P26, P27_
    - _Requirements: 8.1, 8.3_

- [x] 12. Example-app tour (`example/lib/main.dart`)
  - **Goal**: Extend the example to exercise every new capability via visible knobs, so a consumer reading `example/` sees concrete usage.

  - [x] 12.1 Board theme dropdown
    - Add a `DropdownButton<BoardTheme>` above the board with the five preset options: `classicGreen`, `brown`, `blue`, `purple`, `monochrome`. Bind via `setState(() => _boardTheme = newValue)` and pass as `boardTheme: _boardTheme` to the `AdvancedChessBoard(...)`.
    - _Requirements: 1.3, 8.4_

  - [x] 12.2 Piece set dropdown
    - `DropdownButton<PieceSet>` with two options: `PieceSet.chessDotCom` and a `PieceSet.fromAssetMap({...})` wired against a toy 12-entry map using `AssetImage` with placeholder paths (or the same bundled assets under different keys — proves the override plumbs through). Example app README notes the expected set layout.
    - _Requirements: 2.4, 2.5, 8.4_

  - [x] 12.3 Coordinate labels segmented button
    - `SegmentedButton<CoordinateLabels>` with the three values (`inside`, `outside`, `none`). Bind via `setState`.
    - _Requirements: 3.1, 3.2, 3.5, 3.8, 8.4_

  - [x] 12.4 Debug sound pack wiring
    - Add a private `class _DebugSoundPack extends SoundPack` whose `play(SoundEvent e)` calls `debugPrint('sound: $e')` and returns `Future<void>.value()`. Toggle the example app between `const SilentSoundPack()` and `_DebugSoundPack()` via a checkbox.
    - The example app's README notes that a real implementation would route to `package:audioplayers` or equivalent — the library itself bundles no audio.
    - _Requirements: 4.3, 4.4, 8.4_

  - [x] 12.5 "Show hint: Nf3" button
    - Add an `ElevatedButton(onPressed: () => setState(() => _hint = const HintArrow(startSquare: 'g1', endSquare: 'f3', duration: Duration(seconds: 4))), child: Text('Show hint: Nf3'))`. Pass `hintArrow: _hint` to the board.
    - _Requirements: 5.1, 5.2, 5.5, 8.4_

  - [x] 12.6 Example README
    - Update `example/README.md` (create if missing) with: one paragraph per new knob pointing at the corresponding widget in `example/lib/main.dart`; a short note that drag legality indicator is automatic whenever `enableMoves: true` and a drag is in progress; a short note that the `_DebugSoundPack` is for demo only — real apps plug in an audio backend.
    - _Requirements: 8.4_

- [x] 13. `CHANGELOG.md` — prepend 3.1.0 entry
  - Prepend a `## 3.1.0 — YYYY-MM-DD` block at the top of `CHANGELOG.md` (use the current UTC date at release time; the existing `changelog_format_test` regex accepts `YYYY-MM` or `YYYY-MM-DD`).
  - Body follows the verbatim structure from `design.md → Migration / Release Notes → CHANGELOG.md`:
    - **Additions**: `BoardTheme` (list presets + copyWith + legacy-wins resolution); `PieceSet` (abstraction + `chessDotCom` + `fromAssetMap`); `CoordinateLabels` (inside/outside/none); `SoundEvent` + `SoundPack` + `SilentSoundPack` (priority classifier, no bundled audio); `HintArrow` (dashed shaft + stroke-only head + auto-dismiss); drag legality indicator (legal ring + illegal tint, gated by `enableMoves`).
    - **Polish**: `HighlightOverlay` threads `BoardTheme.legalDestinationColor` (pixel-identical default); `AdvancedChessBoard` re-precaches `PieceSet` on `didUpdateWidget` swap; new `BoardTheme.kingCheckColor` (default null = no in-check tint, matches 3.0.0).
  - Leave every prior release entry untouched.
  - _Requirements: 8.2_

- [x] 14. `README.md` — add 3.1.0 feature subsections, update Known limitations
  - Under the "Features" section, add (or extend) the following subsections with one minimal worked example each:
    - **Theming** — `boardTheme: BoardTheme.brown`; mention the five presets; show a `copyWith` snippet.
    - **Piece sets** — `pieceSet: PieceSet.fromAssetMap({...})`; link to the bundled `assets/pieces/` layout for the default.
    - **Coordinates** — `coordinates: CoordinateLabels.outside`; explain that `AspectRatio(1)` still wraps the playing grid.
    - **Sound effects** — skeleton `class MySoundPack extends SoundPack` that routes `SoundEvent`s to an audio backend (e.g. `audioplayers`); state the "no bundled audio" stance.
    - **Hint arrows** — `hintArrow: HintArrow(startSquare: 'g1', endSquare: 'f3', duration: Duration(seconds: 4))`; note the auto-dismiss-on-move semantics.
    - **Drag legality indicator** — one paragraph noting the indicator fires automatically whenever `enableMoves: true` and a drag is in progress; reference `boardTheme.dragLegalRingColor` / `dragIllegalTintColor`.
  - Edit the **Known limitations** section:
    - Remove the sentence "Piece theming currently requires forking the `assets/pieces/` directory." (Requirement 8.5 — now addressed by `PieceSet`.)
    - Add a sentence: "Premoves are tracked in a separate spec (`chess-board-premoves`) and are not yet available."
  - _Requirements: 8.4, 8.5_

- [x] 15. Extend `test/properties/generators.dart`
  - Add the following generators to the existing `extension ChessGenerators on Any` (or a new sibling extension):
    - `Generator<BoardTheme> get boardTheme` — constructs a `BoardTheme` from 11 random `Color`s (use `any.color` if present, otherwise build from 4 random bytes). Include the five presets in the generated pool with small probability so the "default" path is exercised alongside randomised themes.
    - `Generator<PieceSet> get pieceSet` — chooses between `PieceSet.chessDotCom` and a `PieceSet.fromAssetMap(...)` built against a static 12-entry map of `MemoryImage(kTransparentImageBytes)` (kept constant per test run for equality comparisons).
    - `Generator<CoordinateLabels> get coordinateLabels` — `any.choose(CoordinateLabels.values)`.
    - `Generator<SoundEvent> get soundEvent` — `any.choose(SoundEvent.values)`.
    - `Generator<HintArrow> get hintArrow` — random `startSquare`, `endSquare` (reuse `chessSquare`), `duration` either `null` or `Duration(milliseconds: 100..5000)`.
    - `Generator<(chess.Chess, chess.Move)> get legalMoveFromRandomPosition` — pull a `chess.Chess` from the `chessFen` generator, generate its legal moves, pick one at random; return both. Used by the sound classifier PBT (Task 7.7).
  - Dartdoc on every new generator.
  - _Requirements: 9.3_
  - _Preservation: P27 (existing generators untouched)_

- [ ] 16. Final validation
  - **Goal**: Confirm 3.1.0 is release-ready. No new code writes — this task runs commands and reports.

  - [x] 16.1 Analyse clean at repo root AND in `example/`
    - Run `flutter analyze --fatal-warnings --fatal-infos` at the repo root. Expected: exit 0 with zero errors, zero warnings, zero infos.
    - Run `flutter analyze --fatal-warnings --fatal-infos` in `example/`. Expected: exit 0.
    - Any diagnostic must be fixed at its root cause (missing dartdoc, `strict-inference` failure, unused import, etc.). Do NOT add `// ignore:` suppressions. If a rule genuinely does not apply to a specific line, document the reason in a `///` comment above the line.
    - _Requirements: 9.1, 9.2, 9.3, 9.4_
    - _Preservation: P25 (analyse contract unchanged)_

  - [x] 16.2 Run the full test suite
    - `flutter test --reporter expanded` at the repo root.
    - Expected: every new test from Tasks 3–11 PASSES, every 3.0.0 test (the unmodified `test/controller`, `test/painter`, `test/widget`, `test/packaging`, `test/api`, `test/properties` files) PASSES, AND the `preservation_3_0_0_suite_unchanged_test` from Task 11.12 PASSES.
    - Zero skipped tests other than any explicitly tagged `skip:` for reasons documented inline.
    - _Requirements: 9.1_
    - _Preservation: P26, P27_

  - [x] 16.3 Run `flutter pub publish --dry-run`
    - Execute at the repo root.
    - Expected: zero metadata / documentation deductions. `pub.dev` score unchanged from 3.0.0 or improved.
    - _Requirements: 8.1, 8.2, 9.3_

- [ ] 17.* Integration smoke tests (OPTIONAL)
  - Add `example/integration_test/ux_enhancements_smoke_test.dart` — ONE smoke test per capability (six total). Each test clicks the corresponding knob added in Task 12 and asserts the board reacts:
    - Smoke 1 (BoardTheme): change dropdown from `classicGreen` to `brown`; assert the light-square `ColoredBox` colour is `Color(0xFFF0D9B5)`.
    - Smoke 2 (PieceSet): change dropdown from `chessDotCom` to `fromAssetMap`; assert `Image` widgets in the board render with the custom `ImageProvider`.
    - Smoke 3 (CoordinateLabels): switch segmented button to `outside`; assert `_CoordinateGutter` widgets exist in the tree.
    - Smoke 4 (SoundPack): flip to `_DebugSoundPack`; drive a tap move; capture `debugPrint` output and assert it contains `"sound: move"` (or the appropriate event).
    - Smoke 5 (HintArrow): tap "Show hint: Nf3"; assert `HintArrowPainter` is in the tree; drive any legal move; assert `HintArrowPainter` is gone.
    - Smoke 6 (Drag indicator): start a drag on e2; hover over e4; assert `_DragLegalRing` is rendered on e4.
  - Add `integration_test` under `example/dev_dependencies` if missing. Skip if CI cannot run `integration_test`.
  - _Requirements: 8.4_

- [ ] 18.* Golden widget tests (OPTIONAL)
  - Generate goldens under `test/goldens/` for:
    - The five `BoardTheme` presets at a fixed 512×512 canvas (`classicGreen.png`, `brown.png`, `blue.png`, `purple.png`, `monochrome.png`).
    - `CoordinateLabels.outside` vs `CoordinateLabels.inside` at 512×512 (`coords_outside.png`, `coords_inside.png`).
  - Use `matchesGoldenFile('goldens/classicGreen.png')` etc. Generate against the CURRENT (3.1.0) code state as the baseline.
  - Skip if CI goldens are flaky across platforms or if the PBTs in Tasks 3–11 cover the semantic claims sufficiently.
  - _Requirements: 1.4, 3.5_

- [x] 19. Checkpoint — ensure everything passes
  - Ensure all tests pass, ask the user if questions arise.
  - Confirm `flutter analyze --fatal-warnings --fatal-infos` exits 0 both at the repo root AND in `example/`.
  - Confirm `flutter test` exits 0 with no unexpected skipped tests.
  - Confirm `flutter pub publish --dry-run` reports no metadata / documentation deductions.
  - Confirm the preservation PBTs from Task 11 all PASS (no regressions of 3.0.0 behaviour under 3.1.0 parameters).
  - Confirm the 3.0.0 test suite, run verbatim against the 3.1.0 tree, PASSES unchanged (Task 11.12 and Task 16.2 together prove this).

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP (integration smokes, goldens).
- Every leaf task references specific requirements (`8.1`, `1.5`, …) for traceability and the correctness properties (`P1.x`, `P2.x`) it satisfies.
- Preservation references (`P1`–`P27` from `requirements.md`) are added wherever a task must NOT regress 3.0.0 behaviour.
- Checkpoints ensure incremental validation — Task 4.4 and Task 16 both re-run `flutter analyze` at the repo root AND in `example/`.
- Property tests are layered near their implementation tasks (Tasks 3.2–3.4, 5.6–5.9, 6.5–6.9, 7.7–7.12, 8.6–8.13, 9.4–9.7) so that a property regression is caught within the capability's own task group; Task 11 aggregates cross-capability preservation PBTs.
- The `fake_async` dev dep added in Task 1 is consumed by Tasks 8.10 and 8.11 (hint-duration timing PBTs). No runtime dependency is added — the library stays dependency-light per Requirement 4.
