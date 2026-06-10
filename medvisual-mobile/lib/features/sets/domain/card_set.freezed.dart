// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_set.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CardSet {

 String get id; String get title; String? get description; String get status; String? get error; String? get documentId; int get cardCount; List<Flashcard> get cards; DateTime? get createdAt;
/// Create a copy of CardSet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardSetCopyWith<CardSet> get copyWith => _$CardSetCopyWithImpl<CardSet>(this as CardSet, _$identity);

  /// Serializes this CardSet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardSet&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.cardCount, cardCount) || other.cardCount == cardCount)&&const DeepCollectionEquality().equals(other.cards, cards)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,status,error,documentId,cardCount,const DeepCollectionEquality().hash(cards),createdAt);

@override
String toString() {
  return 'CardSet(id: $id, title: $title, description: $description, status: $status, error: $error, documentId: $documentId, cardCount: $cardCount, cards: $cards, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CardSetCopyWith<$Res>  {
  factory $CardSetCopyWith(CardSet value, $Res Function(CardSet) _then) = _$CardSetCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? description, String status, String? error, String? documentId, int cardCount, List<Flashcard> cards, DateTime? createdAt
});




}
/// @nodoc
class _$CardSetCopyWithImpl<$Res>
    implements $CardSetCopyWith<$Res> {
  _$CardSetCopyWithImpl(this._self, this._then);

  final CardSet _self;
  final $Res Function(CardSet) _then;

/// Create a copy of CardSet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? status = null,Object? error = freezed,Object? documentId = freezed,Object? cardCount = null,Object? cards = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,documentId: freezed == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String?,cardCount: null == cardCount ? _self.cardCount : cardCount // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<Flashcard>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CardSet].
extension CardSetPatterns on CardSet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardSet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardSet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardSet value)  $default,){
final _that = this;
switch (_that) {
case _CardSet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardSet value)?  $default,){
final _that = this;
switch (_that) {
case _CardSet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  String status,  String? error,  String? documentId,  int cardCount,  List<Flashcard> cards,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardSet() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.status,_that.error,_that.documentId,_that.cardCount,_that.cards,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  String status,  String? error,  String? documentId,  int cardCount,  List<Flashcard> cards,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _CardSet():
return $default(_that.id,_that.title,_that.description,_that.status,_that.error,_that.documentId,_that.cardCount,_that.cards,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? description,  String status,  String? error,  String? documentId,  int cardCount,  List<Flashcard> cards,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CardSet() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.status,_that.error,_that.documentId,_that.cardCount,_that.cards,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CardSet extends CardSet {
  const _CardSet({required this.id, required this.title, this.description, required this.status, this.error, this.documentId, this.cardCount = 0, final  List<Flashcard> cards = const <Flashcard>[], this.createdAt}): _cards = cards,super._();
  factory _CardSet.fromJson(Map<String, dynamic> json) => _$CardSetFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? description;
@override final  String status;
@override final  String? error;
@override final  String? documentId;
@override@JsonKey() final  int cardCount;
 final  List<Flashcard> _cards;
@override@JsonKey() List<Flashcard> get cards {
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cards);
}

@override final  DateTime? createdAt;

/// Create a copy of CardSet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardSetCopyWith<_CardSet> get copyWith => __$CardSetCopyWithImpl<_CardSet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CardSetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardSet&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.cardCount, cardCount) || other.cardCount == cardCount)&&const DeepCollectionEquality().equals(other._cards, _cards)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,status,error,documentId,cardCount,const DeepCollectionEquality().hash(_cards),createdAt);

@override
String toString() {
  return 'CardSet(id: $id, title: $title, description: $description, status: $status, error: $error, documentId: $documentId, cardCount: $cardCount, cards: $cards, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CardSetCopyWith<$Res> implements $CardSetCopyWith<$Res> {
  factory _$CardSetCopyWith(_CardSet value, $Res Function(_CardSet) _then) = __$CardSetCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? description, String status, String? error, String? documentId, int cardCount, List<Flashcard> cards, DateTime? createdAt
});




}
/// @nodoc
class __$CardSetCopyWithImpl<$Res>
    implements _$CardSetCopyWith<$Res> {
  __$CardSetCopyWithImpl(this._self, this._then);

  final _CardSet _self;
  final $Res Function(_CardSet) _then;

/// Create a copy of CardSet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? status = null,Object? error = freezed,Object? documentId = freezed,Object? cardCount = null,Object? cards = null,Object? createdAt = freezed,}) {
  return _then(_CardSet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,documentId: freezed == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String?,cardCount: null == cardCount ? _self.cardCount : cardCount // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<Flashcard>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
