/// A lightweight, zero-dependency logger for Dart and Flutter.
///
/// ```dart
/// import 'package:trackly_logger/trackly_logger.dart';
///
/// void main() {
///   trackly.info('App started');
///
///   const auth = TracklyLogger('Auth');
///   auth.success('Signed in', extra: {'userId': 42});
/// }
/// ```
library;

export 'src/console_output.dart';
export 'src/developer_output.dart';
export 'src/level.dart';
export 'src/logger.dart';
export 'src/logger_mixin.dart';
export 'src/memory_output.dart';
export 'src/output.dart';
export 'src/record.dart';
