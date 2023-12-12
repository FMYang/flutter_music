import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:imusic/app_bar.dart';
import 'package:imusic/audio_background.dart';
import 'package:imusic/custom_list_tile.dart';
import 'package:imusic/play_info.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:imusic/song.dart';

// 程序入口函数main()
void main() async {
  // runApp(const ViewWidget());
  await initAudioService();
  runApp(const ListApp());
}

// 2.列表组件
class ListApp extends StatelessWidget {
  const ListApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "List",
      theme: ThemeData(
        colorScheme: const ColorScheme.light(primary: Colors.white),
        // useMaterial3: true,
      ),
      home: const Scaffold(
        backgroundColor: Colors.white,
        appBar: SharedAppBar(titleText: "Music"),
        body: ListWidget(),
      ),
    );
  }
}

class ListWidget extends StatefulWidget {
  const ListWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ListWidgeState();
}

class _ListWidgeState extends State<ListWidget> {
  List<Song> songData = [];

  @override
  void initState() {
    super.initState();
    loadJsonFile();
  }

  // 加载本地json数据
  Future<void> loadJsonFile() async {
    String jsonString = await rootBundle.loadString('assets/jsons/周杰伦.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      songData = jsonData.map((item) => Song.fromJson(item)).toList();
      // MusicPlayer().songList = songData;
    });
  }

  // 播放歌曲
  void playSong(int index) {
    MyAudioHandler().skipToQueueItem(index);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: MyAudioHandler().indexNotifier,
        builder: (context, value, child) {
          return Stack(
            children: [
              Container(
                color: Colors.grey.withOpacity(0.2),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  margin: const EdgeInsets.only(
                      left: 20, right: 20, bottom: 20, top: 10),
                  child: ListView.builder(
                      itemCount: songData.length,
                      itemBuilder: (context, index) {
                        Song song = songData[index];
                        return GestureDetector(
                            onTap: () {
                              playSong(index);
                              // Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //         builder: (context) =>
                              //             ListDetail(index: index.toString()),
                              //         fullscreenDialog: true));
                            },
                            child: CustomListTile(
                              img: song.icon,
                              name: song.songName,
                              author: song.authorName,
                              isSelected: (index == value),
                            ));
                      }),
                ),
              ),
              if (value >= 0)
                PlayInfoWidget(
                    name: songData[value].authorName,
                    author: songData[value].songName,
                    img: songData[value].icon)
            ],
          );
        });
  }
}
