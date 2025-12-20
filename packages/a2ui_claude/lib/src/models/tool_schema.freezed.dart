// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tool_schema.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$A2uiToolSchema {

/// Unique tool name identifier.
 String get name;/// Human-readable description of what the tool does.
 String get description;/// JSON Schema defining the tool's input parameters.
 Map<String, dynamic> get inputSchema;/// List of required field names.
 List<String>? get requiredFields;
/// Create a copy of A2uiToolSchema
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$A2uiToolSchemaCopyWith<A2uiToolSchema> get copyWith => _$A2uiToolSchemaCopyWithImpl<A2uiToolSchema>(this as A2uiToolSchema, _$identity);

  /// Serializes this A2uiToolSchema to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is A2uiToolSchema&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.inputSchema, inputSchema)&&const DeepCollectionEquality().equals(other.requiredFields, requiredFields));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,const DeepCollectionEquality().hash(inputSchema),const DeepCollectionEquality().hash(requiredFields));

@override
String toString() {
  return 'A2uiToolSchema(name: $name, description: $description, inputSchema: $inputSchema, requiredFields: $requiredFields)';
}


}

/// @nodoc
abstract mixin class $A2uiToolSchemaCopyWith<$Res>  {
  factory $A2uiToolSchemaCopyWith(A2uiToolSchema value, $Res Function(A2uiToolSchema) _then) = _$A2uiToolSchemaCopyWithImpl;
@useResult
$Res call({
 String name, String description, Map<String, dynamic> inputSchema, List<String>? requiredFields
});




}
/// @nodoc
class _$A2uiToolSchemaCopyWithImpl<$Res>
    implements $A2uiToolSchemaCopyWith<$Res> {
  _$A2uiToolSchemaCopyWithImpl(this._self, this._then);

  final A2uiToolSchema _self;
  final $Res Function(A2uiToolSchema) _then;

/// Create a copy of A2uiToolSchema
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,Object? inputSchema = null,Object? requiredFields = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,inputSchema: null == inputSchema ? _self.inputSchema : inputSchema // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,requiredFields: freezed == requiredFields ? _self.requiredFields : requiredFields // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [A2uiToolSchema].
extension A2uiToolSchemaPatterns on A2uiToolSchema {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _A2uiToolSchema value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _A2uiToolSchema() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _A2uiToolSchema value)  $default,){
final _that = this;
switch (_that) {
case _A2uiToolSchema():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _A2uiToolSchema value)?  $default,){
final _that = this;
switch (_that) {
case _A2uiToolSchema() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description,  Map<String, dynamic> inputSchema,  List<String>? requiredFields)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _A2uiToolSchema() when $default != null:
return $default(_that.name,_that.description,_that.inputSchema,_that.requiredFields);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description,  Map<String, dynamic> inputSchema,  List<String>? requiredFields)  $default,) {final _that = this;
switch (_that) {
case _A2uiToolSchema():
return $default(_that.name,_that.description,_that.inputSchema,_that.requiredFields);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description,  Map<String, dynamic> inputSchema,  List<String>? requiredFields)?  $default,) {final _that = this;
switch (_that) {
case _A2uiToolSchema() when $default != null:
return $default(_that.name,_that.description,_that.inputSchema,_that.requiredFields);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _A2uiToolSchema implements A2uiToolSchema {
  const _A2uiToolSchema({required this.name, required this.description, required final  Map<String, dynamic> inputSchema, final  List<String>? requiredFields}): _inputSchema = inputSchema,_requiredFields = requiredFields;
  factory _A2uiToolSchema.fromJson(Map<String, dynamic> json) => _$A2uiToolSchemaFromJson(json);

/// Unique tool name identifier.
@override final  String name;
/// Human-readable description of what the tool does.
@override final  String description;
/// JSON Schema defining the tool's input parameters.
 final  Map<String, dynamic> _inputSchema;
/// JSON Schema defining the tool's input parameters.
@override Map<String, dynamic> get inputSchema {
  if (_inputSchema is EqualUnmodifiableMapView) return _inputSchema;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_inputSchema);
}

/// List of required field names.
 final  List<String>? _requiredFields;
/// List of required field names.
@override List<String>? get requiredFields {
  final value = _requiredFields;
  if (value == null) return null;
  if (_requiredFields is EqualUnmodifiableListView) return _requiredFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of A2uiToolSchema
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$A2uiToolSchemaCopyWith<_A2uiToolSchema> get copyWith => __$A2uiToolSchemaCopyWithImpl<_A2uiToolSchema>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$A2uiToolSchemaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _A2uiToolSchema&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._inputSchema, _inputSchema)&&const DeepCollectionEquality().equals(other._requiredFields, _requiredFields));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,const DeepCollectionEquality().hash(_inputSchema),const DeepCollectionEquality().hash(_requiredFields));

@override
String toString() {
  return 'A2uiToolSchema(name: $name, description: $description, inputSchema: $inputSchema, requiredFields: $requiredFields)';
}


}

/// @nodoc
abstract mixin class _$A2uiToolSchemaCopyWith<$Res> implements $A2uiToolSchemaCopyWith<$Res> {
  factory _$A2uiToolSchemaCopyWith(_A2uiToolSchema value, $Res Function(_A2uiToolSchema) _then) = __$A2uiToolSchemaCopyWithImpl;
@override @useResult
$Res call({
 String name, String description, Map<String, dynamic> inputSchema, List<String>? requiredFields
});




}
/// @nodoc
class __$A2uiToolSchemaCopyWithImpl<$Res>
    implements _$A2uiToolSchemaCopyWith<$Res> {
  __$A2uiToolSchemaCopyWithImpl(this._self, this._then);

  final _A2uiToolSchema _self;
  final $Res Function(_A2uiToolSchema) _then;

/// Create a copy of A2uiToolSchema
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,Object? inputSchema = null,Object? requiredFields = freezed,}) {
  return _then(_A2uiToolSchema(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,inputSchema: null == inputSchema ? _self._inputSchema : inputSchema // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,requiredFields: freezed == requiredFields ? _self._requiredFields : requiredFields // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
