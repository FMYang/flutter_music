import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imusic/lrc_parse.dart';
import 'package:imusic/song.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// 播放模式
enum MyLoopMode { list, one, random }

enum MyClockMode { off, time15, time30, time60 }

extension MyClockModeExtesion on MyClockMode {
  String titleText() {
    switch (this) {
      case MyClockMode.off:
        return "assets/images/kg_ic_player_menu_music_clock_normal@3x.png";
      case MyClockMode.time15:
        return "15:00";
      case MyClockMode.time30:
        return "30:00";
      case MyClockMode.time60:
        return "60:00";
    }
  }

  int seconds() {
    switch (this) {
      case MyClockMode.off:
        return 0;
      case MyClockMode.time15:
        return 15 * 60;
      case MyClockMode.time30:
        return 30 * 60;
      case MyClockMode.time60:
        return 59 * 60 + 59;
    }
  }
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playList =
      ConcatenatingAudioSource(children: []);
  // 歌曲列表
  List<Song> songData = [];
  // 当前播放的歌曲的歌词列表
  List<LRCLine> lrclist = [];
  // slider滑动中
  bool sliderChanging = false;
  // 播放模式
  MyLoopMode loopMode = MyLoopMode.list;

  // 监听播放的下标
  ValueNotifier<int> indexNotifier = ValueNotifier(0);
  // 监听是否播放中
  ValueNotifier<bool> playingNotifier = ValueNotifier(false);
  // 监听歌词列表状态
  ValueNotifier<List<LRCLine>> lrcListNotifier = ValueNotifier([]);
  // 监听当前播放的歌词所在的行
  ValueNotifier<int> lrcLineNotifier = ValueNotifier(0);
  // 当前歌曲的时长
  ValueNotifier<String> durationNotifier = ValueNotifier('00:00');
  // 当前歌曲的播放时长
  ValueNotifier<String> playTimeNotifier = ValueNotifier('00:00');
  // 当前歌曲的播放进度
  ValueNotifier<double> progressNotifier = ValueNotifier(0);
  // 循环模式
  ValueNotifier<MyLoopMode> loopModeNotifier = ValueNotifier(MyLoopMode.list);
  // 当前歌曲的时长
  int songDuration = 0;
  // 定时关闭
  ValueNotifier<MyClockMode> clockModeNotifer = ValueNotifier(MyClockMode.off);
  // 计时
  int clockTime = 0;
  // 倒计时的值
  ValueNotifier<int> timerNotifer = ValueNotifier(0);
  // 定时器
  Timer? timer;

  // 单例
  MyAudioHandler._internal() {
    Future.delayed(Duration.zero, () async {
      await loadPlayList('top500');
      _notifyAudioHandlerAboutPlaybackEvents();
      _listenToPlaybackState();
      _listenForCurrentSongIndexChanges();
      _listenForDurationChanges();

      setLoopMode(await loadPlayMode());
    });
  }

  // 获取单例实例的方法
  factory MyAudioHandler() => _instance;

  // 单例实例
  static final MyAudioHandler _instance = MyAudioHandler._internal();

  // 加载播放列表
  Future<void> loadPlayList(String jsonFileName) async {
    _playList.clear();
    songData = await loadJsonData(jsonFileName);
    List<MediaItem> mediaItems = songData.map((e) => e.toMediaItem()).toList();
    List<AudioSource> sources = mediaItems
        .map((e) => AudioSource.asset('assets/audio/${e.title}.mp3', tag: e))
        .toList();
    _playList.addAll(sources);
    _player.setAudioSource(_playList);

    // notify system
    queue.value.clear();
    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);

