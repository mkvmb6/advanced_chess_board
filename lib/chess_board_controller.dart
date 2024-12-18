import 'package:chess/chess.dart';
import 'package:flutter/foundation.dart';

import 'constants/global_constants.dart';
import 'models/enums.dart';

class ChessBoardController extends ChangeNotifier {
  VoidCallback? _listener;

  final Chess _game = Chess();

  @override
  void addListener(VoidCallback listener) {
    _listener = listener;
  }

  @override
  void dispose() {
    super.dispose();
    _listener = null;
  }

  void _notifyListeners() {
    if (_listener != null) {
      _listener!();
    }
  }

  void resetBoard() {
    game.reset();
    _notifyListeners();
  }

  bool makeMove({
    required final String from,
    required final String to,
    final String? promotion,
  }) {
    final moveMade = promotion != null
        ? game.move({fromKey: from, toKey: to, promotionKey: promotion})
        : game.move({fromKey: from, toKey: to});
    if (moveMade) {
      _notifyListeners();
      return true;
    }
    return false;
  }

  void undo() {
    game.undo();
    _notifyListeners();
  }

  bool isCheckmate() {
    return game.in_checkmate;
  }

  void loadGameFromFEN(final String fen) {
    game.load(fen);
    _notifyListeners();
  }

  String get fen => game.fen;

  Chess get game => _game;

  PlayerColor get playerColor =>
      game.turn == Color.WHITE ? PlayerColor.white : PlayerColor.black;
}
