// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_A2uiToolSchema _$A2uiToolSchemaFromJson(Map<String, dynamic> json) =>
    _A2uiToolSchema(
      name: json['name'] as String,
      description: json['description'] as String,
      inputSchema: json['inputSchema'] as Map<String, dynamic>,
      requiredFields: (json['requiredFields'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$A2uiToolSchemaToJson(_A2uiToolSchema instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'inputSchema': instance.inputSchema,
      'requiredFields': ?instance.requiredFields,
    };
