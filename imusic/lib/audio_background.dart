import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imusic/lrc_parse.dart';
import 'package:imusic/song.dart';
import 'package:just_audio/just_audio.dart';

// 初始化AudioService
Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.yfm.imusic',
      androidNotificationChannelName: 'Audio Service',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playList =
      ConcatenatingAudioSource(children: []);
  // 歌曲列表
  List<Song> songData = [];
  // 当前播放的歌曲的歌词列表
  List<LRCLine> lrclist = [];
  bool sliderChanging = false;

  // 监听播放的下标，为-1表示没有播放歌曲
  ValueNotifier<int> indexNotifier = ValueNotifier(-1);
  // 监听是否播放中
  ValueNotifier<bool> playingNotifier = ValueNotifier(false);
  // 监听歌词列表状态
  ValueNotifier<List<LRCLine>> lrcListNotifier = ValueNotifier([]);
  // 监听当前播放的歌词所在的行
  ValueNotifier<int> lrcLineNotifier = ValueNotifier(0);
  //
  ValueNotifier<String> durationNotifier = ValueNotifier('00:00');
  //
  ValueNotifier<String> playTimeNotifier = ValueNotifier('00:00');
  //
  ValueNotifier<double> progressNotifier = ValueNotifier(0);
  //
  int songDuration = 0;

  // 单例
  MyAudioHandler._internal() {
    loadPlayList();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenToPlaybackState();
    _listenForCurrentSongIndexChanges();
    _listenForDurationChanges();
  }

  // 获取单例实例的方法
  factory MyAudioHandler() => _instance;

  // 单例实例
  static final MyAudioHandler _instance = MyAudioHandler._internal();

  // 加载本地json数据
  Future<void> loadPlayList() async {
    String jsonString = await rootBundle.loadString('assets/jsons/top500.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    songData = jsonData.map((item) => Song.fromJson(item)).toList();
    List<MediaItem> mediaItems = songData.map((e) => e.toMediaItem()).toList();
    List<AudioSource> sources = mediaItems
        .map((e) => AudioSource.asset('assets/audio/${e.title}.mp3', tag: e))
        .toList();
    _playList.addAll(sources);
    _player.setAudioSource(_playList);

    // notify system
    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
  }

  // 监听播放事件
  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[_player.loopMode]!,
        shuffleMode: (_player.shuffleModeEnabled)
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  // 监听播放状态
  void _listenToPlaybackState() {
    playbackState.listen((playbackState) {
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;
      playingNotifier.value = isPlaying;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
      } else if (!isPlaying) {
      } else if (processingState != AudioProcessingState.completed) {
      } else {}
    });
  }

  // 监听播放歌曲下标
  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices!.indexOf(index);
      }
      indexNotifier.value = index;
      mediaItem.add(playlist[index]);

      Song song = songData[index];
      songDuration = song.timelength ~/ 1000;
      lrclist = LRCParse.parse(song.lrc);
      lrcListNotifier.value = lrclist;
      durationNotifier.value = LRCParse.formatDuration(song.timelength / 1000);
    });
  }

  // 监听时间
  void _listenForDurationChanges() {
    _player.positionStream.listen((position) {
      if (lrclist.isEmpty) return;
      int index = findCurPlayLrcIndex(position.inSeconds);
      if (lrcLineNotifier.value != index) {
        lrcLineNotifier.value = index;
      }
      double playTime = position.inSeconds.toDouble();
      playTimeNotifier.value = LRCParse.formatDuration(playTime);
      double progress = playTime / songDuration;
      if (progress >= 1.0) {
        progress = 1.0;
      }
      if (!sliderChanging) {
        progressNotifier.value = progress;
      }
    });
  }

  // 找到歌词所在的行
  int findCurPlayLrcIndex(int time) {
    int index = 0;
    for (int i = 0; i < lrclist.length; i++) {
      LRCLine line = lrclist[i];
      int lineTime = line.time.inSeconds;
      if (time <= lineTime) {
        if (i > 0) {
          index = i - 1;
        }
        break;
      } else {
        index = lrclist.length - 1;
      }
    }
    return index;
  }

  // 播放暂停
  Future<void> playOrPause() async {
    if (_player.playing) {
      pause();
    } else {
      play();
    }
  }

  // 播放指定的item
  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    if (_player.shuffleModeEnabled) {
      index = _player.shuffleIndices![index];
    }
    indexNotifier.value = index;
    _player.seek(Duration.zero, index: index);
    play();
  }

  // 播放
  @override
  Future<void> play() => _player.play();

  // 暂停
  @override
  Future<void> pause() => _player.pause();

  // 停止
  @override
  Future<void> stop() => _player.stop();

  // 快进/快退
  @override
  Future<void> seek(Duration position) => _player.seek(position);

  // 下一首
  @override
  Future<void> skipToNext() => _player.seekToNext();

  // 上一首
  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();
}
