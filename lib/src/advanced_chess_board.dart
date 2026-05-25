import 'dart:async';
import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import 'chess_board_controller.dart';
import 'constants/global_constants.dart';
import 'coordinates/coordinate_labels.dart';
import 'hint/hint_arrow.dart';
import 'hint/hint_arrow_painter.dart';
import 'models/chess_arrow.dart';
import 'models/enums.dart';
import 'piece_set/piece_set.dart';
import 'sound/move_classifier.dart';
import 'sound/sound_event.dart';
import 'sound/sound_pack.dart';
import 'theme/board_theme.dart';
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
/// board colours via [boardTheme], orientation flipping, a configurable
/// last-move highlight, arrow overlays, a smooth piece-move animation for
/// non-drag moves, a pluggable [pieceSet], coordinate-label modes via
/// [coordinates], an audio hook via [soundPack], and an engine-suggestion
/// [hintArrow].
///
/// The widget subscribes to [controller] internally — you do NOT need to
/// call `controller.addListener(setState)` yourself; the board rebuilds on
/// its own when the controller notifies.
///
/// ### Legacy-wins resolution
///
/// The legacy per-colour parameters ([lightSquareColor], [darkSquareColor],
/// [kingBackgroundColorOnCheckmate]) take precedence over the corresponding
/// fields on [boardTheme] when explicitly passed. The effective theme is
/// computed as:
/// ```dart
/// _effectiveTheme = boardTheme.copyWith(
///   lightSquareColor: lightSquareColor,
///   darkSquareColor: darkSquareColor,
///   kingCheckmateColor: kingBackgroundColorOnCheckmate ?? boardTheme.kingCheckmateColor,
/// );
/// ```
class AdvancedChessBoard extends StatefulWidget {
  /// Creates an [AdvancedChessBoard].
  const AdvancedChessBoard({
    super.key,
    required this.controller,
    this.lightSquareColor,
    this.darkSquareColor,
    this.initialFEN,
    this.boardOrientation = PlayerColor.white,
    this.enableMoves = true,
    this.highlightLastMove = true,
    this.arrows = const <ChessArrow>[],
    this.kingBackgroundColorOnCheckmate,
    this.moveAnimationDuration = kDefaultMoveAnimationDuration,
    this.boardTheme = BoardTheme.classicGreen,
    this.pieceSet = PieceSet.chessDotCom,
    this.coordinates = CoordinateLabels.inside,
    this.soundPack = const SilentSoundPack(),
    this.hintArrow,
  });

  /// Controller driving the board state.
  ///
  /// The widget subscribes to this controller via [ListenableBuilder] — no
  /// consumer-side `addListener(setState)` is needed.
  final ChessBoardController controller;

  /// Colour of the light squares.
  ///
  /// When passed explicitly, this value takes precedence over
  /// [boardTheme.lightSquareColor] (legacy-wins resolution). When `null`
  /// (the default), [boardTheme.lightSquareColor] is used.
  final Color? lightSquareColor;

  /// Colour of the dark squares.
  ///
  /// When passed explicitly, this value takes precedence over
  /// [boardTheme.darkSquareColor] (legacy-wins resolution). When `null`
  /// (the default), [boardTheme.darkSquareColor] is used.
  final Color? darkSquareColor;

  /// Background colour painted behind the mated king when the game ends by
  /// checkmate. Defaults to `Colors.red.withAlpha(155)`.
  ///
  /// When passed explicitly, this value takes precedence over
  /// [boardTheme.kingCheckmateColor] (legacy-wins resolution).
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

  /// Colour bundle used for every square, overlay, label, and tint.
  ///
  /// Legacy per-colour parameters ([lightSquareColor], [darkSquareColor],
  /// [kingBackgroundColorOnCheckmate]) take precedence over the corresponding
  /// fields on [boardTheme] when explicitly passed — see the class-level
  /// dartdoc for the resolution formula.
  final BoardTheme boardTheme;

  /// Piece image provider. Default is [PieceSet.chessDotCom] — the 12
  /// bundled Chess.com-sourced PNGs.
  final PieceSet pieceSet;

  /// Coordinate-label rendering mode. Default [CoordinateLabels.inside]
  /// matches 3.0.0.
  final CoordinateLabels coordinates;

  /// Audio hook. Default [SilentSoundPack] produces no sound.
  final SoundPack soundPack;

  /// Optional engine/app-supplied suggestion arrow, rendered on top of
  /// [arrows] and auto-dismissed on the next successful move.
  final HintArrow? hintArrow;

  @override
  State<AdvancedChessBoard> createState() => _AdvancedChessBoardState();

  /// Returns the effective theme of the board state for testing purposes.
  ///
  /// Only available in debug/test builds. Throws if the widget is not mounted.
  @visibleForTesting
  static BoardTheme effectiveThemeOf(final State<AdvancedChessBoard> state) {
    return (state as _AdvancedChessBoardState)._effectiveTheme;
  }
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

