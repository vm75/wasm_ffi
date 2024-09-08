library wasm_ffi;

export 'package:wasm_ffi/_export_ffi/helper_wasm_ffi.dart'
    if (dart.library.ffi) 'package:wasm_ffi/_export_ffi/helper_dart_ffi.dart';
