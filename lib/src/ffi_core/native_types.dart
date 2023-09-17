import 'dart:typed_data';
import 'annotations.dart';
import 'memory.dart';
import 'null_memory.dart';

/// Endianness of the underlying system.
const Endian endianess = Endian.little;
int _wordSize = 4;

/// [NativeType]'s subtypes represent a native type in C.
///
/// [NativeType]'s subtypes are not constructible in the Dart code and serve
/// purely as markers in type signatures.
abstract final class NativeType {
  const NativeType();
}

/// [Opaque]'s subtypes represent opaque types in C.
///
/// [Opaque]'s subtypes are not constructible in the Dart code and serve purely
/// as markers in type signatures.
abstract base class Opaque extends NativeType {}

/// [_NativeInteger]'s subtypes represent a native integer in C.
///
/// [_NativeInteger]'s subtypes are not constructible in the Dart code and serve
/// purely as markers in type signatures.
abstract base class _NativeInteger extends NativeType {
  const _NativeInteger();
}

/// [_NativeDouble]'s subtypes represent a native float or double in C.
///
/// [_NativeDouble]'s subtypes are not constructible in the Dart code and serve
/// purely as markers in type signatures.
abstract base class _NativeDouble extends NativeType {
  const _NativeDouble();
}

/// Represents a native signed 8 bit integer in C.
///
/// [Int] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class Int extends _NativeInteger {
  const Int();
}

/// Represents a native signed 8 bit integer in C.
///
/// [UnsignedInt] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class UnsignedInt extends _NativeInteger {
  const UnsignedInt();
}

/// Represents a native signed 8 bit integer in C.
///
/// [Int8] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class Int8 extends _NativeInteger {
  const Int8();
}

/// Represents a native signed 16 bit integer in C.
///
/// [Int16] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class Int16 extends _NativeInteger {
  const Int16();
}

/// Represents a native signed 32 bit integer in C.
///
/// [Int32] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class Int32 extends _NativeInteger {
  const Int32();
}

/// Represents a native signed 64 bit integer in C.
///
/// [Int64] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class Int64 extends _NativeInteger {
  const Int64();
}

/// Represents a native signed 8 bit integer in C.
///
/// [Int8] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class Uint8 extends _NativeInteger {
  const Uint8();
}

/// Represents a native signed 16 bit integer in C.
///
/// [Int16] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class Uint16 extends _NativeInteger {
  const Uint16();
}

/// Represents a native signed 32 bit integer in C.
///
/// [Int32] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class Uint32 extends _NativeInteger {
  const Uint32();
}

/// Represents a native signed 64 bit integer in C.
///
/// [Int64] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
final class Uint64 extends _NativeInteger {
  const Uint64();
}

/// Represents a native 32 bit float in C.
///
/// [Float] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
final class Float extends _NativeDouble {
  const Float();
}

/// Represents a native 64 bit double in C.
///
/// [Double] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
final class Double extends _NativeDouble {
  const Double();
}

/// Represents a native bool in C.
///
/// [Bool] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
final class Bool extends NativeType {
  const Bool();
}

/// Represents a native bool in C.
///
/// [Size] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
final class Size extends NativeType {
  const Size();
}

/// Represents a void type in C.
///
/// [Void] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
@unsized
abstract final class Void extends NativeType {}

/// Represents `Dart_Handle` in C.
///
/// [Handle] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
abstract final class Handle extends NativeType {}

/// Represents a function type in C.
///
/// [NativeFunction] is not constructible in the Dart code and serves purely as
/// marker in type signatures.
@unsized
abstract final class NativeFunction<T extends Function> extends NativeType {}

/// Represents a pointer into the native C memory corresponding to "NULL",
/// e.g. a pointer with address 0.
///
/// You can compare any other pointer with this pointer using == to check
/// if it's also an nullpointer.
///
/// Any other operation than comparing (e.g. calling [Pointer.cast])
/// will result in exceptions.
final Pointer<Never> nullptr = Pointer<Never>._null();

