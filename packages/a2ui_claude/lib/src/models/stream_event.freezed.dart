// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StreamEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StreamEvent()';
}


}




/// Adds pattern-matching-related methods to [StreamEvent].
extension StreamEventPatterns on StreamEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeltaEvent value)?  delta,TResult Function( A2uiMessageEvent value)?  a2uiMessage,TResult Function( TextDeltaEvent value)?  textDelta,TResult Function( ThinkingEvent value)?  thinking,TResult Function( CompleteEvent value)?  complete,TResult Function( ErrorEvent value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeltaEvent() when delta != null:
return delta(_that);case A2uiMessageEvent() when a2uiMessage != null:
return a2uiMessage(_that);case TextDeltaEvent() when textDelta != null:
return textDelta(_that);case ThinkingEvent() when thinking != null:
return thinking(_that);case CompleteEvent() when complete != null:
return complete(_that);case ErrorEvent() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeltaEvent value)  delta,required TResult Function( A2uiMessageEvent value)  a2uiMessage,required TResult Function( TextDeltaEvent value)  textDelta,required TResult Function( ThinkingEvent value)  thinking,required TResult Function( CompleteEvent value)  complete,required TResult Function( ErrorEvent value)  error,}){
final _that = this;
switch (_that) {
case DeltaEvent():
return delta(_that);case A2uiMessageEvent():
return a2uiMessage(_that);case TextDeltaEvent():
return textDelta(_that);case ThinkingEvent():
return thinking(_that);case CompleteEvent():
return complete(_that);case ErrorEvent():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeltaEvent value)?  delta,TResult? Function( A2uiMessageEvent value)?  a2uiMessage,TResult? Function( TextDeltaEvent value)?  textDelta,TResult? Function( ThinkingEvent value)?  thinking,TResult? Function( CompleteEvent value)?  complete,TResult? Function( ErrorEvent value)?  error,}){
final _that = this;
switch (_that) {
case DeltaEvent() when delta != null:
return delta(_that);case A2uiMessageEvent() when a2uiMessage != null:
return a2uiMessage(_that);case TextDeltaEvent() when textDelta != null:
return textDelta(_that);case ThinkingEvent() when thinking != null:
return thinking(_that);case CompleteEvent() when complete != null:
return complete(_that);case ErrorEvent() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Map<String, dynamic> data)?  delta,TResult Function( A2uiMessageData message)?  a2uiMessage,TResult Function( String text)?  textDelta,TResult Function( String content,  bool isComplete)?  thinking,TResult Function()?  complete,TResult Function( A2uiException error)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DeltaEvent() when delta != null:
return delta(_that.data);case A2uiMessageEvent() when a2uiMessage != null:
return a2uiMessage(_that.message);case TextDeltaEvent() when textDelta != null:
return textDelta(_that.text);case ThinkingEvent() when thinking != null:
return thinking(_that.content,_that.isComplete);case CompleteEvent() when complete != null:
return complete();case ErrorEvent() when error != null:
return error(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Map<String, dynamic> data)  delta,required TResult Function( A2uiMessageData message)  a2uiMessage,required TResult Function( String text)  textDelta,required TResult Function( String content,  bool isComplete)  thinking,required TResult Function()  complete,required TResult Function( A2uiException error)  error,}) {final _that = this;
switch (_that) {
case DeltaEvent():
return delta(_that.data);case A2uiMessageEvent():
return a2uiMessage(_that.message);case TextDeltaEvent():
return textDelta(_that.text);case ThinkingEvent():
return thinking(_that.content,_that.isComplete);case CompleteEvent():
return complete();case ErrorEvent():
return error(_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Map<String, dynamic> data)?  delta,TResult? Function( A2uiMessageData message)?  a2uiMessage,TResult? Function( String text)?  textDelta,TResult? Function( String content,  bool isComplete)?  thinking,TResult? Function()?  complete,TResult? Function( A2uiException error)?  error,}) {final _that = this;
switch (_that) {
case DeltaEvent() when delta != null:
return delta(_that.data);case A2uiMessageEvent() when a2uiMessage != null:
return a2uiMessage(_that.message);case TextDeltaEvent() when textDelta != null:
return textDelta(_that.text);case ThinkingEvent() when thinking != null:
return thinking(_that.content,_that.isComplete);case CompleteEvent() when complete != null:
return complete();case ErrorEvent() when error != null:
return error(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class DeltaEvent implements StreamEvent {
  const DeltaEvent(final  Map<String, dynamic> data): _data = data;
  

/// The raw delta data from the stream.
 final  Map<String, dynamic> _data;
/// The raw delta data from the stream.
 Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeltaEvent&&const DeepCollectionEquality().equals(other._data, _data));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'StreamEvent.delta(data: $data)';
}


}




/// @nodoc


class A2uiMessageEvent implements StreamEvent {
  const A2uiMessageEvent(this.message);
  

/// The parsed A2UI message.
 final  A2uiMessageData message;




@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is A2uiMessageEvent&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'StreamEvent.a2uiMessage(message: $message)';
}


}




/// @nodoc


class TextDeltaEvent implements StreamEvent {
  const TextDeltaEvent(this.text);
  

/// The text content chunk.
 final  String text;




@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextDeltaEvent&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'StreamEvent.textDelta(text: $text)';
}


}




/// @nodoc


class ThinkingEvent implements StreamEvent {
  const ThinkingEvent(this.content, {this.isComplete = false});
  

/// The thinking content chunk.
 final  String content;
/// Whether this is the final thinking chunk for the current block.
@JsonKey() final  bool isComplete;




@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThinkingEvent&&(identical(other.content, content) || other.content == content)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete));
}


@override
int get hashCode => Object.hash(runtimeType,content,isComplete);

@override
String toString() {
  return 'StreamEvent.thinking(content: $content, isComplete: $isComplete)';
}


}




/// @nodoc


class CompleteEvent implements StreamEvent {
  const CompleteEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompleteEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StreamEvent.complete()';
}


}




/// @nodoc


class ErrorEvent implements StreamEvent {
  const ErrorEvent(this.error);
  

/// The error that occurred.
 final  A2uiException error;




@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorEvent&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'StreamEvent.error(error: $error)';
}


}




// dart format on
