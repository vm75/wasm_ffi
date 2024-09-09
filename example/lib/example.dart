import 'package:wasm_ffi/ffi_bridge.dart';
import 'package:wasm_ffi/ffi_utils_bridge.dart';
import 'package:wasm_ffi/ffi_wrapper.dart';
import 'libopus_bindings.dart';
import 'wasmffi_bindings.dart';

class Result {
  final String helloStr;
  int sizeOfInt;
  int sizeOfBool;
  int sizeOfPointer;

  Result(this.helloStr, this.sizeOfInt, this.sizeOfBool, this.sizeOfPointer);

  @override
  String toString() {
    return 'hello: $helloStr, int: $sizeOfInt, bool: $sizeOfBool, pointer: $sizeOfPointer';
  }
}

Future<Result> testWasmFfi(String name, bool standalone) async {
  FfiWrapper? ffiWrapper;
  if (standalone) {
    ffiWrapper = await FfiWrapper.load('assets/standalone/WasmFfi.wasm');
  } else {
    ffiWrapper = await FfiWrapper.load('assets/emscripten/WasmFfi.js');
  }

  WasmFfiBindings bindings = WasmFfiBindings(ffiWrapper.library);

  return ffiWrapper.safeUsing((Arena arena) {
    Pointer<Char> cString = name.toNativeUtf8().cast<Char>();
    String helloStr = bindings.hello(cString).cast<Utf8>().toDartString();
    int sizeOfInt = bindings.intSize();
    int sizeOfBool = bindings.boolSize();
    int sizeOfPointer = bindings.pointerSize();
    return Result(helloStr, sizeOfInt, sizeOfBool, sizeOfPointer);
  });
}

Future<String> testLibOpus() async {
  final ffiWrapper = await FfiWrapper.load('assets/emscripten/libopus.js');

  FunctionsAndGlobals bindings = FunctionsAndGlobals(ffiWrapper.library);

  return ffiWrapper.safeUsing((Arena arena) {
    String version =
        bindings.opus_get_version_string().cast<Utf8>().toDartString();
    return version;
  });
}
