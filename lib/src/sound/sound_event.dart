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
