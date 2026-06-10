// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flashcard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Flashcard {

 String get id; String? get setId; String get front; String get back; String? get term; String? get kind; int? get page; String? get imageUrl; int? get position;
/// Create a copy of Flashcard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlashcardCopyWith<Flashcard> get copyWith => _$FlashcardCopyWithImpl<Flashcard>(this as Flashcard, _$identity);

  /// Serializes this Flashcard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Flashcard&&(identical(other.id, id) || other.id == id)&&(identical(other.setId, setId) || other.setId == setId)&&(identical(other.front, front) || other.front == front)&&(identical(other.back, back) || other.back == back)&&(identical(other.term, term) || other.term == term)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.page, page) || other.page == page)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,setId,front,back,term,kind,page,imageUrl,position);

@override
String toString() {
  return 'Flashcard(id: $id, setId: $setId, front: $front, back: $back, term: $term, kind: $kind, page: $page, imageUrl: $imageUrl, position: $position)';
}


}

/// @nodoc
abstract mixin class $FlashcardCopyWith<$Res>  {
  factory $FlashcardCopyWith(Flashcard value, $Res Function(Flashcard) _then) = _$FlashcardCopyWithImpl;
@useResult
$Res call({
 String id, String? setId, String front, String back, String? term, String? kind, int? page, String? imageUrl, int? position
});




}
/// @nodoc
class _$FlashcardCopyWithImpl<$Res>
    implements $FlashcardCopyWith<$Res> {
  _$FlashcardCopyWithImpl(this._self, this._then);

  final Flashcard _self;
  final $Res Function(Flashcard) _then;

/// Create a copy of Flashcard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? setId = freezed,Object? front = null,Object? back = null,Object? term = freezed,Object? kind = freezed,Object? page = freezed,Object? imageUrl = freezed,Object? position = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,setId: freezed == setId ? _self.setId : setId // ignore: cast_nullable_to_non_nullable
as String?,front: null == front ? _self.front : front // ignore: cast_nullable_to_non_nullable
as String,back: null == back ? _self.back : back // ignore: cast_nullable_to_non_nullable
as String,term: freezed == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,page: freezed == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Flashcard].
extension FlashcardPatterns on Flashcard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Flashcard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Flashcard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Flashcard value)  $default,){
final _that = this;
switch (_that) {
case _Flashcard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Flashcard value)?  $default,){
final _that = this;
switch (_that) {
case _Flashcard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? setId,  String front,  String back,  String? term,  String? kind,  int? page,  String? imageUrl,  int? position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Flashcard() when $default != null:
return $default(_that.id,_that.setId,_that.front,_that.back,_that.term,_that.kind,_that.page,_that.imageUrl,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? setId,  String front,  String back,  String? term,  String? kind,  int? page,  String? imageUrl,  int? position)  $default,) {final _that = this;
switch (_that) {
case _Flashcard():
return $default(_that.id,_that.setId,_that.front,_that.back,_that.term,_that.kind,_that.page,_that.imageUrl,_that.position);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? setId,  String front,  String back,  String? term,  String? kind,  int? page,  String? imageUrl,  int? position)?  $default,) {final _that = this;
switch (_that) {
case _Flashcard() when $default != null:
return $default(_that.id,_that.setId,_that.front,_that.back,_that.term,_that.kind,_that.page,_that.imageUrl,_that.position);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Flashcard implements Flashcard {
  const _Flashcard({required this.id, this.setId, required this.front, required this.back, this.term, this.kind, this.page, this.imageUrl, this.position});
  factory _Flashcard.fromJson(Map<String, dynamic> json) => _$FlashcardFromJson(json);

@override final  String id;
@override final  String? setId;
@override final  String front;
@override final  String back;
@override final  String? term;
@override final  String? kind;
@override final  int? page;
@override final  String? imageUrl;
@override final  int? position;

/// Create a copy of Flashcard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FlashcardCopyWith<_Flashcard> get copyWith => __$FlashcardCopyWithImpl<_Flashcard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FlashcardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Flashcard&&(identical(other.id, id) || other.id == id)&&(identical(other.setId, setId) || other.setId == setId)&&(identical(other.front, front) || other.front == front)&&(identical(other.back, back) || other.back == back)&&(identical(other.term, term) || other.term == term)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.page, page) || other.page == page)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,setId,front,back,term,kind,page,imageUrl,position);

@override
String toString() {
  return 'Flashcard(id: $id, setId: $setId, front: $front, back: $back, term: $term, kind: $kind, page: $page, imageUrl: $imageUrl, position: $position)';
}


}

/// @nodoc
abstract mixin class _$FlashcardCopyWith<$Res> implements $FlashcardCopyWith<$Res> {
  factory _$FlashcardCopyWith(_Flashcard value, $Res Function(_Flashcard) _then) = __$FlashcardCopyWithImpl;
@override @useResult
$Res call({
 String id, String? setId, String front, String back, String? term, String? kind, int? page, String? imageUrl, int? position
});




}
/// @nodoc
class __$FlashcardCopyWithImpl<$Res>
    implements _$FlashcardCopyWith<$Res> {
  __$FlashcardCopyWithImpl(this._self, this._then);

  final _Flashcard _self;
  final $Res Function(_Flashcard) _then;

/// Create a copy of Flashcard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? setId = freezed,Object? front = null,Object? back = null,Object? term = freezed,Object? kind = freezed,Object? page = freezed,Object? imageUrl = freezed,Object? position = freezed,}) {
  return _then(_Flashcard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,setId: freezed == setId ? _self.setId : setId // ignore: cast_nullable_to_non_nullable
as String?,front: null == front ? _self.front : front // ignore: cast_nullable_to_non_nullable
as String,back: null == back ? _self.back : back // ignore: cast_nullable_to_non_nullable
as String,term: freezed == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,page: freezed == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
