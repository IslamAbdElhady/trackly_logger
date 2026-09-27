/// A place in the source code, such as the line that logged a record.
class TracklyLocation {
  /// Creates a location.
  const TracklyLocation(this.uri, this.line, [this.column]);

  /// The file, e.g. `package:app/src/login_page.dart` or `file:///...`.
  final Uri uri;

  /// The 1-based line number.
  final int line;

  /// The 1-based column number, if known.
  final int? column;

  /// The file name, e.g. `login_page.dart`.
  String get fileName =>
      uri.pathSegments.isEmpty ? '$uri' : uri.pathSegments.last;

  /// The full location, e.g. `package:app/src/login_page.dart:42:7`.
  ///
  /// VS Code and Android Studio turn this into a link that opens the file at
  /// this line.
  String get link => column == null ? '$uri:$line' : '$uri:$line:$column';

  /// The short location, e.g. `login_page.dart:42`.
  @override
  String toString() => '$fileName:$line';

  @override
  bool operator ==(Object other) =>
      other is TracklyLocation &&
      other.uri == uri &&
      other.line == line &&
      other.column == column;

  @override
  int get hashCode => Object.hash(uri, line, column);
}
