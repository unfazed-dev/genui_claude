// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'widget_node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WidgetNode {

/// The widget type identifier (e.g., 'text', 'button', 'container').
 String get type;/// Optional unique instance identifier for this widget.
///
/// When provided, this ID uniquely identifies this widget instance
/// within a surface. If not provided, a UUID will be generated
/// during conversion to GenUI Component.
 String? get id;/// Configuration properties for this widget.
 Map<String, dynamic> get properties;/// Child widgets for container-type widgets.
///
/// Supports both:
/// - Full widget objects (nested [WidgetNode] instances)
/// - String ID references (converted to placeholder nodes with type='_ref')
@JsonKey(fromJson: _childrenFromJson) List<WidgetNode>? get children;/// Optional data binding specification for dynamic content.
///
/// Can be either:
/// - A [String] path (e.g., 'form.email') for simple one-way binding
/// - A [Map] with property → path mappings (e.g., {'value': 'form.email'})
/// - A [Map] with property → binding config (e.g., {'value': {'path': 'form.email', 'mode': 'twoWay'}})
 Object? get dataBinding;
/// Create a copy of WidgetNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WidgetNodeCopyWith<WidgetNode> get copyWith => _$WidgetNodeCopyWithImpl<WidgetNode>(this as WidgetNode, _$identity);

  /// Serializes this WidgetNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WidgetNode&&(identical(other.type, type) || other.type == type)&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.properties, properties)&&const DeepCollectionEquality().equals(other.children, children)&&const DeepCollectionEquality().equals(other.dataBinding, dataBinding));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,id,const DeepCollectionEquality().hash(properties),const DeepCollectionEquality().hash(children),const DeepCollectionEquality().hash(dataBinding));

@override
String toString() {
  return 'WidgetNode(type: $type, id: $id, properties: $properties, children: $children, dataBinding: $dataBinding)';
}


}

/// @nodoc
abstract mixin class $WidgetNodeCopyWith<$Res>  {
  factory $WidgetNodeCopyWith(WidgetNode value, $Res Function(WidgetNode) _then) = _$WidgetNodeCopyWithImpl;
@useResult
$Res call({
 String type, String? id, Map<String, dynamic> properties,@JsonKey(fromJson: _childrenFromJson) List<WidgetNode>? children, Object? dataBinding
});




}
/// @nodoc
class _$WidgetNodeCopyWithImpl<$Res>
    implements $WidgetNodeCopyWith<$Res> {
  _$WidgetNodeCopyWithImpl(this._self, this._then);

  final WidgetNode _self;
  final $Res Function(WidgetNode) _then;

/// Create a copy of WidgetNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? id = freezed,Object? properties = null,Object? children = freezed,Object? dataBinding = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,children: freezed == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<WidgetNode>?,dataBinding: freezed == dataBinding ? _self.dataBinding : dataBinding ,
  ));
}

}


