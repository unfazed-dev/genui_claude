// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'parse_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ParseResult {

/// Parsed A2UI messages from tool_use blocks.
 List<A2uiMessageData> get a2uiMessages;/// Combined text content from text blocks.
 String get textContent;/// Whether any tool_use blocks were found.
 bool get hasToolUse;
/// Create a copy of ParseResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParseResultCopyWith<ParseResult> get copyWith => _$ParseResultCopyWithImpl<ParseResult>(this as ParseResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParseResult&&const DeepCollectionEquality().equals(other.a2uiMessages, a2uiMessages)&&(identical(other.textContent, textContent) || other.textContent == textContent)&&(identical(other.hasToolUse, hasToolUse) || other.hasToolUse == hasToolUse));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(a2uiMessages),textContent,hasToolUse);

@override
String toString() {
  return 'ParseResult(a2uiMessages: $a2uiMessages, textContent: $textContent, hasToolUse: $hasToolUse)';
}


}

/// @nodoc
abstract mixin class $ParseResultCopyWith<$Res>  {
  factory $ParseResultCopyWith(ParseResult value, $Res Function(ParseResult) _then) = _$ParseResultCopyWithImpl;
@useResult
$Res call({
 List<A2uiMessageData> a2uiMessages, String textContent, bool hasToolUse
});




}
/// @nodoc
class _$ParseResultCopyWithImpl<$Res>
    implements $ParseResultCopyWith<$Res> {
  _$ParseResultCopyWithImpl(this._self, this._then);

  final ParseResult _self;
  final $Res Function(ParseResult) _then;

/// Create a copy of ParseResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? a2uiMessages = null,Object? textContent = null,Object? hasToolUse = null,}) {
  return _then(_self.copyWith(
a2uiMessages: null == a2uiMessages ? _self.a2uiMessages : a2uiMessages // ignore: cast_nullable_to_non_nullable
as List<A2uiMessageData>,textContent: null == textContent ? _self.textContent : textContent // ignore: cast_nullable_to_non_nullable
as String,hasToolUse: null == hasToolUse ? _self.hasToolUse : hasToolUse // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ParseResult].
extension ParseResultPatterns on ParseResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParseResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParseResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParseResult value)  $default,){
final _that = this;
switch (_that) {
case _ParseResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParseResult value)?  $default,){
final _that = this;
switch (_that) {
case _ParseResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<A2uiMessageData> a2uiMessages,  String textContent,  bool hasToolUse)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParseResult() when $default != null:
return $default(_that.a2uiMessages,_that.textContent,_that.hasToolUse);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<A2uiMessageData> a2uiMessages,  String textContent,  bool hasToolUse)  $default,) {final _that = this;
switch (_that) {
case _ParseResult():
return $default(_that.a2uiMessages,_that.textContent,_that.hasToolUse);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<A2uiMessageData> a2uiMessages,  String textContent,  bool hasToolUse)?  $default,) {final _that = this;
switch (_that) {
case _ParseResult() when $default != null:
return $default(_that.a2uiMessages,_that.textContent,_that.hasToolUse);case _:
  return null;

}
}

}

/// @nodoc


class _ParseResult extends ParseResult {
  const _ParseResult({required final  List<A2uiMessageData> a2uiMessages, required this.textContent, required this.hasToolUse}): _a2uiMessages = a2uiMessages,super._();
  

/// Parsed A2UI messages from tool_use blocks.
 final  List<A2uiMessageData> _a2uiMessages;
/// Parsed A2UI messages from tool_use blocks.
@override List<A2uiMessageData> get a2uiMessages {
  if (_a2uiMessages is EqualUnmodifiableListView) return _a2uiMessages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_a2uiMessages);
}

/// Combined text content from text blocks.
@override final  String textContent;
/// Whether any tool_use blocks were found.
@override final  bool hasToolUse;

/// Create a copy of ParseResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParseResultCopyWith<_ParseResult> get copyWith => __$ParseResultCopyWithImpl<_ParseResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParseResult&&const DeepCollectionEquality().equals(other._a2uiMessages, _a2uiMessages)&&(identical(other.textContent, textContent) || other.textContent == textContent)&&(identical(other.hasToolUse, hasToolUse) || other.hasToolUse == hasToolUse));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_a2uiMessages),textContent,hasToolUse);

@override
String toString() {
  return 'ParseResult(a2uiMessages: $a2uiMessages, textContent: $textContent, hasToolUse: $hasToolUse)';
}


}

/// @nodoc
abstract mixin class _$ParseResultCopyWith<$Res> implements $ParseResultCopyWith<$Res> {
  factory _$ParseResultCopyWith(_ParseResult value, $Res Function(_ParseResult) _then) = __$ParseResultCopyWithImpl;
@override @useResult
$Res call({
 List<A2uiMessageData> a2uiMessages, String textContent, bool hasToolUse
});




}
/// @nodoc
class __$ParseResultCopyWithImpl<$Res>
    implements _$ParseResultCopyWith<$Res> {
  __$ParseResultCopyWithImpl(this._self, this._then);

  final _ParseResult _self;
  final $Res Function(_ParseResult) _then;

/// Create a copy of ParseResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? a2uiMessages = null,Object? textContent = null,Object? hasToolUse = null,}) {
  return _then(_ParseResult(
a2uiMessages: null == a2uiMessages ? _self._a2uiMessages : a2uiMessages // ignore: cast_nullable_to_non_nullable
as List<A2uiMessageData>,textContent: null == textContent ? _self.textContent : textContent // ignore: cast_nullable_to_non_nullable
as String,hasToolUse: null == hasToolUse ? _self.hasToolUse : hasToolUse // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
