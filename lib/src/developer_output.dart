import 'dart:developer' as developer;

import 'console_output.dart';
import 'output.dart';
import 'record.dart';

/// Sends records to `dart:developer`'s `log`, which shows them in the Logging
/// tab of Dart & Flutter DevTools, with filtering by level and tag.
///
/// Also shows logs in IDE debug consoles, but not in the `flutter run`
/// terminal. Combine it with [TracklyConsoleOutput] to get both:
///
/// ```dart
/// TracklyLogger.output = const TracklyMultiOutput([
///   TracklyConsoleOutput(),
///   TracklyDeveloperOutput(),
/// ]);
/// ```
class TracklyDeveloperOutput extends TracklyOutput {
  /// Creates an output that logs to `dart:developer`.
  const TracklyDeveloperOutput({this.defaultName = 'trackly'});

  /// The log name used for records without a tag.
  final String defaultName;

  @override
  void write(TracklyRecord record) {
    developer.log(
      format(record),
      time: record.time,
      level: record.level.value,
      name: record.tag ?? defaultName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }

  /// The message passed to `dart:developer`'s `log` for [record].
  ///
  /// The level, tag, time, error, and stack trace are passed separately.
  String format(TracklyRecord record) {
    final text = StringBuffer(record.message);
    final location = record.location;
    if (location != null) text.write(' (${location.link})');
    final extra = record.extra;
    if (extra != null && extra.isNotEmpty) text.write(' | extra: $extra');
    return text.toString();
  }
}
