// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'documents_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DocumentsState {

 ViewStatus get status; List<Document> get documents; StudyStats? get stats; StudyHistory? get history; bool get uploading; String? get error; String? get notice;
/// Create a copy of DocumentsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentsStateCopyWith<DocumentsState> get copyWith => _$DocumentsStateCopyWithImpl<DocumentsState>(this as DocumentsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.documents, documents)&&(identical(other.stats, stats) || other.stats == stats)&&(identical(other.history, history) || other.history == history)&&(identical(other.uploading, uploading) || other.uploading == uploading)&&(identical(other.error, error) || other.error == error)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(documents),stats,history,uploading,error,notice);

@override
String toString() {
  return 'DocumentsState(status: $status, documents: $documents, stats: $stats, history: $history, uploading: $uploading, error: $error, notice: $notice)';
}


}

/// @nodoc
abstract mixin class $DocumentsStateCopyWith<$Res>  {
  factory $DocumentsStateCopyWith(DocumentsState value, $Res Function(DocumentsState) _then) = _$DocumentsStateCopyWithImpl;
@useResult
$Res call({
 ViewStatus status, List<Document> documents, StudyStats? stats, StudyHistory? history, bool uploading, String? error, String? notice
});


$StudyStatsCopyWith<$Res>? get stats;$StudyHistoryCopyWith<$Res>? get history;

}
/// @nodoc
class _$DocumentsStateCopyWithImpl<$Res>
    implements $DocumentsStateCopyWith<$Res> {
  _$DocumentsStateCopyWithImpl(this._self, this._then);

  final DocumentsState _self;
  final $Res Function(DocumentsState) _then;

/// Create a copy of DocumentsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? documents = null,Object? stats = freezed,Object? history = freezed,Object? uploading = null,Object? error = freezed,Object? notice = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ViewStatus,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,stats: freezed == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as StudyStats?,history: freezed == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as StudyHistory?,uploading: null == uploading ? _self.uploading : uploading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of DocumentsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StudyStatsCopyWith<$Res>? get stats {
    if (_self.stats == null) {
    return null;
  }

  return $StudyStatsCopyWith<$Res>(_self.stats!, (value) {
    return _then(_self.copyWith(stats: value));
  });
}/// Create a copy of DocumentsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StudyHistoryCopyWith<$Res>? get history {
    if (_self.history == null) {
    return null;
  }

  return $StudyHistoryCopyWith<$Res>(_self.history!, (value) {
    return _then(_self.copyWith(history: value));
  });
}
}


/// Adds pattern-matching-related methods to [DocumentsState].
extension DocumentsStatePatterns on DocumentsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentsState value)  $default,){
final _that = this;
switch (_that) {
case _DocumentsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentsState value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ViewStatus status,  List<Document> documents,  StudyStats? stats,  StudyHistory? history,  bool uploading,  String? error,  String? notice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentsState() when $default != null:
return $default(_that.status,_that.documents,_that.stats,_that.history,_that.uploading,_that.error,_that.notice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ViewStatus status,  List<Document> documents,  StudyStats? stats,  StudyHistory? history,  bool uploading,  String? error,  String? notice)  $default,) {final _that = this;
switch (_that) {
case _DocumentsState():
return $default(_that.status,_that.documents,_that.stats,_that.history,_that.uploading,_that.error,_that.notice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ViewStatus status,  List<Document> documents,  StudyStats? stats,  StudyHistory? history,  bool uploading,  String? error,  String? notice)?  $default,) {final _that = this;
switch (_that) {
case _DocumentsState() when $default != null:
return $default(_that.status,_that.documents,_that.stats,_that.history,_that.uploading,_that.error,_that.notice);case _:
  return null;

}
}

}

/// @nodoc


class _DocumentsState implements DocumentsState {
  const _DocumentsState({this.status = ViewStatus.initial, final  List<Document> documents = const <Document>[], this.stats, this.history, this.uploading = false, this.error, this.notice}): _documents = documents;
  

@override@JsonKey() final  ViewStatus status;
 final  List<Document> _documents;
@override@JsonKey() List<Document> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}

@override final  StudyStats? stats;
@override final  StudyHistory? history;
@override@JsonKey() final  bool uploading;
@override final  String? error;
@override final  String? notice;

/// Create a copy of DocumentsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentsStateCopyWith<_DocumentsState> get copyWith => __$DocumentsStateCopyWithImpl<_DocumentsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._documents, _documents)&&(identical(other.stats, stats) || other.stats == stats)&&(identical(other.history, history) || other.history == history)&&(identical(other.uploading, uploading) || other.uploading == uploading)&&(identical(other.error, error) || other.error == error)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_documents),stats,history,uploading,error,notice);

@override
String toString() {
  return 'DocumentsState(status: $status, documents: $documents, stats: $stats, history: $history, uploading: $uploading, error: $error, notice: $notice)';
}


}

/// @nodoc
abstract mixin class _$DocumentsStateCopyWith<$Res> implements $DocumentsStateCopyWith<$Res> {
  factory _$DocumentsStateCopyWith(_DocumentsState value, $Res Function(_DocumentsState) _then) = __$DocumentsStateCopyWithImpl;
@override @useResult
$Res call({
 ViewStatus status, List<Document> documents, StudyStats? stats, StudyHistory? history, bool uploading, String? error, String? notice
});


@override $StudyStatsCopyWith<$Res>? get stats;@override $StudyHistoryCopyWith<$Res>? get history;

}
/// @nodoc
class __$DocumentsStateCopyWithImpl<$Res>
    implements _$DocumentsStateCopyWith<$Res> {
  __$DocumentsStateCopyWithImpl(this._self, this._then);

  final _DocumentsState _self;
  final $Res Function(_DocumentsState) _then;

/// Create a copy of DocumentsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? documents = null,Object? stats = freezed,Object? history = freezed,Object? uploading = null,Object? error = freezed,Object? notice = freezed,}) {
  return _then(_DocumentsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ViewStatus,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,stats: freezed == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as StudyStats?,history: freezed == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as StudyHistory?,uploading: null == uploading ? _self.uploading : uploading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of DocumentsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StudyStatsCopyWith<$Res>? get stats {
    if (_self.stats == null) {
    return null;
  }

  return $StudyStatsCopyWith<$Res>(_self.stats!, (value) {
    return _then(_self.copyWith(stats: value));
  });
}/// Create a copy of DocumentsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StudyHistoryCopyWith<$Res>? get history {
    if (_self.history == null) {
    return null;
  }

  return $StudyHistoryCopyWith<$Res>(_self.history!, (value) {
    return _then(_self.copyWith(history: value));
  });
}
}

// dart format on
