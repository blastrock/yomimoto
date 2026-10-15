import 'dart:convert';

/// A type converter for a general purpose key-value map for conversion to a
/// primitive the database can store.
class EnhancementsConverter {
  /// Decodes the JSON stored in the database.
  static Map<String, Map<int, String>> decode(String object) {
    Map<String, dynamic> map = jsonDecode(object);

    return map.map(
      (k, e) => MapEntry(
        k,
        (e as Map<String, dynamic>).map(
          (k, e) => MapEntry(int.parse(k), e as String),
        ),
      ),
    );
  }

  /// Encodes for the database as JSON.
  static String encode(Map<String, Map<int, String>> object) {
    Map<String, dynamic> map = object
        .map((k, e) => MapEntry(k, e.map((k, e) => MapEntry(k.toString(), e))));
    return jsonEncode(map);
  }
}
