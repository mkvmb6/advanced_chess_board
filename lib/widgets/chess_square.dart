import 'package:flutter/material.dart';

class ChessSquare extends StatelessWidget {
  final Color color;

  const ChessSquare({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
      ),
    );
  }
}