/// Hacky workadround, see https://github.com/dart-lang/language/issues/123
Type _extractType<T>() => T;
String typeString<T>() => _extractType<T>().toString();

// ignore: non_constant_identifier_names
final Type DartVoidType = _extractType<void>();
// ignore: non_constant_identifier_names
final Type FfiVoidType = _extractType<Void>();

final String _dynamicTypeString = typeString<dynamic>();

final String pointerPointerPointerPrefix =
    typeString<Pointer<Pointer<Pointer<dynamic>>>>()
        .split(_dynamicTypeString)
        .first;

final String pointerNativeFunctionPrefix =
    typeString<Pointer<NativeFunction<dynamic>>>()
        .split(_dynamicTypeString)
        .first;

final String _nativeFunctionPrefix =
    typeString<NativeFunction<dynamic>>().split(_dynamicTypeString).first;
bool isNativeFunctionType<T extends NativeType>() =>
    typeString<T>().startsWith(_nativeFunctionPrefix);

final String _pointerPrefix =
    typeString<Pointer<dynamic>>().split(_dynamicTypeString).first;
bool isPointerType<T extends NativeType>() =>
    typeString<T>().startsWith(_pointerPrefix);

bool isVoidType<T extends NativeType>() => _extractType<T>() == FfiVoidType;

bool _isUnsizedType<T extends NativeType>() {
  return isNativeFunctionType<T>() || isVoidType<T>();
}

/// Represents a pointer into the native C memory. Cannot be extended.
final class Pointer<T extends NativeType> extends NativeType {
  //static Pointer<NativeFunction<T>> fromFunction<T extends Function>(Function f,
  //       [Object? exceptionalReturn]) =>
  //   throw UnimplementedError();

  /// Access to the raw pointer value.
  final int address;

  /// The [Memory] object this pointer is bound to.
  ///
  /// The `Memory` object backs this pointer, if the value of
  /// this pointer is accessed.
  @extra
  final Memory boundMemory;

  /// How much memory in bytes the type this pointer points to occupies,
  /// or `null` for @[unsized] types.
  @extra
  final int? size;

  factory Pointer._null() {
    return Pointer._(0, NullMemory(), null);
  }

  /// Constructs a pointer from an address.
  ///
  /// The optional parameter `bindTo` can be ommited, if and only if
  /// [Memory.global] is set, which is then used as `Memory` to bind to.
  factory Pointer.fromAddress(int ptr, [Memory? bindTo]) {
    Memory? memory = bindTo ?? Memory.global;
    if (memory == null) {
      throw StateError(
          'No global memory set and no explcity memory to bind to given!');
    }
    return Pointer._(ptr, memory, _isUnsizedType<T>() ? null : sizeOf<T>());
  }

  Pointer._(this.address, this.boundMemory, this.size);

  /// Casts this pointer to an other type.
  Pointer<U> cast<U extends NativeType>() => Pointer<U>._(
      address, boundMemory, _isUnsizedType<U>() ? null : sizeOf<U>());

  /// Pointer arithmetic (takes element size into account).
  ///
  /// Throws an [UnsupportedError] if called on a pointer with an @[unsized]
  /// type argument.
  Pointer<T> elementAt(int index) {
    int? s = size;
    if (s != null) {
      return Pointer<T>._(address + index * s, boundMemory, s);
    } else {
      throw UnsupportedError('elementAt is not supported for unsized types!');
    }
  }

  /// The hash code for a Pointer only depends on its address.
  @override
  int get hashCode => address;

  /// Two pointers are equal if their address is the same, independently
  /// of their type argument and of the memory they are bound to.
  @override
  bool operator ==(Object other) =>
      (other is Pointer && other.address == address);

