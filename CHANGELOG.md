## 0.2.0

* **Jump to the code**: each log now ends with its full location, such as
  `(package:app/login_page.dart:42:7)`, which VS Code and Android Studio turn
  into a link that opens the file at that line.
  * `TracklyConsoleOutput(callerLinks: false)` shows the short `main.dart:42`
    form instead.
* New `TracklyRecord.location` (`TracklyLocation`) with the `uri`, `line`,
  `column`, and `link` of where a record was logged. `caller` still returns
  the short form.
* Colors are off by default on iOS, where logs showed the color codes as text.
  `TracklyConsoleOutput.colors` is now `null` by default, meaning automatic.
* Long lines are split at spaces, so words and links stay whole.
* **Breaking**: the `caller` parameter of `TracklyRecord`'s constructor is
  replaced by `location`.

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
