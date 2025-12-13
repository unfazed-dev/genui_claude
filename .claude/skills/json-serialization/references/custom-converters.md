# Custom JSON Converters

## JsonConverter Interface

```dart
abstract class JsonConverter<T, S> {
  const JsonConverter();

  /// Convert from JSON value to Dart type
  T fromJson(S json);

  /// Convert from Dart type to JSON value
  S toJson(T object);
}
```

## DateTime Converters

### ISO 8601 String

```dart
class Iso8601DateTimeConverter implements JsonConverter<DateTime, String> {
  const Iso8601DateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json);

  @override
  String toJson(DateTime object) => object.toIso8601String();
}

// Nullable version
class NullableIso8601DateTimeConverter
    implements JsonConverter<DateTime?, String?> {
  const NullableIso8601DateTimeConverter();

  @override
  DateTime? fromJson(String? json) => json != null ? DateTime.parse(json) : null;

  @override
  String? toJson(DateTime? object) => object?.toIso8601String();
}
```

### Unix Timestamp (Seconds)

```dart
class UnixTimestampConverter implements JsonConverter<DateTime, int> {
  const UnixTimestampConverter();

  @override
  DateTime fromJson(int json) =>
      DateTime.fromMillisecondsSinceEpoch(json * 1000);

  @override
  int toJson(DateTime object) => object.millisecondsSinceEpoch ~/ 1000;
}
```

### Unix Timestamp (Milliseconds)

```dart
class UnixMillisConverter implements JsonConverter<DateTime, int> {
  const UnixMillisConverter();

  @override
  DateTime fromJson(int json) => DateTime.fromMillisecondsSinceEpoch(json);

  @override
  int toJson(DateTime object) => object.millisecondsSinceEpoch;
}
```

### Flexible Date Parser

```dart
class FlexibleDateTimeConverter implements JsonConverter<DateTime, dynamic> {
  const FlexibleDateTimeConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json is int) {
      // Unix timestamp
      return DateTime.fromMillisecondsSinceEpoch(
        json > 9999999999 ? json : json * 1000,
      );
    }
    if (json is String) {
      return DateTime.parse(json);
    }
    throw FormatException('Cannot parse DateTime from $json');
  }

  @override
  String toJson(DateTime object) => object.toIso8601String();
}
```

## Duration Converters

### Duration as Seconds

```dart
class DurationSecondsConverter implements JsonConverter<Duration, int> {
  const DurationSecondsConverter();

  @override
  Duration fromJson(int json) => Duration(seconds: json);

  @override
  int toJson(Duration object) => object.inSeconds;
}
```

### Duration as ISO 8601

```dart
class IsoDurationConverter implements JsonConverter<Duration, String> {
  const IsoDurationConverter();

  @override
  Duration fromJson(String json) {
    // Parse ISO 8601 duration: PT1H30M45S
    final regex = RegExp(
      r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?',
    );
    final match = regex.firstMatch(json);
    if (match == null) throw FormatException('Invalid duration: $json');

    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    final seconds = double.tryParse(match.group(3) ?? '') ?? 0;

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds.floor(),
      milliseconds: ((seconds % 1) * 1000).round(),
    );
  }

  @override
  String toJson(Duration object) {
    final hours = object.inHours;
    final minutes = object.inMinutes.remainder(60);
    final seconds = object.inSeconds.remainder(60);

    final buffer = StringBuffer('PT');
    if (hours > 0) buffer.write('${hours}H');
    if (minutes > 0) buffer.write('${minutes}M');
    if (seconds > 0) buffer.write('${seconds}S');

    return buffer.isEmpty ? 'PT0S' : buffer.toString();
  }
}
```

## Color Converters

### Hex String

```dart
class HexColorConverter implements JsonConverter<Color, String> {
  const HexColorConverter();

  @override
  Color fromJson(String json) {
    final hex = json.replaceFirst('#', '').replaceFirst('0x', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  String toJson(Color object) {
    return '#${object.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
```

### RGBA Object

```dart
class RgbaColorConverter implements JsonConverter<Color, Map<String, dynamic>> {
  const RgbaColorConverter();

  @override
  Color fromJson(Map<String, dynamic> json) {
    return Color.fromARGB(
      ((json['a'] as num? ?? 1.0) * 255).round(),
      json['r'] as int,
      json['g'] as int,
      json['b'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson(Color object) {
    return {
      'r': object.red,
      'g': object.green,
      'b': object.blue,
      'a': object.opacity,
    };
  }
}
```

## Uri Converter

```dart
class UriConverter implements JsonConverter<Uri, String> {
  const UriConverter();

  @override
  Uri fromJson(String json) => Uri.parse(json);

  @override
  String toJson(Uri object) => object.toString();
}

class NullableUriConverter implements JsonConverter<Uri?, String?> {
  const NullableUriConverter();

  @override
  Uri? fromJson(String? json) => json != null ? Uri.parse(json) : null;

  @override
  String? toJson(Uri? object) => object?.toString();
}
```

## BigInt Converter

```dart
class BigIntConverter implements JsonConverter<BigInt, String> {
  const BigIntConverter();

  @override
  BigInt fromJson(String json) => BigInt.parse(json);

  @override
  String toJson(BigInt object) => object.toString();
}
```

## Decimal/Money Converters

