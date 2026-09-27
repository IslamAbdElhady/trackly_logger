import 'level.dart';
import 'location.dart';

/// A single log event, passed to `TracklyLogger.output`.
class TracklyRecord {
  /// Creates a log record.
  const TracklyRecord({
    required this.level,
    required this.message,
    required this.time,
    this.tag,
    this.error,
    this.stackTrace,
    this.extra,
    this.location,
  });

  /// The severity of this record.
  final TracklyLevel level;

  /// The log message.
  final String message;

  /// When the record was created.
  final DateTime time;

  /// The tag of the logger that created this record, e.g. a class name.
  final String? tag;

  /// The error attached to this record, if any.
  final Object? error;

  /// The stack trace attached to this record, if any.
  final StackTrace? stackTrace;

  /// Extra key/value data attached to this record, if any.
  final Map<String, Object?>? extra;

  /// Where in the code this record was logged.
  ///
  /// Only available on the Dart VM (Flutter debug builds, Dart CLI and
  /// server apps) and when `TracklyLogger.showCaller` is `true`.
  final TracklyLocation? location;

  /// The short form of [location], e.g. `main.dart:12`.
  String? get caller => location?.toString();
}
