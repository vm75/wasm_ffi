// ignore_for_file: avoid_relative_lib_imports, avoid_print

import '../lib/src/internal/type_utils.dart';
import '../lib/wasm_ffi.dart';

void main() {
  print(pointerPointerPointerPrefix);
  print(pointerNativeFunctionPrefix);
  print(isVoidType<Void>());
  print(isVoidType<NativeType>());
}
