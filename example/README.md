# advanced_chess_board example

A Flutter example app demonstrating the `advanced_chess_board` 3.1.0 features.

## Features demonstrated

### Board theme dropdown

The **Theme** dropdown at the top switches between the five built-in presets:
`classicGreen`, `brown`, `blue`, `purple`, and `monochrome`. See
`example/lib/main.dart` — the `_boardTheme` state variable is passed as
`boardTheme:` to `AdvancedChessBoard`.

### Coordinate labels segmented button

The **Coords** segmented button switches between `inside` (3.0.0 default),
`outside` (labels in gutters outside the 8×8 grid), and `none` (no labels).
The `AspectRatio(1)` contract still applies to the playing grid in every mode.

### Debug sound pack

The **Debug sound** checkbox toggles between `SilentSoundPack` (default, no
audio) and `_DebugSoundPack` (prints `sound: <event>` to the console). This
demonstrates the `SoundPack` interface without bundling any audio assets.

For a real implementation, route `SoundEvent`s to your preferred audio backend
(e.g. `package:audioplayers`):

```dart
class MySoundPack extends SoundPack {
  @override
  Future<void> play(SoundEvent event) async {
    await audioPlayer.play(AssetSource('sounds/${event.name}.mp3'));
  }
}
```

### Hint arrow

The **Show hint: Nf3** button sets a `HintArrow` from g1 to f3 with a 4-second
auto-dismiss duration. The arrow is rendered with a dashed shaft and
stroke-only outlined arrowhead in lime green, visually distinct from the
user-drawn `ChessArrow`s. It auto-dismisses on the next successful move or
after 4 seconds.

### Drag legality indicator

The drag legality indicator fires automatically whenever `enableMoves: true`
(the default) and a drag is in progress. A thickened ring appears on legal
destination squares under the pointer; a translucent red tint appears on
non-source non-legal squares. Customise the colours via
`boardTheme.dragLegalRingColor` and `boardTheme.dragIllegalTintColor`.

## Getting started

```bash
cd example
flutter run
```
