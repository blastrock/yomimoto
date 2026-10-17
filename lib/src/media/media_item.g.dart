// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaItem _$MediaItemFromJson(Map<String, dynamic> json) => MediaItem(
  mediaIdentifier: json['mediaIdentifier'] as String,
  title: json['title'] as String,
  mediaSourceIdentifier: json['mediaSourceIdentifier'] as String,
  position: (json['position'] as num).toInt(),
  duration: (json['duration'] as num).toInt(),
  canDelete: json['canDelete'] as bool,
  canEdit: json['canEdit'] as bool,
  id: (json['id'] as num?)?.toInt(),
  imageUrl: json['imageUrl'] as String?,
  sourceMetadata: json['sourceMetadata'] as String?,
  lastOpenedAt: json['lastOpenedAt'] == null
      ? null
      : DateTime.parse(json['lastOpenedAt'] as String),
  overrideTitle: json['overrideTitle'] as String?,
);

Map<String, dynamic> _$MediaItemToJson(MediaItem instance) => <String, dynamic>{
  'id': instance.id,
  'mediaIdentifier': instance.mediaIdentifier,
  'title': instance.title,
  'mediaSourceIdentifier': instance.mediaSourceIdentifier,
  'imageUrl': instance.imageUrl,
  'sourceMetadata': instance.sourceMetadata,
  'position': instance.position,
  'duration': instance.duration,
  'canDelete': instance.canDelete,
  'canEdit': instance.canEdit,
  'lastOpenedAt': instance.lastOpenedAt?.toIso8601String(),
  'overrideTitle': instance.overrideTitle,
};
