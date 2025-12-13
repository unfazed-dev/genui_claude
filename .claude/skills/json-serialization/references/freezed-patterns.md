# Freezed Patterns

## Union Types for API States

### Request State

```dart
@freezed
sealed class RequestState<T> with _$RequestState<T> {
  const factory RequestState.initial() = RequestInitial<T>;
  const factory RequestState.loading() = RequestLoading<T>;
  const factory RequestState.success(T data) = RequestSuccess<T>;
  const factory RequestState.error(String message, {Object? exception}) =
      RequestError<T>;
}

// Usage in ViewModel
class UserViewModel extends ChangeNotifier {
  RequestState<User> _userState = const RequestState.initial();
  RequestState<User> get userState => _userState;

  Future<void> fetchUser(String id) async {
    _userState = const RequestState.loading();
    notifyListeners();

    try {
      final user = await _repository.getUser(id);
      _userState = RequestState.success(user);
    } catch (e) {
      _userState = RequestState.error(e.toString(), exception: e);
    }
    notifyListeners();
  }
}

// Usage in Widget
Widget build(BuildContext context) {
  return userState.when(
    initial: () => const SizedBox.shrink(),
    loading: () => const CircularProgressIndicator(),
    success: (user) => UserCard(user: user),
    error: (message, _) => ErrorWidget(message: message),
  );
}
```

### Result Type

```dart
@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = ResultFailure<T>;
}

@freezed
sealed class Failure with _$Failure {
  const factory Failure.network(String message) = NetworkFailure;
  const factory Failure.server(int code, String message) = ServerFailure;
  const factory Failure.validation(Map<String, String> errors) =
      ValidationFailure;
  const factory Failure.unknown(Object error) = UnknownFailure;
}

// Usage
Future<Result<User>> login(String email, String password) async {
  try {
    final user = await _api.login(email, password);
    return Result.success(user);
  } on NetworkException catch (e) {
    return Result.failure(Failure.network(e.message));
  } on ApiException catch (e) {
    return Result.failure(Failure.server(e.code, e.message));
  } catch (e) {
    return Result.failure(Failure.unknown(e));
  }
}

// Handle result
final result = await login(email, password);
result.when(
  success: (user) => navigateToHome(user),
  failure: (failure) => failure.when(
    network: (msg) => showNetworkError(msg),
    server: (code, msg) => showServerError(code, msg),
    validation: (errors) => showValidationErrors(errors),
    unknown: (e) => showGenericError(),
  ),
);
```

### Form State

```dart
@freezed
sealed class FormState with _$FormState {
  const factory FormState.initial() = FormInitial;
  const factory FormState.editing({
    required Map<String, String> values,
    @Default({}) Map<String, String> errors,
  }) = FormEditing;
  const factory FormState.submitting(Map<String, String> values) =
      FormSubmitting;
  const factory FormState.success() = FormSuccess;
  const factory FormState.failure(String message) = FormFailure;
}

// Form controller
class FormController extends ChangeNotifier {
  FormState _state = const FormState.initial();
  FormState get state => _state;

  void updateField(String field, String value) {
    _state = _state.maybeMap(
      editing: (s) => s.copyWith(
        values: {...s.values, field: value},
        errors: {...s.errors}..remove(field),
      ),
      orElse: () => FormState.editing(values: {field: value}),
    );
    notifyListeners();
  }

  Future<void> submit() async {
    final values = _state.maybeMap(
      editing: (s) => s.values,
      orElse: () => <String, String>{},
    );

    _state = FormState.submitting(values);
    notifyListeners();

    try {
      await _api.submit(values);
      _state = const FormState.success();
    } catch (e) {
      _state = FormState.failure(e.toString());
    }
    notifyListeners();
  }
}
```

## Pagination

```dart
@freezed
class PaginatedList<T> with _$PaginatedList<T> {
  const factory PaginatedList({
    required List<T> items,
    required int currentPage,
    required int totalPages,
    required int totalItems,
    @Default(false) bool isLoadingMore,
  }) = _PaginatedList<T>;

  factory PaginatedList.empty() => PaginatedList(
        items: [],
        currentPage: 0,
        totalPages: 0,
        totalItems: 0,
      );
}

// With custom methods
@freezed
class PaginatedList<T> with _$PaginatedList<T> {
  const PaginatedList._();

  const factory PaginatedList({
    required List<T> items,
    required int currentPage,
    required int totalPages,
    required int totalItems,
    @Default(false) bool isLoadingMore,
  }) = _PaginatedList<T>;

  bool get hasMore => currentPage < totalPages;
  bool get isEmpty => items.isEmpty;
  int get itemCount => items.length;

  PaginatedList<T> appendPage(List<T> newItems, int page) {
    return copyWith(
      items: [...items, ...newItems],
      currentPage: page,
      isLoadingMore: false,
    );
  }
}
```

## Configuration Objects

```dart
@freezed
class AppConfig with _$AppConfig {
  const factory AppConfig({
    required String apiBaseUrl,
    required String environment,
    @Default(30) int timeoutSeconds,
    @Default(3) int maxRetries,
    @Default(false) bool enableLogging,
    @Default(false) bool enableAnalytics,
    Map<String, String>? featureFlags,
  }) = _AppConfig;

  factory AppConfig.development() => const AppConfig(
        apiBaseUrl: 'http://localhost:8080',
        environment: 'development',
        enableLogging: true,
      );

  factory AppConfig.staging() => const AppConfig(
        apiBaseUrl: 'https://staging-api.example.com',
        environment: 'staging',
        enableLogging: true,
        enableAnalytics: true,
      );

  factory AppConfig.production() => const AppConfig(
        apiBaseUrl: 'https://api.example.com',
        environment: 'production',
        enableAnalytics: true,
      );

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
}
```

