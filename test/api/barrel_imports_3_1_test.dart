// Feature: chess-board-ux-enhancements, Property P2.11 slice:
// The 3.1.0 barrel re-exports every new public symbol.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('3.1.0 new enum values are accessible', () {
    // CoordinateLabels values.
    expect(CoordinateLabels.inside, isA<CoordinateLabels>());
    expect(CoordinateLabels.outside, isA<CoordinateLabels>());
    expect(CoordinateLabels.none, isA<CoordinateLabels>());

    // SoundEvent values.
    expect(SoundEvent.move, isA<SoundEvent>());
    expect(SoundEvent.capture, isA<SoundEvent>());
    expect(SoundEvent.check, isA<SoundEvent>());
    expect(SoundEvent.castle, isA<SoundEvent>());
    expect(SoundEvent.promote, isA<SoundEvent>());
    expect(SoundEvent.gameEnd, isA<SoundEvent>());
  });

  test('3.1.0 BoardTheme presets are accessible', () {
    expect(BoardTheme.classicGreen, isA<BoardTheme>());
    expect(BoardTheme.brown, isA<BoardTheme>());
    expect(BoardTheme.blue, isA<BoardTheme>());
    expect(BoardTheme.purple, isA<BoardTheme>());
    expect(BoardTheme.monochrome, isA<BoardTheme>());
  });

  test('3.1.0 PieceSet.chessDotCom is accessible', () {
    expect(PieceSet.chessDotCom, isA<PieceSet>());
  });

  test('3.1.0 SilentSoundPack is const-constructible', () {
    const pack = SilentSoundPack();
    expect(pack, isA<SoundPack>());
  });
}
