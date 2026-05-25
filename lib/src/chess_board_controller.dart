import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart';

import 'constants/global_constants.dart';
import 'models/enums.dart';

/// Controller for [AdvancedChessBoard].
///
/// Wraps a [chess.Chess] instance and exposes typed getters for common game
/// state. Extends [ChangeNotifier] so the board widget (and any consumer
/// listener) can react to mutations.
///
/// Mutating methods accept a `notify` flag (default `true`). Passing `false`
/// suppresses the listener notification — useful for batching several moves
/// before triggering a rebuild.
///
/// Example:
/// ```dart
/// final controller = ChessBoardController();
/// controller.makeMove(from: 'e2', to: 'e4');
/// print(controller.fen);
/// ```
class ChessBoardController extends ChangeNotifier {
  final chess.Chess _game = chess.Chess();

  /// Escape hatch to the underlying [chess.Chess] engine.
  ///
  /// Prefer the typed getters on this controller ([fen], [playerColor],
  /// [isInCheck], [isCheckmate], [isStalemate], [isDraw], [isGameOver],
  /// [history], [pgn], [moveCount]). This getter stays as an escape hatch
  /// for advanced use cases not covered by the typed API.
  chess.Chess get game => _game;

  /// FEN (Forsyth–Edwards Notation) of the current position.
  String get fen => _game.fen;

  /// The side to move.
  PlayerColor get playerColor =>
      _game.turn == chess.Color.WHITE ? PlayerColor.white : PlayerColor.black;

  /// `true` when the side to move is in check.
  bool get isInCheck => _game.in_check;

  /// `true` when the side to move is checkmated.
  bool get isCheckmate => _game.in_checkmate;

  /// `true` when the position is stalemate.
  bool get isStalemate => _game.in_stalemate;

  /// `true` when the position is drawn by rule
  /// (50-move, threefold repetition, insufficient material, or stalemate).
  bool get isDraw => _game.in_draw;

  /// `true` when the game has ended by any rule.
  bool get isGameOver => _game.game_over;

  /// Unmodifiable view of the move history as [chess.State] entries.
  List<chess.State> get history => List.unmodifiable(_game.history);

  /// Standard PGN (Portable Game Notation) of the game so far.
  String get pgn => _game.pgn();

  /// Number of plies (half-moves) played.
  int get moveCount => _game.history.length;

  /// Reset the board to the standard starting position.
  ///
  /// Fires registered listeners unless `notify` is `false`.
  void resetBoard({final bool notify = true}) {
    _game.reset();
    if (notify) {
      notifyListeners();
    }
  }

  /// Attempt a move from [from] to [to].
  ///
  /// If the move promotes a pawn, [promotion] must be a single-character
  /// piece letter (`'q'`, `'r'`, `'b'`, or `'n'`).
  ///
  /// Returns `true` when the move is accepted (legal), `false` otherwise.
  /// On success, fires listeners unless `notify` is `false`.
  bool makeMove({
    required final String from,
    required final String to,
    final String? promotion,
    final bool notify = true,
  }) {
    final moveMade = promotion != null
        ? _game.move({fromKey: from, toKey: to, promotionKey: promotion})
        : _game.move({fromKey: from, toKey: to});
    if (moveMade) {
      if (notify) {
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  /// Undo the last move.
  ///
  /// No-op when history is empty. Fires listeners unless `notify` is `false`.
  void undo({final bool notify = true}) {
    _game.undo();
    if (notify) {
      notifyListeners();
    }
  }

  /// Load a position from a FEN string.
  ///
  /// Fires listeners unless `notify` is `false`.
  void loadGameFromFEN(final String fen, {final bool notify = true}) {
    _game.load(fen);
    if (notify) {
      notifyListeners();
    }
  }
}
