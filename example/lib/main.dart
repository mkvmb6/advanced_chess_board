import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/chess_board_controller.dart';
import 'package:advanced_chess_board/models/chess_arrow.dart';
import 'package:advanced_chess_board/models/enums.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = ChessBoardController();
  var boardOrientation = PlayerColor.white;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {});
      debugPrint("Player to move: ${controller.playerColor}");
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Board Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        appBar: AppBar(title: const Text('Chess Board Example')),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: AdvancedChessBoard(
                    controller: controller,
                    boardOrientation: boardOrientation,
                    arrows: [
                      ChessArrow(
                        startSquare: "e2",
                        endSquare: "e4",
                      ),
                      ChessArrow(
                        startSquare: "e7",
                        endSquare: "e5",
                      ),
                      ChessArrow(
                        startSquare: "g1",
                        endSquare: "f3",
                        color: Colors.red.withAlpha(128),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() {
                      boardOrientation = boardOrientation == PlayerColor.white
                          ? PlayerColor.black
                          : PlayerColor.white;
                    }),
                    child: const Text("Flip"),
                  ),
                  ElevatedButton(
                    onPressed: () => controller.undo(),
                    child: const Text("Undo"),
                  ),
                  ElevatedButton(
                    onPressed: () => controller.loadGameFromFEN(
                        "4k3/p2pNpp1/p2P4/4P2R/5P2/2P3P1/r1PKN1q1/4R3 w - - 0 1"),
                    child: const Text("Load Fen"),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
