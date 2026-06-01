import 'exceptions.dart';
import 'memory.dart';

Object? applyJsFunction(Object base, List<Object> args) {
  throw const MarshallingException(
    'JavaScript function invocation is only available in JavaScript runtimes!',
  );
}

T jsResultToDartType<T>(
  Object result,
  Memory memory,
  R Function<R>(Object value, Memory memory) toDartType,
) {
  return toDartType<T>(result, memory);
}
