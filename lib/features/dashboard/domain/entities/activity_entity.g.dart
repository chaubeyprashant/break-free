// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityEntity _$ActivityEntityFromJson(Map<String, dynamic> json) =>
    _ActivityEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      iconType: json['iconType'] as String,
    );

Map<String, dynamic> _$ActivityEntityToJson(_ActivityEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'timestamp': instance.timestamp.toIso8601String(),
      'iconType': instance.iconType,
    };
