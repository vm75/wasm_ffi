import 'package:meta/meta.dart';

import 'annotations.dart';
import 'exceptions.dart';
import 'invoker_generated.dart';
import 'js_function_apply.dart';
import 'memory.dart';
import 'type_utils.dart';
import 'types.dart';

final Map<Type, int> sizeMap = {};

/// The size of a pointer in bytes. Should be same for all loaded wasm modules.
int? registeredPointerSizeBytes;

/// Must be called with each type that extends Opaque before
/// attemtping to use that type.
@extra
void registerOpaqueType<T extends Opaque>([int? size]) {
  sizeMap[T] = size ?? sizeOf<Opaque>();
  _registerNativeMarshallerOpaque<T>();
}

void _registerType<T extends NativeType>(int size) {
  sizeMap[T] = size;
  _registerNativeMarshallerType<T>();
}

/// Number of bytes used by native type T.
///
/// MUST NOT be called with types annoteted with @[unsized] or
/// before [initTypes] was called or else an exception will be thrown.
int sizeOf<T extends NativeType>() {
  int? size;
  if (isPointerType<T>()) {
    size = sizeMap[IntPtr];
  } else {
    size = sizeMap[T];
  }
  if (size != null) {
    return size;
  } else {
    throw ArgumentError('The type $T is not known!');
  }
}

/// Must be called before working with `wasm_ffi` to initalize all type sizes.
///
/// The optional parameter [pointerSizeBytes] can be used to adjust the size
/// of pointers. It defaults to `4` since WebAssembly usually uses 32 bit pointers.
/// If you want to use wasm64, set [pointerSizeBytes] to `8` to denote 64 bit pointers.
void initTypes([int pointerSizeBytes = 4]) {
  if (registeredPointerSizeBytes != null) {
    if (registeredPointerSizeBytes != pointerSizeBytes) {
      throw MarshallingException(
        'Can not change pointer size after it was set to $registeredPointerSizeBytes!',
      );
    }
    return;
  }
  registeredPointerSizeBytes = pointerSizeBytes;
  _registerType<Int>(pointerSizeBytes);
  _registerType<UnsignedInt>(pointerSizeBytes);
  _registerType<Float>(4);
  _registerType<Double>(8);
  _registerType<Int8>(1);
  _registerType<Uint8>(1);
  _registerType<Int16>(2);
  _registerType<Uint16>(2);
  _registerType<Int32>(4);
  _registerType<Uint32>(4);
  _registerType<Int64>(8);
  _registerType<Uint64>(8);
  _registerType<Size>(pointerSizeBytes);
  _registerType<IntPtr>(pointerSizeBytes);
  _registerType<UintPtr>(pointerSizeBytes);
  _registerType<Opaque>(pointerSizeBytes);
  _registerNativeMarshallerType<Void>();
  _registerNativeMarshallerType<NativeFunction<dynamic>>();
}

// Called from the invokers
T execute<T>(Object base, List<Object> args, Memory memory) {
  final invocation = base is _NativeFunctionInvocation ? base : null;
  final Object target = invocation?.base ?? base;
  final jsBigIntArgumentIndexes =
      invocation?.jsBigIntArgumentIndexes ?? const <int>{};

  if (T == DartVoidType) {
    if (target is Function) {
      Function.apply(
        target,
        _toJsFunctionArguments(args, jsBigIntArgumentIndexes),
      );
    } else {
      applyJsFunction(target, args, jsBigIntArgumentIndexes);
    }
    return null as T;
  } else {
    if (target is Function) {
      final Object? result = Function.apply(
        target,
        _toJsFunctionArguments(args, jsBigIntArgumentIndexes),
      );
      if (result == null) {
        return null as T;
      }
      return jsResultToDartType<T>(result, memory, _toDartType);
    }

    final Object? result = applyJsFunction(
      target,
      args,
      jsBigIntArgumentIndexes,
    );
    if (result == null) {
      return null as T;
    }
    return jsResultToDartType<T>(result, memory, _toDartType);
  }
}

DF marshall<NF extends Function, DF extends Function>(
  Object base,
  Memory memory,
) {
  final indexes = _jsBigIntArgumentIndexes(typeString<NF>());
  final target = _NativeFunctionInvocation(base, indexes);
  return _inferFromSignature(DF.toString()).copyWith(target, memory).run as DF;
}

@visibleForTesting
List<int> jsBigIntArgumentIndexesForTesting<NF extends Function>({
  int? pointerSizeBytes,
}) => List.unmodifiable(
  _jsBigIntArgumentIndexes(
    typeString<NF>(),
    pointerSizeBytes: pointerSizeBytes,
  ),
);

final class _NativeFunctionInvocation {
  const _NativeFunctionInvocation(this.base, this.jsBigIntArgumentIndexes);

  final Object base;
  final Set<int> jsBigIntArgumentIndexes;
}

Set<int> _jsBigIntArgumentIndexes(
  String nativeSignature, {
  int? pointerSizeBytes,
}) {
  final indexes = <int>{};
  final argTypes = _argumentTypesFromSignature(nativeSignature);
  for (var i = 0; i < argTypes.length; i++) {
    if (_usesJsBigInt(argTypes[i], pointerSizeBytes)) {
      indexes.add(i);
    }
  }
  return indexes;
}

