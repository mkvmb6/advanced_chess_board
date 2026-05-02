// Feature: chess-board-ux-enhancements, Property P1.3:
// _effectiveTheme = theme.copyWith(
//   lightSquareColor: legacyLight ?? theme.lightSquareColor,
//   darkSquareColor:  legacyDark  ?? theme.darkSquareColor,
//   kingCheckmateColor: legacyMate ?? theme.kingCheckmateColor,
// ); every other field passes through from `theme` untouched.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:glados/glados.dart';

import '../properties/generators.dart';

void main() {
  ft.group('_effectiveTheme resolution', () {
    // P1.4 fallthrough: with classicGreen and no legacy overrides,
    // _effectiveTheme == BoardTheme.classicGreen.
    ft.testWidgets(
      'P1.4: classicGreen + no legacy overrides => effectiveTheme == classicGreen',
      (final ft.WidgetTester tester) async {
        final controller = ChessBoardController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(controller: controller),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final state = tester.state<State<AdvancedChessBoard>>(
          ft.find.byType(AdvancedChessBoard),
        );
        final effectiveTheme = AdvancedChessBoard.effectiveThemeOf(state);
        ft.expect(effectiveTheme, ft.equals(BoardTheme.classicGreen));
      },
    );

    // Legacy lightSquareColor wins over boardTheme.lightSquareColor.
    ft.testWidgets(
      'legacy lightSquareColor wins over boardTheme.lightSquareColor',
      (final ft.WidgetTester tester) async {
        final controller = ChessBoardController();
        const legacyLight = Color(0xFF112233);
        const theme = BoardTheme(lightSquareColor: Color(0xFF998877));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  boardTheme: theme,
                  lightSquareColor: legacyLight,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final state = tester.state<State<AdvancedChessBoard>>(
          ft.find.byType(AdvancedChessBoard),
        );
        final effectiveTheme = AdvancedChessBoard.effectiveThemeOf(state);
        ft.expect(effectiveTheme.lightSquareColor, ft.equals(legacyLight));
        // Other fields pass through from theme.
        ft.expect(
          effectiveTheme.darkSquareColor,
          ft.equals(theme.darkSquareColor),
        );
        ft.expect(
          effectiveTheme.selectionColor,
          ft.equals(theme.selectionColor),
        );
      },
    );

    // Legacy darkSquareColor wins over boardTheme.darkSquareColor.
    ft.testWidgets(
      'legacy darkSquareColor wins over boardTheme.darkSquareColor',
      (final ft.WidgetTester tester) async {
        final controller = ChessBoardController();
        const legacyDark = Color(0xFF445566);
        const theme = BoardTheme(darkSquareColor: Color(0xFF998877));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  boardTheme: theme,
                  darkSquareColor: legacyDark,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final state = tester.state<State<AdvancedChessBoard>>(
          ft.find.byType(AdvancedChessBoard),
        );
        final effectiveTheme = AdvancedChessBoard.effectiveThemeOf(state);
        ft.expect(effectiveTheme.darkSquareColor, ft.equals(legacyDark));
      },
    );

    // Legacy kingBackgroundColorOnCheckmate wins over boardTheme.kingCheckmateColor.
    ft.testWidgets(
      'legacy kingBackgroundColorOnCheckmate wins over boardTheme.kingCheckmateColor',
      (final ft.WidgetTester tester) async {
        final controller = ChessBoardController();
        const legacyMate = Color(0xFF778899);
        const theme = BoardTheme(kingCheckmateColor: Color(0xFF998877));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  boardTheme: theme,
                  kingBackgroundColorOnCheckmate: legacyMate,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final state = tester.state<State<AdvancedChessBoard>>(
          ft.find.byType(AdvancedChessBoard),
        );
        final effectiveTheme = AdvancedChessBoard.effectiveThemeOf(state);
        ft.expect(effectiveTheme.kingCheckmateColor, ft.equals(legacyMate));
      },
    );

    // When kingBackgroundColorOnCheckmate is null, boardTheme.kingCheckmateColor is used.
    ft.testWidgets(
      'null kingBackgroundColorOnCheckmate falls back to boardTheme.kingCheckmateColor',
      (final ft.WidgetTester tester) async {
        final controller = ChessBoardController();
        const themeColor = Color(0xFF998877);
        const theme = BoardTheme(kingCheckmateColor: themeColor);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  boardTheme: theme,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final state = tester.state<State<AdvancedChessBoard>>(
          ft.find.byType(AdvancedChessBoard),
        );
        final effectiveTheme = AdvancedChessBoard.effectiveThemeOf(state);
        ft.expect(effectiveTheme.kingCheckmateColor, ft.equals(themeColor));
      },
    );

    // PBT: for any boardTheme, the non-legacy fields pass through unchanged.
    Glados<BoardTheme>(any.boardTheme).test(
      'prop_effective_theme_non_legacy_fields_pass_through',
      (final BoardTheme theme) {
        // Compute the effective theme manually using the same formula.
        final effective = theme.copyWith(
          lightSquareColor: const Color(0xFFEBECD0), // default legacy value
          darkSquareColor: const Color(0xFF739552), // default legacy value
          // kingBackgroundColorOnCheckmate is null by default
          kingCheckmateColor: theme.kingCheckmateColor,
        );
        // Non-legacy fields should pass through unchanged.
        ft.expect(effective.selectionColor, ft.equals(theme.selectionColor));
        ft.expect(
          effective.lastMoveHighlightColor,
          ft.equals(theme.lastMoveHighlightColor),
        );
        ft.expect(
          effective.legalDestinationColor,
          ft.equals(theme.legalDestinationColor),
        );
        ft.expect(
          effective.coordinateLabelColor,
          ft.equals(theme.coordinateLabelColor),
        );
        ft.expect(effective.kingCheckColor, ft.equals(theme.kingCheckColor));
        ft.expect(effective.hintArrowColor, ft.equals(theme.hintArrowColor));
        ft.expect(
          effective.dragLegalRingColor,
          ft.equals(theme.dragLegalRingColor),
        );
        ft.expect(
          effective.dragIllegalTintColor,
          ft.equals(theme.dragIllegalTintColor),
        );
      },
    );
  });
}
