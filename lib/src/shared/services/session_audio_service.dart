import 'package:audioplayers/audioplayers.dart';

class SessionAudioService {
  SessionAudioService._();

  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playLogin() async {
    await _play('start.mp3');
  }

  static Future<void> playLogout() async {
    await _play('start.mp3');
  }

  static Future<void> _play(String fileName) async {
    try {
      await _player.play(AssetSource('sounds/$fileName'));
    } catch (_) {}
  }
}
