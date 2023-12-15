import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:imusic/audio_background.dart';

class PlayInfoWidget extends StatelessWidget {
  final String name;
  final String author;
  final String img;
  final Function tapAction;

  const PlayInfoWidget(
      {super.key,
      required this.name,
      required this.author,
      required this.img,
      required this.tapAction});

  @override
  Widget build(BuildContext context) {
    return Positioned(
        bottom: 34,
        right: 10,
        left: 10,
        child: Container(
            decoration: BoxDecoration(
              color: const Color(0x11EBEFFF).withOpacity(1.0),
              borderRadius: BorderRadius.circular(27.0),
            ),
            // width: 100,
            height: 54,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => tapAction,
                  child: RotatingWidget(img: img),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                      onTap: () {
                        tapAction();
                      },
                      child: Container(
                          color: Colors.transparent,
                          alignment: Alignment.centerLeft,
                          height: 54,
                          child: Text(
                            '$name - $author',
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                overflow: TextOverflow.ellipsis),
                          ))),
                ),
                IconButton(
                    onPressed: () {
                      MyAudioHandler().playOrPause();
                    },
                    icon: ValueListenableBuilder(
                        valueListenable: MyAudioHandler().playingNotifier,
                        builder: (context, value, child) {
                          return Image.asset(
                              value
                                  ? 'assets/images/tab_center_pause@2x.png'
                                  : 'assets/images/tab_center_play@2x.png',
                              width: 20,
                              height: 20);
                        })),
                IconButton(
                    onPressed: () {
                      MyAudioHandler().skipToNext();
                    },
                    icon: Image.asset('assets/images/tab_center_next@2x.png',
                        width: 20, height: 20)),
                const SizedBox(width: 10),
              ],
            )));
  }
}

class RotatingWidget extends StatefulWidget {
  final String img;
  const RotatingWidget({super.key, required this.img});

  @override
  State<StatefulWidget> createState() => _RotatingWidgetState();
}

class _RotatingWidgetState extends State<RotatingWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 10), vsync: this)
          ..repeat(period: const Duration(seconds: 10));
    // 设置动画初始值为停止状态
    _controller.value = 0;
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);

    MyAudioHandler().playingNotifier.addListener(() {
      MyAudioHandler().playingNotifier.value
          ? _controller.forward()
          : _controller.stop();
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 回到前台播放
      if (MyAudioHandler().playingNotifier.value) {
        _controller.forward();
      }
    } else {
      // 退到后台停止播放
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
        turns: _animation,
        child: ClipOval(
            child: CachedNetworkImage(
                width: 54,
                height: 54,
                imageUrl: widget.img,
                placeholder: (context, url) {
                  return Image.asset(
                      'assets/images/svg_kg_playpage__album_default_01@3x.png');
                })));
  }
}
