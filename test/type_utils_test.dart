import '../lib/src/internal/type_utils.dart';
import '../lib/wasm_ffi.dart';

void main() {
  print(pointerPointerPointerPrefix);
  print(pointerNativeFunctionPrefix);
  print(isVoidType<Void>());
  print(isVoidType<NativeType>());
}
