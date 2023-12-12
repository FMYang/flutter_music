import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:imusic/audio_background.dart';

class PlayInfoWidget extends StatelessWidget {
  final String name;
  final String author;
  final String img;

  const PlayInfoWidget(
      {super.key, required this.name, required this.author, required this.img});

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
                ClipOval(
                    child: CachedNetworkImage(
                        width: 54,
                        height: 54,
                        imageUrl: img,
                        placeholder: (context, url) {
                          return Image.asset(
                              'assets/images/svg_kg_playpage__album_default_01@3x.png');
                        })),
                Container(
                  height: 25,
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(left: 10, right: 0),
                  child: SizedBox(
                      width: 200,
                      child: Text(
                        '$name - $author',
                        style:
                            const TextStyle(color: Colors.black, fontSize: 16),
                      )),
                ),
                const Spacer(),
                IconButton(
                    onPressed: () {
                      MyAudioHandler().playOrPause();
                    },
                    icon: ValueListenableBuilder(
                        valueListenable: MyAudioHandler().playingNotifier,
                        builder: (context, value, child) {
                          return Image.asset(
                              value
                                  ? 'assets/images/miniapp_playbar_pause@2x.png'
                                  : 'assets/images/miniapp_playbar_play@2x.png',
                              width: 25,
                              height: 25);
                        })),
                IconButton(
                    onPressed: () {
                      MyAudioHandler().skipToNext();
                    },
                    icon: Image.asset(
                        'assets/images/miniapp_playbar_next@2x.png',
                        width: 25,
                        height: 25)),
                const SizedBox(width: 10),
              ],
            )));
  }
}
