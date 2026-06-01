import 'package:test/test.dart';
import 'package:wasm_ffi/ffi.dart';
import 'package:wasm_ffi/src/ffi/marshaller.dart' as marshaller;

void main() {
  test('identifies native i64 arguments that require JS BigInt', () {
    expect(
      marshaller
          .jsBigIntArgumentIndexesForTesting<
            Int Function(Int64, Uint64, Int, Pointer<Int64>)
          >(),
      [0, 1],
    );
  });

  test('handles native functions without arguments', () {
    expect(
      marshaller.jsBigIntArgumentIndexesForTesting<Int Function()>(),
      isEmpty,
    );
  });
}
