import 'package:meta/meta.dart';

import '../ffi/types.dart';
import '../ffi/utf8.dart';
import '../modules/exceptions.dart';
import '../modules/memory.dart';
import 'invoker_generated.dart';
import 'type_utils.dart';

// Called from the invokers
T execute<T>(Function base, List<Object> args, Memory memory) {
  if (T == DartVoidType) {
    Function.apply(base, args.map(_toJsType).toList());
    return null as T;
  } else {
    Object result = Function.apply(base, args.map(_toJsType).toList());
    return _toDartType<T>(result, memory);
  }
}

DF marshall<NF extends Function, DF extends Function>(
    Function base, Memory memory) {
  return _inferFromSignature(DF.toString()).copyWith(base, memory).run as DF;
}

Object _toJsType(Object dartObject) {
  if (dartObject is int || dartObject is double || dartObject is bool) {
    return dartObject;
  } else if (dartObject is Pointer) {
    return dartObject.address;
  } else {
    throw MarshallingException(
        'Could not convert dart type ${dartObject.runtimeType} to a JavaScript type!');
  }
}

InvokeHelper _inferFromSignature(String signature) {
  String returnType = signature.split('=>').last.trim();
  if (returnType.startsWith(pointerPointerPointerPrefix)) {
    throw const MarshallingException(
        'Nesting pointers is only supported to a deepth of 2!'
        '\nThis means that you can write Pointer<Pointer<X>> but not Pointer<Pointer<Pointer<X>>>, ...');
  }
  InvokeHelper? h = _knownTypes[returnType];
  if (h != null) {
    return h;
  } else {
    if (returnType.startsWith(pointerNativeFunctionPrefix)) {
      throw const MarshallingException(
          'Using pointers to native functions as return type is only allowed if the type of the native function is dynamic!'
          '\nThis means that only Pointer<NativeFunction<dynamic>> is allowed!');
    } else {
      throw MarshallingException(
          'Unknown type $returnType (infered from $signature), all marshallable types: ${listKnownTypes()}');
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
  typeString<void>(): const InvokeHelper<void>(null, null)
};

final Map<String, Function> _knownTypes2 = {
  typeString<int>():  (o, b) => _toDartType<int>(o, b),
  typeString<double>():  (o, b) => _toDartType<double>(o, b),
  typeString<bool>():  (o, b) => _toDartType<bool>(o, b),
  typeString<void>():  (o, b) => _toDartType<void>(o, b),
};

void registerNativeMarshallerType<T extends NativeType>() {
  _knownTypes[typeString<Pointer<T>>()] = InvokeHelper<Pointer<T>>(null, null);
  _knownTypes[typeString<Pointer<Pointer<T>>>()] =
      InvokeHelper<Pointer<Pointer<T>>>(null, null);
  _knownTypes2[typeString<Pointer<T>>()] =  (o, b) => _toDartType<Pointer<T>>(o, b);
  _knownTypes2[typeString<Pointer<Pointer<T>>>()] =
       (o, b) => _toDartType<Pointer<Pointer<T>>>(o, b);
}

void registerNativeMarshallerOpaque<T extends Opaque>() {
  _knownTypes[typeString<Pointer<T>>()] = OpaqueInvokeHelper<T>(null, null);
  _knownTypes[typeString<Pointer<Pointer<T>>>()] =
      OpaqueInvokeHelperSquare<T>(null, null);
  _knownTypes2[typeString<Pointer<T>>()] =  (o, b) => _toDartType<Pointer<Opaque>>(o, b).cast<T>();
  _knownTypes2[typeString<Pointer<Pointer<T>>>()] =
       (o, b) => _toDartType<Pointer<Pointer<Opaque>>>(o, b).cast<Pointer<T>>();
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
    if (T == Pointer_Void) {
      if (o is int) {
        return Pointer<Void>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_IntPtr) {
      if (o is int) {
        return Pointer<IntPtr>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_UintPtr) {
      if (o is int) {
        return Pointer<UintPtr>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Bool) {
      if (o is int) {
        return Pointer<Bool>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Int) {
      if (o is int) {
        return Pointer<Int>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Int8) {
      if (o is int) {
        return Pointer<Int8>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Int16) {
      if (o is int) {
        return Pointer<Int16>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Int32) {
      if (o is int) {
        return Pointer<Int32>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Int64) {
      if (o is int) {
        return Pointer<Int64>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Double) {
      if (o is int) {
        return Pointer<Double>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_UnsignedInt) {
      if (o is int) {
        return Pointer<UnsignedInt>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Uint8) {
      if (o is int) {
        return Pointer<Uint8>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Uint16) {
      if (o is int) {
        return Pointer<Uint16>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Uint32) {
      if (o is int) {
        return Pointer<Uint32>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Uint64) {
      if (o is int) {
        return Pointer<Uint64>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Float) {
      if (o is int) {
        return Pointer<Float>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Char) {
      if (o is int) {
        return Pointer<Char>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Utf8) {
      if (o is int) {
        return Pointer<Utf8>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_Opaque) {
      if (o is int) {
        return Pointer<Opaque>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else if (T == Pointer_NativeFunction_dynamic) {
      if (o is int) {
        return Pointer<NativeFunction<dynamic>>.fromAddress(o, bind) as T;
      } else {
        throw MarshallingException.noAddress(o);
      }
    } else {
      if (T == Pointer_Pointer_Void) {
        if (o is int) {
          return Pointer<Pointer<Void>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_IntPtr) {
        if (o is int) {
          return Pointer<Pointer<IntPtr>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_UintPtr) {
        if (o is int) {
          return Pointer<Pointer<UintPtr>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Bool) {
        if (o is int) {
          return Pointer<Pointer<Bool>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Int) {
        if (o is int) {
          return Pointer<Pointer<Int>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Int8) {
        if (o is int) {
          return Pointer<Pointer<Int8>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Int16) {
        if (o is int) {
          return Pointer<Pointer<Int16>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Int32) {
        if (o is int) {
          return Pointer<Pointer<Int32>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Int64) {
        if (o is int) {
          return Pointer<Pointer<Int64>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Double) {
        if (o is int) {
          return Pointer<Pointer<Double>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_UnsignedInt) {
        if (o is int) {
          return Pointer<Pointer<UnsignedInt>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Uint8) {
        if (o is int) {
          return Pointer<Pointer<Uint8>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Uint16) {
        if (o is int) {
          return Pointer<Pointer<Uint16>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Uint32) {
        if (o is int) {
          return Pointer<Pointer<Uint32>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Uint64) {
        if (o is int) {
          return Pointer<Pointer<Uint64>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Char) {
        if (o is int) {
          return Pointer<Pointer<Char>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Utf8) {
        if (o is int) {
          return Pointer<Pointer<Utf8>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Float) {
        if (o is int) {
          return Pointer<Pointer<Float>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else if (T == Pointer_Pointer_Opaque) {
        if (o is int) {
          return Pointer<Pointer<Opaque>>.fromAddress(o, bind) as T;
        } else {
          throw MarshallingException.noAddress(o);
        }
      } else {
        throw MarshallingException(
            'Can not back-marshall to type $T (object type is ${o.runtimeType})');
      }
    }
  }
}
