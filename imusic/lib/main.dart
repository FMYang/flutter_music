import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:imusic/app_bar.dart';
import 'package:imusic/audio_background.dart';
import 'package:imusic/custom_list_tile.dart';
import 'package:imusic/list_detail.dart';
import 'package:imusic/play_info.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:imusic/song.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

// 程序入口函数main()
void main() async {
  // runApp(const ViewWidget());
  await initAudioService();
  runApp(const MusicApp());
}

// 2.列表组件
class MusicApp extends StatelessWidget {
  const MusicApp({Key? key}) : super(key: key);

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
  final ItemScrollController _controller = ItemScrollController();

  @override
  void initState() {
    super.initState();
    loadJsonFile();

    MyAudioHandler().indexNotifier.addListener(() {
      scrollToIndex();
    });
  }

  void scrollToIndex() {
    int index = MyAudioHandler().indexNotifier.value;
    _controller.jumpTo(index: index, alignment: 0.4);
    // if (!_controller.position.hasContentDimensions) return;
    // int index = MyAudioHandler().indexNotifier.value;
    // if (index < 5) {
    //   _controller.jumpTo(0);
    //   return;
    // }
    // if (index > songData.length - 5) {
    //   _controller.jumpTo(_controller.position.maxScrollExtent);
    //   return;
    // }
    // final double itemHeight =
    //     _controller.position.maxScrollExtent / songData.length;
    // final double offset = itemHeight * index;
    // _controller.jumpTo(offset);
  }

  // 加载本地json数据
  Future<void> loadJsonFile() async {
    String jsonString = await rootBundle.loadString('assets/jsons/top500.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      songData = jsonData.map((item) => Song.fromJson(item)).toList();
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
          if (songData.isEmpty) return Container();
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
                  child: ScrollablePositionedList.builder(
                      // 使用三方库（scrollable_positioned_list）的ScrollablePositionedList，跳到指定位置，ListView的不准
                      itemScrollController: _controller,
                      itemCount: songData.length,
                      itemBuilder: (context, index) {
                        Song song = songData[index];
                        return GestureDetector(
                            onTap: () {
                              playSong(index);
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
              PlayInfoWidget(
                  name: songData[value].authorName,
                  author: songData[value].songName,
                  img: songData[value].icon,
                  tapAction: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ListDetail(),
                            fullscreenDialog: true));
                  })
            ],
          );
        });
  }
}
