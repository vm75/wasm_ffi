import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'exceptions.dart';
import 'memory.dart';
import 'types.dart';

@JS('BigInt')
external JSBigInt _bigInt(JSAny? obj);

extension type _WrappedJSAny._(JSAny _) implements JSAny {
  @JS('toString')
  external JSString _toString();
}

Object? applyJsFunction(
  Object base,
  List<Object> args, [
  Set<int> jsBigIntArgumentIndexes = const {},
]) {
  final jsFunction = base as JSFunction;
  final JSFunction apply = (jsFunction as JSObject).getProperty<JSFunction>(
    'apply'.toJS,
  );
  final jsArgs = <JSAny?>[
    for (var i = 0; i < args.length; i++)
      _toJsAny(args[i], asBigInt: jsBigIntArgumentIndexes.contains(i)),
  ];
  return apply.callAsFunction(jsFunction, null, jsArgs.toJS);
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
      return _jsBigIntToDartInt(jsResult) as T;
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
    return toDartType<T>(_jsBigIntToDartInt(jsResult), memory);
  }

  final Object? dartified = jsResult.dartify();
  if (dartified == null) {
    return null as T;
  }
  return toDartType<T>(dartified, memory);
}

int _jsBigIntToDartInt(JSAny jsBigInt) {
  return BigInt.parse((jsBigInt as _WrappedJSAny)._toString().toDart).toInt();
}

JSAny? _toJsAny(Object dartObject, {bool asBigInt = false}) {
  if (dartObject is int) {
    return asBigInt ? _bigInt(dartObject.toString().toJS) : dartObject.toJS;
  } else if (dartObject is double) {
    return dartObject.toJS;
  } else if (dartObject is bool) {
    return dartObject.toJS;
  } else if (dartObject is Pointer) {
    return asBigInt
        ? _bigInt(dartObject.address.toString().toJS)
        : dartObject.address.toJS;
  } else {
    throw MarshallingException(
      'Could not convert dart type ${dartObject.runtimeType} to a JavaScript type!',
    );
  }
}
