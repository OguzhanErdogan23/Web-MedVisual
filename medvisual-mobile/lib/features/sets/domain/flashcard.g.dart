// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Flashcard _$FlashcardFromJson(Map<String, dynamic> json) => _Flashcard(
  id: json['id'] as String,
  setId: json['set_id'] as String?,
  front: json['front'] as String,
  back: json['back'] as String,
  term: json['term'] as String?,
  kind: json['kind'] as String?,
  page: (json['page'] as num?)?.toInt(),
  imageUrl: json['image_url'] as String?,
  position: (json['position'] as num?)?.toInt(),
);

Map<String, dynamic> _$FlashcardToJson(_Flashcard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'set_id': instance.setId,
      'front': instance.front,
      'back': instance.back,
      'term': instance.term,
      'kind': instance.kind,
      'page': instance.page,
      'image_url': instance.imageUrl,
      'position': instance.position,
    };
