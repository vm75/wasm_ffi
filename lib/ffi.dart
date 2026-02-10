/// Foreign Function Interface for interoperability with the C programming language.
///
/// This is quivalent to the `dart:ffi` package for the web platform.
library;

export 'src/ffi/allocation.dart';
export 'src/ffi/dynamic_library.dart';
export 'src/ffi/extensions.dart';
export 'src/ffi/marshaller.dart' show registerOpaqueType;
export 'src/ffi/native_finalizer.dart';
export 'src/ffi/types.dart';
