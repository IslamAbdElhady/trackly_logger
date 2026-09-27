# trackly_logger

[![pub package](https://img.shields.io/pub/v/trackly_logger.svg)](https://pub.dev/packages/trackly_logger)
[![CI](https://github.com/IslamAbdElhady/trackly_logger/actions/workflows/ci.yml/badge.svg)](https://github.com/IslamAbdElhady/trackly_logger/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A lightweight, zero-dependency logger for Dart and Flutter. Colored, readable
logs that tell you exactly which file and line they came from.

```text
[2026-09-27 10:53:53.664] [DEBUG  ] 🐞 Config loaded [main.dart:6] | extra: {env: dev, retries: 3}
[2026-09-27 10:53:53.665] [SUCCESS] ✅ Connected to the server [main.dart:8]
[2026-09-27 10:53:53.665] [WARNING] ⚠️ Cache is almost full [main.dart:9]
[2026-09-27 10:53:53.666] [INFO   ] ℹ️ [CartService] Added apple to the cart [main.dart:40]
[2026-09-27 10:53:53.793] [DEBUG  ] 🐞 Load users took 126 ms [main.dart:25]
```

## Features

- **Seven levels**: trace, debug, info, success, warning, error, fatal.
- **Automatic caller info**: every log shows the `file.dart:line` that wrote it.
- **Colors, emojis, and timestamps**, each of which can be turned off.
- **Tags**: per-feature loggers, or the class name through a mixin.
- **Errors, stack traces, and extra data** on any log.
- **Timing**: `measure()` logs how long an operation took.
- **Off in release builds** by default.
- **Outputs**: console, Dart DevTools, in-memory history, or your own (e.g. Crashlytics).
- **No dependencies**. Works on every platform Dart and Flutter support.

## Installation

```sh
flutter pub add trackly_logger
# or, for Dart projects:
dart pub add trackly_logger
```

## Usage

```dart
import 'package:trackly_logger/trackly_logger.dart';

trackly.trace('Reading config');
trackly.debug('Config loaded', extra: {'env': 'dev'});
trackly.info('App started');
trackly.success('Signed in');
trackly.warning('Cache is almost full');
trackly.fatal('Out of memory');

try {
  await api.fetchUsers();
} catch (e, st) {
  trackly.error('Failed to load users', error: e, stackTrace: st);
}
```

### Tagged loggers

Create a logger with a tag to see which part of the app a log came from:

```dart
const network = TracklyLogger('Network');
network.info('GET /users'); // [INFO   ] ℹ️ [Network] GET /users
```

Or add `TracklyLoggerMixin` to a class to get a `logger` tagged with the class
name:

```dart
class CartService with TracklyLoggerMixin {
  void addItem(String id) => logger.info('Added $id');
  // [INFO   ] ℹ️ [CartService] Added apple
}
```

Class names are shortened when code is obfuscated. Override `loggerTag` to
keep them readable:

```dart
@override
String get loggerTag => 'CartService';
```

### Timing

`measure()` runs a function, logs how long it took, and returns its result.
If the function throws, it logs the error and rethrows it.

```dart
final users = await trackly.measure('Load users', api.fetchUsers);
// [DEBUG  ] 🐞 Load users took 126 ms [users_page.dart:24]
```

### Lazy messages

Pass a function to build a message only when it will actually be logged:

```dart
trackly.debug(() => 'State: ${state.toJson()}');
```

## Configuration

All loggers share these settings:

```dart
// On by default, except in release builds.
TracklyLogger.enabled = true;

// Ignore anything below this level.
TracklyLogger.minLevel = TracklyLevel.info;

// Turn off file:line detection to skip capturing a stack trace per log.
TracklyLogger.showCaller = false;

// Drop specific records, e.g. mute a noisy tag.
TracklyLogger.filter = (record) => record.tag != 'Network';

// Change how logs are printed.
TracklyLogger.output = const TracklyConsoleOutput(
  colors: true,
  emojis: true,
  timestamp: true,
  maxLineLength: 800, // Longer lines are split so logcat doesn't cut them.
);
```

If your console shows codes like `[33m` instead of colors (for example the
Xcode console), use `TracklyConsoleOutput(colors: false)`.

## Outputs

| Output | Sends logs to |
| --- | --- |
| `TracklyConsoleOutput` | The console, using `print` (the default). |
| `TracklyDeveloperOutput` | The Logging tab of Dart & Flutter DevTools, via `dart:developer`. |
| `TracklyMemoryOutput` | An in-memory list of recent records, for an in-app log viewer or bug reports. |
| `TracklyMultiOutput` | Several outputs at once. |

```dart
final history = TracklyMemoryOutput(capacity: 200);

TracklyLogger.output = TracklyMultiOutput([
  const TracklyConsoleOutput(),
  const TracklyDeveloperOutput(),
  history,
]);

// Later, e.g. when the user sends feedback:
final report = history.records
    .expand(const TracklyConsoleOutput(colors: false).format)
    .join('\n');
```

### Custom outputs

Extend `TracklyOutput` to send logs anywhere. For example, to report errors to
Firebase Crashlytics in release builds:

```dart
class CrashlyticsOutput extends TracklyOutput {
  @override
  void write(TracklyRecord record) {
    if (record.level >= TracklyLevel.error) {
      FirebaseCrashlytics.instance.recordError(
        record.error ?? record.message,
        record.stackTrace,
        reason: record.message,
      );
    }
  }
}

void main() {
  TracklyLogger.enabled = true; // Keep logging on in release.
  TracklyLogger.output = TracklyMultiOutput([
    if (kDebugMode) const TracklyConsoleOutput(),
    CrashlyticsOutput(),
  ]);
  runApp(const MyApp());
}
```

## Logging uncaught Flutter errors

```dart
void main() {
  FlutterError.onError = (details) {
    trackly.fatal(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    trackly.fatal('Uncaught error', error: error, stackTrace: stackTrace);
    return true;
  };
  runApp(const MyApp());
}
```

## Caller info

The `file.dart:line` part is read from the stack trace, so it's available
wherever Dart produces readable stack traces, such as Flutter apps in debug mode
and Dart CLI and server apps. When stack traces aren't readable, for example on
the web or in builds using `--obfuscate` or `--split-debug-info`, it's left out
and everything else still works.

## License

MIT. See [LICENSE](LICENSE).
