import 'dart:ffi';

class LRCLine {
  final Duration time;
  final String text;

  LRCLine({required this.time, required this.text});
}

class LRCParse {
  static Duration timeStampToTime(String timeStamp) {
    final str = timeStamp.replaceAll('[', '').replaceAll(']', '');
    final tmp = str.split(':');

    final seconds = double.parse(tmp[0]) * 60.0 + double.parse(tmp[1]);
    return Duration(seconds: seconds.toInt());
  }

  static Future<List<LRCLine>> parse(String content) async {
    final array = content.split('\n');
    final lrc = <LRCLine>[];

    try {
      for (var val in array) {
        final chomp = val.replaceAll('\r', '');

        final regex = RegExp(r'\[\d{2}:\d{2}.\d{2}\]', caseSensitive: false);
        final matches = regex.allMatches(chomp);

        if (matches.isNotEmpty) {
          final last = matches.last;

          final line =
              chomp.substring(last.start + last.group(0)!.length, chomp.length);

          for (var match in matches) {
            final temp = chomp.substring(match.start, match.end);
            final time = timeStampToTime(temp);
            final model = LRCLine(time: time, text: line);
            lrc.add(model);
          }
        }
      }

      lrc.sort((left, right) => left.time.compareTo(right.time));

      return lrc;
    } catch (e) {
      return [];
    }
  }

  static String formatDuration(double totalSeconds) {
    // final hours = totalSeconds ~/ 3600;
    final minutes = ((totalSeconds / 60) % 60).toInt();
    final seconds = (totalSeconds % 60).toInt();

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

extension StringExtension on String {
  double toFloat() {
    return double.parse(this);
  }
}
