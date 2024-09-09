/// equivalient for dart:ffi, but for wasm on web.
library wasm_ffi;

export 'ffi/allocation.dart';
export 'ffi/dynamic_library.dart';
export 'ffi/extensions.dart';
export 'ffi/marshaller.dart' show registerOpaqueType;
export 'ffi/native_finalizer.dart';
export 'ffi/types.dart';
