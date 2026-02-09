@JS()
library emscripten_module;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import '../../js_utils/wasm_interop.dart';
import '../annotations.dart';
import '../extensions.dart';
import '../memory.dart';
import '../type_utils.dart';
import '../types.dart';
import 'module.dart';

@JS()
@anonymous
extension type EmscriptenModuleJs._(JSObject _) implements JSObject {
  external JSUint8Array? get wasmBinary;
  // ignore: non_constant_identifier_names
  external JSUint8Array? get HEAPU8;

  external JSObject? get asm; // Emscripten <3.1.44
  external JSObject? get wasmExports; // Emscripten >=3.1.44
  external JSPromise? get readyPromise;
  external JSObject? get memory; // WebAssembly memory object

  // Must have an unnamed factory constructor with named arguments.
  external factory EmscriptenModuleJs({JSUint8Array? wasmBinary});
}

const String _github = 'https://github.com/vm75/wasm_ffi';
String _adu(WasmSymbol? original, WasmSymbol? tried) =>
    'CRITICAL EXCEPTION! Address double use! This should never happen, please report this issue on github immediately at $_github'
    '\r\nOriginal: $original'
    '\r\nTried: $tried';

typedef _Malloc = int Function(int size);
typedef _Free = void Function(int address);

FunctionDescription _fromWasmFunction(String name, JSFunction func) {
  final funcDesc = func as WrappedJSFunction;

  final String? funcName = funcDesc.name?.toDart;
  if (funcName != null) {
    final int? index = int.tryParse(funcName);
    if (index != null) {
      final int? argCount = funcDesc.length?.toDartInt;
      if (argCount != null) {
        return FunctionDescription(
            tableIndex: index,
            name: name,
            function: func,
            argumentCount: argCount);
      } else {
        throw ArgumentError('$name does not seem to be a function symbol!');
      }
    } else {
      throw ArgumentError('$name does not seem to be a function symbol!');
    }
  } else {
    throw ArgumentError('$name does not seem to be a function symbol!');
  }
}

typedef EmscriptenModuleFunc = JSObject? Function();

/// Documentation is in `emscripten_module_stub.dart`!
@extra
class EmscriptenModule extends Module {
  static EmscriptenModuleFunc _getModuleFunction(String moduleName) {
    final JSFunction? moduleFunction =
        globalContext.getProperty(moduleName.toJS);
    if (moduleFunction == null) {
      throw StateError('Could not find a emscripten module named $moduleName');
    }
    return moduleFunction as EmscriptenModuleFunc;
  }

  /// Documentation is in `emscripten_module_stub.dart`!
  static Future<EmscriptenModule> compile(String moduleName,
      {void Function(EmscriptenModuleJs)? preinit}) async {
    final moduleFunction = _getModuleFunction(moduleName);

    try {
      var module = moduleFunction();

      // Handle nested promises from newer emscripten (async function returns Promise)
      // Keep unwrapping until we get the actual module object
      // Both old and new emscripten only resolve promises after full initialization

      // Check if it's a thenable (has a 'then' method) and unwrap it
      while (module != null) {
        final then = (module).getProperty('then'.toJS);
        if (then != null && then is JSFunction) {
          // It's a thenable, await it
          module = await (module as JSPromise).toDart as JSObject?;
        } else {
          // Not a promise, break out
          break;
        }
      }

      if (module != null && module is EmscriptenModuleJs) {
        preinit?.call(module);
        return EmscriptenModule._fromJs(module);
      } else {
        throw StateError(
            'Could not instantiate an emscripten module! Got: ${module.runtimeType}');
      }
    } catch (e) {
      throw StateError('Could not instantiate an emscripten module: $e');
    }
  }

  final EmscriptenModuleJs _emscriptenModuleJs;
  final List<WasmSymbol> _exports;
  final _Malloc _malloc;
  final _Free _free;
  final WasmTable? _indirectFunctionTable;
  final JSObject? _memory;

  @override
  List<WasmSymbol> get exports => _exports;

  @override
  WasmTable? get indirectFunctionTable => _indirectFunctionTable;

  EmscriptenModule._(this._emscriptenModuleJs, this._exports,
      this._indirectFunctionTable, this._malloc, this._free, this._memory);

