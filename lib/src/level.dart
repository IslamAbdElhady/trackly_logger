/// The severity of a log record, from least to most severe.
///
/// Levels can be compared with the usual operators:
///
/// ```dart
/// if (record.level >= TracklyLevel.error) { ... }
/// ```
enum TracklyLevel implements Comparable<TracklyLevel> {
  /// Very fine-grained details, usually only useful while tracing a problem.
  trace('TRACE', '🔍', 300),

  /// Information useful while developing and debugging.
  debug('DEBUG', '🐞', 500),

  /// General information about what the app is doing.
  info('INFO', 'ℹ️', 800),

  /// An operation completed successfully.
  success('SUCCESS', '✅', 850),

  /// Something unexpected happened, but the app can continue.
  warning('WARNING', '⚠️', 900),

  /// An operation failed.
  error('ERROR', '🛑', 1000),

  /// A failure the app cannot recover from.
  fatal('FATAL', '💀', 1200);

  const TracklyLevel(this.label, this.emoji, this.value);

  /// Upper-case name shown in the console, e.g. `INFO`.
  final String label;

  /// Emoji shown next to the level in the console.
  final String emoji;

  /// Numeric severity, on the same scale as `package:logging` and
  /// `dart:developer` (e.g. 800 for info, 1000 for error).
  final int value;

  @override
  int compareTo(TracklyLevel other) => index - other.index;

  /// Whether this level is less severe than [other].
  bool operator <(TracklyLevel other) => index < other.index;

  /// Whether this level is less severe than or equal to [other].
  bool operator <=(TracklyLevel other) => index <= other.index;

  /// Whether this level is more severe than [other].
  bool operator >(TracklyLevel other) => index > other.index;

  /// Whether this level is more severe than or equal to [other].
  bool operator >=(TracklyLevel other) => index >= other.index;
}
