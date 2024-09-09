// ignore_for_file: avoid_relative_lib_imports, avoid_print

import 'package:wasm_ffi/src/ffi/type_utils.dart';
import 'package:wasm_ffi/wasm_ffi.dart';

void main() {
  print(pointerPointerPointerPrefix);
  print(pointerNativeFunctionPrefix);
  print(isVoidType<Void>());
  print(isVoidType<NativeType>());
}
