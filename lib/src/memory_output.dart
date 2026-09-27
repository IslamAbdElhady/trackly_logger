import 'dart:collection';

import 'output.dart';
import 'record.dart';

/// Keeps the most recent records in memory.
///
/// Useful for an in-app log viewer, or for attaching recent logs to a bug
/// report:
///
/// ```dart
/// final history = TracklyMemoryOutput(capacity: 200);
/// TracklyLogger.output = TracklyMultiOutput([
///   const TracklyConsoleOutput(),
///   history,
/// ]);
///
/// // Later:
/// final report = history.records
///     .expand(const TracklyConsoleOutput(colors: false).format)
///     .join('\n');
/// ```
class TracklyMemoryOutput extends TracklyOutput {
  /// Creates an output that keeps up to [capacity] records.
  TracklyMemoryOutput({this.capacity = 500})
    : assert(capacity > 0, 'capacity must be positive');

  /// The maximum number of records kept. The oldest are dropped first.
  final int capacity;

  final _records = ListQueue<TracklyRecord>();

  /// The kept records, oldest first.
  List<TracklyRecord> get records => List.unmodifiable(_records);

  /// Removes all kept records.
  void clear() => _records.clear();

  @override
  void write(TracklyRecord record) {
    if (_records.length >= capacity) _records.removeFirst();
    _records.addLast(record);
  }
}
