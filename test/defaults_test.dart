import 'package:test/test.dart';
import 'package:trackly_logger/trackly_logger.dart';

// Kept in its own file so no other test has changed the static settings yet.
void main() {
  test('defaults to logging everything to the console outside release', () {
    expect(TracklyLogger.enabled, isTrue);
    expect(TracklyLogger.minLevel, TracklyLevel.trace);
    expect(TracklyLogger.showCaller, isTrue);
    expect(TracklyLogger.output, isA<TracklyConsoleOutput>());
  });
}
