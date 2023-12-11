// import 'package:flutter/foundation.dart';

import 'package:audio_service/audio_service.dart';

class Song {
  String songName;
  String authorName;
  String icon;
  String albumId;

  Song({
    required this.albumId,
    required this.songName,
    required this.authorName,
    required this.icon,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
        albumId: json['album_id'],
        songName: json['song_name'],
        authorName: json['author_name'],
        icon: json['img']);
  }

  /// Converts the song info to [AudioService] media item.
  MediaItem toMediaItem() => MediaItem(
        id: albumId,
        album: songName,
        artist: authorName,
        title: songName,
      );
}