    // 资源reload的之后更新下标
    indexDidChanged(0);
  }

  // 加载本地json数据
  Future<List<Song>> loadJsonData(String jsonFileName) async {
    String jsonString =
        await rootBundle.loadString('assets/jsons/$jsonFileName.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    List<Song> data = jsonData.map((item) => Song.fromJson(item)).toList();
    data = await filterSongData(data);
    return data;
  }

  // 过滤数据
  Future<List<Song>> filterSongData(List<Song> songData) async {
    List<Song> filteredList = [];
    for (Song song in songData) {
      String fileName = song.songName;
      String path = 'assets/audio/$fileName.mp3';
      bool exist = await fileExist(path);
      if (exist) {
        filteredList.add(song);
      }
    }
    return filteredList;
  }

  // 判断资源文件是否存在
  Future<bool> fileExist(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (error) {
      return false;
    }
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
      } else if (processingState == AudioProcessingState.completed) {
      } else {}
    });
  }

  // 监听播放歌曲下标
  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) async {
      indexDidChanged(index ?? 0);
    });
  }

  void indexDidChanged(int index) async {
    final playlist = queue.value;
    if (playlist.isEmpty) return;
    if (index > playlist.length - 1) return;
    if (_player.shuffleModeEnabled) {
      index = _player.shuffleIndices!.indexOf(index);
    }
    indexNotifier.value = index;
    Song song = songData[index];
    songDuration = song.timelength ~/ 1000;
    durationNotifier.value = LRCParse.formatDuration(song.timelength / 1000);
    lrclist = await LRCParse.parse(song.lrc);
    lrcListNotifier.value = lrclist;
    mediaItem.add(playlist[index]);
  }

  // 监听时间
  void _listenForDurationChanges() {
    _player.positionStream.listen((position) {
      if (lrclist.isEmpty) return;
      int index = findCurPlayLrcIndex(position.inSeconds);

      if (lrcLineNotifier.value != index) {
        updateDisplayMediaItem(index);
      }

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
      if (playTime >= (songDuration - 1)) {
        skipToNext();
      }
    });
  }

  // 控制台显示歌词信息
  void updateDisplayMediaItem(int index) {
    String lrcText = lrclist[index].text;
    Song song = songData[indexNotifier.value];
    MediaItem item = MediaItem(
        id: song.albumId,
        album: song.songName,
        artist: '${song.authorName} - ${song.songName}',
        title: lrcText,
        duration: Duration(
            minutes: (((song.timelength / 1000.0) / 60 % 60).toInt()),
            seconds: (((song.timelength / 1000.0) % 60).toInt())),
        artUri: Uri.parse(song.icon));
    mediaItem.add(item);
  }

  // 自动播放事件（调用skipToNext报错）
  // 随机播放这里实现不了，就放在duration还剩1s的时候播放一下一曲实现随机播放吧
  // void _listenPositionContinueChanges() {
  //   _player.positionDiscontinuityStream.listen((event) {
  //     print('auto play ${event.reason}');
  //     if (event.reason == PositionDiscontinuityReason.autoAdvance) {
  //       // skipToNext();
  //     }
  //   });
  // }

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
    try {
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices![index];
      }
      indexNotifier.value = index;
      _player.seek(Duration.zero, index: index);
      play();
    } finally {}
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
  Future<void> skipToNext() async {
    if (loopMode == MyLoopMode.random) {
      skipToQueueItem(randomValue());
      return;
    }
    _player.seekToNext();
  }

  // 上一首
  @override
  Future<void> skipToPrevious() async {
    if (loopMode == MyLoopMode.random) {
      skipToQueueItem(randomValue());
      return;
    }
    _player.seekToPrevious();
  }

  // 随机值
  int randomValue() {
    // 伪随机数，可能产生相同的随机序列，待优化
    var random = Random();
    int index = random.nextInt(songData.length);
    return index;
  }

  // 设置播放模式
  Future<void> setLoopMode(MyLoopMode loopMode) async {
    switch (loopMode) {
      case MyLoopMode.list:
        _player.setLoopMode(LoopMode.all);
      case MyLoopMode.one:
        _player.setLoopMode(LoopMode.one);
      case MyLoopMode.random:
        _player.setLoopMode(LoopMode.off);
      default:
        break;
    }
    this.loopMode = loopMode;
    loopModeNotifier.value = loopMode;
  }

  // 存储播放模式
  Future<void> savePlayMode(MyLoopMode loopMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('playMode', loopMode.toString());
  }

  // 存储播放模式
  Future<MyLoopMode> loadPlayMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? stringValue = prefs.getString('playMode');
    if (stringValue != null) {
      return MyLoopMode.values.firstWhere((e) => e.toString() == stringValue);
    }
    return MyLoopMode.list;
  }

  // 定时模式改变
  void clockModeChanged() {
    MyClockMode clockMode = clockModeNotifer.value;
    if (clockMode == MyClockMode.off) {
      clockMode = MyClockMode.time15;
    } else if (clockMode == MyClockMode.time15) {
      clockMode = MyClockMode.time30;
    } else if (clockMode == MyClockMode.time30) {
      clockMode = MyClockMode.time60;
    } else {
      clockMode = MyClockMode.off;
    }
    clockTime = clockMode.seconds();
    clockModeNotifer.value = clockMode;
    if (clockMode == MyClockMode.off) {
      timer?.cancel();
    } else {
      startTimer();
    }
  }

  // 倒计时退出
  void startTimer() {
    timerNotifer.value = clockModeNotifer.value.seconds();
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      clockTime -= 1;
      timerNotifer.value = clockTime;

      if (clockTime <= 0) {
        timer.cancel();
        exit(0);
        // SystemChannels.platform.invokeMapMethod('SystemNavigator.pop');
      }
    });
  }
}
