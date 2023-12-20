import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imusic/audio_background.dart';
import 'package:imusic/lrc_parse.dart';
// import 'app_bar.dart';

class ListDetail extends StatelessWidget {
  const ListDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        // appBar: const SharedAppBar(titleText: 'Detail'),
        body: ContentWidget());
  }
}

class ContentWidget extends StatefulWidget {
  const ContentWidget({super.key});

  @override
  State<StatefulWidget> createState() => _ContentWidgetState();
}

class _ContentWidgetState extends State<ContentWidget> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Stack(
        children: [
          Positioned.fill(
              child: Image.asset('assets/images/bg_playview_iPhoneX@2x.jpg',
                  fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black38)),
          Positioned(
              child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: const Column(children: [
                    SizedBox(height: 100),
                    // 歌词列表
                    ListWidget(),
                    // 底部widget
                    BottomWidget(),
                  ]))),
        ],
      ),
    );
  }
}

class ListWidget extends StatefulWidget {
  const ListWidget({super.key});

  @override
  State<StatefulWidget> createState() => _ListWidgetState();
}

class _ListWidgetState extends State<ListWidget> {
  bool scrolling = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      scrollToIndex(MyAudioHandler().lrcLineNotifier.value, false);
    });

    MyAudioHandler().lrcLineNotifier.addListener(() {
      int index = MyAudioHandler().lrcLineNotifier.value;
      scrollToIndex(index, true);
    });
  }

  @override
  void dispose() {
    MyAudioHandler().lrcLineNotifier.removeListener(() {
      int index = MyAudioHandler().lrcLineNotifier.value;
      scrollToIndex(index, true);
    });
    super.dispose();
  }

  void scrollToIndex(int index, bool animated) {
    if (scrolling) return;
    if (!_scrollController.hasClients) return;
    if (!_scrollController.position.hasContentDimensions) return;
    if (index < 5) {
      _scrollController.jumpTo(0);
      return;
    }
    if (index > MyAudioHandler().lrclist.length - 6) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      return;
    }
    if (!animated) {
      _scrollController.jumpTo(
        (index * 50 - 200).toDouble(), // 计算滚动的偏移量
      );
    } else {
      _scrollController.animateTo(
        index * 50 - 200, // 计算滚动的偏移量
        duration: const Duration(milliseconds: 250), // 滚动动画的持续时间
        curve: Curves.easeInOut, // 滚动动画的曲线
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            scrolling = true;
          } else if (notification is ScrollEndNotification) {
            scrolling = false;
          }
          return true;
        },
        child: Expanded(
          child: ValueListenableBuilder(
              valueListenable: MyAudioHandler().lrcListNotifier,
              builder: (context, value, child) {
                return ListView.separated(
                    padding: const EdgeInsets.only(left: 40, right: 40),
                    controller: _scrollController,
                    separatorBuilder: (context, index) => Container(),
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      String lrcText = value[index].text;
                      return ValueListenableBuilder(
                          valueListenable: MyAudioHandler().lrcLineNotifier,
                          builder: (context, innerValue, child) {
                            // scrollToIndex(innerValue, true);
                            return Container(
                                height: 50,
                                alignment: Alignment.center,
                                child: Text(lrcText,
                                    textAlign: TextAlign.center,
                                    style: (innerValue == index)
                                        ? const TextStyle(
                                            decoration:
                                                // 去掉文本下划线
                                                TextDecoration.none,
                                            fontSize: 20,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.white)
                                        : const TextStyle(
                                            decoration: TextDecoration.none,
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.white70)));
                          });
                    });
              }),
        ));
  }
}

// 底部widget
class BottomWidget extends StatefulWidget {
  const BottomWidget({super.key});

  @override
  State<StatefulWidget> createState() => _BottomWidget();
}