## Entity with Validation

```dart
@freezed
class Email with _$Email {
  const Email._();

  const factory Email._(String value) = _Email;

  factory Email.create(String value) {
    if (!_isValid(value)) {
      throw ArgumentError('Invalid email: $value');
    }
    return Email._(value.toLowerCase().trim());
  }

  factory Email.tryCreate(String value) {
    if (!_isValid(value)) {
      return Email._('');
    }
    return Email._(value.toLowerCase().trim());
  }

  static bool _isValid(String value) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
  }

  bool get isValid => value.isNotEmpty;

  factory Email.fromJson(Map<String, dynamic> json) => _$EmailFromJson(json);
}
```

## Event Sourcing

```dart
@freezed
sealed class DomainEvent with _$DomainEvent {
  const factory DomainEvent.userCreated({
    required String userId,
    required String email,
    required DateTime timestamp,
  }) = UserCreated;

  const factory DomainEvent.userUpdated({
    required String userId,
    required Map<String, dynamic> changes,
    required DateTime timestamp,
  }) = UserUpdated;

  const factory DomainEvent.userDeleted({
    required String userId,
    required DateTime timestamp,
  }) = UserDeleted;

  factory DomainEvent.fromJson(Map<String, dynamic> json) =>
      _$DomainEventFromJson(json);
}

// Event handler
void handleEvent(DomainEvent event) {
  event.when(
    userCreated: (userId, email, timestamp) {
      // Handle user creation
    },
    userUpdated: (userId, changes, timestamp) {
      // Handle user update
    },
    userDeleted: (userId, timestamp) {
      // Handle user deletion
    },
  );
}
```

## Nested Unions

```dart
@freezed
sealed class Message with _$Message {
  const factory Message.text({
    required String content,
    required DateTime timestamp,
  }) = TextMessage;

  const factory Message.image({
    required String url,
    required int width,
    required int height,
    required DateTime timestamp,
  }) = ImageMessage;

  const factory Message.file({
    required String url,
    required String fileName,
    required int size,
    required DateTime timestamp,
  }) = FileMessage;

  const factory Message.system({
    required SystemMessageType type,
    required DateTime timestamp,
  }) = SystemMessage;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

@freezed
sealed class SystemMessageType with _$SystemMessageType {
  const factory SystemMessageType.userJoined(String userId) = UserJoined;
  const factory SystemMessageType.userLeft(String userId) = UserLeft;
  const factory SystemMessageType.roomCreated() = RoomCreated;

  factory SystemMessageType.fromJson(Map<String, dynamic> json) =>
      _$SystemMessageTypeFromJson(json);
}
```

## Using maybeWhen and maybeMap

```dart
@freezed
sealed class Status with _$Status {
  const factory Status.idle() = StatusIdle;
  const factory Status.loading() = StatusLoading;
  const factory Status.success(String data) = StatusSuccess;
  const factory Status.error(String message) = StatusError;
}

// maybeWhen - returns null for unhandled cases
String? getErrorMessage(Status status) {
  return status.maybeWhen(
    error: (message) => message,
    orElse: () => null,
  );
}

// maybeMap - returns null for unhandled cases
StatusError? asError(Status status) {
  return status.maybeMap(
    error: (e) => e,
    orElse: () => null,
  );
}

// whenOrNull - no orElse required
void showLoadingIfNeeded(Status status) {
  status.whenOrNull(
    loading: () => showLoadingDialog(),
  );
}

// mapOrNull - no orElse required
StatusSuccess? getSuccess(Status status) {
  return status.mapOrNull(
    success: (s) => s,
  );
}
```

## Assert Statements

```dart
@freezed
class PositiveNumber with _$PositiveNumber {
  @Assert('value > 0', 'value must be positive')
  const factory PositiveNumber(int value) = _PositiveNumber;
}

@freezed
class DateRange with _$DateRange {
  @Assert('end.isAfter(start)', 'end must be after start')
  const factory DateRange({
    required DateTime start,
    required DateTime end,
  }) = _DateRange;
}

@freezed
class Password with _$Password {
  @Assert('value.length >= 8', 'Password must be at least 8 characters')
  @Assert(
    'RegExp(r"[A-Z]").hasMatch(value)',
    'Password must contain uppercase letter',
  )
  @Assert(
    'RegExp(r"[0-9]").hasMatch(value)',
    'Password must contain a number',
  )
  const factory Password(String value) = _Password;
}
```

## Private Constructors

```dart
@freezed
class User with _$User {
  // Private constructor enables custom methods
  const User._();

  // All factory constructors
  const factory User({
    required String id,
    required String name,
    required String email,
  }) = _User;

  // Named constructors
  factory User.guest() => const User(
        id: 'guest',
        name: 'Guest User',
        email: 'guest@example.com',
      );

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  // Custom getters
  String get initials => name.split(' ').map((n) => n[0]).take(2).join();

  // Custom methods
  bool get isGuest => id == 'guest';

  User updateEmail(String newEmail) => copyWith(email: newEmail);
}
```
