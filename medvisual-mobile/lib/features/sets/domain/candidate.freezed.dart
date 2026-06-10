// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'candidate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Candidate {

 String? get label; int? get page; double? get distance; String get dipDocId; String get path; String get url;
/// Create a copy of Candidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CandidateCopyWith<Candidate> get copyWith => _$CandidateCopyWithImpl<Candidate>(this as Candidate, _$identity);

  /// Serializes this Candidate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Candidate&&(identical(other.label, label) || other.label == label)&&(identical(other.page, page) || other.page == page)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.dipDocId, dipDocId) || other.dipDocId == dipDocId)&&(identical(other.path, path) || other.path == path)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,page,distance,dipDocId,path,url);

@override
String toString() {
  return 'Candidate(label: $label, page: $page, distance: $distance, dipDocId: $dipDocId, path: $path, url: $url)';
}


}

/// @nodoc
abstract mixin class $CandidateCopyWith<$Res>  {
  factory $CandidateCopyWith(Candidate value, $Res Function(Candidate) _then) = _$CandidateCopyWithImpl;
@useResult
$Res call({
 String? label, int? page, double? distance, String dipDocId, String path, String url
});




}
/// @nodoc
class _$CandidateCopyWithImpl<$Res>
    implements $CandidateCopyWith<$Res> {
  _$CandidateCopyWithImpl(this._self, this._then);

  final Candidate _self;
  final $Res Function(Candidate) _then;

/// Create a copy of Candidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = freezed,Object? page = freezed,Object? distance = freezed,Object? dipDocId = null,Object? path = null,Object? url = null,}) {
  return _then(_self.copyWith(
label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,page: freezed == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int?,distance: freezed == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double?,dipDocId: null == dipDocId ? _self.dipDocId : dipDocId // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Candidate].
extension CandidatePatterns on Candidate {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Candidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Candidate() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Candidate value)  $default,){
final _that = this;
switch (_that) {
case _Candidate():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Candidate value)?  $default,){
final _that = this;
switch (_that) {
case _Candidate() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? label,  int? page,  double? distance,  String dipDocId,  String path,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Candidate() when $default != null:
return $default(_that.label,_that.page,_that.distance,_that.dipDocId,_that.path,_that.url);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? label,  int? page,  double? distance,  String dipDocId,  String path,  String url)  $default,) {final _that = this;
switch (_that) {
case _Candidate():
return $default(_that.label,_that.page,_that.distance,_that.dipDocId,_that.path,_that.url);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? label,  int? page,  double? distance,  String dipDocId,  String path,  String url)?  $default,) {final _that = this;
switch (_that) {
case _Candidate() when $default != null:
return $default(_that.label,_that.page,_that.distance,_that.dipDocId,_that.path,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Candidate implements Candidate {
  const _Candidate({this.label, this.page, this.distance, required this.dipDocId, required this.path, required this.url});
  factory _Candidate.fromJson(Map<String, dynamic> json) => _$CandidateFromJson(json);

@override final  String? label;
@override final  int? page;
@override final  double? distance;
@override final  String dipDocId;
@override final  String path;
@override final  String url;

/// Create a copy of Candidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CandidateCopyWith<_Candidate> get copyWith => __$CandidateCopyWithImpl<_Candidate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CandidateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Candidate&&(identical(other.label, label) || other.label == label)&&(identical(other.page, page) || other.page == page)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.dipDocId, dipDocId) || other.dipDocId == dipDocId)&&(identical(other.path, path) || other.path == path)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,page,distance,dipDocId,path,url);

@override
String toString() {
  return 'Candidate(label: $label, page: $page, distance: $distance, dipDocId: $dipDocId, path: $path, url: $url)';
}


}

/// @nodoc
abstract mixin class _$CandidateCopyWith<$Res> implements $CandidateCopyWith<$Res> {
  factory _$CandidateCopyWith(_Candidate value, $Res Function(_Candidate) _then) = __$CandidateCopyWithImpl;
@override @useResult
$Res call({
 String? label, int? page, double? distance, String dipDocId, String path, String url
});




}
/// @nodoc
class __$CandidateCopyWithImpl<$Res>
    implements _$CandidateCopyWith<$Res> {
  __$CandidateCopyWithImpl(this._self, this._then);

  final _Candidate _self;
  final $Res Function(_Candidate) _then;

/// Create a copy of Candidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = freezed,Object? page = freezed,Object? distance = freezed,Object? dipDocId = null,Object? path = null,Object? url = null,}) {
  return _then(_Candidate(
label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,page: freezed == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int?,distance: freezed == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double?,dipDocId: null == dipDocId ? _self.dipDocId : dipDocId // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MatchResult {

 String? get term; bool? get matched; double? get similarity; int? get bestPage; List<Candidate> get candidates;
/// Create a copy of MatchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchResultCopyWith<MatchResult> get copyWith => _$MatchResultCopyWithImpl<MatchResult>(this as MatchResult, _$identity);

  /// Serializes this MatchResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchResult&&(identical(other.term, term) || other.term == term)&&(identical(other.matched, matched) || other.matched == matched)&&(identical(other.similarity, similarity) || other.similarity == similarity)&&(identical(other.bestPage, bestPage) || other.bestPage == bestPage)&&const DeepCollectionEquality().equals(other.candidates, candidates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,term,matched,similarity,bestPage,const DeepCollectionEquality().hash(candidates));

@override
String toString() {
  return 'MatchResult(term: $term, matched: $matched, similarity: $similarity, bestPage: $bestPage, candidates: $candidates)';
}


}

/// @nodoc
abstract mixin class $MatchResultCopyWith<$Res>  {
  factory $MatchResultCopyWith(MatchResult value, $Res Function(MatchResult) _then) = _$MatchResultCopyWithImpl;
@useResult
$Res call({
 String? term, bool? matched, double? similarity, int? bestPage, List<Candidate> candidates
});




}
/// @nodoc
class _$MatchResultCopyWithImpl<$Res>
    implements $MatchResultCopyWith<$Res> {
  _$MatchResultCopyWithImpl(this._self, this._then);

  final MatchResult _self;
  final $Res Function(MatchResult) _then;

/// Create a copy of MatchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? term = freezed,Object? matched = freezed,Object? similarity = freezed,Object? bestPage = freezed,Object? candidates = null,}) {
  return _then(_self.copyWith(
term: freezed == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String?,matched: freezed == matched ? _self.matched : matched // ignore: cast_nullable_to_non_nullable
as bool?,similarity: freezed == similarity ? _self.similarity : similarity // ignore: cast_nullable_to_non_nullable
as double?,bestPage: freezed == bestPage ? _self.bestPage : bestPage // ignore: cast_nullable_to_non_nullable
as int?,candidates: null == candidates ? _self.candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<Candidate>,
  ));
}

}


/// Adds pattern-matching-related methods to [MatchResult].
extension MatchResultPatterns on MatchResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchResult value)  $default,){
final _that = this;
switch (_that) {
case _MatchResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchResult value)?  $default,){
final _that = this;
switch (_that) {
case _MatchResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? term,  bool? matched,  double? similarity,  int? bestPage,  List<Candidate> candidates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchResult() when $default != null:
return $default(_that.term,_that.matched,_that.similarity,_that.bestPage,_that.candidates);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? term,  bool? matched,  double? similarity,  int? bestPage,  List<Candidate> candidates)  $default,) {final _that = this;
switch (_that) {
case _MatchResult():
return $default(_that.term,_that.matched,_that.similarity,_that.bestPage,_that.candidates);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? term,  bool? matched,  double? similarity,  int? bestPage,  List<Candidate> candidates)?  $default,) {final _that = this;
switch (_that) {
case _MatchResult() when $default != null:
return $default(_that.term,_that.matched,_that.similarity,_that.bestPage,_that.candidates);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MatchResult implements MatchResult {
  const _MatchResult({this.term, this.matched, this.similarity, this.bestPage, final  List<Candidate> candidates = const <Candidate>[]}): _candidates = candidates;
  factory _MatchResult.fromJson(Map<String, dynamic> json) => _$MatchResultFromJson(json);

@override final  String? term;
@override final  bool? matched;
@override final  double? similarity;
@override final  int? bestPage;
 final  List<Candidate> _candidates;
@override@JsonKey() List<Candidate> get candidates {
  if (_candidates is EqualUnmodifiableListView) return _candidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candidates);
}


/// Create a copy of MatchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchResultCopyWith<_MatchResult> get copyWith => __$MatchResultCopyWithImpl<_MatchResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchResult&&(identical(other.term, term) || other.term == term)&&(identical(other.matched, matched) || other.matched == matched)&&(identical(other.similarity, similarity) || other.similarity == similarity)&&(identical(other.bestPage, bestPage) || other.bestPage == bestPage)&&const DeepCollectionEquality().equals(other._candidates, _candidates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,term,matched,similarity,bestPage,const DeepCollectionEquality().hash(_candidates));

@override
String toString() {
  return 'MatchResult(term: $term, matched: $matched, similarity: $similarity, bestPage: $bestPage, candidates: $candidates)';
}


}

/// @nodoc
abstract mixin class _$MatchResultCopyWith<$Res> implements $MatchResultCopyWith<$Res> {
  factory _$MatchResultCopyWith(_MatchResult value, $Res Function(_MatchResult) _then) = __$MatchResultCopyWithImpl;
@override @useResult
$Res call({
 String? term, bool? matched, double? similarity, int? bestPage, List<Candidate> candidates
});




}
/// @nodoc
class __$MatchResultCopyWithImpl<$Res>
    implements _$MatchResultCopyWith<$Res> {
  __$MatchResultCopyWithImpl(this._self, this._then);

  final _MatchResult _self;
  final $Res Function(_MatchResult) _then;

/// Create a copy of MatchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? term = freezed,Object? matched = freezed,Object? similarity = freezed,Object? bestPage = freezed,Object? candidates = null,}) {
  return _then(_MatchResult(
term: freezed == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String?,matched: freezed == matched ? _self.matched : matched // ignore: cast_nullable_to_non_nullable
as bool?,similarity: freezed == similarity ? _self.similarity : similarity // ignore: cast_nullable_to_non_nullable
as double?,bestPage: freezed == bestPage ? _self.bestPage : bestPage // ignore: cast_nullable_to_non_nullable
as int?,candidates: null == candidates ? _self._candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<Candidate>,
  ));
}


}

// dart format on