class _BottomWidget extends State<BottomWidget> {
  double _currentSliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    MyAudioHandler().progressNotifier.addListener(_handleSliderValueChange);
    setState(() {
      _currentSliderValue = MyAudioHandler().progressNotifier.value;
    });
  }

  @override
  void dispose() {
    MyAudioHandler().progressNotifier.removeListener(_handleSliderValueChange);
    super.dispose();
  }

  // 监听播放进度的回调函数
  void _handleSliderValueChange() {
    double newValue = MyAudioHandler().progressNotifier.value;
    setState(() {
      _currentSliderValue = newValue;
    });
  }

  // 滑条滑动时
  void onSliderChanged(value) {
    setState(() {
      _currentSliderValue = value;
    });
  }

  // 结束滑动
  void onSliderChangedEnd(double value) {
    int second = (MyAudioHandler().songDuration * value).toInt();
    Duration duration = Duration(seconds: second);
    MyAudioHandler().seek(duration);
  }

  void setLoopMode() {
    if (MyAudioHandler().loopMode == MyLoopMode.list) {
      MyAudioHandler().loopMode = MyLoopMode.one;
    } else if (MyAudioHandler().loopMode == MyLoopMode.one) {
      MyAudioHandler().loopMode = MyLoopMode.random;
    } else {
      MyAudioHandler().loopMode = MyLoopMode.list;
    }
    MyAudioHandler().loopModeNotifier.value = MyAudioHandler().loopMode;
    MyAudioHandler().setLoopMode(MyAudioHandler().loopMode);
    MyAudioHandler().savePlayMode(MyAudioHandler().loopMode);
  }

  String modeImageName(MyLoopMode value) {
    switch (value) {
      case MyLoopMode.list:
        return 'assets/images/svg_kg_common_ic_player_mode_all_default@3x.png';
      case MyLoopMode.one:
        return 'assets/images/svg_kg_common_ic_player_mode_single_default@3x.png';
      case MyLoopMode.random:
        return 'assets/images/svg_kg_common_ic_player_mode_random_default@3x.png';
    }
  }

  void _clockModeChanged() {
    MyAudioHandler().clockModeChanged();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 200,
        child: Column(children: [
          const SizedBox(height: 30),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(width: 30),
            ValueListenableBuilder(
                valueListenable: MyAudioHandler().playTimeNotifier,
                builder: (context, value, child) {
                  return SizedBox(
                      width: 40,
                      child: Text(value,
                          style: const TextStyle(color: Colors.white70)));
                }),
            const SizedBox(width: 0),
            Expanded(
              child: SizedBox(
                width: 230,
                height: 30,
                child: SliderTheme(
                  data: SliderThemeData(
                      trackHeight: 2,
                      trackShape: const CustomSliderTrackShape(),
                      thumbShape: CustomSliderThumbShape(
                          thumbHeight: 14, thumbRadius: 7)),
                  child: Slider(
                    value: _currentSliderValue,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (double value) {
                      onSliderChanged(value);
                    },
                    onChangeStart: (value) {
                      MyAudioHandler().sliderChanging = true;
                    },
                    onChangeEnd: (value) {
                      MyAudioHandler().sliderChanging = false;
                      onSliderChangedEnd(value);
                    },
                  ),
                ),
                // }),
              ),
            ),
            const SizedBox(width: 0),
            ValueListenableBuilder(
                valueListenable: MyAudioHandler().durationNotifier,
                builder: (context, value, child) {
                  return SizedBox(
                      width: 40,
                      child: Text(value,
                          style: const TextStyle(color: Colors.white70)));
                }),
            const SizedBox(width: 30),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                onPressed: () => setLoopMode(),
                icon: ValueListenableBuilder(
                    valueListenable: MyAudioHandler().loopModeNotifier,
                    builder: (context, value, child) {
                      return Image.asset(
                        modeImageName(value),
                        width: 25,
                        height: 25,
                      );
                    })),
            const SizedBox(width: 20),
            IconButton(
                onPressed: () => MyAudioHandler().skipToPrevious(),
                icon: Image.asset(
                  'assets/images/ic_player_btn_last_newMode@3x.png',
                  width: 25,
                  height: 25,
                )),
            const SizedBox(width: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(40), // 设置圆角的大小
              ),
              width: 80,
              height: 80,
              child: IconButton(
                  onPressed: () => MyAudioHandler().playOrPause(),
                  icon: ValueListenableBuilder(
                      valueListenable: MyAudioHandler().playingNotifier,
                      builder: (context, value, child) {
                        return value
                            ? Image.asset(
                                'assets/images/playview_pause@2x.png',
                                width: 25,
                                height: 25,
                              )
                            : Image.asset(
                                'assets/images/playview_play@2x.png',
                                width: 25,
                                height: 25,
                              );
                      })),
            ),
            const SizedBox(width: 20),
            IconButton(
                onPressed: () => MyAudioHandler().skipToNext(),
                icon: Image.asset(
                  'assets/images/ic_player_btn_next_newMode@3x.png',
                  width: 25,
                  height: 25,
                )),
            const SizedBox(width: 20),
            ValueListenableBuilder(
                valueListenable: MyAudioHandler().clockModeNotifer,
                builder: (context, value, child) {
                  if (value == MyClockMode.off) {
                    return IconButton(
                        onPressed: () => _clockModeChanged(),
                        icon: Image.asset(
                          'assets/images/kg_ic_player_menu_music_clock_normal@3x.png',
                          width: 25,
                          height: 25,
                        ));
                  } else {
                    return GestureDetector(
                        onTap: () => _clockModeChanged(),
                        child: ValueListenableBuilder(
                            valueListenable: MyAudioHandler().timerNotifer,
                            builder: ((context, value, child) {
                              return SizedBox(
                                  height: 54,
                                  child: Center(
                                      child: Text(
                                          LRCParse.formatDuration(
                                              value.toDouble()),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white))));
                            })));
                  }
                }),
          ])
        ]));
  }
}

