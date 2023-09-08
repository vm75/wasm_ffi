import 'dart:typed_data';
import '../../../wasm_ffi_meta.dart';
import '../module.dart';

@extra
class StandaloneWasmModule extends Module {
  @override
  List<WasmSymbol> get exports => throw UnsupportedError(
      'Wasm operations are only allowed on the web (where dart:js is present)!');

  static Future<StandaloneWasmModule> compile(
          Uint8List wasmBinary, String moduleName) =>
      throw UnsupportedError(
          'Emscripten operations are only allowed on the web (where dart:js is present)!');

  @override
  void free(int pointer) => throw UnsupportedError(
      'Wasm operations are only allowed on the web (where dart:js is present)!');

  @override
  ByteBuffer get heap => throw UnsupportedError(
      'Wasm operations are only allowed on the web (where dart:js is present)!');

  @override
  int malloc(int size) => throw UnsupportedError(
      'Wasm operations are only allowed on the web (where dart:js is present)!');

  Function? getMethod(String methodName) => throw UnsupportedError(
      'Wasm operations are only allowed on the web (where dart:js is present)!');
}
