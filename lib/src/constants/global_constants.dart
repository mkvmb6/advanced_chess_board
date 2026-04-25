/// Package name used when resolving bundled asset paths.
const String packageName = 'advanced_chess_board';

/// Map key for the `from` square passed to `chess.Chess.move`.
const String fromKey = 'from';

/// Map key for the `to` square passed to `chess.Chess.move`.
const String toKey = 'to';

/// Map key for the `promotion` piece letter passed to `chess.Chess.move`.
const String promotionKey = 'promotion';

/// Map key for the `square` parameter passed to `chess.Chess.moves` /
/// `generate_moves` for single-square generation.
const String squareKey = 'square';

/// Files (columns) of the board in algebraic notation.
const List<String> files = <String>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

/// Minimum rendered font size (in logical pixels) for rank/file labels.
///
/// On very small boards, `squareSize * 0.18` can fall below readable.
/// Labels are rendered at `max(kMinLabelFontSize, squareSize * 0.18)`.
const double kMinLabelFontSize = 9;

/// Upper bound on the drag-feedback scale factor applied to a piece while
/// the user drags it. The real scale is clamped so that feedback never
/// overflows the underlying square by more than [kMaxFeedbackOverflowPx].
const double kMaxFeedbackScale = 1.15;

/// Hard ceiling on how many logical pixels the drag feedback may exceed
/// the underlying square size.
const double kMaxFeedbackOverflowPx = 8;

/// Default duration of the post-tap / post-programmatic move animation.
const Duration kDefaultMoveAnimationDuration = Duration(milliseconds: 150);

/// All 12 piece asset paths, used to precache piece images on first
/// `didChangeDependencies`.
const List<String> kAllPieceAssetPaths = <String>[
  'assets/pieces/bb.png',
  'assets/pieces/bk.png',
  'assets/pieces/bn.png',
  'assets/pieces/bp.png',
  'assets/pieces/bq.png',
  'assets/pieces/br.png',
  'assets/pieces/wb.png',
  'assets/pieces/wk.png',
  'assets/pieces/wn.png',
  'assets/pieces/wp.png',
  'assets/pieces/wq.png',
  'assets/pieces/wr.png',
];