// 自定义slider的TrackShape
// RoundedRectSliderTrackShape的代码，修改下additionalActiveTrackHeight
// 因为它不能重写paint方法修改additionalActiveTrackHeight，只能改源码了
class CustomSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  /// Create a slider track that draws two rectangles with rounded outer edges.
  const CustomSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    // additionalActiveTrackHeight默认为2，改为0，使进度条的高度一致
    double additionalActiveTrackHeight = 0,
  }) {
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.thumbShape != null);
    // If the slider [SliderThemeData.trackHeight] is less than or equal to 0,
    // then it makes no difference whether the track is painted or not,
    // therefore the painting can be a no-op.
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    // Assign the track segment paints, which are leading: active and
    // trailing: inactive.
    final ColorTween activeTrackColorTween = ColorTween(
        begin: sliderTheme.disabledActiveTrackColor,
        end: sliderTheme.activeTrackColor);
    final ColorTween inactiveTrackColorTween = ColorTween(
        begin: sliderTheme.disabledInactiveTrackColor,
        end: sliderTheme.inactiveTrackColor);
    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation)!;
    final Paint leftTrackPaint;
    final Paint rightTrackPaint;
    switch (textDirection) {
      case TextDirection.ltr:
        leftTrackPaint = activePaint;
        rightTrackPaint = inactivePaint;
      case TextDirection.rtl:
        leftTrackPaint = inactivePaint;
        rightTrackPaint = activePaint;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final Radius trackRadius = Radius.circular(trackRect.height / 2);
    final Radius activeTrackRadius =
        Radius.circular((trackRect.height + additionalActiveTrackHeight) / 2);

    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        trackRect.left,
        (textDirection == TextDirection.ltr)
            ? trackRect.top - (additionalActiveTrackHeight / 2)
            : trackRect.top,
        thumbCenter.dx,
        (textDirection == TextDirection.ltr)
            ? trackRect.bottom + (additionalActiveTrackHeight / 2)
            : trackRect.bottom,
        topLeft: (textDirection == TextDirection.ltr)
            ? activeTrackRadius
            : trackRadius,
        bottomLeft: (textDirection == TextDirection.ltr)
            ? activeTrackRadius
            : trackRadius,
      ),
      leftTrackPaint,
    );
    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        thumbCenter.dx,
        (textDirection == TextDirection.rtl)
            ? trackRect.top - (additionalActiveTrackHeight / 2)
            : trackRect.top,
        trackRect.right,
        (textDirection == TextDirection.rtl)
            ? trackRect.bottom + (additionalActiveTrackHeight / 2)
            : trackRect.bottom,
        topRight: (textDirection == TextDirection.rtl)
            ? activeTrackRadius
            : trackRadius,
        bottomRight: (textDirection == TextDirection.rtl)
            ? activeTrackRadius
            : trackRadius,
      ),
      rightTrackPaint,
    );

    final bool showSecondaryTrack = (secondaryOffset != null) &&
        ((textDirection == TextDirection.ltr)
            ? (secondaryOffset.dx > thumbCenter.dx)
            : (secondaryOffset.dx < thumbCenter.dx));

    if (showSecondaryTrack) {
      final ColorTween secondaryTrackColorTween = ColorTween(
          begin: sliderTheme.disabledSecondaryActiveTrackColor,
          end: sliderTheme.secondaryActiveTrackColor);
      final Paint secondaryTrackPaint = Paint()
        ..color = secondaryTrackColorTween.evaluate(enableAnimation)!;
      if (textDirection == TextDirection.ltr) {
        context.canvas.drawRRect(
          RRect.fromLTRBAndCorners(
            thumbCenter.dx,
            trackRect.top,
            secondaryOffset.dx,
            trackRect.bottom,
            topRight: trackRadius,
            bottomRight: trackRadius,
          ),
          secondaryTrackPaint,
        );
      } else {
        context.canvas.drawRRect(
          RRect.fromLTRBAndCorners(
            secondaryOffset.dx,
            trackRect.top,
            thumbCenter.dx,
            trackRect.bottom,
            topLeft: trackRadius,
            bottomLeft: trackRadius,
          ),
          secondaryTrackPaint,
        );
      }
    }
  }
}

// 自定义slider的ThumbShape
class CustomSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final double thumbHeight;

  CustomSliderThumbShape({this.thumbRadius = 6.0, this.thumbHeight = 24.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double>? activationAnimation,
    Animation<double>? enableAnimation,
    bool? isDiscrete,
    TextPainter? labelPainter,
    RenderBox? parentBox,
    SliderThemeData? sliderTheme,
    TextDirection? textDirection,
    double? value,
    double? textScaleFactor,
    Size? sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final Paint thumbPaint = Paint()
      ..color = sliderTheme!.thumbColor!
      ..style = PaintingStyle.fill;

    final double thumbCenterY = center.dy;
    final double thumbTopY = thumbCenterY - (thumbHeight / 2);
    final double thumbBottomY = thumbCenterY + (thumbHeight / 2);

    final Rect thumbRect = Rect.fromLTRB(center.dx - thumbRadius, thumbTopY,
        center.dx + thumbRadius, thumbBottomY);

    canvas.drawRRect(
        RRect.fromRectAndRadius(thumbRect, Radius.circular(thumbRadius)),
        thumbPaint);
  }
}
