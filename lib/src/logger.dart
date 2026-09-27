import 'dart:async';

import 'caller.dart';
import 'console_output.dart';
import 'level.dart';
import 'output.dart';
import 'record.dart';

/// The global logger, without a tag.
///
/// ```dart
/// trackly.info('App started');
/// ```
const trackly = TracklyLogger();

/// Logs messages at different [TracklyLevel]s.
///
/// Use the global [trackly] logger, or create one with a tag to show where
/// logs come from:
///
/// ```dart
/// const log = TracklyLogger('Auth');
/// log.success('Signed in', extra: {'userId': 42});
/// ```
///
/// The static fields configure every logger at once:
///
/// ```dart
/// TracklyLogger.minLevel = TracklyLevel.info;
/// TracklyLogger.output = const TracklyConsoleOutput(colors: false);
/// ```
///
/// A message can be any object, or a function that returns one. A function is
/// only called when the record is actually logged, which avoids building
/// expensive messages that would be filtered out:
///
/// ```dart
/// trackly.debug(() => 'State: ${state.toJson()}');
/// ```
class TracklyLogger {
  /// Creates a logger whose records carry [tag].
  const TracklyLogger([this.tag]);

  /// Shown before each message from this logger, e.g. a class or feature name.
  final String? tag;

  /// Whether logging is on.
  ///
  /// Defaults to `false` in release builds (when `dart.vm.product` is set, as
  /// in Flutter release mode) and `true` otherwise.
  static bool enabled = !_isReleaseMode;

  /// Records below this level are ignored.
  static TracklyLevel minLevel = TracklyLevel.trace;

  /// Whether to find the file name and line of each log call.
  ///
  /// Only works on the Dart VM (Flutter debug builds, Dart CLI and server
  /// apps). Turn it off to save the cost of capturing a stack trace per log.
  static bool showCaller = true;

  /// Where records go. Defaults to the console.
  ///
  /// Use [TracklyMultiOutput] to send records to more than one place.
  static TracklyOutput output = const TracklyConsoleOutput();

  /// Return `false` from this to drop a record, e.g. to mute a noisy tag:
  ///
  /// ```dart
  /// TracklyLogger.filter = (record) => record.tag != 'Network';
  /// ```
  ///
  /// Runs after [enabled] and [minLevel] are checked. `null` keeps everything.
  static bool Function(TracklyRecord record)? filter;

  static const _isReleaseMode = bool.fromEnvironment('dart.vm.product');

  /// Logs [message] at [TracklyLevel.trace].
  void trace(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? extra,
  }) => log(
    TracklyLevel.trace,
    message,
    error: error,
    stackTrace: stackTrace,
    extra: extra,
  );

  /// Logs [message] at [TracklyLevel.debug].
  void debug(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? extra,
  }) => log(
    TracklyLevel.debug,
    message,
    error: error,
    stackTrace: stackTrace,
    extra: extra,
  );

  /// Logs [message] at [TracklyLevel.info].
  void info(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? extra,
  }) => log(
    TracklyLevel.info,
    message,
    error: error,
    stackTrace: stackTrace,
    extra: extra,
  );

  /// Logs [message] at [TracklyLevel.success].
  void success(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? extra,
  }) => log(
    TracklyLevel.success,
    message,
    error: error,
    stackTrace: stackTrace,
    extra: extra,
  );

  /// Logs [message] at [TracklyLevel.warning].
  void warning(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? extra,
  }) => log(
    TracklyLevel.warning,
    message,
    error: error,
    stackTrace: stackTrace,
    extra: extra,
  );

  /// Logs [message] at [TracklyLevel.error].
  void error(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? extra,
  }) => log(
    TracklyLevel.error,
    message,
    error: error,
    stackTrace: stackTrace,
    extra: extra,
  );

  /// Logs [message] at [TracklyLevel.fatal].
  void fatal(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? extra,
  }) => log(
    TracklyLevel.fatal,
    message,
    error: error,
    stackTrace: stackTrace,
    extra: extra,
  );

  /// Logs [message] at [level].
  ///
  /// Does nothing if logging is not [enabled] or [level] is below [minLevel].
  void log(
    TracklyLevel level,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? extra,
  }) {
    if (!enabled || level < minLevel) return;

    final text = message is Object? Function() ? message() : message;
    final record = TracklyRecord(
      level: level,
      message: '$text',
      time: DateTime.now(),
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
      location: showCaller ? findCaller(StackTrace.current) : null,
    );
    if (filter?.call(record) ?? true) output.write(record);
  }

  /// Runs [body] and logs how long it took, at [level].
  ///
  /// If [body] throws, logs the error at [TracklyLevel.error] and rethrows it.
  ///
  /// ```dart
  /// final users = await trackly.measure('Load users', api.fetchUsers);
  /// // [DEBUG  ] 🐞 Load users took 132 ms [users_page.dart:24]
  /// ```
  Future<T> measure<T>(
    String label,
    FutureOr<T> Function() body, {
    TracklyLevel level = TracklyLevel.debug,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await body();
      log(level, '$label took ${stopwatch.elapsedMilliseconds} ms');
      return result;
    } catch (e, st) {
      log(
        TracklyLevel.error,
        '$label failed after ${stopwatch.elapsedMilliseconds} ms',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
