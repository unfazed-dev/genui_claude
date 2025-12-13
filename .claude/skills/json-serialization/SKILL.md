---
name: json-serialization
description: Dart JSON serialization toolkit with json_serializable, freezed, and manual patterns. Use when creating data models, parsing API responses, handling JSON conversion, or implementing immutable classes.
---

# Dart JSON Serialization

## Quick Start

```yaml
# pubspec.yaml
dependencies:
  json_annotation: ^4.8.0
  freezed_annotation: ^2.4.0

dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
  freezed: ^2.4.0
```

```bash
# Generate code
dart run build_runner build --delete-conflicting-outputs

# Watch mode
dart run build_runner watch --delete-conflicting-outputs
```

## Package Comparison

| Feature | json_serializable | freezed |
|---------|-------------------|---------|
| JSON conversion | Yes | Yes |
| Immutability | Manual | Built-in |
| copyWith | Manual | Built-in |
| Equality | Manual | Built-in |
| Union types | No | Yes |
| Null safety | Yes | Yes |
| Setup complexity | Lower | Higher |

## json_serializable

### Basic Model

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

### Field Customization

```dart
@JsonSerializable()
class Product {
  final String id;

  @JsonKey(name: 'product_name')
  final String name;

  @JsonKey(name: 'price_cents')
  final int priceCents;

  @JsonKey(defaultValue: 0)
  final int quantity;

  @JsonKey(includeIfNull: false)
  final String? description;

  @JsonKey(ignore: true)
  final String? localCache;

  @JsonKey(fromJson: _parseDate, toJson: _dateToJson)
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.priceCents,
    this.quantity = 0,
    this.description,
    this.localCache,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  static DateTime _parseDate(String date) => DateTime.parse(date);
  static String _dateToJson(DateTime date) => date.toIso8601String();
}
```

### Nested Objects

```dart
@JsonSerializable(explicitToJson: true)
class Order {
  final String id;
  final User customer;
  final List<OrderItem> items;
  final Address? shippingAddress;

  Order({
    required this.id,
    required this.customer,
    required this.items,
    this.shippingAddress,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}

@JsonSerializable()
class OrderItem {
  final String productId;
  final int quantity;
  final int unitPrice;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}
```

### Enums

```dart
@JsonEnum(valueField: 'code')
enum OrderStatus {
  @JsonValue('pending')
  pending('pending'),

  @JsonValue('processing')
  processing('processing'),

  @JsonValue('shipped')
  shipped('shipped'),

  @JsonValue('delivered')
  delivered('delivered'),

  @JsonValue('cancelled')
  cancelled('cancelled');

  final String code;
  const OrderStatus(this.code);
}

@JsonSerializable()
class Order {
  final String id;
  final OrderStatus status;

  Order({required this.id, required this.status});

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}
```

### Generic Classes

```dart
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
}

// Usage
final response = ApiResponse<User>.fromJson(
  jsonData,
  (json) => User.fromJson(json as Map<String, dynamic>),
);
```

## Freezed

### Basic Freezed Model

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    @Default(false) bool isVerified,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### With Custom Methods

```dart
@freezed
class User with _$User {
  const User._(); // Private constructor for custom methods

  const factory User({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
  }) = _User;

  // Custom getter
  String get fullName => '$firstName $lastName';

  // Custom method
  bool get hasValidEmail => email.contains('@');

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### Union Types (Sealed Classes)

```dart
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(User user) = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.error(String message) = AuthError;

  factory AuthState.fromJson(Map<String, dynamic> json) =>
      _$AuthStateFromJson(json);
}

// Usage with pattern matching
String getMessage(AuthState state) {
  return switch (state) {
    AuthInitial() => 'Welcome',
    AuthLoading() => 'Loading...',
    AuthAuthenticated(:final user) => 'Hello, ${user.name}',
    AuthUnauthenticated() => 'Please log in',
    AuthError(:final message) => 'Error: $message',
  };
}

// Or using when/map
String getMessage2(AuthState state) {
  return state.when(
    initial: () => 'Welcome',
    loading: () => 'Loading...',
    authenticated: (user) => 'Hello, ${user.name}',
    unauthenticated: () => 'Please log in',
    error: (message) => 'Error: $message',
  );
}
```

### JSON with Union Types

```dart
@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
sealed class PaymentMethod with _$PaymentMethod {
  const factory PaymentMethod.creditCard({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
  }) = CreditCard;

