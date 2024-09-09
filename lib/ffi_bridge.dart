library wasm_ffi;

export 'package:wasm_ffi/ffi.dart'
    if (dart.library.ffi) 'package:wasm_ffi/_dart_ffi/ffi.dart';
