import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../../wasm_ffi.dart';

/// Extension method for converting a [String] to a `Pointer<Utf8>`.
extension StringUtf8Pointer on String {
  /// Creates a zero-terminated [Utf8] code-unit array from this String.
  ///
  /// If this [String] contains NUL characters, converting it back to a string
  /// using [Utf8Pointer.toDartString] will truncate the result if a length is
  /// not passed.
  /// Optionally, a [size] can be passed to specify the size of the allocated
  /// array. If [size] is not provided, the array is sized to fit the string.
  ///
  /// Unpaired surrogate code points in this [String] will be encoded as
  /// replacement characters (U+FFFD, encoded as the bytes 0xEF 0xBF 0xBD) in
  /// the UTF-8 encoded result. See [Utf8Encoder] for details on encoding.
  ///
  /// Returns an [allocator]-allocated pointer to the result.
  Pointer<T> toNativeUtf8<T extends Uint8>(Allocator allocator, [int? size]) {
    final units = utf8.encode(this);
    size ??= units.length + 1;
    final Pointer<Uint8> result = allocator<Uint8>(size);
    final Uint8List nativeString = result.asTypedList(size);
    final int lengthToCopy = min(size - 1, units.length);
    nativeString.setRange(0, lengthToCopy, units);
    nativeString[lengthToCopy - 1] = 0;
    return result.cast();
  }
}
