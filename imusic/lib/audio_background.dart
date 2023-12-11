import 'package:audio_service/audio_service.dart';
import 'package:imusic/audio_player.dart';

late AudioHandler audioHandler;

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  MyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    List<MediaItem> items =
        MusicPlayer().songList.map((e) => e.toMediaItem()).toList();
    queue.add(items);
    setSong();
  }

  Future<void> setSong() async {
    if (MusicPlayer().playsong != null) {
      mediaItem.add(MusicPlayer().playsong!.toMediaItem());
    }
  }

  @override
  Future<void> play() async {
    MusicPlayer().play();
    setSong();
  }

  @override
  Future<void> pause() async {
    MusicPlayer().pause();
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> skipToQueueItem(int index) async {}
}
