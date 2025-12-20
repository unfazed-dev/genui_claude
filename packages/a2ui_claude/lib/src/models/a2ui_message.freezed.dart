// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'a2ui_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
A2uiMessageData _$A2uiMessageDataFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'begin_rendering':
          return BeginRenderingData.fromJson(
            json
          );
                case 'surface_update':
          return SurfaceUpdateData.fromJson(
            json
          );
                case 'data_model_update':
          return DataModelUpdateData.fromJson(
            json
          );
                case 'delete_surface':
          return DeleteSurfaceData.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'A2uiMessageData',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$A2uiMessageData {



  /// Serializes this A2uiMessageData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is A2uiMessageData);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'A2uiMessageData()';
}


}

/// @nodoc
class $A2uiMessageDataCopyWith<$Res>  {
$A2uiMessageDataCopyWith(A2uiMessageData _, $Res Function(A2uiMessageData) __);
}


/// Adds pattern-matching-related methods to [A2uiMessageData].
extension A2uiMessageDataPatterns on A2uiMessageData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BeginRenderingData value)?  beginRendering,TResult Function( SurfaceUpdateData value)?  surfaceUpdate,TResult Function( DataModelUpdateData value)?  dataModelUpdate,TResult Function( DeleteSurfaceData value)?  deleteSurface,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BeginRenderingData() when beginRendering != null:
return beginRendering(_that);case SurfaceUpdateData() when surfaceUpdate != null:
return surfaceUpdate(_that);case DataModelUpdateData() when dataModelUpdate != null:
return dataModelUpdate(_that);case DeleteSurfaceData() when deleteSurface != null:
return deleteSurface(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BeginRenderingData value)  beginRendering,required TResult Function( SurfaceUpdateData value)  surfaceUpdate,required TResult Function( DataModelUpdateData value)  dataModelUpdate,required TResult Function( DeleteSurfaceData value)  deleteSurface,}){
final _that = this;
switch (_that) {
case BeginRenderingData():
return beginRendering(_that);case SurfaceUpdateData():
return surfaceUpdate(_that);case DataModelUpdateData():
return dataModelUpdate(_that);case DeleteSurfaceData():
return deleteSurface(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BeginRenderingData value)?  beginRendering,TResult? Function( SurfaceUpdateData value)?  surfaceUpdate,TResult? Function( DataModelUpdateData value)?  dataModelUpdate,TResult? Function( DeleteSurfaceData value)?  deleteSurface,}){
final _that = this;
switch (_that) {
case BeginRenderingData() when beginRendering != null:
return beginRendering(_that);case SurfaceUpdateData() when surfaceUpdate != null:
return surfaceUpdate(_that);case DataModelUpdateData() when dataModelUpdate != null:
return dataModelUpdate(_that);case DeleteSurfaceData() when deleteSurface != null:
return deleteSurface(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String surfaceId,  String? parentSurfaceId,  String? root,  Map<String, dynamic>? metadata)?  beginRendering,TResult Function( String surfaceId,  List<WidgetNode> widgets,  bool append)?  surfaceUpdate,TResult Function( Map<String, dynamic> updates,  String? scope)?  dataModelUpdate,TResult Function( String surfaceId,  bool cascade)?  deleteSurface,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BeginRenderingData() when beginRendering != null:
return beginRendering(_that.surfaceId,_that.parentSurfaceId,_that.root,_that.metadata);case SurfaceUpdateData() when surfaceUpdate != null:
return surfaceUpdate(_that.surfaceId,_that.widgets,_that.append);case DataModelUpdateData() when dataModelUpdate != null:
return dataModelUpdate(_that.updates,_that.scope);case DeleteSurfaceData() when deleteSurface != null:
return deleteSurface(_that.surfaceId,_that.cascade);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String surfaceId,  String? parentSurfaceId,  String? root,  Map<String, dynamic>? metadata)  beginRendering,required TResult Function( String surfaceId,  List<WidgetNode> widgets,  bool append)  surfaceUpdate,required TResult Function( Map<String, dynamic> updates,  String? scope)  dataModelUpdate,required TResult Function( String surfaceId,  bool cascade)  deleteSurface,}) {final _that = this;
switch (_that) {
case BeginRenderingData():
return beginRendering(_that.surfaceId,_that.parentSurfaceId,_that.root,_that.metadata);case SurfaceUpdateData():
return surfaceUpdate(_that.surfaceId,_that.widgets,_that.append);case DataModelUpdateData():
return dataModelUpdate(_that.updates,_that.scope);case DeleteSurfaceData():
return deleteSurface(_that.surfaceId,_that.cascade);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String surfaceId,  String? parentSurfaceId,  String? root,  Map<String, dynamic>? metadata)?  beginRendering,TResult? Function( String surfaceId,  List<WidgetNode> widgets,  bool append)?  surfaceUpdate,TResult? Function( Map<String, dynamic> updates,  String? scope)?  dataModelUpdate,TResult? Function( String surfaceId,  bool cascade)?  deleteSurface,}) {final _that = this;
switch (_that) {
case BeginRenderingData() when beginRendering != null:
return beginRendering(_that.surfaceId,_that.parentSurfaceId,_that.root,_that.metadata);case SurfaceUpdateData() when surfaceUpdate != null:
return surfaceUpdate(_that.surfaceId,_that.widgets,_that.append);case DataModelUpdateData() when dataModelUpdate != null:
return dataModelUpdate(_that.updates,_that.scope);case DeleteSurfaceData() when deleteSurface != null:
return deleteSurface(_that.surfaceId,_that.cascade);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class BeginRenderingData implements A2uiMessageData {
  const BeginRenderingData({required this.surfaceId, this.parentSurfaceId, this.root, final  Map<String, dynamic>? metadata, final  String? $type}): _metadata = metadata,$type = $type ?? 'begin_rendering';
  factory BeginRenderingData.fromJson(Map<String, dynamic> json) => _$BeginRenderingDataFromJson(json);

/// Unique identifier for this surface.
 final  String surfaceId;
/// Parent surface ID for nested surfaces.
 final  String? parentSurfaceId;
/// Optional root element ID for hierarchical rendering.
///
/// When provided, specifies the root element identifier for the surface.
/// If not provided, defaults to 'root' in GenUI SDK conversion.
 final  String? root;
/// Additional metadata for the surface.
 final  Map<String, dynamic>? _metadata;
/// Additional metadata for the surface.
 Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of A2uiMessageData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BeginRenderingDataCopyWith<BeginRenderingData> get copyWith => _$BeginRenderingDataCopyWithImpl<BeginRenderingData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BeginRenderingDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BeginRenderingData&&(identical(other.surfaceId, surfaceId) || other.surfaceId == surfaceId)&&(identical(other.parentSurfaceId, parentSurfaceId) || other.parentSurfaceId == parentSurfaceId)&&(identical(other.root, root) || other.root == root)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,surfaceId,parentSurfaceId,root,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'A2uiMessageData.beginRendering(surfaceId: $surfaceId, parentSurfaceId: $parentSurfaceId, root: $root, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $BeginRenderingDataCopyWith<$Res> implements $A2uiMessageDataCopyWith<$Res> {
  factory $BeginRenderingDataCopyWith(BeginRenderingData value, $Res Function(BeginRenderingData) _then) = _$BeginRenderingDataCopyWithImpl;
@useResult
$Res call({
 String surfaceId, String? parentSurfaceId, String? root, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$BeginRenderingDataCopyWithImpl<$Res>
    implements $BeginRenderingDataCopyWith<$Res> {
  _$BeginRenderingDataCopyWithImpl(this._self, this._then);

  final BeginRenderingData _self;
  final $Res Function(BeginRenderingData) _then;

/// Create a copy of A2uiMessageData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? surfaceId = null,Object? parentSurfaceId = freezed,Object? root = freezed,Object? metadata = freezed,}) {
  return _then(BeginRenderingData(
surfaceId: null == surfaceId ? _self.surfaceId : surfaceId // ignore: cast_nullable_to_non_nullable
as String,parentSurfaceId: freezed == parentSurfaceId ? _self.parentSurfaceId : parentSurfaceId // ignore: cast_nullable_to_non_nullable
as String?,root: freezed == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SurfaceUpdateData implements A2uiMessageData {
  const SurfaceUpdateData({required this.surfaceId, required final  List<WidgetNode> widgets, this.append = false, final  String? $type}): _widgets = widgets,$type = $type ?? 'surface_update';
  factory SurfaceUpdateData.fromJson(Map<String, dynamic> json) => _$SurfaceUpdateDataFromJson(json);

/// The surface ID to update.
 final  String surfaceId;
/// Widget tree to render.
 final  List<WidgetNode> _widgets;
/// Widget tree to render.
 List<WidgetNode> get widgets {
  if (_widgets is EqualUnmodifiableListView) return _widgets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_widgets);
}

/// Whether to append widgets or replace existing content.
@JsonKey() final  bool append;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of A2uiMessageData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurfaceUpdateDataCopyWith<SurfaceUpdateData> get copyWith => _$SurfaceUpdateDataCopyWithImpl<SurfaceUpdateData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SurfaceUpdateDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurfaceUpdateData&&(identical(other.surfaceId, surfaceId) || other.surfaceId == surfaceId)&&const DeepCollectionEquality().equals(other._widgets, _widgets)&&(identical(other.append, append) || other.append == append));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,surfaceId,const DeepCollectionEquality().hash(_widgets),append);

@override
String toString() {
  return 'A2uiMessageData.surfaceUpdate(surfaceId: $surfaceId, widgets: $widgets, append: $append)';
}


}

/// @nodoc
abstract mixin class $SurfaceUpdateDataCopyWith<$Res> implements $A2uiMessageDataCopyWith<$Res> {
  factory $SurfaceUpdateDataCopyWith(SurfaceUpdateData value, $Res Function(SurfaceUpdateData) _then) = _$SurfaceUpdateDataCopyWithImpl;
@useResult
$Res call({
 String surfaceId, List<WidgetNode> widgets, bool append
});




}
/// @nodoc
class _$SurfaceUpdateDataCopyWithImpl<$Res>
    implements $SurfaceUpdateDataCopyWith<$Res> {
  _$SurfaceUpdateDataCopyWithImpl(this._self, this._then);

  final SurfaceUpdateData _self;
  final $Res Function(SurfaceUpdateData) _then;

/// Create a copy of A2uiMessageData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? surfaceId = null,Object? widgets = null,Object? append = null,}) {
  return _then(SurfaceUpdateData(
surfaceId: null == surfaceId ? _self.surfaceId : surfaceId // ignore: cast_nullable_to_non_nullable
as String,widgets: null == widgets ? _self._widgets : widgets // ignore: cast_nullable_to_non_nullable
as List<WidgetNode>,append: null == append ? _self.append : append // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
@JsonSerializable()

class DataModelUpdateData implements A2uiMessageData {
  const DataModelUpdateData({required final  Map<String, dynamic> updates, this.scope, final  String? $type}): _updates = updates,$type = $type ?? 'data_model_update';
  factory DataModelUpdateData.fromJson(Map<String, dynamic> json) => _$DataModelUpdateDataFromJson(json);

/// Data updates as key-value pairs.
 final  Map<String, dynamic> _updates;
/// Data updates as key-value pairs.
 Map<String, dynamic> get updates {
  if (_updates is EqualUnmodifiableMapView) return _updates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_updates);
}

/// Optional scope to limit the update visibility.
 final  String? scope;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of A2uiMessageData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataModelUpdateDataCopyWith<DataModelUpdateData> get copyWith => _$DataModelUpdateDataCopyWithImpl<DataModelUpdateData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DataModelUpdateDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataModelUpdateData&&const DeepCollectionEquality().equals(other._updates, _updates)&&(identical(other.scope, scope) || other.scope == scope));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_updates),scope);

@override
String toString() {
  return 'A2uiMessageData.dataModelUpdate(updates: $updates, scope: $scope)';
}


}

/// @nodoc
abstract mixin class $DataModelUpdateDataCopyWith<$Res> implements $A2uiMessageDataCopyWith<$Res> {
  factory $DataModelUpdateDataCopyWith(DataModelUpdateData value, $Res Function(DataModelUpdateData) _then) = _$DataModelUpdateDataCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic> updates, String? scope
});




}
/// @nodoc
class _$DataModelUpdateDataCopyWithImpl<$Res>
    implements $DataModelUpdateDataCopyWith<$Res> {
  _$DataModelUpdateDataCopyWithImpl(this._self, this._then);

  final DataModelUpdateData _self;
  final $Res Function(DataModelUpdateData) _then;

/// Create a copy of A2uiMessageData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? updates = null,Object? scope = freezed,}) {
  return _then(DataModelUpdateData(
updates: null == updates ? _self._updates : updates // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class DeleteSurfaceData implements A2uiMessageData {
  const DeleteSurfaceData({required this.surfaceId, this.cascade = true, final  String? $type}): $type = $type ?? 'delete_surface';
  factory DeleteSurfaceData.fromJson(Map<String, dynamic> json) => _$DeleteSurfaceDataFromJson(json);

/// The surface ID to delete.
 final  String surfaceId;
/// Whether to delete child surfaces as well.
@JsonKey() final  bool cascade;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of A2uiMessageData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteSurfaceDataCopyWith<DeleteSurfaceData> get copyWith => _$DeleteSurfaceDataCopyWithImpl<DeleteSurfaceData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeleteSurfaceDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteSurfaceData&&(identical(other.surfaceId, surfaceId) || other.surfaceId == surfaceId)&&(identical(other.cascade, cascade) || other.cascade == cascade));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,surfaceId,cascade);

@override
String toString() {
  return 'A2uiMessageData.deleteSurface(surfaceId: $surfaceId, cascade: $cascade)';
}


}

/// @nodoc
abstract mixin class $DeleteSurfaceDataCopyWith<$Res> implements $A2uiMessageDataCopyWith<$Res> {
  factory $DeleteSurfaceDataCopyWith(DeleteSurfaceData value, $Res Function(DeleteSurfaceData) _then) = _$DeleteSurfaceDataCopyWithImpl;
@useResult
$Res call({
 String surfaceId, bool cascade
});




}
/// @nodoc
class _$DeleteSurfaceDataCopyWithImpl<$Res>
    implements $DeleteSurfaceDataCopyWith<$Res> {
  _$DeleteSurfaceDataCopyWithImpl(this._self, this._then);

  final DeleteSurfaceData _self;
  final $Res Function(DeleteSurfaceData) _then;

/// Create a copy of A2uiMessageData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? surfaceId = null,Object? cascade = null,}) {
  return _then(DeleteSurfaceData(
surfaceId: null == surfaceId ? _self.surfaceId : surfaceId // ignore: cast_nullable_to_non_nullable
as String,cascade: null == cascade ? _self.cascade : cascade // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
