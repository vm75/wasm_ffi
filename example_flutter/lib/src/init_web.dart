import 'package:flutter/services.dart';
// Notice that in this file, we import wasm_ffi and not proxy_ffi.dart
import 'package:wasm_ffi/wasm_ffi_core.dart';

// Note that if you use assets included in a package rather them the main app,
// the _basePath would be different: 'packages/<package_name>/assets'
const String _basePath = 'assets';

DynamicLibrary? _library;

Future<void> initFfi() async {
  // Only initalize if there is no module yet
  if (_library == null) {
    // Load the WebAssembly binaries from assets
    String path = '$_basePath/libopus.wasm';
    Uint8List wasmBinary = (await rootBundle.load(path)).buffer.asUint8List();

    _library = await DynamicLibrary.open(
      WasmType.wasm32WithJs,
      moduleName: 'libopus',
      wasmBinary: wasmBinary,
      jsModule: '$_basePath/libopus.js',
    );
  }
}

DynamicLibrary openOpus() {
  if (_library != null) {
    return _library!;
  } else {
    throw new StateError('You can not open opus before calling initFfi()!');
  }
}
