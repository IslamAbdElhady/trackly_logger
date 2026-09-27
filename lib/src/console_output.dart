import 'level.dart';
import 'output.dart';
import 'record.dart';

/// Prints records to the console, one `print` call per line.
///
/// Output looks like:
///
/// ```text
/// [2026-09-27 10:39:44.762] [INFO   ] ℹ️ [AuthService] Signed in [auth_service.dart:42]
/// ```
class TracklyConsoleOutput extends TracklyOutput {
  /// Creates a console output.
  ///
  /// Set [colors] to `false` if your console shows raw codes such as `[33m`
  /// instead of colors (for example, the Xcode console).
  const TracklyConsoleOutput({
    this.colors = true,
    this.emojis = true,
    this.timestamp = true,
    this.maxLineLength = 800,
  }) : assert(maxLineLength == null || maxLineLength > 0);

  /// Whether to color each line with ANSI escape codes based on its level.
  final bool colors;

  /// Whether to show the level's emoji.
  final bool emojis;

  /// Whether to show the date and time of each record.
  final bool timestamp;

  /// Lines longer than this are split into several lines, or `null` to never
  /// split.
  ///
  /// Android's logcat truncates very long lines, so splitting them keeps the
  /// whole message visible.
  final int? maxLineLength;

  static const _reset = '\x1B[0m';
  static const _labelWidth = 7; // Length of the longest label, 'SUCCESS'.

  @override
  void write(TracklyRecord record) {
    for (final line in format(record)) {
      // ignore: avoid_print
      print(line);
    }
  }

  /// Formats [record] into the lines that [write] prints.
  List<String> format(TracklyRecord record) {
    final text = StringBuffer();
    if (timestamp) text.write('[${_formatTime(record.time)}] ');
    text.write('[${record.level.label.padRight(_labelWidth)}] ');
    if (emojis) text.write('${record.level.emoji} ');
    if (record.tag != null) text.write('[${record.tag}] ');
    text.write(record.message);
    if (record.caller != null) text.write(' [${record.caller}]');

    final extra = record.extra;
    if (extra != null && extra.isNotEmpty) text.write(' | extra: $extra');
    if (record.error != null) text.write(' | error: ${record.error}');

    final stackTrace = record.stackTrace?.toString().trimRight() ?? '';
    if (stackTrace.isNotEmpty) text.write('\n$stackTrace');

    final color = colors ? _colorOf(record.level) : null;
    return [
      for (final line in text.toString().split('\n'))
        for (final chunk in _split(line))
          color == null ? chunk : '$color$chunk$_reset',
    ];
  }

  Iterable<String> _split(String line) sync* {
    final max = maxLineLength;
    if (max == null || line.length <= max) {
      yield line;
      return;
    }

    var start = 0;
    while (line.length - start > max) {
      var end = start + max;
      // Don't cut an emoji or other surrogate pair in half.
      if (end - 1 > start && _isHighSurrogate(line.codeUnitAt(end - 1))) end--;
      yield line.substring(start, end);
      start = end;
    }
    yield line.substring(start);
  }

  static bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xD800 && codeUnit <= 0xDBFF;

  static String _colorOf(TracklyLevel level) => switch (level) {
    TracklyLevel.trace => '\x1B[90m', // gray
    TracklyLevel.debug => '\x1B[36m', // cyan
    TracklyLevel.info => '\x1B[34m', // blue
    TracklyLevel.success => '\x1B[32m', // green
    TracklyLevel.warning => '\x1B[33m', // yellow
    TracklyLevel.error => '\x1B[31m', // red
    TracklyLevel.fatal => '\x1B[97;41m', // white on red
  };

  static String _formatTime(DateTime time) {
    String pad(int value, [int width = 2]) =>
        value.toString().padLeft(width, '0');
    return '${pad(time.year, 4)}-${pad(time.month)}-${pad(time.day)} '
        '${pad(time.hour)}:${pad(time.minute)}:${pad(time.second)}'
        '.${pad(time.millisecond, 3)}';
  }
}
