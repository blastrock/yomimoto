/// Used for formatting time-related strings.
class JidoujishoTimeFormat {
  /// Used to display the position and duration of audio being played.
  static String getDurationText(Duration duration) {
    String twoDigits(String n) => n.padLeft(2, '0');

    String hours = duration.inHours.toString();
    String mins = duration.inMinutes.remainder(60).toString();
    String secs = duration.inSeconds.remainder(60).toString();

    String padMins = twoDigits(mins);
    String padSecs = twoDigits(secs);

    if (duration.inHours != 0) {
      return '  $hours:$padMins:$padSecs  ';
    } else if (duration.inMinutes != 0) {
      return '  $mins:$padSecs  ';
    } else {
      return '  0:$padSecs  ';
    }
  }
}
