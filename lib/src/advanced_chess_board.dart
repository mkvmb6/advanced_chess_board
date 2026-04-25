import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import 'chess_board_controller.dart';
import 'constants/global_constants.dart';
import 'models/chess_arrow.dart';
import 'models/enums.dart';
import 'utils/arrow_painter.dart';
import 'utils/utils.dart';
import 'widgets/chess_piece_widget.dart';
import 'widgets/chess_square.dart';
import 'widgets/highlight_overlay.dart';
import 'widgets/move_animation_layer.dart';

/// A fully-featured chess board widget.
///
/// Pieces can be moved by tap-to-select-then-tap-to-move, by drag-and-drop,
/// or programmatically through the supplied [controller]. Supports custom
/// board colours, orientation flipping, a configurable last-move highlight,
/// arrow overlays, and a smooth piece-move animation for non-drag moves.
///
/// The widget subscribes to [controller] internally — you do NOT need to
/// call `controller.addListener(setState)` yourself; the board rebuilds on
/// its own when the controller notifies.
class AdvancedChessBoard extends StatefulWidget {
  /// Creates an [AdvancedChessBoard].
  const AdvancedChessBoard({
    super.key,
    required this.controller,
    this.lightSquareColor = const Color(0xFFEBECD0),
    this.darkSquareColor = const Color(0xFF739552),
    this.initialFEN,
    this.boardOrientation = PlayerColor.white,
    this.enableMoves = true,
    this.highlightLastMove = true,
    this.arrows = const <ChessArrow>[],
    this.kingBackgroundColorOnCheckmate,
    this.moveAnimationDuration = kDefaultMoveAnimationDuration,
  });

  /// Controller driving the board state.
  ///
  /// The widget subscribes to this controller via [ListenableBuilder] — no
  /// consumer-side `addListener(setState)` is needed.
  final ChessBoardController controller;

  /// Colour of the light squares. Default: warm off-white.
  final Color lightSquareColor;

  /// Colour of the dark squares. Default: muted green.
  final Color darkSquareColor;

  /// Background colour painted behind the mated king when the game ends by
  /// checkmate. Defaults to `Colors.red.withAlpha(155)`.
  final Color? kingBackgroundColorOnCheckmate;

  /// Optional starting FEN. If non-`null`, the board loads this position on
  /// first mount.
  final String? initialFEN;

  /// Which side is drawn at the bottom.
  final PlayerColor boardOrientation;

  /// Whether the board accepts user-driven moves. When `false`, the board is
  /// render-only and pieces use the default cursor.
  final bool enableMoves;

  /// Whether the last-played move is highlighted with a yellow tint on the
  /// from and to squares.
  final bool highlightLastMove;

  /// Arrows to draw on top of the board.
  final List<ChessArrow> arrows;

  /// Duration of the post-tap / post-programmatic move animation.
  ///
  /// Drag-drop moves do not animate (the [Draggable.feedback] already follows
  /// the pointer). Set to [Duration.zero] to disable.
  final Duration moveAnimationDuration;

  @override
  State<AdvancedChessBoard> createState() => _AdvancedChessBoardState();
}

class _AdvancedChessBoardState extends State<AdvancedChessBoard> {
  Set<String> _legalMoves = <String>{};
  String? _selectedSquare;
  bool _isPieceDragging = false;

  // Move animation state.
  _InFlightMove? _animatingMove;
  bool _suppressNextAnimation = false;

  // Asset-precache gate.
  bool _precached = false;

  chess.Chess get _game => widget.controller.game;

