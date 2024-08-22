// Notice that in this file, we import wasm_ffi and not proxy_ffi.dart
import 'package:wasm_ffi/wasm_ffi_core.dart';

DynamicLibrary? _library;

Future<void> initFfi() async {
  // Only initalize if there is no module yet
  if (_library == null) {
    _library = await DynamicLibrary.open(
      WasmType.wasm32WithJs,
      moduleName: 'libopus',
    );
  }
}

DynamicLibrary openOpus() {
  if (_library != null) {
    return _library!;
  } else {
    throw StateError('You can not open opus before calling initFfi()!');
  }
}