  factory EmscriptenModule._fromJs(EmscriptenModuleJs module) {
    final asm = module.wasmExports ?? module.asm;
    if (asm != null) {
      final Map<int, WasmSymbol> knownAddresses = {};
      _Malloc? malloc;
      _Free? free;
      final List<WasmSymbol> exports = [];
      final List entries = WrappedJSObject.entries(asm).toDart;
      WasmTable? indirectFunctionTable;
      JSObject? memory;
      // if (entries is List<Object>) {
      for (dynamic entry in entries) {
        if (entry is! List) {
          throw StateError("Unexpected entry in entries(Module['asm'])!");
        }
        final Object? value = entry.last;
        if (value == null) {
          throw StateError('Error: Unexpected null value in for entry $entry');
        }
        // TODO: Not sure if `value` can ever be `int` directly. I only
        // observed it being WebAssembly.Global for globals.
        if (value is int ||
            (WasmGlobal.isInstance(value as WasmGlobal) &&
                value.value is int)) {
          final int address =
              (value is int) ? value : ((value as WasmGlobal).value as int);
          final Global g =
              Global(address: address, name: entry.first as String);
          if (knownAddresses.containsKey(address) &&
              knownAddresses[address] is! Global) {
            throw StateError(_adu(knownAddresses[address], g));
          }
          knownAddresses[address] = g;
          exports.add(g);
        } else if (value is Function) {
          final FunctionDescription description =
              _fromWasmFunction(entry.first as String, value as JSFunction);
          // It might happen that there are two different c functions that do nothing else than calling the same underlying c function
          // In this case, a compiler might substitute both functions with the underlying c function
          // So we got two functions with different names at the same table index
          // So it is actually ok if there are two things at the same address, as long as they are both functions
          if (knownAddresses.containsKey(description.tableIndex) &&
              knownAddresses[description.tableIndex] is! FunctionDescription) {
            throw StateError(
                _adu(knownAddresses[description.tableIndex], description));
          }
          knownAddresses[description.tableIndex] = description;
          exports.add(description);
          if (description.name == 'malloc') {
            malloc = description.function as _Malloc;
          } else if (description.name == 'free') {
            free = description.function as _Free;
          }
        } else if (WasmTable.isInstance(value as WasmTable) &&
            entry.first as String == '__indirect_function_table') {
          indirectFunctionTable = value as WasmTable;
        } else if (entry.first as String == 'memory' ||
            entry.first as String == 'b') {
          // memory is often at index 'b'
          // Store the memory object for heap access
          memory = value as JSObject;
        } else {
          // ignore unknown entries
          // throw StateError(
          //     'Warning: Unexpected value in entry list! Entry is $entry, value is $value (of type ${value.runtimeType})');
        }
      }
      if (malloc == null) {
        throw StateError('Module does not export the malloc function!');
      }
      if (free == null) {
        throw StateError('Module does not export the free function!');
      }
      return EmscriptenModule._(
          module, exports, indirectFunctionTable, malloc, free, memory);
    } else {
      _Malloc? malloc;
      _Free? free;
      final List<WasmSymbol> exports = [];
      WasmTable? indirectFunctionTable;
      JSObject? memory;
      final entries = WrappedJSObject.entries(module).toDart;
      for (final jsEntry in entries) {
        if (jsEntry == null || jsEntry is! List) {
          throw StateError('Unexpected entry in entries(Module[])!');
        }
        final entry = jsEntry as List;
        var name = entry.first as String;
        final value = entry.last;
        if (value is Function) {
          // if name starts with _ , exclude first character
          if (!name.startsWith('_')) {
            continue;
          }
          name = name.substring(1);

          final func = value as WrappedJSFunction;
          final desc = FunctionDescription(
            tableIndex: exports.length,
            name: name,
            function: value as JSFunction,
            argumentCount: func.length?.toDartInt ?? 0,
          );
          exports.add(desc);

          if (name == 'malloc') {
            malloc = value as _Malloc;
          }
          if (name == 'free') {
            free = value as _Free;
          }
        }
      }

      if (malloc == null) {
        throw StateError('Module does not export the malloc function!');
      }
      if (free == null) {
        throw StateError('Module does not export the free function!');
      }
      return EmscriptenModule._(
          module, exports, indirectFunctionTable, malloc, free, memory);
    }
  }

  @override
  void free(int pointer) => _free(pointer);

  @override
  ByteBuffer get heap => _getHeap();
  ByteBuffer _getHeap() {
    // Try HEAPU8 first (older emscripten)
    final Uint8List? h = _emscriptenModuleJs.HEAPU8?.toDart;
    if (h != null) {
      return h.buffer;
    }

    // Try accessing through stored memory object (newer emscripten)
    if (_memory != null) {
      // Try to get the buffer from the WebAssembly memory
      final buffer = _memory.getProperty('buffer'.toJS);
      if (buffer != null && buffer is JSArrayBuffer) {
        final uint8Array = JSUint8Array(buffer);
        return uint8Array.toDart.buffer;
      }
    }

    // Try accessing through module memory object
    final memory = _emscriptenModuleJs.memory;
    if (memory != null) {
      // Try to get the buffer from the WebAssembly memory
      final buffer = memory.getProperty('buffer'.toJS);
      if (buffer != null && buffer is JSArrayBuffer) {
        final uint8Array = JSUint8Array(buffer);
        return uint8Array.toDart.buffer;
      }
    }

    throw StateError('Unexpected memory error!');
  }

  @override
  int malloc(int size) => _malloc(size);

  /// Looks up a symbol in the DynamicLibrary and returns its address in memory.
  ///
  /// Throws an [ArgumentError] if it fails to lookup the symbol.
  ///
  /// While this method checks if the underyling wasm symbol is a actually
  /// a function when you lookup a [NativeFunction]`<T>`, it does not check if
  /// the return type and parameters of `T` match the wasm function.
  @override
  Pointer<T> lookup<T extends NativeType>(String name, Memory memory) {
    final WasmSymbol symbol = symbolByName(memory, name);
    if (isNativeFunctionType<T>()) {
      if (symbol is FunctionDescription) {
        return Pointer<T>.fromAddress(symbol.tableIndex, memory);
      } else {
        throw ArgumentError(
            'Tried to look up $name as a function, but it seems it is NOT a function!');
      }
    } else {
      return Pointer<T>.fromAddress(symbol.address, memory);
    }
  }

  /// Checks whether this dynamic library provides a symbol with the given
  /// name.
  @override
  bool providesSymbol(String symbolName) => throw UnimplementedError();

  @override
  F lookupFunction<T extends Function, F extends Function>(
      String name, Memory memory) {
    return lookup<NativeFunction<T>>(name, memory).asFunction<F>();
  }
  // _EmscriptenModuleJs get module => _emscriptenModuleJs;
}
