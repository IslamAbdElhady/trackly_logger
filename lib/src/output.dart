import 'record.dart';

/// Receives every [TracklyRecord] that passes `TracklyLogger`'s filters.
///
/// Implement this to send logs somewhere other than the console, such as a
/// file or a crash reporting service:
///
/// ```dart
/// class CrashlyticsOutput extends TracklyOutput {
///   @override
///   void write(TracklyRecord record) {
///     if (record.level >= TracklyLevel.error) {
///       FirebaseCrashlytics.instance.recordError(
///         record.error ?? record.message,
///         record.stackTrace,
///         reason: record.message,
///       );
///     }
///   }
/// }
/// ```
abstract class TracklyOutput {
  /// Allows subclasses to have `const` constructors.
  const TracklyOutput();

  /// Handles a single [record].
  void write(TracklyRecord record);
}

/// Sends every record to each of [outputs], in order.
class TracklyMultiOutput extends TracklyOutput {
  /// Creates an output that forwards records to all [outputs].
  const TracklyMultiOutput(this.outputs);

  /// The outputs that receive every record.
  final List<TracklyOutput> outputs;

  @override
  void write(TracklyRecord record) {
    for (final output in outputs) {
      output.write(record);
    }
  }
}
