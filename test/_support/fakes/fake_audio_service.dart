import 'package:arrow_maze/application/enums/sound_effect.dart';
import 'package:arrow_maze/application/ports/i_audio_service.dart';

/// Fake in-memory de IAudioService: registra llamadas, no reproduce nada.
class FakeAudioService implements IAudioService {
  int playMusicCount = 0;
  int stopMusicCount = 0;
  final List<SoundEffect> sfxPlayed = [];
  bool _muted = false;

  @override
  bool get isMuted => _muted;

  @override
  Future<void> playMusic() async => playMusicCount++;

  @override
  Future<void> stopMusic() async => stopMusicCount++;

  @override
  Future<void> playSfx(SoundEffect effect) async => sfxPlayed.add(effect);

  @override
  void toggleMute() => _muted = !_muted;
}