```dart
// Using decimal package
class DecimalConverter implements JsonConverter<Decimal, String> {
  const DecimalConverter();

  @override
  Decimal fromJson(String json) => Decimal.parse(json);

  @override
  String toJson(Decimal object) => object.toString();
}

// Money as cents (int)
class MoneyCentsConverter implements JsonConverter<double, int> {
  const MoneyCentsConverter();

  @override
  double fromJson(int json) => json / 100;

  @override
  int toJson(double object) => (object * 100).round();
}

// Money from string
class MoneyStringConverter implements JsonConverter<double, String> {
  const MoneyStringConverter();

  @override
  double fromJson(String json) => double.parse(json.replaceAll(',', ''));

  @override
  String toJson(double object) => object.toStringAsFixed(2);
}
```

## Enum Converters

### String Enum with Custom Values

```dart
class OrderStatusConverter implements JsonConverter<OrderStatus, String> {
  const OrderStatusConverter();

  static const _mapping = {
    'PENDING': OrderStatus.pending,
    'IN_PROGRESS': OrderStatus.inProgress,
    'COMPLETED': OrderStatus.completed,
    'CANCELLED': OrderStatus.cancelled,
  };

  @override
  OrderStatus fromJson(String json) {
    return _mapping[json] ??
        (throw ArgumentError('Unknown status: $json'));
  }

  @override
  String toJson(OrderStatus object) {
    return _mapping.entries
        .firstWhere((e) => e.value == object)
        .key;
  }
}
```

### Int Enum

```dart
class PriorityConverter implements JsonConverter<Priority, int> {
  const PriorityConverter();

  @override
  Priority fromJson(int json) => Priority.values[json];

  @override
  int toJson(Priority object) => object.index;
}
```

## List Converters

### CSV String to List

```dart
class CsvListConverter implements JsonConverter<List<String>, String> {
  const CsvListConverter();

  @override
  List<String> fromJson(String json) =>
      json.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  @override
  String toJson(List<String> object) => object.join(',');
}
```

### List of Custom Objects

```dart
class UsersListConverter implements JsonConverter<List<User>, List<dynamic>> {
  const UsersListConverter();

  @override
  List<User> fromJson(List<dynamic> json) {
    return json
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic> toJson(List<User> object) {
    return object.map((e) => e.toJson()).toList();
  }
}
```

## Map Converters

### String Keys to Int Keys

```dart
class StringToIntMapConverter
    implements JsonConverter<Map<int, String>, Map<String, dynamic>> {
  const StringToIntMapConverter();

  @override
  Map<int, String> fromJson(Map<String, dynamic> json) {
    return json.map((key, value) => MapEntry(int.parse(key), value as String));
  }

  @override
  Map<String, dynamic> toJson(Map<int, String> object) {
    return object.map((key, value) => MapEntry(key.toString(), value));
  }
}
```

## Boolean Converters

### Int to Bool

```dart
class IntBoolConverter implements JsonConverter<bool, int> {
  const IntBoolConverter();

  @override
  bool fromJson(int json) => json != 0;

  @override
  int toJson(bool object) => object ? 1 : 0;
}
```

### String to Bool

```dart
class StringBoolConverter implements JsonConverter<bool, String> {
  const StringBoolConverter();

  @override
  bool fromJson(String json) {
    return json.toLowerCase() == 'true' ||
        json == '1' ||
        json.toLowerCase() == 'yes';
  }

  @override
  String toJson(bool object) => object.toString();
}
```

## Flexible/Polymorphic Converters

### Dynamic Type Converter

```dart
class FlexibleIntConverter implements JsonConverter<int, dynamic> {
  const FlexibleIntConverter();

  @override
  int fromJson(dynamic json) {
    if (json is int) return json;
    if (json is String) return int.parse(json);
    if (json is double) return json.round();
    throw FormatException('Cannot convert $json to int');
  }

  @override
  dynamic toJson(int object) => object;
}
```

### Safe Parse Converter

```dart
class SafeIntConverter implements JsonConverter<int, dynamic> {
  final int defaultValue;

  const SafeIntConverter({this.defaultValue = 0});

  @override
  int fromJson(dynamic json) {
    if (json == null) return defaultValue;
    if (json is int) return json;
    if (json is String) return int.tryParse(json) ?? defaultValue;
    if (json is double) return json.round();
    return defaultValue;
  }

  @override
  dynamic toJson(int object) => object;
}
```

## Using Converters

### With @JsonKey

```dart
@JsonSerializable()
class Event {
  final String id;

  @Iso8601DateTimeConverter()
  final DateTime startDate;

  @UnixTimestampConverter()
  final DateTime createdAt;

  @HexColorConverter()
  final Color primaryColor;

  @DurationSecondsConverter()
  final Duration duration;

  Event({...});

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
  Map<String, dynamic> toJson() => _$EventToJson(this);
}
```

### With Freezed

```dart
@freezed
class Event with _$Event {
  const factory Event({
    required String id,
    @Iso8601DateTimeConverter() required DateTime startDate,
    @UnixTimestampConverter() required DateTime createdAt,
    @HexColorConverter() required Color primaryColor,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}
```

### Global Converters in build.yaml

```yaml
# build.yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          # Use custom DateTime handling globally
          any_map: false
          checked: true
```
