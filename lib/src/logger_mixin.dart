import 'logger.dart';

/// Gives a class a [logger] tagged with the class name.
///
/// ```dart
/// class CartService with TracklyLoggerMixin {
///   void addItem(String id) => logger.info('Added $id');
/// }
/// // [INFO   ] ℹ️ [CartService] Added apple
/// ```
///
/// If a top-level `logger` is declared or imported in the same file, it takes
/// precedence over this getter; use `this.logger` in that case.
mixin TracklyLoggerMixin {
  /// The tag for this class's logs. Defaults to the runtime type's name.
  ///
  /// Override it to keep a readable tag when the code is obfuscated or
  /// minified, where type names are shortened.
  String get loggerTag => runtimeType.toString();

  /// A logger tagged with [loggerTag].
  TracklyLogger get logger => TracklyLogger(loggerTag);
}