  const factory PaymentMethod.bankTransfer({
    required String accountNumber,
    required String routingNumber,
  }) = BankTransfer;

  const factory PaymentMethod.paypal({
    required String email,
  }) = Paypal;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json);
}

// JSON output:
// {"type": "credit_card", "cardNumber": "...", ...}
// {"type": "bank_transfer", "accountNumber": "...", ...}
```

### copyWith

```dart
@freezed
class Settings with _$Settings {
  const factory Settings({
    required String theme,
    required String language,
    @Default(true) bool notificationsEnabled,
    @Default(14) int fontSize,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}

// Usage
final settings = Settings(theme: 'dark', language: 'en');
final updated = settings.copyWith(fontSize: 16);
final withNotifications = settings.copyWith(notificationsEnabled: false);
```

### Deep copyWith

```dart
@freezed
class Company with _$Company {
  const factory Company({
    required String name,
    required Address address,
  }) = _Company;

  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);
}

@freezed
class Address with _$Address {
  const factory Address({
    required String street,
    required String city,
    required String country,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
}

// Deep copy
final company = Company(
  name: 'Acme',
  address: Address(street: '123 Main', city: 'NYC', country: 'USA'),
);
final updated = company.copyWith.address(city: 'LA');
```

## Custom Converters

### DateTime Converter

```dart
class DateTimeConverter implements JsonConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json);

  @override
  String toJson(DateTime object) => object.toIso8601String();
}

// Unix timestamp
class UnixTimestampConverter implements JsonConverter<DateTime, int> {
  const UnixTimestampConverter();

  @override
  DateTime fromJson(int json) =>
      DateTime.fromMillisecondsSinceEpoch(json * 1000);

  @override
  int toJson(DateTime object) => object.millisecondsSinceEpoch ~/ 1000;
}

@JsonSerializable()
class Event {
  final String id;

  @DateTimeConverter()
  final DateTime startDate;

  @UnixTimestampConverter()
  final DateTime createdAt;

  Event({required this.id, required this.startDate, required this.createdAt});

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
  Map<String, dynamic> toJson() => _$EventToJson(this);
}
```

### Color Converter

```dart
class ColorConverter implements JsonConverter<Color, String> {
  const ColorConverter();

  @override
  Color fromJson(String json) {
    final hex = json.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  String toJson(Color object) {
    return '#${object.value.toRadixString(16).substring(2)}';
  }
}
```

### Nullable Converter

```dart
class NullableDateTimeConverter
    implements JsonConverter<DateTime?, String?> {
  const NullableDateTimeConverter();

  @override
  DateTime? fromJson(String? json) =>
      json != null ? DateTime.parse(json) : null;

  @override
  String? toJson(DateTime? object) => object?.toIso8601String();
}
```

## build.yaml Configuration

```yaml
# build.yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          # Include all fields even if null
          include_if_null: false
          # Use explicit toJson for nested objects
          explicit_to_json: true
          # Field rename strategy
          field_rename: snake
          # Generate fromJson/toJson in separate file
          create_factory: true
          create_to_json: true

      freezed:
        options:
          # Generate toString
          to_string: true
          # Generate == and hashCode
          equal: true
          # Generate copyWith
          copy_with: true
          # Make classes immutable
          immutable: true
          # Union key for JSON
          union_key: type
          # Union value case
          union_value_case: snake
```

## Manual JSON (No Code Gen)

```dart
class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Manual equality
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          id == other.id &&
          name == other.name &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, name, email);

  // Manual copyWith
  User copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `part` directive not found | Run `build_runner build` |
| `_$ClassName` not found | Check `part` directive matches file name |
| Nested object not serializing | Add `explicitToJson: true` |
| Enum parsing fails | Use `@JsonEnum` or `@JsonValue` |
| Generic type error | Use `genericArgumentFactories: true` |
| Freezed union type error | Check `unionKey` configuration |
| Build conflicts | Use `--delete-conflicting-outputs` |

## Resources

- **Freezed Patterns**: See [references/freezed-patterns.md](references/freezed-patterns.md)
- **Custom Converters**: See [references/custom-converters.md](references/custom-converters.md)
