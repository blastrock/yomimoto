import 'dart:convert';

/// A type converter for a general purpose key-value map for conversion to a
/// primitive the database can store.
class QuickActionsConverter {
  /// Decodes the JSON stored in the database.
  static Map<int, String> decode(String object) {
    Map<dynamic, dynamic> json = jsonDecode(object);

    return json.map(
      (k, e) => MapEntry(int.parse(k), e as String),
    );
  }

  /// Encodes for the database as JSON.
  static String encode(Map<int, String> object) {
    return jsonEncode(object.map((k, e) => MapEntry(k.toString(), e)));
  }
}
