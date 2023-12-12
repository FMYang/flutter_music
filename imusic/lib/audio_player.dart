// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:imusic/song.dart';

// // 单例
// class MusicPlayer {
//   // 播放器
//   late AudioPlayer player;

//   // 当前播放的item下标
//   int index = -1;

//   // 当前播放的歌曲信息
//   Song? playsong;

//   // 播放列表
//   List<Song> songList = [];

//   // 监听
//   ValueNotifier<int> indexNotifier = ValueNotifier(0);
//   ValueNotifier<bool> playingNotifier = ValueNotifier(false);

//   MusicPlayer._internal() {
//     player = AudioPlayer();

//     // 下标监听方法
//     indexNotifier.addListener(() {
//       index = indexNotifier.value;
//       playsong = songList[index];
//       play();
//     });

//     // 监听播放状态
//     player.onPlayerStateChanged.listen((event) {
//       playingNotifier.value = (event == PlayerState.playing);
//     });
//   }

//   // 单例
  // factory MusicPlayer() => _instance;

  // static final MusicPlayer _instance = MusicPlayer._internal();

//   Future<void> play() async {
//     String name = playsong?.songName ?? '';
//     String path = '';
//     if (name.isNotEmpty) {
//       // AudioPlayer库加载资源时自动在路径上加了'assets/'前缀，所以注意这里的路径不要在加assets了
//       path = 'audio/$name.mp3';
//     }
//     if (path.isNotEmpty) {
//       await player.play(AssetSource(path));
//     }
//   }

//   Future<void> pause() async {
//     await player.pause();
//   }

//   Future<void> playOrPause() async {
//     if (playingNotifier.value) {
//       pause();
//     } else {
//       play();
//     }
//   }

//   Future<void> playNext() async {
//     if (index < songList.length) {
//       indexNotifier.value += 1;
//     }
//   }
// }
