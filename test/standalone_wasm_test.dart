import 'package:test/test.dart';
import 'package:wasm_ffi/ffi.dart';
import 'package:wasm_ffi/ffi_utils.dart'; // Maybe not needed, but good

// Declare types
typedef Add32Native = Uint32 Function(Uint32 a, Uint32 b);
typedef Add32Dart = int Function(int a, int b);

typedef Add64Native = Uint64 Function(Uint64 a, Uint64 b);
typedef Add64Dart = int Function(int a, int b);

typedef DerefU8Native = Uint8 Function(Pointer<Uint8> ptr);
typedef DerefU8Dart = int Function(Pointer<Uint8> ptr);

typedef WriteU8Native = Void Function(Pointer<Uint8> ptr, Uint8 val);
typedef WriteU8Dart = void Function(Pointer<Uint8> ptr, int val);

void main() {
  group('Standalone Wasm Tests', () {
    late DynamicLibrary dylib;

    setUpAll(() async {
      // For a browser test, the root is usually the test path or root workspace.
      // test/standalone_test_module.wasm will be served by dart test.
      // The relative path is usually just the file name because the test html is in the same dir,
      // but let's try 'standalone_test_module.wasm'.
      // DynamicLibrary.open uses `http` by default in WebModuleLoader.
      try {
        dylib = await DynamicLibrary.open(
          'standalone_test_module.wasm',
          wasmType: WasmType.wasm32Standalone,
        );
      } catch (e) {
        // Fallback if the path is different
        dylib = await DynamicLibrary.open(
          'test/standalone_test_module.wasm',
          wasmType: WasmType.wasm32Standalone,
        );
      }
    });

    test('add32 (32-bit int)', () {
      final add32 = dylib.lookupFunction<Add32Native, Add32Dart>('add32');
      expect(add32(10, 20), equals(30));
    });

    test('add64 (64-bit int)', () {
      final add64 = dylib.lookupFunction<Add64Native, Add64Dart>('add64');
      expect(add64(100, 200), equals(300));
    });

    test('add64 (large 64-bit int)', () {
      final add64 = dylib.lookupFunction<Add64Native, Add64Dart>('add64');
      // Let's test with values larger than 32-bit max
      final a = 4294967296; // 2^32
      final b = 4294967296; // 2^32
      expect(add64(a, b), equals(a + b));
    });

    test(
      'pointer read/write (32-bit pointers but we handle them transparently)',
      () {
        final derefU8 = dylib.lookupFunction<DerefU8Native, DerefU8Dart>(
          'deref_u8',
        );
        final writeU8 = dylib.lookupFunction<WriteU8Native, WriteU8Dart>(
          'write_u8',
        );

        final ptr = malloc.allocate<Uint8>(1);

        writeU8(ptr, 42);
        final val = derefU8(ptr);

        expect(val, equals(42));

        // Also verify via the dart pointer abstraction
        expect(ptr.value, equals(42));

        ptr.value = 99;
        expect(derefU8(ptr), equals(99));

        malloc.free(ptr);
      },
    );

    test('lookup asFunction equivalent to lookupFunction', () {
      final add64_1 = dylib.lookupFunction<Add64Native, Add64Dart>('add64');
      final add64_2 = dylib
          .lookup<NativeFunction<Add64Native>>('add64')
          .asFunction<Add64Dart>();

      expect(add64_1(5, 5), equals(10));
      expect(add64_2(5, 5), equals(10));
    });

    test('lookup missing symbol throws ArgumentError', () {
      expect(
        () => dylib.lookupFunction<Add32Native, Add32Dart>('missing'),
        throwsArgumentError,
      );
    });

    test('lookup non-function symbol as function throws', () {
      // "dummy" is exported but is memory/global data, not a function
      expect(
        () => dylib.lookupFunction<Add32Native, Add32Dart>('dummy'),
        throwsArgumentError,
      );
    });
  });
}
