// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'a2ui_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BeginRenderingData _$BeginRenderingDataFromJson(Map<String, dynamic> json) =>
    BeginRenderingData(
      surfaceId: json['surfaceId'] as String,
      parentSurfaceId: json['parentSurfaceId'] as String?,
      root: json['root'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$BeginRenderingDataToJson(BeginRenderingData instance) =>
    <String, dynamic>{
      'surfaceId': instance.surfaceId,
      'parentSurfaceId': ?instance.parentSurfaceId,
      'root': ?instance.root,
      'metadata': ?instance.metadata,
      'type': instance.$type,
    };

SurfaceUpdateData _$SurfaceUpdateDataFromJson(Map<String, dynamic> json) =>
    SurfaceUpdateData(
      surfaceId: json['surfaceId'] as String,
      widgets: (json['widgets'] as List<dynamic>)
          .map((e) => WidgetNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      append: json['append'] as bool? ?? false,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$SurfaceUpdateDataToJson(SurfaceUpdateData instance) =>
    <String, dynamic>{
      'surfaceId': instance.surfaceId,
      'widgets': instance.widgets.map((e) => e.toJson()).toList(),
      'append': instance.append,
      'type': instance.$type,
    };

DataModelUpdateData _$DataModelUpdateDataFromJson(Map<String, dynamic> json) =>
    DataModelUpdateData(
      updates: json['updates'] as Map<String, dynamic>,
      scope: json['scope'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$DataModelUpdateDataToJson(
  DataModelUpdateData instance,
) => <String, dynamic>{
  'updates': instance.updates,
  'scope': ?instance.scope,
  'type': instance.$type,
};

DeleteSurfaceData _$DeleteSurfaceDataFromJson(Map<String, dynamic> json) =>
    DeleteSurfaceData(
      surfaceId: json['surfaceId'] as String,
      cascade: json['cascade'] as bool? ?? true,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$DeleteSurfaceDataToJson(DeleteSurfaceData instance) =>
    <String, dynamic>{
      'surfaceId': instance.surfaceId,
      'cascade': instance.cascade,
      'type': instance.$type,
    };
