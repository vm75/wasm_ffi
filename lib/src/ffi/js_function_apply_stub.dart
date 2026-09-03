import 'exceptions.dart';
import 'memory.dart';
import 'types.dart';

Object? applyJsFunction(
  Object base,
  List<Object> args, [
  Set<int> jsBigIntArgumentIndexes = const {},
]) {
  throw const MarshallingException(
    'JavaScript function invocation is only available in JavaScript runtimes!',
  );
}

Object? toJsFunctionArgument(Object dartObject, {bool asBigInt = false}) {
  if (dartObject is int || dartObject is double || dartObject is bool) {
    return dartObject;
  } else if (dartObject is Pointer) {
    return dartObject.address;
  }

  throw MarshallingException(
    'Could not convert dart type ${dartObject.runtimeType} to a JavaScript type!',
  );
}

T jsResultToDartType<T>(
  Object result,
  Memory memory,
  R Function<R>(Object value, Memory memory) toDartType,
) {
  return toDartType<T>(result, memory);
}
