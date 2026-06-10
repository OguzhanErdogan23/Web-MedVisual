import 'package:freezed_annotation/freezed_annotation.dart';

part 'candidate.freezed.dart';
part 'candidate.g.dart';

/// Karta onerilen gorsel adayi (DIP motoru ciktisi).
@freezed
abstract class Candidate with _$Candidate {
  const factory Candidate({
    String? label,
    int? page,
    double? distance,
    required String dipDocId,
    required String path,
    required String url,
  }) = _Candidate;

  factory Candidate.fromJson(Map<String, dynamic> json) =>
      _$CandidateFromJson(json);
}

/// /cards/{id}/match yaniti.
@freezed
abstract class MatchResult with _$MatchResult {
  const factory MatchResult({
    String? term,
    bool? matched,
    double? similarity,
    int? bestPage,
    @Default(<Candidate>[]) List<Candidate> candidates,
  }) = _MatchResult;

  factory MatchResult.fromJson(Map<String, dynamic> json) =>
      _$MatchResultFromJson(json);
}
