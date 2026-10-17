/// A setting persisted by `PreferenceStore`: its key, the type of its value
/// and its default. Values are stored as JSON; [toJson] and [fromJson]
/// convert, and work as is for `bool`, `int`, `double` and `String`, nullable
/// or not.
class Preference<T> {
  /// Name a setting by [key], with [defaultValue] returned while unset.
  const Preference(this.key, {required this.defaultValue});

  /// The setting's name in the database. Per-source settings are prefixed
  /// with the source's `uniqueKey` and a `/`.
  final String key;

  /// The value while the setting is unset. Always a constant.
  final T defaultValue;

  /// Convert [value] to a JSON-encodable object.
  Object? toJson(T value) => value;

  /// Convert a decoded JSON object back to a value. Throws if [json] does not
  /// hold one.
  T fromJson(Object? json) => json as T;
}

/// A setting holding a list of strings.
class StringListPreference extends Preference<List<String>> {
  /// Name a list setting by [key], with [defaultValue] returned while unset.
  const StringListPreference(super.key, {required super.defaultValue});

  @override
  List<String> fromJson(Object? json) =>
      (json as List).cast<String>().toList();
}

/// A setting holding an enum value, stored by its name.
class EnumPreference<E extends Enum> extends Preference<E> {
  /// Name an enum setting by [key]. [values] are the enum's values, used to
  /// find a value by its name.
  const EnumPreference(super.key, this.values, {required super.defaultValue});

  /// Every value of the enum.
  final List<E> values;

  @override
  Object? toJson(E value) => value.name;

  @override
  E fromJson(Object? json) => values.byName(json as String);
}
