// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Document _$DocumentFromJson(Map<String, dynamic> json) => _Document(
  id: json['id'] as String,
  dipDocId: json['dip_doc_id'] as String?,
  filename: json['filename'] as String,
  pageCount: (json['page_count'] as num?)?.toInt(),
  hasText: json['has_text'] as bool?,
  status: json['status'] as String,
  error: json['error'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$DocumentToJson(_Document instance) => <String, dynamic>{
  'id': instance.id,
  'dip_doc_id': instance.dipDocId,
  'filename': instance.filename,
  'page_count': instance.pageCount,
  'has_text': instance.hasText,
  'status': instance.status,
  'error': instance.error,
  'created_at': instance.createdAt?.toIso8601String(),
};

_Book _$BookFromJson(Map<String, dynamic> json) => _Book(
  name: json['name'] as String,
  display: json['display'] as String,
  sizeMb: (json['size_mb'] as num?)?.toDouble(),
  pages: (json['pages'] as num?)?.toInt(),
);

Map<String, dynamic> _$BookToJson(_Book instance) => <String, dynamic>{
  'name': instance.name,
  'display': instance.display,
  'size_mb': instance.sizeMb,
  'pages': instance.pages,
};
