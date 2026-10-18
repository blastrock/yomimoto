// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anki_mapping.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnkiMapping _$AnkiMappingFromJson(Map<String, dynamic> json) => AnkiMapping(
  label: json['label'] as String,
  model: json['model'] as String,
  exportFieldKeys: (json['exportFieldKeys'] as List<dynamic>)
      .map((e) => e as String?)
      .toList(),
  creatorFieldKeys: (json['creatorFieldKeys'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  creatorCollapsedFieldKeys:
      (json['creatorCollapsedFieldKeys'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
  order: (json['order'] as num).toInt(),
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  exportMediaTags: json['exportMediaTags'] as bool?,
  useBrTags: json['useBrTags'] as bool?,
  prependDictionaryNames: json['prependDictionaryNames'] as bool?,
  enhancements: (json['enhancements'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(
      k,
      (e as Map<String, dynamic>).map(
        (k, e) => MapEntry(int.parse(k), e as String),
      ),
    ),
  ),
  id: (json['id'] as num?)?.toInt(),
);

Map<String, dynamic> _$AnkiMappingToJson(AnkiMapping instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'model': instance.model,
      'exportFieldKeys': instance.exportFieldKeys,
      'creatorFieldKeys': instance.creatorFieldKeys,
      'creatorCollapsedFieldKeys': instance.creatorCollapsedFieldKeys,
      'tags': instance.tags,
      'enhancements': instance.enhancements?.map(
        (k, e) => MapEntry(k, e.map((k, e) => MapEntry(k.toString(), e))),
      ),
      'exportMediaTags': instance.exportMediaTags,
      'useBrTags': instance.useBrTags,
      'prependDictionaryNames': instance.prependDictionaryNames,
      'order': instance.order,
    };
