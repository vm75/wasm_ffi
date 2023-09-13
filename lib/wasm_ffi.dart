/// Provides mechanisms to use a [dart:ffi 2.12.0](https://api.dart.dev/stable/2.12.0/dart-ffi/dart-ffi-library.html) like API on the web but using [dart:js](https://api.dart.dev/stable/dart-js/dart-js-library.html).
/// While some things are missing, new things were added, identifiable by the @[extra] annotation.
library wasm_ffi;

export 'dynamic_library.dart';
export 'src/memory/allocation.dart';
export 'src/types/extensions.dart';
export 'src/types/types.dart';
