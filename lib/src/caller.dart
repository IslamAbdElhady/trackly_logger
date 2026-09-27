/// Matches a Dart VM stack frame, e.g.
/// `#3      main (package:app/main.dart:12:5)`.
final _vmFrame = RegExp(r'^#\d+\s+.+ \((.+?):(\d+)(?::\d+)?\)$');

const _ownPackage = 'package:trackly_logger/';

/// Returns `file.dart:line` for the first frame of [trace] that is outside
/// this package and the Dart SDK, or `null` if none can be found.
///
/// Returns `null` for stack traces that are not in the Dart VM format, such as
/// on the web or in Flutter release builds.
String? findCaller(StackTrace trace) {
  for (final line in trace.toString().split('\n')) {
    final match = _vmFrame.firstMatch(line.trim());
    if (match == null) continue;

    final uri = match.group(1)!;
    if (uri.startsWith(_ownPackage) || uri.startsWith('dart:')) continue;

    final fileName = uri.substring(uri.lastIndexOf('/') + 1);
    return '$fileName:${match.group(2)}';
  }
  return null;
}