/// Adds pattern-matching-related methods to [WidgetNode].
extension WidgetNodePatterns on WidgetNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WidgetNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WidgetNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WidgetNode value)  $default,){
final _that = this;
switch (_that) {
case _WidgetNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WidgetNode value)?  $default,){
final _that = this;
switch (_that) {
case _WidgetNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String? id,  Map<String, dynamic> properties, @JsonKey(fromJson: _childrenFromJson)  List<WidgetNode>? children,  Object? dataBinding)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WidgetNode() when $default != null:
return $default(_that.type,_that.id,_that.properties,_that.children,_that.dataBinding);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String? id,  Map<String, dynamic> properties, @JsonKey(fromJson: _childrenFromJson)  List<WidgetNode>? children,  Object? dataBinding)  $default,) {final _that = this;
switch (_that) {
case _WidgetNode():
return $default(_that.type,_that.id,_that.properties,_that.children,_that.dataBinding);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String? id,  Map<String, dynamic> properties, @JsonKey(fromJson: _childrenFromJson)  List<WidgetNode>? children,  Object? dataBinding)?  $default,) {final _that = this;
switch (_that) {
case _WidgetNode() when $default != null:
return $default(_that.type,_that.id,_that.properties,_that.children,_that.dataBinding);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WidgetNode implements WidgetNode {
  const _WidgetNode({required this.type, this.id, final  Map<String, dynamic> properties = const <String, dynamic>{}, @JsonKey(fromJson: _childrenFromJson) final  List<WidgetNode>? children, this.dataBinding}): _properties = properties,_children = children;
  factory _WidgetNode.fromJson(Map<String, dynamic> json) => _$WidgetNodeFromJson(json);

/// The widget type identifier (e.g., 'text', 'button', 'container').
@override final  String type;
/// Optional unique instance identifier for this widget.
///
/// When provided, this ID uniquely identifies this widget instance
/// within a surface. If not provided, a UUID will be generated
/// during conversion to GenUI Component.
@override final  String? id;
/// Configuration properties for this widget.
 final  Map<String, dynamic> _properties;
/// Configuration properties for this widget.
@override@JsonKey() Map<String, dynamic> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}

/// Child widgets for container-type widgets.
///
/// Supports both:
/// - Full widget objects (nested [WidgetNode] instances)
/// - String ID references (converted to placeholder nodes with type='_ref')
 final  List<WidgetNode>? _children;
/// Child widgets for container-type widgets.
///
/// Supports both:
/// - Full widget objects (nested [WidgetNode] instances)
/// - String ID references (converted to placeholder nodes with type='_ref')
@override@JsonKey(fromJson: _childrenFromJson) List<WidgetNode>? get children {
  final value = _children;
  if (value == null) return null;
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Optional data binding specification for dynamic content.
///
/// Can be either:
/// - A [String] path (e.g., 'form.email') for simple one-way binding
/// - A [Map] with property → path mappings (e.g., {'value': 'form.email'})
/// - A [Map] with property → binding config (e.g., {'value': {'path': 'form.email', 'mode': 'twoWay'}})
@override final  Object? dataBinding;

/// Create a copy of WidgetNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WidgetNodeCopyWith<_WidgetNode> get copyWith => __$WidgetNodeCopyWithImpl<_WidgetNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WidgetNodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WidgetNode&&(identical(other.type, type) || other.type == type)&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._properties, _properties)&&const DeepCollectionEquality().equals(other._children, _children)&&const DeepCollectionEquality().equals(other.dataBinding, dataBinding));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,id,const DeepCollectionEquality().hash(_properties),const DeepCollectionEquality().hash(_children),const DeepCollectionEquality().hash(dataBinding));

@override
String toString() {
  return 'WidgetNode(type: $type, id: $id, properties: $properties, children: $children, dataBinding: $dataBinding)';
}


}

/// @nodoc
abstract mixin class _$WidgetNodeCopyWith<$Res> implements $WidgetNodeCopyWith<$Res> {
  factory _$WidgetNodeCopyWith(_WidgetNode value, $Res Function(_WidgetNode) _then) = __$WidgetNodeCopyWithImpl;
@override @useResult
$Res call({
 String type, String? id, Map<String, dynamic> properties,@JsonKey(fromJson: _childrenFromJson) List<WidgetNode>? children, Object? dataBinding
});




}
/// @nodoc
class __$WidgetNodeCopyWithImpl<$Res>
    implements _$WidgetNodeCopyWith<$Res> {
  __$WidgetNodeCopyWithImpl(this._self, this._then);

  final _WidgetNode _self;
  final $Res Function(_WidgetNode) _then;

/// Create a copy of WidgetNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? id = freezed,Object? properties = null,Object? children = freezed,Object? dataBinding = freezed,}) {
  return _then(_WidgetNode(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,children: freezed == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<WidgetNode>?,dataBinding: freezed == dataBinding ? _self.dataBinding : dataBinding ,
  ));
}


}

// dart format on