  // Hint arrow state.
  HintArrow? _activeHint;
  Timer? _hintTimer;

  // Track move count to detect programmatic moves.
  int _lastMoveCount = 0;

  chess.Chess get _game => widget.controller.game;

  /// Computes the effective theme by applying legacy-wins resolution.
  ///
  /// The legacy per-colour parameters ([AdvancedChessBoard.lightSquareColor],
  /// [AdvancedChessBoard.darkSquareColor],
  /// [AdvancedChessBoard.kingBackgroundColorOnCheckmate]) take precedence over
  /// the corresponding fields on [AdvancedChessBoard.boardTheme].
  BoardTheme get _effectiveTheme => widget.boardTheme.copyWith(
        lightSquareColor: widget.lightSquareColor,
        darkSquareColor: widget.darkSquareColor,
        kingCheckmateColor: widget.kingBackgroundColorOnCheckmate ??
            widget.boardTheme.kingCheckmateColor,
      );

  /// Returns the active hint arrow for testing purposes.
  @visibleForTesting
  HintArrow? get debugActiveHint => _activeHint;

  @override
  void initState() {
    super.initState();
    if (widget.initialFEN != null) {
      widget.controller.loadGameFromFEN(widget.initialFEN!);
    }
    _reconcileHint(widget.hintArrow);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    _precacheActivePieceSet();
  }

  void _precacheActivePieceSet() {
    for (final color in PlayerColor.values) {
      for (final type in const <chess.PieceType>[
        chess.PieceType.KING,
        chess.PieceType.QUEEN,
        chess.PieceType.ROOK,
        chess.PieceType.BISHOP,
        chess.PieceType.KNIGHT,
        chess.PieceType.PAWN,
      ]) {
        precacheImage(widget.pieceSet.imageFor(color, type), context);
      }
    }
  }

