// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WidgetNode _$WidgetNodeFromJson(Map<String, dynamic> json) => _WidgetNode(
  type: json['type'] as String,
  id: json['id'] as String?,
  properties:
      json['properties'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  children: (json['children'] as List<dynamic>?)
      ?.map((e) => WidgetNode.fromJson(e as Map<String, dynamic>))
      .toList(),
  dataBinding: json['dataBinding'],
);

Map<String, dynamic> _$WidgetNodeToJson(_WidgetNode instance) =>
    <String, dynamic>{
      'type': instance.type,
      'id': ?instance.id,
      'properties': instance.properties,
      'children': ?instance.children?.map((e) => e.toJson()).toList(),
      'dataBinding': ?instance.dataBinding,
    };
