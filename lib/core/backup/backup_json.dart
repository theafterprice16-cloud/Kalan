import '../date/local_date.dart';

/// Thrown while reading a backup whose content does not have the shape
/// docs/YEDEK_BICIMI.md describes (a missing field, a wrong type, an
/// unknown value). Never carries a value from the file.
class BackupFormatException implements Exception {
  const BackupFormatException(this.field);

  /// Where the problem is ("plans[2].payments[0].dueDate").
  final String field;

  @override
  String toString() => 'BackupFormatException($field)';
}

/// "2026-11-19": a calendar day, the same everywhere.
String formatDay(LocalDate day) => day.toString();

/// "2026-11-19T07:30:05Z": a moment in UTC, to the second (the database
/// keeps seconds).
String formatInstant(DateTime moment) {
  final utc = moment.toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-'
      '${two(utc.day)}T${two(utc.hour)}:${two(utc.minute)}:'
      '${two(utc.second)}Z';
}

final _day = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
final _instant = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?Z$');

/// Typed reads from one JSON object of a backup. Fields it is not asked
/// for are ignored (a newer app may add some); a field it is asked for
/// must have the documented type.
class JsonFields {
  JsonFields(Object? value, this.path) : _map = _object(value, path);

  final Map<String, Object?> _map;

  /// The object as read (unknown fields included).
  Map<String, Object?> get raw => _map;

  /// Where this object is, for [BackupFormatException].
  final String path;

  static Map<String, Object?> _object(Object? value, String path) {
    if (value is Map<String, Object?>) return value;
    throw BackupFormatException(path);
  }

  String _at(String key) => path.isEmpty ? key : '$path.$key';

  Object? _value(String key, {required bool optional}) {
    final value = _map[key];
    if (value == null && !optional) throw BackupFormatException(_at(key));
    return value;
  }

  T _typed<T>(String key, {required bool optional}) {
    final value = _value(key, optional: optional);
    if (value is T) return value;
    throw BackupFormatException(_at(key));
  }

  String string(String key) => _typed<String>(key, optional: false);
  String? optionalString(String key) => _typed<String?>(key, optional: true);

  int integer(String key) => _typed<int>(key, optional: false);
  int? optionalInteger(String key) => _typed<int?>(key, optional: true);

  /// An amount in minor units: a whole number (never a fraction).
  int amount(String key) => integer(key);
  int? optionalAmount(String key) => optionalInteger(key);

  bool boolean(String key) => _typed<bool>(key, optional: false);

  LocalDate day(String key) => _parseDay(string(key), _at(key));
  LocalDate? optionalDay(String key) {
    final text = optionalString(key);
    return text == null ? null : _parseDay(text, _at(key));
  }

  DateTime instant(String key) => _parseInstant(string(key), _at(key));
  DateTime? optionalInstant(String key) {
    final text = optionalString(key);
    return text == null ? null : _parseInstant(text, _at(key));
  }

  /// An enum value written by its name.
  T name<T extends Enum>(String key, List<T> values) =>
      _byName(values, string(key), _at(key));
  T? optionalName<T extends Enum>(String key, List<T> values) {
    final text = optionalString(key);
    return text == null ? null : _byName(values, text, _at(key));
  }

  /// One of [allowed] (a value kept as text).
  String oneOf(String key, Set<String> allowed) {
    final text = string(key);
    if (!allowed.contains(text)) throw BackupFormatException(_at(key));
    return text;
  }

  JsonFields object(String key) =>
      JsonFields(_value(key, optional: false), _at(key));
  JsonFields? optionalObject(String key) {
    final value = _value(key, optional: true);
    return value == null ? null : JsonFields(value, _at(key));
  }

  /// A list of objects.
  List<JsonFields> objects(String key) {
    final list = _typed<List<Object?>>(key, optional: false);
    return [
      for (var i = 0; i < list.length; i++)
        JsonFields(list[i], '${_at(key)}[$i]'),
    ];
  }

  /// A list of whole numbers.
  List<int> ints(String key) {
    final list = _typed<List<Object?>>(key, optional: false);
    return [
      for (var i = 0; i < list.length; i++)
        if (list[i] case final int v)
          v
        else
          throw BackupFormatException('${_at(key)}[$i]'),
    ];
  }

  /// A list of calendar days.
  List<LocalDate> days(String key) {
    final list = _typed<List<Object?>>(key, optional: false);
    return [
      for (var i = 0; i < list.length; i++)
        if (list[i] case final String v)
          _parseDay(v, '${_at(key)}[$i]')
        else
          throw BackupFormatException('${_at(key)}[$i]'),
    ];
  }

  static T _byName<T extends Enum>(List<T> values, String name, String at) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    throw BackupFormatException(at);
  }

  static LocalDate _parseDay(String text, String at) {
    final m = _day.firstMatch(text);
    if (m == null) throw BackupFormatException(at);
    final (y, mo, d) = (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    if (mo < 1 || mo > 12 || d < 1 || d > LocalDate.daysInMonth(y, mo)) {
      throw BackupFormatException(at);
    }
    return LocalDate(y, mo, d);
  }

  static DateTime _parseInstant(String text, String at) {
    if (!_instant.hasMatch(text)) throw BackupFormatException(at);
    final parsed = DateTime.tryParse(text);
    if (parsed == null || !parsed.isUtc) throw BackupFormatException(at);
    return parsed;
  }
}
