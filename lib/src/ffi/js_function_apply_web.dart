import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'exceptions.dart';
import 'memory.dart';
import 'types.dart';

@JS('Number')
external JSNumber _number(JSAny? obj);

Object? applyJsFunction(Object base, List<Object> args) {
  final jsFunction = base as JSFunction;
  final JSFunction apply = (jsFunction as JSObject).getProperty<JSFunction>(
    'apply'.toJS,
  );
  return apply.callAsFunction(
    jsFunction,
    null,
    args.map(_toJsAny).toList().toJS,
  );
}

T jsResultToDartType<T>(
  Object result,
  Memory memory,
  R Function<R>(Object value, Memory memory) toDartType,
) {
  final jsResult = result as JSAny;
  if (T == int) {
    if (jsResult.typeofEquals('number')) {
      return (jsResult as JSNumber).toDartInt as T;
    }
    if (jsResult.typeofEquals('bigint')) {
      return _number(jsResult).toDartInt as T;
    }
  } else if (T == double) {
    if (jsResult.typeofEquals('number')) {
      return (jsResult as JSNumber).toDartDouble as T;
    }
  } else if (T == bool) {
    if (jsResult.typeofEquals('boolean')) {
      return (jsResult as JSBoolean).toDart as T;
    }
    if (jsResult.typeofEquals('number')) {
      return toDartType<T>((jsResult as JSNumber).toDartInt, memory);
    }
  } else if (jsResult.typeofEquals('number')) {
    return toDartType<T>((jsResult as JSNumber).toDartInt, memory);
  } else if (jsResult.typeofEquals('bigint')) {
    return toDartType<T>(_number(jsResult).toDartInt, memory);
  }

  final Object? dartified = jsResult.dartify();
  if (dartified == null) {
    return null as T;
  }
  return toDartType<T>(dartified, memory);
}

JSAny? _toJsAny(Object dartObject) {
  if (dartObject is int || dartObject is double) {
    return (dartObject as num).toJS;
  } else if (dartObject is bool) {
    return dartObject.toJS;
  } else if (dartObject is Pointer) {
    return dartObject.address.toJS;
  } else {
    throw MarshallingException(
      'Could not convert dart type ${dartObject.runtimeType} to a JavaScript type!',
    );
  }
}
