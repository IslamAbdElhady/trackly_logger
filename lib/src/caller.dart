import 'location.dart';

/// Matches a Dart VM stack frame, e.g.
/// `#3      main (package:app/main.dart:12:5)`.
final _vmFrame = RegExp(r'^#\d+\s+.+ \((.+?):(\d+)(?::(\d+))?\)$');

const _ownPackage = 'package:trackly_logger/';

/// Returns the location of the first frame of [trace] that is outside this
/// package and the Dart SDK, or `null` if none can be found.
///
/// Returns `null` for stack traces that are not in the Dart VM format, such as
/// on the web or in Flutter release builds.
TracklyLocation? findCaller(StackTrace trace) {
  for (final line in trace.toString().split('\n')) {
    final match = _vmFrame.firstMatch(line.trim());
    if (match == null) continue;

    final uri = match.group(1)!;
    if (uri.startsWith(_ownPackage) || uri.startsWith('dart:')) continue;

    final parsed = Uri.tryParse(uri);
    if (parsed == null) continue;
    final column = match.group(3);
    return TracklyLocation(
      parsed,
      int.parse(match.group(2)!),
      column == null ? null : int.parse(column),
    );
  }
  return null;
}