  @override
  void didUpdateWidget(covariant final AdvancedChessBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _selectedSquare = null;
      _legalMoves = <String>{};
      _animatingMove = null;
      _activeHint = null;
      _hintTimer?.cancel();
      _hintTimer = null;
      setState(() {});
    }
    if (old.pieceSet != widget.pieceSet) {
      _precacheActivePieceSet();
      setState(() {});
    }
    _reconcileHint(widget.hintArrow);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _reconcileHint(final HintArrow? next) {
    if (next == null) {
      if (_activeHint != null) {
        setState(() {
          _activeHint = null;
          _hintTimer?.cancel();
          _hintTimer = null;
        });
      }
      return;
    }
    if (_activeHint == next) return; // same value — leave timer running
    _hintTimer?.cancel();
    _hintTimer = null;
    setState(() {
      _activeHint = next;
    });
    if (next.duration != null) {
      _hintTimer = Timer(next.duration!, () {
        if (!mounted) return;
        setState(() {
          _activeHint = null;
          _hintTimer = null;
        });
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final BuildContext ctx, final BoxConstraints boxConstraints) {
        final side = min(boxConstraints.maxWidth, boxConstraints.maxHeight);
        final squareSize = side / 8;

        final child = switch (widget.coordinates) {
          CoordinateLabels.inside => AspectRatio(
              aspectRatio: 1,
              child: _buildBoardWithStack(squareSize),
            ),
          CoordinateLabels.outside => _buildWithOutsideGutter(squareSize),
          CoordinateLabels.none => AspectRatio(
              aspectRatio: 1,
              child: _buildBoardWithStack(squareSize),
            ),
        };

        return child;
      },
    );
  }

  Widget _buildBoardWithStack(final double squareSize) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (final BuildContext context, final Widget? _) {
        // Dismiss hint on any successful move (including programmatic ones).
        final currentMoveCount = widget.controller.moveCount;
        if (currentMoveCount != _lastMoveCount && _activeHint != null) {
          _lastMoveCount = currentMoveCount;
          // Schedule dismissal after the build completes.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _activeHint != null) {
              setState(() {
                _activeHint = null;
                _hintTimer?.cancel();
                _hintTimer = null;
              });
            }
          });
        } else {
          _lastMoveCount = currentMoveCount;
        }
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
                pieceSet: widget.pieceSet,
                onComplete: () {
                  if (!mounted) return;
                  setState(() => _animatingMove = null);
                },
              ),
            IgnorePointer(
              child: CustomPaint(
                painter: ArrowPainter(widget.arrows, widget.boardOrientation),
                child: const SizedBox.expand(),
              ),
            ),
            if (_activeHint != null)
              IgnorePointer(
                child: CustomPaint(
                  painter: HintArrowPainter(
                    _activeHint!,
                    _effectiveTheme,
                    widget.boardOrientation,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildWithOutsideGutter(final double squareSize) {
    final gutterSize = max(kMinLabelFontSize * 2, squareSize * 0.36);
    final ranks = widget.boardOrientation == PlayerColor.white
        ? const <String>['8', '7', '6', '5', '4', '3', '2', '1']
        : const <String>['1', '2', '3', '4', '5', '6', '7', '8'];
    final filesOrdered = widget.boardOrientation == PlayerColor.white
        ? files
        : files.reversed.toList(growable: false);
    return LayoutBuilder(
      builder: (
        final BuildContext ctx,
        final BoxConstraints outerConstraints,
      ) {
        // Clamp gutter to at most half the available width/height to prevent
        // overflow on very narrow boards (Requirement 3.10).
        final maxGutter = min(
          gutterSize,
          min(outerConstraints.maxWidth, outerConstraints.maxHeight) / 2,
        );
        return Row(
          children: <Widget>[
            SizedBox(
              width: maxGutter,
              child: _CoordinateGutter(
                axis: Axis.vertical,
                labels: ranks,
                gutterSize: maxGutter,
                squareSize: squareSize,
                labelColor: _effectiveTheme.coordinateLabelColor,
              ),
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: LayoutBuilder(
                      builder: (
                        final BuildContext innerCtx,
                        final BoxConstraints innerConstraints,
                      ) {
                        final innerSide = min(
                          innerConstraints.maxWidth,
                          innerConstraints.maxHeight,
                        );
                        final innerSquareSize = innerSide / 8;
                        return AspectRatio(
                          aspectRatio: 1,
                          child: _buildBoardWithStack(innerSquareSize),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: maxGutter,
                    child: _CoordinateGutter(
                      axis: Axis.horizontal,
                      labels: filesOrdered,
                      gutterSize: maxGutter,
                      squareSize: squareSize,
                      labelColor: _effectiveTheme.coordinateLabelColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    final accepted =
        widget.controller.makeMove(from: from, to: to, promotion: promotion);

    if (accepted) {
      // Classification and audio dispatch.
      final last = _game.history.last.move;
      final event = classifySoundEvent(
        verboseMove: last,
        isGameOverAfter: widget.controller.isGameOver,
        isInCheckAfter: widget.controller.isInCheck,
      );
      _firePlay(event);

      // Dismiss any active hint on any successful move.
      if (_activeHint != null) {
        setState(() {
          _activeHint = null;
          _hintTimer?.cancel();
          _hintTimer = null;
        });
      }

      if (shouldAnimate) {
        setState(() {
          _animatingMove = _InFlightMove(from, to, movingPiece);
        });
      }
    }
    return accepted;
  }

  void _firePlay(final SoundEvent event) {
    try {
      widget.soundPack
          .play(event)
          .catchError((final Object err, final StackTrace st) {
        debugPrint('SoundPack.play($event) threw asynchronously: $err');
      });
    } catch (err) {
      debugPrint('SoundPack.play($event) threw synchronously: $err');
    }
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
      children: List<Widget>.generate(8, (final int row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(8, (final int col) {
            final rank = widget.boardOrientation == PlayerColor.white
                ? (7 - row) + 1
                : row + 1;
            final file = widget.boardOrientation == PlayerColor.white
                ? files[col]
                : files[7 - col];
            final square = '$file$rank';
            final isLight = (row + col).isEven;
            final squareColor = isLight
                ? _effectiveTheme.lightSquareColor
                : _effectiveTheme.darkSquareColor;
            final invertColor = isLight
                ? _effectiveTheme.darkSquareColor
                : _effectiveTheme.lightSquareColor;
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
      onWillAcceptWithDetails: (final DragTargetDetails<String> details) =>
          _isLegalDestination(details.data, square),
      onAcceptWithDetails: (final DragTargetDetails<String> details) async {
        _suppressNextAnimation = true;
        await _makeMove(details.data, square, squareSize);
        setState(() {
          _selectedSquare = null;
          _legalMoves = <String>{};
        });
      },
      builder: (
        final BuildContext ctx,
        final List<String?> candidateData,
        final List<dynamic> rejectedData,
      ) {
        final isDragSource = _isPieceDragging && square == _selectedSquare;
        final isDragLegalHover =
            widget.enableMoves && candidateData.isNotEmpty && !isDragSource;
        final isDragIllegalHover =
            widget.enableMoves && rejectedData.isNotEmpty && !isDragSource;

        final Widget result = GestureDetector(
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
                  coordinates: widget.coordinates,
                  labelColor: _effectiveTheme.coordinateLabelColor,
                ),
                if (isSelected && hasPiece)
                  Positioned.fill(
                    child: ColoredBox(color: _effectiveTheme.selectionColor),
                  ),
                if (hasPiece) _buildKingStateOverlay(piece),
                if (isLegalTarget)
                  HighlightOverlay(
                    hasPiece: hasPiece,
                    squareSize: squareSize,
                    color: _effectiveTheme.legalDestinationColor,
                  ),
                if (isDragLegalHover)
                  _DragLegalRing(
                    color: _effectiveTheme.dragLegalRingColor,
                    squareSize: squareSize,
                  ),
                if (isDragIllegalHover)
                  Positioned.fill(
                    child: ColoredBox(
                      color: _effectiveTheme.dragIllegalTintColor,
                    ),
                  ),
                if (showLastMoveHighlight)
                  Positioned.fill(
                    child: ColoredBox(
                      color: _effectiveTheme.lastMoveHighlightColor,
                    ),
                  ),
                if (hasPiece) _buildPiece(square, squareSize, piece),
              ],
            ),
          ),
        );
        return result;
      },
    );
  }

  bool _isLastMoveSquare(final String square) {
    if (_game.history.isEmpty) return false;
    final lastMove = _game.history.last.move;
    return square == lastMove.fromAlgebraic || square == lastMove.toAlgebraic;
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
    final hiddenByAnimation =
        _animatingMove != null && square == _animatingMove!.from;
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
        pieceSet: widget.pieceSet,
      ),
      childWhenDragging: const SizedBox.shrink(),
      child: ChessPieceWidget(
        piece: piece,
        squareSize: squareSize,
        isBoardEnabled: widget.enableMoves,
        onTap: () => _handleTap(square, squareSize),
        pieceSet: widget.pieceSet,
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
      for (final m in _game.generate_moves(<String, String>{squareKey: square}))
        m.toAlgebraic,
    };
  }

  Future<chess.PieceType> _showPromotionDialog(
    final BuildContext context,
    final double squareSize,
  ) async {
    return await showDialog<chess.PieceType>(
          context: context,
          builder: (final BuildContext context) {
            return AlertDialog(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <chess.PieceType>[
                  chess.PieceType.QUEEN,
                  chess.PieceType.ROOK,
                  chess.PieceType.BISHOP,
                  chess.PieceType.KNIGHT,
                ].map((final chess.PieceType pieceType) {
                  return ChessPieceWidget(
                    piece: chess.Piece(pieceType, _game.turn),
                    squareSize: squareSize,
                    onTap: () => Navigator.of(context).pop(pieceType),
                    isBoardEnabled: widget.enableMoves,
                    pieceSet: widget.pieceSet,
                  );
                }).toList(),
              ),
            );
          },
        ) ??
        chess.PieceType.QUEEN;
  }

  Widget _buildKingStateOverlay(final chess.Piece piece) {
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
}

/// A thickened ring drawn on a legal-destination square currently under the
/// drag pointer.
class _DragLegalRing extends StatelessWidget {
  /// Creates a [_DragLegalRing].
  const _DragLegalRing({required this.color, required this.squareSize});

  /// Colour of the ring border.
  final Color color;

  /// Size of the underlying square in logical pixels.
  final double squareSize;

  @override
  Widget build(final BuildContext context) {
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

/// A gutter strip (rank or file) used when [CoordinateLabels.outside] is
/// active.
class _CoordinateGutter extends StatelessWidget {
  /// Creates a [_CoordinateGutter].
  const _CoordinateGutter({
    required this.axis,
    required this.labels,
    required this.gutterSize,
    required this.squareSize,
    this.labelColor,
  });

  /// Whether this gutter is vertical (ranks) or horizontal (files).
  final Axis axis;

  /// The labels to render, in order from top-to-bottom or left-to-right.
  final List<String> labels;

  /// Size of the gutter in logical pixels (width for vertical, height for
  /// horizontal).
  final double gutterSize;

  /// Size of a board square in logical pixels; used to compute font size.
  final double squareSize;

  /// Optional explicit label colour. When `null`, uses the theme's derived
  /// colour (inverted square colour at alpha 200).
  final Color? labelColor;

  @override
  Widget build(final BuildContext context) {
    final fontSize = max(kMinLabelFontSize, squareSize * 0.18);
    final textStyle = TextStyle(
      fontSize: fontSize,
      color: (labelColor ?? Theme.of(context).colorScheme.onSurface)
          .withAlpha(200),
    );

    final children = labels
        .map(
          (final String l) => Expanded(
            child: Center(
              child: Text(l, style: textStyle),
            ),
          ),
        )
        .toList();

    return axis == Axis.vertical
        ? Column(children: children)
        : Row(children: children);
  }
}

/// Internal record of an in-flight animated move.
class _InFlightMove {
  /// Creates an [_InFlightMove].
  const _InFlightMove(this.from, this.to, this.piece);

  /// Source square.
  final String from;

  /// Destination square.
  final String to;

  /// The piece being animated.
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
