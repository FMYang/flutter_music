import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:imusic/app_bar.dart';
import 'package:imusic/audio_background.dart';
import 'package:imusic/custom_list_tile.dart';
import 'package:imusic/lrc_page.dart';
import 'package:imusic/play_info_page.dart';
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
class MusicApp extends StatefulWidget {
  const MusicApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp>
    with SingleTickerProviderStateMixin {
  // 通过引用子部件的全局键来实现从父部件触发调用子部件方法
  final GlobalKey<_ListWidgeState> _childKey = GlobalKey<_ListWidgeState>();

  // final List<String> sourceList = ['top500', '许嵩'];

  bool _isMenuOpen = false;
  late AnimationController _animatedController;
  late Animation<Offset> _sliderAnimation;

  void onStatusBarTap() {
    _childKey.currentState?.scrollToTop();
  }

  @override
  void initState() {
    super.initState();

    _animatedController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    _sliderAnimation = Tween<Offset>(
            begin: Offset(_isMenuOpen ? 0.0 : -1.0, 0.0),
            end: Offset(_isMenuOpen ? -1.0 : 0.0, 0.0))
        .animate(CurvedAnimation(
      parent: _animatedController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animatedController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
    if (_isMenuOpen) {
      _animatedController.forward();
    } else {
      _animatedController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "List",
      theme: ThemeData(
        colorScheme: const ColorScheme.light(primary: Colors.white),
        // useMaterial3: true,
      ),
      home: Stack(children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: const SharedAppBar(
            titleText: "Music",
          ),
          body: ListWidget(key: _childKey),
        ),
        Positioned(
            top: kToolbarHeight + 10,
            height: 40,
            child: Row(children: [
              const SizedBox(width: 25),
              GestureDetector(
                onTap: () => _toggleMenu(),
                child: Container(
                    alignment: Alignment.centerLeft,
                    width: 100,
                    height: 40,
                    color: Colors.transparent,
                    child: const Text('top500',
                        style: TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.black))),
              ),
            ])),
        // Status bar tap override
        // listview添加controll后，scrollToTop失效（ios，macos），这里添加自定义事件自己实现
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).padding.top,
          child: GestureDetector(
            excludeFromSemantics: true,
            onTap: onStatusBarTap,
          ),
        ),
        Visibility(
          visible: _isMenuOpen,
          child: AnimatedOpacity(
              opacity: _isMenuOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 100),
              child: GestureDetector(
                  onTap: () {
                    _toggleMenu();
                  },
                  child: Container(color: Colors.black45))),
        ),
        Visibility(
            visible: _isMenuOpen,
            child: SlideTransition(
                position: _sliderAnimation,
                child: Container(
                  width: 200,
                  height: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.only(
                      left: 5, top: 40, bottom: 40, right: 5),
                  child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return const SizedBox(
                            height: 50,
                            child: Text('top500',
                                style: TextStyle(
                                    decoration: TextDecoration.none,
                                    fontSize: 18,
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal)));
                      }),
                ))),
      ]),
    );
  }
}

//
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

  void scrollToTop() {
    _controller.scrollTo(index: 0, duration: const Duration(milliseconds: 250));
  }

  void scrollToIndex() {
    int index = MyAudioHandler().indexNotifier.value;
    _controller.jumpTo(index: index, alignment: 0.4);
  }

  // 加载本地json数据
  Future<void> loadJsonFile() async {
    List<Song> data = await MyAudioHandler().loadJsonData('top500');
    setState(() {
      songData = data;
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
