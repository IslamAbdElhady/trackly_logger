import 'package:trackly_logger/trackly_logger.dart';

Future<void> main() async {
  // The global logger.
  trackly.trace('Reading config');
  trackly.debug('Config loaded', extra: {'env': 'dev', 'retries': 3});
  trackly.info('App started');
  trackly.success('Connected to the server');
  trackly.warning('Cache is almost full');

  try {
    throw const FormatException('Unexpected end of JSON');
  } catch (e, st) {
    trackly.error('Failed to parse the response', error: e, stackTrace: st);
  }

  // A tagged logger.
  const network = TracklyLogger('Network');
  network.info('GET /users');

  // A class-name tag via the mixin.
  CartService().addItem('apple');

  // Time an operation.
  final users = await trackly.measure('Load users', fetchUsers);
  trackly.info('Loaded ${users.length} users');

  // Lazy messages are only built when they are logged.
  TracklyLogger.minLevel = TracklyLevel.info;
  trackly.debug(() => 'Filtered out, so this closure never runs');
  trackly.fatal('Out of memory');
}

Future<List<String>> fetchUsers() async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
  return ['Ali', 'Mona'];
}

class CartService with TracklyLoggerMixin {
  void addItem(String id) => logger.info('Added $id to the cart');
}
