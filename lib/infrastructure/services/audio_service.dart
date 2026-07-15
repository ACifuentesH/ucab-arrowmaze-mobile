import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'package:arrow_maze/application/enums/sound_effect.dart';
import 'package:arrow_maze/application/ports/i_audio_service.dart';

/// Implementa IAudioService envolviendo el paquete audioplayers.
///
/// Patrones:
///   Singleton  — una sola instancia compartida en toda la app.
///   Facade     — oculta la gestión de múltiples AudioPlayer tras una API simple.
///   Adapter    — traduce SoundEffect → ruta de asset y API de audioplayers.
class AudioService implements IAudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  final AudioPlayer _music = AudioPlayer();
  bool _isMuted = false;

  static const String _musicPath = 'audio/background.wav';

  static const Map<SoundEffect, String> _sfxPaths = {
    SoundEffect.arrowEscaped: 'audio/sfx/arrow_escaped.wav',
    SoundEffect.moveBlocked: 'audio/sfx/move_blocked.wav',
    SoundEffect.levelCleared: 'audio/sfx/level_cleared.wav',
    SoundEffect.gameOver: 'audio/sfx/game_over.wav',
    SoundEffect.buttonTap: 'audio/sfx/button_tap.wav',
  };

  @override
  bool get isMuted => _isMuted;

  @override
  Future<void> playMusic() async {
    if (_isMuted) return;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.play(AssetSource(_musicPath));
    } catch (e, st) {
      // Audio is non-critical: never let a playback failure surface as
      // user-facing error UI. But a swallowed exception here used to hide
      // real bugs (e.g. an asset missing from pubspec.yaml's `assets:`
      // list, or a browser rejecting playback) with zero trace — so at
      // least log it in debug builds.
      _logPlaybackError('playMusic', e, st);
    }
  }

  @override
  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (e, st) {
      _logPlaybackError('stopMusic', e, st);
    }
  }

  @override
  Future<void> playSfx(SoundEffect effect) async {
    if (_isMuted) return;
    final path = _sfxPaths[effect];
    if (path == null) return;
    final player = AudioPlayer();
    try {
      await player.play(AssetSource(path));
      player.onPlayerComplete.first.then((_) => player.dispose());
    } catch (e, st) {
      _logPlaybackError('playSfx($effect)', e, st);
      await player.dispose();
    }
  }

  /// Logs unexpected audio failures in debug builds only. Playback is a
  /// non-critical feature — never rethrows or shows user-facing error UI —
  /// but silently discarding every exception (the previous behaviour) hid
  /// real bugs from development/debugging, which is what this guards against.
  void _logPlaybackError(String op, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('AudioService.$op failed: $error\n$stackTrace');
    }
  }

  @override
  void toggleMute() {
    _isMuted = !_isMuted;
    _isMuted ? _music.setVolume(0) : _music.setVolume(1);
  }
}
