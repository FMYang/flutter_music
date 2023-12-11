import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:imusic/app_bar.dart';
import 'package:imusic/audio_background.dart';
import 'package:imusic/audio_player.dart';
import 'package:imusic/custom_list_tile.dart';
import 'package:imusic/play_info.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:imusic/song.dart';

// 程序入口函数main()
Future<void> main() async {
  // runApp(const ViewWidget());
  audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
          androidNotificationChannelId: '',
          androidNotificationChannelName: ''));

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
      MusicPlayer().songList = songData;
    });
  }

  // 播放歌曲
  void playSong(int index) {
    MusicPlayer().indexNotifier.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: MusicPlayer().indexNotifier,
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
                              isSelected: (index == MusicPlayer().index),
                            ));
                      }),
                ),
              ),
              if (MusicPlayer().index >= 0)
                PlayInfoWidget(
                    name: MusicPlayer().playsong?.authorName ?? '',
                    author: MusicPlayer().playsong?.songName ?? '')
            ],
          );
        });
  }
}

// 1.基础视图组件
// class ViewWidget extends StatefulWidget {
//   const ViewWidget({super.key});

//   @override
//   State<StatefulWidget> createState() => _ViewState();
// }

// class _ViewState extends State<ViewWidget> {
//   String time = "";

//   Timer? _timer;

//   @override
//   void initState() {
//     super.initState();
//     _startTimer();
//   }

//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         DateTime currentTime = DateTime.now();
//         String formattedTime =
//             "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}:${currentTime.second.toString().padLeft(2, '0')}";
//         time = formattedTime;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.white,
//       child: Center(
//         child: Text(time,
//             textAlign: TextAlign.center,
//             textDirection: TextDirection.ltr,
//             style: const TextStyle(color: Colors.red, fontSize: 60)),
//       ),
//     );
//   }
// }

// // 创建一个 MyApp 类，继承自 StatelessWidget
// // 1.MyApp负责并返回创建一个MaterialApp实例，代表整个应用程序，是程序的根组件
// // 2.MyApp 类没有状态（Stateless），它的 build() 方法只负责构建静态的 Widget 树
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // 创建了一个 MaterialApp，设置了应用程序的标题和主题样式
//     return MaterialApp(
//       title: 'iMusic', // app名
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MyHomePage(title: 'iMusic'), // 首页，参数为首页标题
//     );
//   }
// }

// // 创建一个 MyHomePage 类，继承自 StatefulWidget
// // MyHomePage代表应用的首页，它包含一个可变状态，MyHomePage 类负责创建并返回一个 State 对象
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// // 创建一个 _MyHomePageState 类，继承自 State<MyHomePage>，用于管理 MyHomePage 的状态
// // _MyHomePageState 类负责构建 MyHomePage 的界面
// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   // 按钮点击事件
//   void _incrementCounter() {
//     // 通过调用 setState() 来更新状态 _counter，从而触发界面的重新构建
//     setState(() {
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // 使用 Scaffold 组件作为页面的基本布局
//     // 包含了一个 AppBar、一个居中的列（Column）和一个悬浮按钮（FloatingActionButton）
//     return Scaffold(
//       // AppBar 是应用程序的顶部导航栏，其中的标题文本来自于 widget.title
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//       ),
//       // body 是一个居中的列，包含了一个静态文本和一个显示计数器的文本
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       // floatingActionButton 是一个悬浮按钮，点击它会调用 _incrementCounter 方法
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
