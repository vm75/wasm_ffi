import 'package:test/test.dart';
import 'package:wasm_ffi/ffi.dart';
import 'package:wasm_ffi/src/ffi/type_utils.dart';

void main() {
  test('type utils prefixes and void checks', () {
    expect(pointerPointerPointerPrefix, isNotEmpty);
    expect(pointerNativeFunctionPrefix, isNotEmpty);
    expect(isVoidType<Void>(), isTrue);
    expect(isVoidType<NativeType>(), isFalse);
  });
}
