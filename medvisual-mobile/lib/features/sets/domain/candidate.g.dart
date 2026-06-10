// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Candidate _$CandidateFromJson(Map<String, dynamic> json) => _Candidate(
  label: json['label'] as String?,
  page: (json['page'] as num?)?.toInt(),
  distance: (json['distance'] as num?)?.toDouble(),
  dipDocId: json['dip_doc_id'] as String,
  path: json['path'] as String,
  url: json['url'] as String,
);

Map<String, dynamic> _$CandidateToJson(_Candidate instance) =>
    <String, dynamic>{
      'label': instance.label,
      'page': instance.page,
      'distance': instance.distance,
      'dip_doc_id': instance.dipDocId,
      'path': instance.path,
      'url': instance.url,
    };

_MatchResult _$MatchResultFromJson(Map<String, dynamic> json) => _MatchResult(
  term: json['term'] as String?,
  matched: json['matched'] as bool?,
  similarity: (json['similarity'] as num?)?.toDouble(),
  bestPage: (json['best_page'] as num?)?.toInt(),
  candidates:
      (json['candidates'] as List<dynamic>?)
          ?.map((e) => Candidate.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Candidate>[],
);

Map<String, dynamic> _$MatchResultToJson(_MatchResult instance) =>
    <String, dynamic>{
      'term': instance.term,
      'matched': instance.matched,
      'similarity': instance.similarity,
      'best_page': instance.bestPage,
      'candidates': instance.candidates.map((e) => e.toJson()).toList(),
    };
