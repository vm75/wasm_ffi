import 'dart:typed_data';

import 'package:inject_js/inject_js.dart';

import 'src/annotations.dart';
import 'src/memory/memory.dart';
import 'src/modules/emscripten/emscripten_module.dart';
import 'src/modules/module.dart';
import 'src/modules/standalone/standalone_module.dart';
import 'src/types/extensions.dart';
import 'src/types/type_utils.dart';
import 'src/types/types.dart';

/// Enum for StandaloneWasmModule and EmscriptenModule
enum WasmType {
  /// The module is loaded from a wasm file
  standalone,

  /// The module is loaded from a js file
  withJs
}

/// Represents a dynamically loaded C library.
class DynamicLibrary {
  @extra
  final Memory boundMemory;

  DynamicLibrary._(this.boundMemory);

  /// Creates a instance based on the given module.
  ///
  /// While for each [DynamicLibrary] a [Memory] object is
  /// created, the [Memory] objects share the backing memory if
  /// they are created based on the same module.
  ///
  /// The [type] parameter can be used to control if the module should be
  /// loaded as standalone wasm module or as emscripten module.
  ///
  /// The [moduleName] parameter is only used for debugging purposes. It is
  /// needed for the [EmscriptenModule] to find the correct module. It is
  /// ignored for the [StandaloneWasmModule].
  ///
  /// The [wasmBinary] parameter is the binary content of the wasm file. To keep
  /// pure-dart compatibility, loading from asset is not implemented.
  ///
  /// The [jsModule] parameter is only used for the [EmscriptenModule] to
  /// inject the js code into the webpage. It is ignored for the  [StandaloneWasmModule].
  ///
  /// The [useAsGlobal] parameter can be used to control if the
  /// newly created [Memory] object should be registered as [Memory.global].
  /// Loads a library file and provides access to its symbols.
  ///
  /// Calling this function multiple times with the same [path], even across
  /// different isolates, only loads the library into the DartVM process once.
  /// Multiple loads of the same library file produces [DynamicLibrary] objects
  /// which are equal (`==`), but not [identical].
  @different
  static Future<DynamicLibrary> open(
    WasmType type, {
    String? moduleName,
    Uint8List? wasmBinary,
    String? jsModule,
    GlobalMemory? useAsGlobal,
  }) async {
    Memory.init();

    Module? module;
    if (type == WasmType.withJs) {
      if (moduleName == null) {
        throw ArgumentError(
            'You need to provide a moduleName when loading a module with js!');
      }
      if (jsModule != null) {
        await importLibrary(jsModule);
      }

      module = await EmscriptenModule.compile(moduleName, wasmBinary);
    } else {
      if (wasmBinary == null) {
        throw ArgumentError(
            'You need to provide a wasmBinary when loading a standalone module!');
      }
      module = await StandaloneWasmModule.compile(wasmBinary);
    }

    Memory memory = createMemory(module);

    switch (useAsGlobal ?? GlobalMemory.ifNotSet) {
      case GlobalMemory.yes:
        Memory.global = memory;
        break;
      case GlobalMemory.no:
        break;
      case GlobalMemory.ifNotSet:
        Memory.global ??= memory;
        break;
    }

    return DynamicLibrary._(memory);
  }

  /// Looks up a symbol in the DynamicLibrary and returns its address in memory.
  ///
  /// Throws an [ArgumentError] if it fails to lookup the symbol.
  ///
  /// While this method checks if the underyling wasm symbol is a actually
  /// a function when you lookup a [NativeFunction]`<T>`, it does not check if
  /// the return type and parameters of `T` match the wasm function.
  Pointer<T> lookup<T extends NativeType>(String name) {
    WasmSymbol symbol = symbolByName(boundMemory, name);
    if (isNativeFunctionType<T>()) {
      if (symbol is FunctionDescription) {
        return Pointer<T>.fromAddress(symbol.tableIndex, boundMemory);
      } else {
        throw ArgumentError(
            'Tried to look up $name as a function, but it seems it is NOT a function!');
      }
    } else {
      return Pointer<T>.fromAddress(symbol.address, boundMemory);
    }
  }

  /// Checks whether this dynamic library provides a symbol with the given
  /// name.
  bool providesSymbol(String symbolName) => throw UnimplementedError();

  /// Closes this dynamic library.
  ///
  /// After calling [close], this library object can no longer be used for
  /// lookups. Further, this information is forwarded to the operating system,
  /// which may unload the library if there are no remaining references to it
  /// in the current process.
  ///
  /// Depending on whether another reference to this library has been opened,
  /// pointers and functions previously returned by [lookup] and
  /// [DynamicLibraryExtension.lookupFunction] may become invalid as well.
  void close() => throw UnimplementedError();
}

extension DynamicLibraryExtension on DynamicLibrary {
  /// Helper that combines lookup and cast to a Dart function.
  ///
  /// This simply calls [DynamicLibrary.lookup] and [NativeFunctionPointer.asFunction]
  /// internally, so see this two methods for additional insights.
  F lookupFunction<T extends Function, F extends Function>(String name) =>
      lookup<NativeFunction<T>>(name).asFunction<F>();
}
