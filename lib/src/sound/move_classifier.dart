import 'package:chess/chess.dart' as chess;

import 'sound_event.dart';

/// Classifies [verboseMove] into a [SoundEvent] using the priority order
/// documented on [SoundEvent].
///
/// Priority (highest first): `gameEnd` > `promote` > `castle` > `check` >
/// `capture` > `move`.
///
/// The [verboseMove] flags field is an integer bitmask using the following
/// bit constants from `package:chess`:
///
/// | Constant              | Value | Meaning                        |
/// |-----------------------|-------|--------------------------------|
/// | `chess.Chess.BITS_NORMAL`       | 1     | non-capture quiet move         |
/// | `chess.Chess.BITS_CAPTURE`      | 2     | standard capture               |
/// | `chess.Chess.BITS_BIG_PAWN`     | 4     | pawn jumps two squares         |
/// | `chess.Chess.BITS_EP_CAPTURE`   | 8     | en-passant capture             |
/// | `chess.Chess.BITS_PROMOTION`    | 16    | pawn promotion                 |
/// | `chess.Chess.BITS_KSIDE_CASTLE` | 32    | kingside castling              |
/// | `chess.Chess.BITS_QSIDE_CASTLE` | 64    | queenside castling             |
SoundEvent classifySoundEvent({
  required final chess.Move verboseMove,
  required final bool isGameOverAfter,
  required final bool isInCheckAfter,
}) {
  final flags = verboseMove.flags;

  // 1. gameEnd — highest priority. Game-over covers checkmate, stalemate,
  //    threefold repetition, 50-move rule, and insufficient material.
  if (isGameOverAfter) return SoundEvent.gameEnd;

  // 2. promote — pawn promotion (with or without capture).
  if ((flags & chess.Chess.BITS_PROMOTION) != 0) return SoundEvent.promote;

  // 3. castle — either side.
  if ((flags & chess.Chess.BITS_KSIDE_CASTLE) != 0 ||
      (flags & chess.Chess.BITS_QSIDE_CASTLE) != 0) {
    return SoundEvent.castle;
  }

  // 4. check — move delivered check but not mate / promotion / castle.
  if (isInCheckAfter) return SoundEvent.check;

  // 5. capture — covers standard captures AND en-passant.
  if ((flags & chess.Chess.BITS_CAPTURE) != 0 ||
      (flags & chess.Chess.BITS_EP_CAPTURE) != 0) {
    return SoundEvent.capture;
  }

  // 6. move — quiet move. Fallback.
  return SoundEvent.move;
}
