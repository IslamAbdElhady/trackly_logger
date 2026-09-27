## 0.1.0

* Initial release.
* Seven log levels: trace, debug, info, success, warning, error, fatal.
* Colored console output with emojis and timestamps, each configurable.
* Automatic `file.dart:line` caller info on the Dart VM.
* Global `trackly` logger, tagged `TracklyLogger` instances, and `TracklyLoggerMixin`.
* Attach errors, stack traces, and extra data to any log.
* Lazy messages that are only built when the log is written.
* `measure()` to log how long an operation took.
* `TracklyLogger.filter` to drop specific records, such as a noisy tag.
* Logging is off by default in release builds.
* Outputs: `TracklyConsoleOutput`, `TracklyDeveloperOutput` (DevTools),
  `TracklyMemoryOutput` (recent history), `TracklyMultiOutput`, or your own
  `TracklyOutput`.
* Long lines are split so Android's logcat doesn't truncate them.
* No dependencies; works on every Dart and Flutter platform.
