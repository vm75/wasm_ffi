// ignore_for_file: avoid_relative_lib_imports, avoid_print

import 'package:wasm_ffi/ffi_bridge.dart';
import 'package:wasm_ffi/src/ffi/type_utils.dart';

void main() {
  print(pointerPointerPointerPrefix);
  print(pointerNativeFunctionPrefix);
  print(isVoidType<Void>());
  print(isVoidType<NativeType>());
}