  @override
  void initState() {
    super.initState();
    if (widget.initialFEN != null) {
      widget.controller.loadGameFromFEN(widget.initialFEN!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    for (final asset in kAllPieceAssetPaths) {
      precacheImage(AssetImage(asset, package: packageName), context);
    }
  }

  @override
  void didUpdateWidget(covariant final AdvancedChessBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _selectedSquare = null;
      _legalMoves = <String>{};
      _animatingMove = null;
      setState(() {});
    }
  }

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final ctx, final boxConstraints) {
        final side =
            min(boxConstraints.maxWidth, boxConstraints.maxHeight);
        final squareSize = side / 8;
        return AspectRatio(
          aspectRatio: 1,
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (final context, _) {
              return Stack(
                children: <Widget>[
                  _buildChessBoard(squareSize),
                  if (_animatingMove != null)
                    MoveAnimationLayer(
                      key: ValueKey<_InFlightMove>(_animatingMove!),
                      fromSquare: _animatingMove!.from,
                      toSquare: _animatingMove!.to,
                      piece: _animatingMove!.piece,
                      squareSize: squareSize,
                      orientation: widget.boardOrientation,
                      duration: widget.moveAnimationDuration,
                      onComplete: () {
                        if (!mounted) return;
                        setState(() => _animatingMove = null);
                      },
                    ),
                  IgnorePointer(
                    child: CustomPaint(
                      painter:
                          ArrowPainter(widget.arrows, widget.boardOrientation),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Returns `true` when [to] is a legal destination from [from] using the
  /// `chess` engine's verbose move generation — no SAN substring matching.
  bool _isLegalDestination(final String from, final String to) {
    for (final m in _game.generate_moves(<String, String>{squareKey: from})) {
      if (m.toAlgebraic == to) return true;
    }
    return false;
  }

  Future<bool> _makeMove(
    final String from,
    final String to,
    final double squareSize,
  ) async {
    final String? promotion = _isPromotionMove(from, to)
        ? pieceTypeToString(await _showPromotionDialog(context, squareSize))
        : null;

    // Capture the moving piece BEFORE mutating the engine so the animation
    // layer can render it.
    final movingPiece = _game.get(from);

    final shouldAnimate = !_suppressNextAnimation &&
        widget.moveAnimationDuration > Duration.zero &&
        movingPiece != null;
    _suppressNextAnimation = false;

    final accepted = widget.controller
        .makeMove(from: from, to: to, promotion: promotion);

    if (accepted && shouldAnimate) {
      setState(() {
        _animatingMove = _InFlightMove(from, to, movingPiece);
      });
    }
    return accepted;
  }

  bool _isPromotionMove(final String from, final String to) {
    final piece = _game.get(from);
    return piece != null &&
        piece.type == chess.PieceType.PAWN &&
        ((piece.color == chess.Color.WHITE && to[1] == '8') ||
            (piece.color == chess.Color.BLACK && to[1] == '1'));
  }

  Widget _buildChessBoard(final double squareSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(8, (final row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(8, (final col) {
            final rank = widget.boardOrientation == PlayerColor.white
                ? (7 - row) + 1
                : row + 1;
            final file = widget.boardOrientation == PlayerColor.white
                ? files[col]
                : files[7 - col];
            final square = '$file$rank';
            final isLight = (row + col).isEven;
            final squareColor =
                isLight ? widget.lightSquareColor : widget.darkSquareColor;
            final invertColor =
                isLight ? widget.darkSquareColor : widget.lightSquareColor;
            return SizedBox(
              width: squareSize,
              height: squareSize,
              child: _buildSquareWithDragTarget(
                square,
                squareColor,
                invertColor,
                squareSize,
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildSquareWithDragTarget(
    final String square,
    final Color squareColor,
    final Color invertColor,
    final double squareSize,
  ) {
    final piece = _game.get(square);
    final hasPiece = piece != null;
    final isSelected = square == _selectedSquare;
    final isLegalTarget = _legalMoves.contains(square);
    final isOnLastMove = _isLastMoveSquare(square);
    final showLastMoveHighlight = widget.highlightLastMove &&
        isOnLastMove &&
        !isSelected; // avoid double-tinting

    return DragTarget<String>(
      onWillAcceptWithDetails: (final details) =>
          _isLegalDestination(details.data, square),
      onAcceptWithDetails: (final details) async {
        _suppressNextAnimation = true;
        await _makeMove(details.data, square, squareSize);
        setState(() {
          _selectedSquare = null;
          _legalMoves = <String>{};
        });
      },
      builder: (final ctx, _, __) {
        return GestureDetector(
          onTap: () => _handleTap(square, squareSize),
          child: MouseRegion(
            cursor: _isPieceDragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.basic,
            child: Stack(
              children: <Widget>[
                ChessSquare(
                  color: squareColor,
                  invertColor: invertColor,
                  square: square,
                  boardOrientation: widget.boardOrientation,
                  squareSize: squareSize,
                  piece: piece,
                ),
                if (isSelected && hasPiece)
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0x9BFFEB3B)),
                  ),
                if (hasPiece) _buildCheckmateKingOverlay(piece),
                if (isLegalTarget)
                  HighlightOverlay(
                    hasPiece: hasPiece,
                    squareSize: squareSize,
                  ),
                if (showLastMoveHighlight)
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0x80FFEB3B)),
                  ),
                if (hasPiece)
                  _buildPiece(square, squareSize, piece),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isLastMoveSquare(final String square) {
    if (_game.history.isEmpty) return false;
    final lastMove = _game.history.last.move;
    return square == lastMove.fromAlgebraic ||
        square == lastMove.toAlgebraic;
  }

  Widget _buildPiece(
    final String square,
    final double squareSize,
    final chess.Piece piece,
  ) {
    // Clamp the drag-feedback size so it never overflows the square by more
    // than `kMaxFeedbackOverflowPx` — critical on narrow boards.
    final scaled = squareSize * kMaxFeedbackScale;
    final clamped = squareSize + kMaxFeedbackOverflowPx;
    final feedbackSize = scaled < clamped ? scaled : clamped;

    // Hide the piece under the animating overlay so it doesn't appear twice.
    final hiddenByAnimation = _animatingMove != null &&
        square == _animatingMove!.from;
    if (hiddenByAnimation) {
      return const SizedBox.shrink();
    }

    return Draggable<String>(
      data: square,
      maxSimultaneousDrags: widget.enableMoves ? null : 0,
      onDragStarted: () {
        setState(() {
          _setSelectedSquareAndFindLegalMoves(square);
          _isPieceDragging = true;
        });
      },
      onDragEnd: (_) {
        setState(() => _isPieceDragging = false);
      },
      feedback: ChessPieceWidget(
        piece: piece,
        squareSize: feedbackSize,
        isDragging: _isPieceDragging,
        isBoardEnabled: widget.enableMoves,
      ),
      childWhenDragging: const SizedBox.shrink(),
      child: ChessPieceWidget(
        piece: piece,
        squareSize: squareSize,
        isBoardEnabled: widget.enableMoves,
        onTap: () => _handleTap(square, squareSize),
      ),
    );
  }

  Future<void> _handleTap(
    final String square,
    final double squareSize,
  ) async {
    if (!widget.enableMoves) return;
    final tappedPiece = _game.get(square);
    final hasSelection = _selectedSquare != null;

    if (!hasSelection && tappedPiece == null) {
      // Tap on empty square with nothing selected — no-op, no rebuild.
      return;
    }

    if (!hasSelection ||
        (_selectedSquare != square && _game.turn == tappedPiece?.color)) {
      // Select (or reselect) a piece of the side to move.
      setState(() => _setSelectedSquareAndFindLegalMoves(square));
      return;
    }

    if (_selectedSquare == square) {
      // Deselect.
      setState(() {
        _selectedSquare = null;
        _legalMoves = <String>{};
      });
      return;
    }

    // Attempt a move.
    if (_isLegalDestination(_selectedSquare!, square)) {
      await _makeMove(_selectedSquare!, square, squareSize);
    }
    setState(() {
      _selectedSquare = null;
      _legalMoves = <String>{};
    });
  }

  void _setSelectedSquareAndFindLegalMoves(final String square) {
    _selectedSquare = square;
    _legalMoves = <String>{
      for (final m
          in _game.generate_moves(<String, String>{squareKey: square}))
        m.toAlgebraic,
    };
  }

  Future<chess.PieceType> _showPromotionDialog(
    final BuildContext context,
    final double squareSize,
  ) async {
    return await showDialog<chess.PieceType>(
          context: context,
          builder: (final context) {
            return AlertDialog(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <chess.PieceType>[
                  chess.PieceType.QUEEN,
                  chess.PieceType.ROOK,
                  chess.PieceType.BISHOP,
                  chess.PieceType.KNIGHT,
                ].map((final pieceType) {
                  return ChessPieceWidget(
                    piece: chess.Piece(pieceType, _game.turn),
                    squareSize: squareSize,
                    onTap: () => Navigator.of(context).pop(pieceType),
                    isBoardEnabled: widget.enableMoves,
                  );
                }).toList(),
              ),
            );
          },
        ) ??
        chess.PieceType.QUEEN;
  }

  Widget _buildCheckmateKingOverlay(final chess.Piece piece) {
    if (_game.in_checkmate &&
        piece.type == chess.PieceType.KING &&
        piece.color == _game.turn) {
      return Positioned.fill(
        child: ColoredBox(
          color: widget.kingBackgroundColorOnCheckmate ??
              const Color(0x9BF44336),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Internal record of an in-flight animated move.
class _InFlightMove {
  const _InFlightMove(this.from, this.to, this.piece);

  final String from;
  final String to;
  final chess.Piece piece;

  @override
  bool operator ==(final Object other) =>
      other is _InFlightMove &&
      other.from == from &&
      other.to == to &&
      identical(other.piece, piece);

  @override
  int get hashCode => Object.hash(from, to, identityHashCode(piece));
}
