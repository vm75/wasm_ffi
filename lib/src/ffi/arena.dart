import 'dart:async';

import 'types.dart';

R using<R>(R Function(Arena) computation, Allocator wrappedAllocator) {
  final arena = Arena(wrappedAllocator);
  bool isAsync = false;
  try {
    final result = computation(arena);
    if (result is Future) {
      isAsync = true;
      return result.whenComplete(arena.releaseAll) as R;
    }
    return result;
  } finally {
    if (!isAsync) {
      arena.releaseAll();
    }
  }
}

/// An [Allocator] which frees all allocations at the same time.
///
/// The arena allows you to allocate heap memory, but ignores calls to [free].
/// Instead you call [releaseAll] to release all the allocations at the same
/// time.
///
/// Also allows other resources to be associated with the arena, through the
/// [using] method, to have a release function called for them when the arena
/// is released.
///
/// An [Allocator] can be provided to do the actual allocation and freeing.
/// Defaults to using [calloc].
class Arena implements Allocator {
  /// The [Allocator] used for allocation and freeing.
  final Allocator _wrappedAllocator;

  /// Native memory under management by this [Arena].
  final List<Pointer<NativeType>> _managedMemoryPointers = [];

  /// Callbacks for releasing native resources under management by this [Arena].
  final List<void Function()> _managedResourceReleaseCallbacks = [];

  bool _inUse = true;

  /// Creates a arena of allocations.
  ///
  /// The [allocator] is used to do the actual allocation and freeing of
  /// memory. It defaults to using [calloc].
  Arena(Allocator allocator) : _wrappedAllocator = allocator;

  /// Allocates memory and includes it in the arena.
  ///
  /// Uses the allocator provided to the [Arena] constructor to do the
  /// allocation.
  ///
  /// Throws an [ArgumentError] if the number of bytes or alignment cannot be
  /// satisfied.
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    _ensureInUse();
    final p = _wrappedAllocator.allocate<T>(byteCount, alignment: alignment);
    _managedMemoryPointers.add(p);
    return p;
  }

  /// Registers [resource] in this arena.
  ///
  /// Executes [releaseCallback] on [releaseAll].
  ///
  /// Returns [resource] again, to allow for easily inserting
  /// `arena.using(resource, ...)` where the resource is allocated.
  T using<T>(T resource, void Function(T) releaseCallback) {
    _ensureInUse();
    releaseCallback = Zone.current.bindUnaryCallback(releaseCallback);
    _managedResourceReleaseCallbacks.add(() => releaseCallback(resource));
    return resource;
  }

  /// Registers [releaseResourceCallback] to be executed on [releaseAll].
  void onReleaseAll(void Function() releaseResourceCallback) {
    _managedResourceReleaseCallbacks.add(releaseResourceCallback);
  }

  /// Releases all resources that this [Arena] manages.
  ///
  /// If [reuse] is `true`, the arena can be used again after resources
  /// have been released. If not, the default, then the [allocate]
  /// and [using] methods must not be called after a call to `releaseAll`.
  ///
  /// If any of the callbacks throw, [releaseAll] is interrupted, and should
  /// be started again.
  void releaseAll({bool reuse = false}) {
    if (!reuse) {
      _inUse = false;
    }
    // The code below is deliberately wirtten to allow allocations to happen
    // during `releaseAll(reuse:true)`. The arena will still be guaranteed
    // empty when the `releaseAll` call returns.
    while (_managedResourceReleaseCallbacks.isNotEmpty) {
      _managedResourceReleaseCallbacks.removeLast()();
    }
    for (final p in _managedMemoryPointers) {
      _wrappedAllocator.free(p);
    }
    _managedMemoryPointers.clear();
  }

  /// Does nothing, invoke [releaseAll] instead.
  @override
  void free(Pointer<NativeType> pointer) {}

  void _ensureInUse() {
    if (!_inUse) {
      throw StateError(
          'Arena no longer in use, `releaseAll(reuse: false)` was called.');
    }
  }
}
