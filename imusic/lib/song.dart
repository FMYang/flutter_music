import 'package:audio_service/audio_service.dart';

class Song {
  String songName;
  String authorName;
  String icon;
  String albumId;
  int timelength;
  String lrc;

  Song(
      {required this.albumId,
      required this.songName,
      required this.authorName,
      required this.icon,
      required this.timelength,
      required this.lrc});

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
        albumId: json['album_id'],
        songName: json['song_name'],
        authorName: json['author_name'],
        icon: json['img'],
        timelength: json['timelength'],
        lrc: json['lrc']);
  }

  /// Converts the song info to [AudioService] media item.
  MediaItem toMediaItem() => MediaItem(
      id: albumId,
      album: songName,
      artist: authorName,
      title: songName,
      duration: Duration(
          minutes: (((timelength / 1000.0) / 60 % 60).toInt()),
          seconds: (((timelength / 1000.0) % 60).toInt())),
      artUri: Uri.parse(icon));
}
