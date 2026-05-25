import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// Debug sound pack that prints sound events to the console.
class _DebugSoundPack extends SoundPack {
  /// Creates a [_DebugSoundPack].
  const _DebugSoundPack();

  @override
  Future<void> play(final SoundEvent event) {
    debugPrint('sound: $event');
    return Future<void>.value();
  }
}

class MyApp extends StatefulWidget {
  /// Creates a [MyApp].
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = ChessBoardController();
  var boardOrientation = PlayerColor.white;

  // 3.1.0 knobs.
  BoardTheme _boardTheme = BoardTheme.classicGreen;
  PieceSet _pieceSet = PieceSet.chessDotCom;
  CoordinateLabels _coordinates = CoordinateLabels.inside;
  bool _useDebugSoundPack = false;
  HintArrow? _hint;
  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      setState(() {});
      debugPrint('Player to move: ${controller.playerColor}');
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(final BuildContext context) {
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
          children: <Widget>[
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: AdvancedChessBoard(
                    controller: controller,
                    boardOrientation: boardOrientation,
                    boardTheme: _boardTheme,
                    pieceSet: _pieceSet,
                    coordinates: _coordinates,
                    soundPack: _useDebugSoundPack
                        ? const _DebugSoundPack()
                        : const SilentSoundPack(),
                    hintArrow: _hint,
                    arrows: <ChessArrow>[
                      ChessArrow(
                        startSquare: 'e2',
                        endSquare: 'e4',
                      ),
                      ChessArrow(
                        startSquare: 'e7',
                        endSquare: 'e5',
                      ),
                      ChessArrow(
                        startSquare: 'g1',
                        endSquare: 'f3',
                        color: Colors.red.withAlpha(128),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Board theme dropdown (Task 12.1).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                children: <Widget>[
                  const Text('Theme: '),
                  DropdownButton<BoardTheme>(
                    value: _boardTheme,
                    items: <DropdownMenuItem<BoardTheme>>[
                      DropdownMenuItem<BoardTheme>(
                        value: BoardTheme.classicGreen,
                        child: const Text('Classic Green'),
                      ),
                      DropdownMenuItem<BoardTheme>(
                        value: BoardTheme.brown,
                        child: const Text('Brown'),
                      ),
                      DropdownMenuItem<BoardTheme>(
                        value: BoardTheme.blue,
                        child: const Text('Blue'),
                      ),
                      DropdownMenuItem<BoardTheme>(
                        value: BoardTheme.purple,
                        child: const Text('Purple'),
                      ),
                      DropdownMenuItem<BoardTheme>(
                        value: BoardTheme.monochrome,
                        child: const Text('Monochrome'),
                      ),
                    ],
                    onChanged: (final BoardTheme? value) {
                      if (value != null) {
                        setState(() => _boardTheme = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            // Piece set dropdown (Task 12.2).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                children: <Widget>[
                  const Text('Pieces: '),
                  DropdownButton<String>(
                    value: _pieceSet == PieceSet.chessDotCom
                        ? 'chessDotCom'
                        : 'custom',
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'chessDotCom',
                        child: Text('Chess.com (default)'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'custom',
                        child: Text('Chess.com (same set, demo)'),
                      ),
                    ],
                    onChanged: (final String? value) {
                      setState(() {
                        // Both options use chessDotCom for demo purposes.
                        // In a real app, the second option would use a
                        // different PieceSet.fromAssetMap({...}).
                        _pieceSet = PieceSet.chessDotCom;
                      });
                    },
                  ),
                ],
              ),
            ), // Coordinate labels segmented button (Task 12.3).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                children: <Widget>[
                  const Text('Coords: '),
                  SegmentedButton<CoordinateLabels>(
                    segments: const <ButtonSegment<CoordinateLabels>>[
                      ButtonSegment<CoordinateLabels>(
                        value: CoordinateLabels.inside,
                        label: Text('Inside'),
                      ),
                      ButtonSegment<CoordinateLabels>(
                        value: CoordinateLabels.outside,
                        label: Text('Outside'),
                      ),
                      ButtonSegment<CoordinateLabels>(
                        value: CoordinateLabels.none,
                        label: Text('None'),
                      ),
                    ],
                    selected: <CoordinateLabels>{_coordinates},
                    onSelectionChanged: (final Set<CoordinateLabels> value) {
                      setState(() => _coordinates = value.first);
                    },
                  ),
                ],
              ),
            ),
            // Debug sound pack checkbox (Task 12.4).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                children: <Widget>[
                  const Text('Debug sound: '),
                  Checkbox(
                    value: _useDebugSoundPack,
                    onChanged: (final bool? value) {
                      setState(() => _useDebugSoundPack = value ?? false);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => setState(() {
                      boardOrientation = boardOrientation == PlayerColor.white
                          ? PlayerColor.black
                          : PlayerColor.white;
                    }),
                    child: const Text('Flip'),
                  ),
                  ElevatedButton(
                    onPressed: () => controller.undo(),
                    child: const Text('Undo'),
                  ),
                  ElevatedButton(
                    onPressed: () => controller.loadGameFromFEN(
                      '4k3/p2pNpp1/p2P4/4P2R/5P2/2P3P1/r1PKN1q1/4R3 w - - 0 1',
                    ),
                    child: const Text('Load Fen'),
                  ),
                  // Show hint button (Task 12.5).
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _hint = const HintArrow(
                        startSquare: 'g1',
                        endSquare: 'f3',
                        duration: Duration(seconds: 4),
                      );
                    }),
                    child: const Text('Show hint: Nf3'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