  /// Returns a view of a single element at [index] (takes element
  /// size into account).
  ///
  /// Any modifications to the data will also alter the [Memory] object.
  ///
  /// Throws an [UnsupportedError] if called on a pointer with an @[unsized]
  /// type argument.
  @extra
  ByteData viewSingle(int index) {
    int? s = size;
    if (s != null) {
      return boundMemory.buffer.asByteData(address + index * s, s);
    } else {
      throw UnsupportedError('viewSingle is not supported for unsized types!');
    }
  }
}

/// The types of variadic arguments passed in C.
///
/// The signatures in [NativeFunction] need to specify the exact types of each
/// actual argument used in FFI calls.
///
/// For example take calling `printf` in C.
///
/// ```c
/// int printf(const char *format, ...);
///
/// void call_printf() {
///   int a = 4;
///   double b = 5.5;
///   const char* format = "...";
///   printf(format, a, b);
/// }
/// ```
///
/// To call `printf` directly from Dart with those two argument types, define
/// the native type as follows:
///
/// ```dart
/// /// `int printf(const char *format, ...)` with `int` and `double` as
/// /// varargs.
/// typedef NativePrintfIntDouble =
///     Int Function(Pointer<Char>, VarArgs<(Int, Double)>);
/// ```
///
/// Note the record type inside the `VarArgs` type argument.
///
/// If only a single variadic argument is passed, the record type must
/// contain a trailing comma:
///
/// ```dart continued
/// /// `int printf(const char *format, ...)` with only `int` as varargs.
/// typedef NativePrintfInt = Int Function(Pointer<Char>, VarArgs<(Int,)>);
/// ```
///
/// When a variadic function is called with different variadic argument types,
/// multiple bindings need to be created.
/// To avoid doing multiple [DynamicLibrary.lookup]s for the same symbol, the
/// pointer to the symbol can be cast:
///
/// ```dart continued
/// final dylib = DynamicLibrary.executable();
/// final printfPointer = dylib.lookup('printf');
/// final void Function(Pointer<Char>, int, double) printfIntDouble =
///     printfPointer.cast<NativeFunction<NativePrintfIntDouble>>().asFunction();
/// final void Function(Pointer<Char>, int) printfInt =
///     printfPointer.cast<NativeFunction<NativePrintfInt>>().asFunction();
/// ```
///
/// If no variadic argument is passed, the `VarArgs` must be passed with an
/// empty record type:
///
/// ```dart
/// /// `int printf(const char *format, ...)` with no varargs.
/// typedef NativePrintfNoVarArgs = Int Function(Pointer<Char>, VarArgs<()>);
/// ```
///
/// [VarArgs] must be the last parameter.
///
/// [VarArgs] is not constructible in the Dart code and serves purely as marker
/// in type signatures.
abstract final class VarArgs<T extends Record> extends NativeType {}

/// Type alias
typedef Short = Int16;
typedef UnsignedShort = Uint16;
typedef Long = Int32;
typedef UnsignedLong = Uint32;

final Map<Type, int> sizeMap = {};
int sizeOf<T extends NativeType>() {
  if (!sizeMap.containsKey(T)) {
    if (T == Int8 || T == Uint8) {
      sizeMap[T] = 1;
    } else if (T == Int16 || T == Uint16) {
      sizeMap[T] = 2;
    } else if (T == Int32 || T == Uint32 || T == Float) {
      sizeMap[T] = 4;
    } else if (T == Int64 || T == Uint64 || T == Double) {
      sizeMap[T] = 8;
    } else if (_isUnsizedType<T>()) {
      sizeMap[T] = 0;
    } else if (T == Int ||
        T == UnsignedInt ||
        T == Bool ||
        T == NativeFunction ||
        T == Opaque ||
        T == Size ||
        T == Handle ||
        T == Pointer) {
      sizeMap[T] = _wordSize;
    } else {
      throw ArgumentError.value(T, 'T', 'Invalid NativeType');
    }
  }
  return sizeMap[T]!;
}
