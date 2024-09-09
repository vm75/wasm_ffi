import 'package:wasm_ffi/ffi_helper.dart';
import 'package:wasm_ffi/wasm_ffi.dart';
import 'package:wasm_ffi/wasm_ffi_utils.dart';
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
  FfiHelper? ffiHelper;
  if (standalone) {
    ffiHelper = await FfiHelper.load('assets/standalone/WasmFfi.wasm');
  } else {
    ffiHelper = await FfiHelper.load('assets/emscripten/WasmFfi.js');
  }

  WasmFfiBindings bindings = WasmFfiBindings(ffiHelper.library);

  return ffiHelper.safeUsing((Arena arena) {
    Pointer<Char> cString = name.toNativeUtf8().cast<Char>();
    String helloStr = bindings.hello(cString).cast<Utf8>().toDartString();
    int sizeOfInt = bindings.intSize();
    int sizeOfBool = bindings.boolSize();
    int sizeOfPointer = bindings.pointerSize();
    return Result(helloStr, sizeOfInt, sizeOfBool, sizeOfPointer);
  });
}

Future<String> testLibOpus() async {
  final ffiHelper = await FfiHelper.load('assets/emscripten/libopus.js');

  FunctionsAndGlobals bindings = FunctionsAndGlobals(ffiHelper.library);

  return ffiHelper.safeUsing((Arena arena) {
    String version =
        bindings.opus_get_version_string().cast<Utf8>().toDartString();
    return version;
  });
}
