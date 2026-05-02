import 'sound_event.dart';

/// Plug-in interface for move sound effects.
///
/// The library ships no audio assets and depends on no audio plugin.
/// Consumers pass a subclass that routes [SoundEvent]s to their preferred
/// audio stack (for example, `package:audioplayers` or
/// `package:just_audio`). Thrown errors are caught and logged via
/// `debugPrint` — they do not propagate to the board's rebuild cycle.
///
/// See also:
/// - [SilentSoundPack] — the default implementation that produces no sound.
abstract class SoundPack {
  /// Base const constructor.
  const SoundPack();

  /// Invoked exactly once per successful move. Implementations may return
  /// immediately (fire-and-forget) or `await` loading / playback —
  /// [AdvancedChessBoard] does not await the returned future.
  ///
  /// If this method throws synchronously or the returned [Future] completes
  /// with an error, the error is caught and logged via `debugPrint` — it
  /// does not propagate to the board's rebuild cycle.
  Future<void> play(SoundEvent event);
}

/// Default [SoundPack]: `play` returns immediately without touching any
/// audio plugin or platform channel.
///
/// This is the default value for [AdvancedChessBoard.soundPack]. It produces
/// no sound, has no audio assets, and triggers no platform channels.
class SilentSoundPack extends SoundPack {
  /// Creates a [SilentSoundPack].
  const SilentSoundPack();

  @override
  Future<void> play(final SoundEvent event) => Future<void>.value();
}
