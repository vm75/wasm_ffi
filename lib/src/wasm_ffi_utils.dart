/// equivalient for package:ffi, but for wasm on web.
library wasm_ffi;

export 'ffi_utils/allocation.dart' show calloc, malloc;
export 'ffi_utils/arena.dart';
export 'ffi_utils/utf16.dart';
export 'ffi_utils/utf8.dart';
