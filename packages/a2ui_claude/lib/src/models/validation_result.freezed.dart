// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'validation_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ValidationResult {

/// Whether the input is valid.
 bool get isValid;/// List of validation errors (empty if valid).
 List<ValidationError> get errors;
/// Create a copy of ValidationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValidationResultCopyWith<ValidationResult> get copyWith => _$ValidationResultCopyWithImpl<ValidationResult>(this as ValidationResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationResult&&(identical(other.isValid, isValid) || other.isValid == isValid)&&const DeepCollectionEquality().equals(other.errors, errors));
}


@override
int get hashCode => Object.hash(runtimeType,isValid,const DeepCollectionEquality().hash(errors));

@override
String toString() {
  return 'ValidationResult(isValid: $isValid, errors: $errors)';
}


}

/// @nodoc
abstract mixin class $ValidationResultCopyWith<$Res>  {
  factory $ValidationResultCopyWith(ValidationResult value, $Res Function(ValidationResult) _then) = _$ValidationResultCopyWithImpl;
@useResult
$Res call({
 bool isValid, List<ValidationError> errors
});




}
/// @nodoc
class _$ValidationResultCopyWithImpl<$Res>
    implements $ValidationResultCopyWith<$Res> {
  _$ValidationResultCopyWithImpl(this._self, this._then);

  final ValidationResult _self;
  final $Res Function(ValidationResult) _then;

/// Create a copy of ValidationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isValid = null,Object? errors = null,}) {
  return _then(_self.copyWith(
isValid: null == isValid ? _self.isValid : isValid // ignore: cast_nullable_to_non_nullable
as bool,errors: null == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as List<ValidationError>,
  ));
}

}


/// Adds pattern-matching-related methods to [ValidationResult].
extension ValidationResultPatterns on ValidationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ValidationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ValidationResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ValidationResult value)  $default,){
final _that = this;
switch (_that) {
case _ValidationResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ValidationResult value)?  $default,){
final _that = this;
switch (_that) {
case _ValidationResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isValid,  List<ValidationError> errors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ValidationResult() when $default != null:
return $default(_that.isValid,_that.errors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isValid,  List<ValidationError> errors)  $default,) {final _that = this;
switch (_that) {
case _ValidationResult():
return $default(_that.isValid,_that.errors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isValid,  List<ValidationError> errors)?  $default,) {final _that = this;
switch (_that) {
case _ValidationResult() when $default != null:
return $default(_that.isValid,_that.errors);case _:
  return null;

}
}

}

/// @nodoc


class _ValidationResult extends ValidationResult {
  const _ValidationResult({required this.isValid, required final  List<ValidationError> errors}): _errors = errors,super._();
  

/// Whether the input is valid.
@override final  bool isValid;
/// List of validation errors (empty if valid).
 final  List<ValidationError> _errors;
/// List of validation errors (empty if valid).
@override List<ValidationError> get errors {
  if (_errors is EqualUnmodifiableListView) return _errors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_errors);
}


/// Create a copy of ValidationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValidationResultCopyWith<_ValidationResult> get copyWith => __$ValidationResultCopyWithImpl<_ValidationResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValidationResult&&(identical(other.isValid, isValid) || other.isValid == isValid)&&const DeepCollectionEquality().equals(other._errors, _errors));
}


@override
int get hashCode => Object.hash(runtimeType,isValid,const DeepCollectionEquality().hash(_errors));

@override
String toString() {
  return 'ValidationResult(isValid: $isValid, errors: $errors)';
}


}

/// @nodoc
abstract mixin class _$ValidationResultCopyWith<$Res> implements $ValidationResultCopyWith<$Res> {
  factory _$ValidationResultCopyWith(_ValidationResult value, $Res Function(_ValidationResult) _then) = __$ValidationResultCopyWithImpl;
@override @useResult
$Res call({
 bool isValid, List<ValidationError> errors
});




}
/// @nodoc
class __$ValidationResultCopyWithImpl<$Res>
    implements _$ValidationResultCopyWith<$Res> {
  __$ValidationResultCopyWithImpl(this._self, this._then);

  final _ValidationResult _self;
  final $Res Function(_ValidationResult) _then;

/// Create a copy of ValidationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isValid = null,Object? errors = null,}) {
  return _then(_ValidationResult(
isValid: null == isValid ? _self.isValid : isValid // ignore: cast_nullable_to_non_nullable
as bool,errors: null == errors ? _self._errors : errors // ignore: cast_nullable_to_non_nullable
as List<ValidationError>,
  ));
}


}

// dart format on