List<String> _argumentTypesFromSignature(String signature) {
  final separator = _topLevelReturnSeparator(signature);
  final argList =
      (separator == -1 ? signature : signature.substring(0, separator)).trim();
  if (!argList.startsWith('(') || !argList.endsWith(')')) {
    return const [];
  }

  final body = argList.substring(1, argList.length - 1).trim();
  if (body.isEmpty) {
    return const [];
  }

  final result = <String>[];
  var angleDepth = 0;
  var parenDepth = 0;
  var start = 0;
  for (var i = 0; i < body.length; i++) {
    final codeUnit = body.codeUnitAt(i);
    if (codeUnit == 0x3d &&
        i + 1 < body.length &&
        body.codeUnitAt(i + 1) == 0x3e) {
      i++;
    } else if (codeUnit == 0x3c) {
      angleDepth++;
    } else if (codeUnit == 0x3e) {
      angleDepth--;
    } else if (codeUnit == 0x28) {
      parenDepth++;
    } else if (codeUnit == 0x29) {
      parenDepth--;
    } else if (codeUnit == 0x2c && angleDepth == 0 && parenDepth == 0) {
      result.add(body.substring(start, i).trim());
      start = i + 1;
    }
  }
  result.add(body.substring(start).trim());
  return result;
}

int _topLevelReturnSeparator(String signature) {
  var angleDepth = 0;
  var parenDepth = 0;
  for (var i = 0; i < signature.length - 1; i++) {
    final codeUnit = signature.codeUnitAt(i);
    if (codeUnit == 0x3d && signature.codeUnitAt(i + 1) == 0x3e) {
      if (angleDepth == 0 && parenDepth == 0) {
        return i;
      }
      i++;
    } else if (codeUnit == 0x3c) {
      angleDepth++;
    } else if (codeUnit == 0x3e) {
      angleDepth--;
    } else if (codeUnit == 0x28) {
      parenDepth++;
    } else if (codeUnit == 0x29) {
      parenDepth--;
    }
  }
  return -1;
}

final String _pointerTypePrefix = typeString<Pointer<dynamic>>()
    .split(typeString<dynamic>())
    .first;

bool _usesJsBigInt(String nativeType, int? pointerSizeBytes) {
  if (nativeType == typeString<Int64>() || nativeType == typeString<Uint64>()) {
    return true;
  }

  if ((pointerSizeBytes ?? registeredPointerSizeBytes) != 8) {
    return false;
  }

  return nativeType == typeString<IntPtr>() ||
      nativeType == typeString<UintPtr>() ||
      nativeType == typeString<Size>() ||
      nativeType.startsWith(_pointerTypePrefix);
}

List<Object?> _toJsFunctionArguments(
  List<Object> args,
  Set<int> jsBigIntArgumentIndexes,
) {
  return [
    for (var i = 0; i < args.length; i++)
      toJsFunctionArgument(
        args[i],
        asBigInt: jsBigIntArgumentIndexes.contains(i),
      ),
  ];
}

InvokeHelper _inferFromSignature(String signature) {
  final String returnType = signature.split('=>').last.trim();
  if (returnType.startsWith(pointerPointerPointerPrefix)) {
    throw const MarshallingException(
      'Nesting pointers is only supported to a deepth of 2!'
      '\nThis means that you can write Pointer<Pointer<X>> but not Pointer<Pointer<Pointer<X>>>, ...',
    );
  }
  final InvokeHelper? h = _knownTypes[returnType];
  if (h != null) {
    return h;
  } else {
    if (returnType.startsWith(pointerNativeFunctionPrefix)) {
      throw const MarshallingException(
        'Using pointers to native functions as return type is only allowed if the type of the native function is dynamic!'
        '\nThis means that only Pointer<NativeFunction<dynamic>> is allowed!',
      );
    } else {
      throw MarshallingException(
        'Unknown type $returnType (infered from $signature), all marshallable types: ${listKnownTypes()}',
      );
    }
  }
}

@visibleForTesting
List<String> listKnownTypes() =>
    List<String>.of(_knownTypes.keys, growable: false);

final Map<String, InvokeHelper> _knownTypes = {
  typeString<int>(): const InvokeHelper<int>(null, null),
  typeString<double>(): const InvokeHelper<double>(null, null),
  typeString<bool>(): const InvokeHelper<bool>(null, null),
  typeString<void>(): const InvokeHelper<void>(null, null),
};

final Map<String, Function> _knownTypes2 = {
  typeString<int>(): (Object o, Memory b) => _toDartType<int>(o, b),
  typeString<double>(): (Object o, Memory b) => _toDartType<double>(o, b),
  typeString<bool>(): (Object o, Memory b) => _toDartType<bool>(o, b),
  typeString<void>(): (Object o, Memory b) => _toDartType<void>(o, b),
};

