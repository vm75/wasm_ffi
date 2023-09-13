import '../../wasm_ffi.dart';

/// Manages memory on the native heap.
abstract class Allocator {
  /// Allocates byteCount bytes of memory on the native heap.
  ///
  /// The parameter `alignment` is ignored.
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment});

  /// Releases memory allocated on the native heap.
  void free(Pointer<NativeType> pointer);
}
