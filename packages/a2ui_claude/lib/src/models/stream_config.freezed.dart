// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StreamConfig {

/// Maximum tokens in the response.
 int get maxTokens;/// Connection timeout duration.
 Duration get timeout;/// Number of retry attempts for transient failures.
 int get retryAttempts;
/// Create a copy of StreamConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamConfigCopyWith<StreamConfig> get copyWith => _$StreamConfigCopyWithImpl<StreamConfig>(this as StreamConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamConfig&&(identical(other.maxTokens, maxTokens) || other.maxTokens == maxTokens)&&(identical(other.timeout, timeout) || other.timeout == timeout)&&(identical(other.retryAttempts, retryAttempts) || other.retryAttempts == retryAttempts));
}


@override
int get hashCode => Object.hash(runtimeType,maxTokens,timeout,retryAttempts);

@override
String toString() {
  return 'StreamConfig(maxTokens: $maxTokens, timeout: $timeout, retryAttempts: $retryAttempts)';
}


}

/// @nodoc
abstract mixin class $StreamConfigCopyWith<$Res>  {
  factory $StreamConfigCopyWith(StreamConfig value, $Res Function(StreamConfig) _then) = _$StreamConfigCopyWithImpl;
@useResult
$Res call({
 int maxTokens, Duration timeout, int retryAttempts
});




}
/// @nodoc
class _$StreamConfigCopyWithImpl<$Res>
    implements $StreamConfigCopyWith<$Res> {
  _$StreamConfigCopyWithImpl(this._self, this._then);

  final StreamConfig _self;
  final $Res Function(StreamConfig) _then;

/// Create a copy of StreamConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxTokens = null,Object? timeout = null,Object? retryAttempts = null,}) {
  return _then(_self.copyWith(
maxTokens: null == maxTokens ? _self.maxTokens : maxTokens // ignore: cast_nullable_to_non_nullable
as int,timeout: null == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as Duration,retryAttempts: null == retryAttempts ? _self.retryAttempts : retryAttempts // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StreamConfig].
extension StreamConfigPatterns on StreamConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreamConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreamConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreamConfig value)  $default,){
final _that = this;
switch (_that) {
case _StreamConfig():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreamConfig value)?  $default,){
final _that = this;
switch (_that) {
case _StreamConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int maxTokens,  Duration timeout,  int retryAttempts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreamConfig() when $default != null:
return $default(_that.maxTokens,_that.timeout,_that.retryAttempts);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int maxTokens,  Duration timeout,  int retryAttempts)  $default,) {final _that = this;
switch (_that) {
case _StreamConfig():
return $default(_that.maxTokens,_that.timeout,_that.retryAttempts);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int maxTokens,  Duration timeout,  int retryAttempts)?  $default,) {final _that = this;
switch (_that) {
case _StreamConfig() when $default != null:
return $default(_that.maxTokens,_that.timeout,_that.retryAttempts);case _:
  return null;

}
}

}

/// @nodoc


class _StreamConfig implements StreamConfig {
  const _StreamConfig({this.maxTokens = 4096, this.timeout = const Duration(seconds: 60), this.retryAttempts = 3});
  

/// Maximum tokens in the response.
@override@JsonKey() final  int maxTokens;
/// Connection timeout duration.
@override@JsonKey() final  Duration timeout;
/// Number of retry attempts for transient failures.
@override@JsonKey() final  int retryAttempts;

/// Create a copy of StreamConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreamConfigCopyWith<_StreamConfig> get copyWith => __$StreamConfigCopyWithImpl<_StreamConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreamConfig&&(identical(other.maxTokens, maxTokens) || other.maxTokens == maxTokens)&&(identical(other.timeout, timeout) || other.timeout == timeout)&&(identical(other.retryAttempts, retryAttempts) || other.retryAttempts == retryAttempts));
}


@override
int get hashCode => Object.hash(runtimeType,maxTokens,timeout,retryAttempts);

@override
String toString() {
  return 'StreamConfig(maxTokens: $maxTokens, timeout: $timeout, retryAttempts: $retryAttempts)';
}


}

/// @nodoc
abstract mixin class _$StreamConfigCopyWith<$Res> implements $StreamConfigCopyWith<$Res> {
  factory _$StreamConfigCopyWith(_StreamConfig value, $Res Function(_StreamConfig) _then) = __$StreamConfigCopyWithImpl;
@override @useResult
$Res call({
 int maxTokens, Duration timeout, int retryAttempts
});




}
/// @nodoc
class __$StreamConfigCopyWithImpl<$Res>
    implements _$StreamConfigCopyWith<$Res> {
  __$StreamConfigCopyWithImpl(this._self, this._then);

  final _StreamConfig _self;
  final $Res Function(_StreamConfig) _then;

/// Create a copy of StreamConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxTokens = null,Object? timeout = null,Object? retryAttempts = null,}) {
  return _then(_StreamConfig(
maxTokens: null == maxTokens ? _self.maxTokens : maxTokens // ignore: cast_nullable_to_non_nullable
as int,timeout: null == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as Duration,retryAttempts: null == retryAttempts ? _self.retryAttempts : retryAttempts // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
