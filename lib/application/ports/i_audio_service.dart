import 'package:arrow_maze/application/enums/sound_effect.dart';

/// Puerto de aplicación: servicio de audio.
/// El dominio no lo conoce; solo la capa de aplicación y superiores.
abstract interface class IAudioService {
  bool get isMuted;
  Future<void> playMusic();
  Future<void> stopMusic();
  Future<void> playSfx(SoundEffect effect);
  void toggleMute();
}
