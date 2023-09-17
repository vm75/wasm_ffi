import 'dart:typed_data';
import 'package:meta/meta.dart';

import 'annotations.dart';
import 'marshaller.dart';
import 'memory.dart';
import 'null_memory.dart';
import 'type_utils.dart';

export 'marshaller.dart' show sizeOf, initTypes;

/// Represents a pointer into the native C memory corresponding to "NULL",
/// e.g. a pointer with address 0.
///
/// You can compare any other pointer with this pointer using == to check
/// if it's also an nullpointer.
///
/// Any other operation than comparing (e.g. calling [Pointer.cast])
/// will result in exceptions.
final Pointer<Never> nullptr = Pointer<Never>._null();

bool _isUnsizedType<T extends NativeType>() {
  return isNativeFunctionType<T>() || isVoidType<T>();
}

/// [NativeType]'s subtypes represent a native type in C.
///
/// [NativeType]'s subtypes (except [Pointer]) are not constructible
/// in the Dart code and serve purely as markers in type signatures.
@sealed
@notConstructible
class NativeType {}

/// Represents a native 64 bit double in C.
///
/// Double is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class Double extends NativeType {}

/// Represents a native 32 bit float in C.
///
/// Float is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class Float extends NativeType {}

/// The C `int` type.
///
/// Int is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class Int extends NativeType {}

/// Represents a native signed 8 bit integer in C.
///
/// Int8 is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class Int8 extends NativeType {}

/// Represents a native signed 16 bit integer in C.
///
/// Int16 is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class Int16 extends NativeType {}

/// Represents a native signed 32 bit integer in C.
///
/// Int32 is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class Int32 extends NativeType {}

/// Represents a native signed 64 bit integer in C.
///
/// Int64 is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class Int64 extends NativeType {}

/// The C `unsigned int` type.
///
/// Int is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class UnsignedInt extends NativeType {}

/// Represents a native unsigned 8 bit integer in C.
///
/// Uint8 is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class Uint8 extends NativeType {}

/// Represents a native unsigned 16 bit integer in C.
///
/// Uint16 is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class Uint16 extends NativeType {}

/// Represents a native unsigned 32 bit integer in C.
///
/// Uint32 is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class Uint32 extends NativeType {}

/// Represents a native unsigned 64 bit integer in C.
///
/// Uint64 is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class Uint64 extends NativeType {}

/// Represents a native pointer-sized integer in C.
///
/// IntPtr is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class IntPtr extends NativeType {}

/// Represents a native pointer-sized unsigned integer in C.
///
/// IntPtr is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class UintPtr extends NativeType {}

/// Represents a native bool in C.
///
/// Bool is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
class Bool extends NativeType {}

/// Represents a function type in C.
///
/// NativeFunction is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
@unsized
class NativeFunction<T extends Function> extends NativeType {}

/// Opaque's subtypes represent opaque types in C.
///
/// Classes that extend Opaque MUST NOT have a type argument!
///
/// Opaque's subtypes are not constructible in the Dart code and serve
/// purely as markers in type signatures.
@noGeneric
@notConstructible
class Opaque extends NativeType {}

/// Represents a void type in C.
///
/// Void is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
@unsized
class Void extends NativeType {}

/// Represents a Size type in C.
///
/// Size is not constructible in the Dart code and serves
/// purely as marker in type signatures.
@sealed
@notConstructible
@unsized
class Size extends NativeType {}

/// Miscellaneous types, defined as alias
typedef Char = Int8;
typedef UnsignedChar = Uint8;
typedef Short = Int16;
typedef UnsignedShort = Uint16;
typedef Long = Int32;
typedef UnsignedLong = Uint32;
typedef LongLong = Int64;
typedef UnsignedLongLong = Uint64;
typedef WChar = Int32;

/// Represents a pointer into the native C memory. Cannot be extended.
@sealed
class Pointer<T extends NativeType> extends NativeType {
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