void _registerNativeMarshallerType<T extends NativeType>() {
  _knownTypes[typeString<Pointer<T>>()] = InvokeHelper<Pointer<T>>(null, null);
  _knownTypes[typeString<Pointer<Pointer<T>>>()] =
      InvokeHelper<Pointer<Pointer<T>>>(null, null);
  _knownTypes2[typeString<Pointer<T>>()] = (Object o, Memory b) =>
      _toDartType<Pointer<T>>(o, b);
  _knownTypes2[typeString<Pointer<Pointer<T>>>()] = (Object o, Memory b) =>
      _toDartType<Pointer<Pointer<T>>>(o, b);
}

void _registerNativeMarshallerOpaque<T extends Opaque>() {
  _knownTypes[typeString<Pointer<T>>()] = OpaqueInvokeHelper<T>(null, null);
  _knownTypes[typeString<Pointer<Pointer<T>>>()] = OpaqueInvokeHelperSquare<T>(
    null,
    null,
  );
  _knownTypes2[typeString<Pointer<T>>()] = (Object o, Memory b) =>
      _toDartType<Pointer<Opaque>>(o, b).cast<T>();
  _knownTypes2[typeString<Pointer<Pointer<T>>>()] = (Object o, Memory b) =>
      _toDartType<Pointer<Pointer<Opaque>>>(o, b).cast<Pointer<T>>();
}

Function marshaller(String typeName) => _knownTypes2[typeName]!;

T _toDartType<T>(Object o, Memory bind) {
  if (T == int) {
    if (o is int) {
      return o as T;
    } else {
      throw MarshallingException.typeMissmatch(T, o);
    }
  } else if (T == double) {
    if (o is double) {
      return o as T;
    } else {
      throw MarshallingException.typeMissmatch(T, o);
    }
  } else if (T == bool) {
    if (o is bool) {
      return o as T;
    } else if (o is int) {
      return (o != 0) as T;
    } else {
      throw MarshallingException.typeMissmatch(T, o);
    }
  } else {
    if (T == Pointer<Void>) {
      if (o is int) {
        return Pointer<Void>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<IntPtr>) {
      if (o is int) {
        return Pointer<IntPtr>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<UintPtr>) {
      if (o is int) {
        return Pointer<UintPtr>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<Bool>) {
      if (o is int) {
        return Pointer<Bool>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<Int>) {
      if (o is int) {
        return Pointer<Int>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<Int8>) {
      if (o is int) {
        return Pointer<Int8>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<Int16>) {
      if (o is int) {
        return Pointer<Int16>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<Int32>) {
      if (o is int) {
        return Pointer<Int32>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<Int64>) {
      if (o is int) {
        return Pointer<Int64>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<Double>) {
      if (o is int) {
        return Pointer<Double>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<UnsignedInt>) {
      if (o is int) {
        return Pointer<UnsignedInt>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<Uint8>) {
      if (o is int) {
        return Pointer<Uint8>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<Uint16>) {
      if (o is int) {
        return Pointer<Uint16>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<Uint32>) {
      if (o is int) {
        return Pointer<Uint32>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<Uint64>) {
      if (o is int) {
        return Pointer<Uint64>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<Float>) {
      if (o is int) {
        return Pointer<Float>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<Char>) {
      if (o is int) {
        return Pointer<Char>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<Opaque>) {
      if (o is int) {
        return Pointer<Opaque>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer<NativeFunction<dynamic>>) {
      if (o is int) {
        return Pointer<NativeFunction<dynamic>>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else {
      if (T == Pointer<Pointer<Void>>) {
        if (o is int) {
          return Pointer<Pointer<Void>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<IntPtr>>) {
        if (o is int) {
          return Pointer<Pointer<IntPtr>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<UintPtr>>) {
        if (o is int) {
          return Pointer<Pointer<UintPtr>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<Bool>>) {
        if (o is int) {
          return Pointer<Pointer<Bool>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<Int>>) {
        if (o is int) {
          return Pointer<Pointer<Int>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<Int8>>) {
        if (o is int) {
          return Pointer<Pointer<Int8>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<Int16>>) {
        if (o is int) {
          return Pointer<Pointer<Int16>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<Int32>>) {
        if (o is int) {
          return Pointer<Pointer<Int32>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<Int64>>) {
        if (o is int) {
          return Pointer<Pointer<Int64>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<Double>>) {
        if (o is int) {
          return Pointer<Pointer<Double>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<UnsignedInt>>) {
        if (o is int) {
          return Pointer<Pointer<UnsignedInt>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<Uint8>>) {
        if (o is int) {
          return Pointer<Pointer<Uint8>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<Uint16>>) {
        if (o is int) {
          return Pointer<Pointer<Uint16>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<Uint32>>) {
        if (o is int) {
          return Pointer<Pointer<Uint32>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<Uint64>>) {
        if (o is int) {
          return Pointer<Pointer<Uint64>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<Char>>) {
        if (o is int) {
          return Pointer<Pointer<Char>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<Float>>) {
        if (o is int) {
          return Pointer<Pointer<Float>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer<Pointer<Opaque>>) {
        if (o is int) {
          return Pointer<Pointer<Opaque>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else {
        throw MarshallingException(
          'Can not back-marshall to type $T (object type is ${o.runtimeType})',
        );
      }
    }
  }
}
