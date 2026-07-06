import 'package:audioplayers/audioplayers.dart';

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

  static const String _musicPath = 'audio/background.mp3';

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
    } catch (_) {
      // Audio file not present during development — skip silently.
    }
  }

  @override
  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (_) {}
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
    } catch (_) {
      await player.dispose();
    }
  }

  @override
  void toggleMute() {
    _isMuted = !_isMuted;
    _isMuted ? _music.setVolume(0) : _music.setVolume(1);
  }
}
