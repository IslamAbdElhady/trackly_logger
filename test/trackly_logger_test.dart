import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:trackly_logger/src/caller.dart';
import 'package:trackly_logger/trackly_logger.dart';

class _CaptureOutput extends TracklyOutput {
  final records = <TracklyRecord>[];

  @override
  void write(TracklyRecord record) => records.add(record);
}

class _CartService with TracklyLoggerMixin {
  void addItem() => logger.info('added');
}

class _CustomTagService with TracklyLoggerMixin {
  @override
  String get loggerTag => 'Custom';

  void run() => logger.info('run');
}

/// The line number of the code that calls this function.
int _currentLine() {
  final frame = StackTrace.current.toString().split('\n')[1];
  return int.parse(RegExp(r':(\d+):\d+\)$').firstMatch(frame)!.group(1)!);
}

List<String> _capturePrints(void Function() body) {
  final lines = <String>[];
  runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

TracklyRecord _record({
  String message = 'hello',
  TracklyLevel level = TracklyLevel.info,
  String? tag,
  Object? error,
  StackTrace? stackTrace,
  Map<String, Object?>? extra,
  TracklyLocation? location,
}) => TracklyRecord(
  level: level,
  message: message,
  time: DateTime(2024, 1, 2, 3, 4, 5, 6),
  tag: tag,
  error: error,
  stackTrace: stackTrace,
  extra: extra,
  location: location,
);

void main() {
  late _CaptureOutput capture;

  setUp(() {
    capture = _CaptureOutput();
    TracklyLogger.enabled = true;
    TracklyLogger.minLevel = TracklyLevel.trace;
    TracklyLogger.showCaller = true;
    TracklyLogger.output = capture;
  });

  tearDown(() {
    TracklyLogger.output = const TracklyConsoleOutput();
  });

  group('TracklyLogger', () {
    test('each method logs at its level', () {
      trackly.trace('m');
      trackly.debug('m');
      trackly.info('m');
      trackly.success('m');
      trackly.warning('m');
      trackly.error('m');
      trackly.fatal('m');

      expect(capture.records.map((r) => r.level), TracklyLevel.values);
    });

    test('passes message, tag, error, stack trace, and extra', () {
      final stackTrace = StackTrace.current;
      const TracklyLogger('Auth').error(
        'failed',
        error: 'boom',
        stackTrace: stackTrace,
        extra: {'id': 1},
      );

      final record = capture.records.single;
      expect(record.message, 'failed');
      expect(record.tag, 'Auth');
      expect(record.error, 'boom');
      expect(record.stackTrace, stackTrace);
      expect(record.extra, {'id': 1});
    });

    test('global logger has no tag', () {
      trackly.info('m');
      expect(capture.records.single.tag, isNull);
    });

    test('converts non-string messages with toString', () {
      trackly.info(42);
      trackly.info(null);
      expect(capture.records.map((r) => r.message), ['42', 'null']);
    });

    test('ignores records below minLevel', () {
      TracklyLogger.minLevel = TracklyLevel.warning;
      trackly.info('ignored');
      trackly.warning('kept');
      trackly.fatal('kept');

      expect(capture.records.map((r) => r.level), [
        TracklyLevel.warning,
        TracklyLevel.fatal,
      ]);
    });

    test('logs nothing when disabled', () {
      TracklyLogger.enabled = false;
      trackly.fatal('ignored');
      expect(capture.records, isEmpty);
    });

    test('builds lazy messages only when logged', () {
      var calls = 0;
      String build() {
        calls++;
        return 'lazy';
      }

      TracklyLogger.minLevel = TracklyLevel.info;
      trackly.debug(build);
      expect(calls, 0);

      trackly.info(build);
      expect(calls, 1);
      expect(capture.records.single.message, 'lazy');
    });
  });

  group('caller', () {
    test('points at the line that logged', () {
      final line = _currentLine() + 1;
      trackly.info('m');
      expect(capture.records.single.caller, 'trackly_logger_test.dart:$line');
    });

    test('is the same for tagged loggers and log()', () {
      const tagged = TracklyLogger('Tag');
      final line = _currentLine() + 1;
      tagged.info('m');
      tagged.log(TracklyLevel.info, 'm');

      expect(capture.records.map((r) => r.caller), [
        'trackly_logger_test.dart:$line',
        'trackly_logger_test.dart:${line + 1}',
      ]);
    });

    test('skips Dart SDK frames for tear-offs', () {
      final line = _currentLine() + 1;
      ['a'].forEach(trackly.info);
      expect(capture.records.single.caller, 'trackly_logger_test.dart:$line');
    });

    test('has the full location with a column', () {
      final line = _currentLine() + 1;
      trackly.info('m');
      final location = capture.records.single.location!;

      expect(location.uri.path, endsWith('/test/trackly_logger_test.dart'));
      expect(location.line, line);
      expect(location.column, 15); // The column of `info`.
      expect(location.link, '${location.uri}:$line:15');
      expect(location.fileName, 'trackly_logger_test.dart');
    });

    test('reads Windows file paths', () {
      final trace = StackTrace.fromString(
        '#0      TracklyLogger.info (package:trackly_logger/src/logger.dart:80:5)\n'
        '#1      main (file:///C:/Users/dev/app/bin/main.dart:12:11)\n',
      );
      final location = findCaller(trace)!;

      expect(location.line, 12);
      expect(location.column, 11);
      expect(location.fileName, 'main.dart');
      expect(location.link, 'file:///C:/Users/dev/app/bin/main.dart:12:11');
    });

    test('is null when showCaller is off', () {
      TracklyLogger.showCaller = false;
      trackly.info('m');
      expect(capture.records.single.caller, isNull);
    });
  });

  group('TracklyLoggerMixin', () {
    test('tags logs with the class name', () {
      _CartService().addItem();
      final record = capture.records.single;
      expect(record.tag, '_CartService');
      expect(record.caller, startsWith('trackly_logger_test.dart:'));
    });

    test('uses an overridden loggerTag', () {
      _CustomTagService().run();
      expect(capture.records.single.tag, 'Custom');
    });
  });

  group('TracklyLevel', () {
    test('is ordered by severity', () {
      expect(TracklyLevel.error >= TracklyLevel.warning, isTrue);
      expect(TracklyLevel.error >= TracklyLevel.error, isTrue);
      expect(TracklyLevel.debug > TracklyLevel.info, isFalse);
      expect(TracklyLevel.trace < TracklyLevel.fatal, isTrue);
      expect(TracklyLevel.info <= TracklyLevel.debug, isFalse);
      expect([...TracklyLevel.values.reversed]..sort(), TracklyLevel.values);
    });

    test('has increasing numeric values', () {
      final values = TracklyLevel.values.map((l) => l.value).toList();
      expect(values, [...values]..sort());
      expect(TracklyLevel.info.value, 800);
      expect(TracklyLevel.error.value, 1000);
    });
  });

  group('TracklyConsoleOutput', () {
    const plain = TracklyConsoleOutput(colors: false);

    test('formats a full record on one line', () {
      final lines = plain.format(
        _record(
          tag: 'Auth',
          location: TracklyLocation(Uri.parse('package:app/main.dart'), 10, 5),
          extra: {'id': 1},
          error: 'boom',
        ),
      );

      expect(lines, [
        '[2024-01-02 03:04:05.006] [INFO   ] ℹ️ [Auth] hello '
            '(package:app/main.dart:10:5) | extra: {id: 1} | error: boom',
      ]);
    });

    test('can show the short caller instead of the link', () {
      const short = TracklyConsoleOutput(
        colors: false,
        timestamp: false,
        emojis: false,
        callerLinks: false,
      );
      final record = _record(
        location: TracklyLocation(Uri.parse('package:app/main.dart'), 10, 5),
      );
      expect(short.format(record), ['[INFO   ] hello (main.dart:10)']);
    });

    test('wraps long lines at spaces so links stay whole', () {
      const output = TracklyConsoleOutput(
        colors: false,
        timestamp: false,
        emojis: false,
        maxLineLength: 40,
      );
      final record = _record(
        message: 'word ' * 10,
        location: TracklyLocation(Uri.parse('package:app/a.dart'), 1, 2),
      );
      final lines = output.format(record);

      expect(lines.every((line) => line.length <= 40), isTrue);
      expect(
        lines.join(),
        '[INFO   ] ${'word ' * 10} (package:app/a.dart:1:2)',
      );
      expect(lines.last, contains('package:app/a.dart:1:2'));
    });

    test('turns colors off by default only on iOS', () {
      expect(const TracklyConsoleOutput().usesColors, !Platform.isIOS);
      expect(const TracklyConsoleOutput(colors: true).usesColors, isTrue);
      expect(const TracklyConsoleOutput(colors: false).usesColors, isFalse);
    });

    test('leaves out missing parts without extra spaces', () {
      expect(plain.format(_record()), [
        '[2024-01-02 03:04:05.006] [INFO   ] ℹ️ hello',
      ]);
    });

    test('can hide the timestamp and emoji', () {
      const bare = TracklyConsoleOutput(
        colors: false,
        emojis: false,
        timestamp: false,
      );
      expect(bare.format(_record(level: TracklyLevel.success)), [
        '[SUCCESS] hello',
      ]);
    });

    test('puts each stack trace frame on its own line', () {
      final stackTrace = StackTrace.fromString(
        '#0 a (a.dart:1)\n#1 b (b.dart:2)\n',
      );
      final lines = plain.format(_record(stackTrace: stackTrace));
      expect(lines.skip(1), ['#0 a (a.dart:1)', '#1 b (b.dart:2)']);
    });

    test('colors every line and resets the color', () {
      const colored = TracklyConsoleOutput(timestamp: false, emojis: false);
      final lines = colored.format(
        _record(level: TracklyLevel.error, message: 'line 1\nline 2'),
      );

      expect(lines, [
        '\x1B[31m[ERROR  ] line 1\x1B[0m',
        '\x1B[31mline 2\x1B[0m',
      ]);
    });

    test('splits long lines', () {
      const output = TracklyConsoleOutput(
        colors: false,
        emojis: false,
        timestamp: false,
        maxLineLength: 10,
      );
      final lines = output.format(_record(message: 'x' * 25));

      expect(lines.every((line) => line.length <= 10), isTrue);
      expect(lines.join(), '[INFO   ] ${'x' * 25}');
    });

    test('does not split surrogate pairs', () {
      const output = TracklyConsoleOutput(
        colors: false,
        emojis: false,
        timestamp: false,
        maxLineLength: 5,
      );
      final lines = output.format(_record(message: '😀' * 10));

      expect(lines.join(), '[INFO   ] ${'😀' * 10}');
      for (final line in lines) {
        final last = line.codeUnitAt(line.length - 1);
        expect(last >= 0xD800 && last <= 0xDBFF, isFalse, reason: line);
      }
    });

    test('never splits lines when maxLineLength is null', () {
      const output = TracklyConsoleOutput(colors: false, maxLineLength: null);
      expect(output.format(_record(message: 'x' * 5000)), hasLength(1));
    });

    test('prints one line per call', () {
      TracklyLogger.output = const TracklyConsoleOutput(
        colors: false,
        timestamp: false,
      );
      final printed = _capturePrints(() => trackly.info('a\nb'));
      expect(printed, hasLength(2));
      expect(printed.first, startsWith('[INFO   ] ℹ️ a'));
      expect(printed.last, startsWith('b ('));
    });
  });

  group('TracklyMultiOutput', () {
    test('forwards records to every output', () {
      final other = _CaptureOutput();
      TracklyLogger.output = TracklyMultiOutput([capture, other]);
      trackly.info('m');

      expect(capture.records, hasLength(1));
      expect(other.records, hasLength(1));
    });
  });

  group('filter', () {
    tearDown(() => TracklyLogger.filter = null);

    test('drops records it rejects', () {
      TracklyLogger.filter = (record) => record.tag != 'Noisy';
      const TracklyLogger('Noisy').info('dropped');
      const TracklyLogger('Auth').info('kept');

      expect(capture.records.map((r) => r.tag), ['Auth']);
    });

    test('sees the full record', () {
      final seen = <TracklyRecord>[];
      TracklyLogger.filter = (record) {
        seen.add(record);
        return true;
      };
      trackly.warning('m', extra: {'a': 1});

      expect(seen.single.level, TracklyLevel.warning);
      expect(seen.single.extra, {'a': 1});
      expect(seen.single.caller, startsWith('trackly_logger_test.dart:'));
    });
  });

  group('measure', () {
    test('returns the result and logs the elapsed time', () async {
      final line = _currentLine() + 1;
      final result = await trackly.measure('Load', () async => 42);

      expect(result, 42);
      final record = capture.records.single;
      expect(record.level, TracklyLevel.debug);
      expect(record.message, matches(RegExp(r'^Load took \d+ ms$')));
      expect(record.caller, 'trackly_logger_test.dart:$line');
    });

    test('works with synchronous bodies and a custom level', () async {
      final result = await const TracklyLogger(
        'Db',
      ).measure('Query', () => 'rows', level: TracklyLevel.info);

      expect(result, 'rows');
      expect(capture.records.single.level, TracklyLevel.info);
      expect(capture.records.single.tag, 'Db');
    });

    test('logs and rethrows errors', () async {
      final error = StateError('offline');
      await expectLater(
        trackly.measure('Sync', () async => throw error),
        throwsA(same(error)),
      );

      final record = capture.records.single;
      expect(record.level, TracklyLevel.error);
      expect(record.message, matches(RegExp(r'^Sync failed after \d+ ms$')));
      expect(record.error, same(error));
      expect(record.stackTrace, isNotNull);
    });

    test('still runs the body when logging is disabled', () async {
      TracklyLogger.enabled = false;
      expect(await trackly.measure('Work', () => 1), 1);
      expect(capture.records, isEmpty);
    });
  });

  group('TracklyMemoryOutput', () {
    test('keeps the newest records up to its capacity', () {
      final history = TracklyMemoryOutput(capacity: 2);
      TracklyLogger.output = history;
      trackly.info('1');
      trackly.info('2');
      trackly.info('3');

      expect(history.records.map((r) => r.message), ['2', '3']);
    });

    test('can be cleared', () {
      final history = TracklyMemoryOutput();
      history.write(_record());
      history.clear();
      expect(history.records, isEmpty);
    });

    test('returns an unmodifiable list', () {
      final history = TracklyMemoryOutput()..write(_record());
      expect(() => history.records.clear(), throwsUnsupportedError);
    });
  });

  group('TracklyDeveloperOutput', () {
    const output = TracklyDeveloperOutput();

    test('adds caller and extra to the message', () {
      expect(
        output.format(
          _record(
            location: TracklyLocation(Uri.parse('package:app/main.dart'), 3, 1),
            extra: {'id': 1},
          ),
        ),
        'hello (package:app/main.dart:3:1) | extra: {id: 1}',
      );
    });

    test('keeps a bare message unchanged', () {
      expect(output.format(_record()), 'hello');
    });

    test('writes without throwing', () {
      TracklyLogger.output = output;
      expect(() => trackly.error('m', error: 'e'), returnsNormally);
    });
  });
}
