import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:yuuna/utils.dart';

/// Stores a list of strings as a JSON array.
class StringListConverter extends TypeConverter<List<String>, String> {
  /// Create the converter.
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      List<String>.from(jsonDecode(fromDb) as List<dynamic>);

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// Stores a list of optional strings as a JSON array.
class NullableStringListConverter
    extends TypeConverter<List<String?>, String> {
  /// Create the converter.
  const NullableStringListConverter();

  @override
  List<String?> fromSql(String fromDb) =>
      List<String?>.from(jsonDecode(fromDb) as List<dynamic>);

  @override
  String toSql(List<String?> value) => jsonEncode(value);
}

/// Stores a profile's enhancements, field to slot to enhancement key, as JSON.
class EnhancementsColumnConverter
    extends TypeConverter<Map<String, Map<int, String>>, String> {
  /// Create the converter.
  const EnhancementsColumnConverter();

  @override
  Map<String, Map<int, String>> fromSql(String fromDb) =>
      EnhancementsConverter.decode(fromDb);

  @override
  String toSql(Map<String, Map<int, String>> value) =>
      EnhancementsConverter.encode(value);
}

/// Stores an instant as microseconds since the epoch, so that instants within
/// the same second keep their order. Drift's own `dateTime()` keeps seconds.
class MicrosecondsConverter extends TypeConverter<DateTime, int> {
  /// Create the converter.
  const MicrosecondsConverter();

  @override
  DateTime fromSql(int fromDb) => DateTime.fromMicrosecondsSinceEpoch(fromDb);

  @override
  int toSql(DateTime value) => value.microsecondsSinceEpoch;
}
