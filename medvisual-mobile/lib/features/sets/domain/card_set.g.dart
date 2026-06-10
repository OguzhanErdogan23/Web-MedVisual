// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CardSet _$CardSetFromJson(Map<String, dynamic> json) => _CardSet(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  status: json['status'] as String,
  error: json['error'] as String?,
  documentId: json['document_id'] as String?,
  cardCount: (json['card_count'] as num?)?.toInt() ?? 0,
  cards:
      (json['cards'] as List<dynamic>?)
          ?.map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Flashcard>[],
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$CardSetToJson(_CardSet instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'status': instance.status,
  'error': instance.error,
  'document_id': instance.documentId,
  'card_count': instance.cardCount,
  'cards': instance.cards.map((e) => e.toJson()).toList(),
  'created_at': instance.createdAt?.toIso8601String(),
};
