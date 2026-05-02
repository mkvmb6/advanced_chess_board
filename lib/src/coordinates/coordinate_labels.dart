/// How rank/file coordinate labels are rendered on [AdvancedChessBoard].
enum CoordinateLabels {
  /// Labels overlaid inside the corner squares of the playing grid —
  /// the 3.0.0 default. See [ChessSquare] for exact positioning.
  inside,

  /// Labels rendered in gutters OUTSIDE the 8×8 playing grid (left-edge
  /// for ranks, bottom-edge for files). The playing grid still honours
  /// `AspectRatio(1)`; the gutters consume additional horizontal /
  /// vertical space.
  outside,

  /// No rank or file labels rendered anywhere. No gutter space allocated.
  none,
}
