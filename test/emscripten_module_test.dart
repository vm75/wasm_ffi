import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:wasm_ffi/src/ffi/modules/emscripten_module.dart';
import 'package:wasm_ffi/src/ffi/modules/module.dart';
import 'package:wasm_ffi/src/js_utils/wasm_interop.dart';

@JS('WebAssembly.Global')
extension type TestGlobal._(JSObject _) implements JSObject {
  external factory TestGlobal(GlobalDescriptor descriptor, JSNumber initial);
}

Future<Instance> loadFixture() async {
  for (final path in [
    'standalone_test_module.wasm',
    'test/standalone_test_module.wasm',
  ]) {
    final response = await http.get(Uri.base.resolve(path));
    if (response.statusCode == 200) {
      return Instance.loadFromBinary(response.bodyBytes);
    }
  }
  throw StateError('Could not load the existing standalone Wasm fixture');
}

void main() {
  for (final exportProperty in ['asm', 'wasmExports']) {
    test('reads $exportProperty exports on JavaScript and Wasm', () async {
      final instance = await loadFixture();
      final exports = JSObject();
      for (final key in WrappedJSObject.keys(
        instance.nativeInstance.exports,
      ).toDart) {
        exports.setProperty(
          key!,
          instance.nativeInstance.exports.getProperty<JSAny?>(key),
        );
      }
      // Cover numeric exports in addition to WebAssembly.Global objects.
      exports.setProperty('numeric_global'.toJS, 0x7ffff0.toJS);
      exports.setProperty(
        'wasm_global'.toJS,
        TestGlobal(GlobalDescriptor(value: 'i32'.toJS), 4096.toJS),
      );
      final module = EmscriptenModuleJs();
      module.setProperty(exportProperty.toJS, exports);
      module.setProperty(
        'HEAPU8'.toJS,
        JSUint8Array(instance.memories['memory']!.buffer),
      );
      final moduleName = 'wasm_ffi_test_$exportProperty';
      globalContext.setProperty(moduleName.toJS, (() => module).toJS);
      addTearDown(() => globalContext.delete(moduleName.toJS));

      final parsed = await EmscriptenModule.compile(moduleName);
      final add = parsed.exports.whereType<FunctionDescription>().singleWhere(
        (symbol) => symbol.name == 'add32',
      );
      expect(add.argumentCount, 2);
      expect(
        (add.function.callAsFunction(null, 12.toJS, 30.toJS)! as JSNumber)
            .toDartInt,
        42,
      );
      final globals = {
        for (final symbol in parsed.exports.whereType<Global>())
          symbol.name: symbol.address,
      };
      expect(globals['numeric_global'], 0x7ffff0);
      expect(globals['wasm_global'], 4096);

      final address = parsed.malloc(1);
      final heap = Uint8List.view(parsed.heap);
      heap[address] = 123;
      expect(heap[address], 123);
      parsed.free(address);
    });
  }
}
