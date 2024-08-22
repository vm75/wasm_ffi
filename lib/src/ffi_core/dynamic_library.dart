import 'dart:typed_data';
import 'package:inject_js/inject_js.dart';
import '../../ffi_proxy.dart';
import 'annotations.dart';
import 'memory.dart';
import 'modules/emscripten/emscripten_module.dart';
import 'modules/module.dart';
import 'modules/standalone/standalone_module.dart';
import 'modules/table.dart';

/// Enum for StandaloneWasmModule and EmscriptenModule
enum WasmType {
  /// The module is loaded from a wasm file
  wasm32Standalone,
  wasm64Standalone,

  /// The module is loaded from a js file
  wasm32WithJs,
  wasm64WithJs,
}

/// Used on [DynamicLibrary] creation to control if the therby newly created
/// [Memory] object should be registered as [Memory.global].
@extra
enum GlobalMemory { yes, no, ifNotSet }

/// Represents a dynamically loaded C library.
class DynamicLibrary {
  final Module _module;
  final Memory _memory;

  /// Access the module object
  @extra
  Module get module => _module;

  /// Access the memory bound to this library
  @extra
  Memory get memory => _memory;

  DynamicLibrary._(this._module, this._memory);

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
    /// Initialize the native types in marshaller
    if (type == WasmType.wasm32WithJs || type == WasmType.wasm32Standalone) {
      initTypes(4);
    } else {
      initTypes(8);
    }
    registerOpaqueType<Utf8>(1);
    registerOpaqueType<Utf16>(2);

    Module? module;
    if (type == WasmType.wasm32WithJs || type == WasmType.wasm64WithJs) {
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
        Table.global = module.indirectFunctionTable;
        break;
      case GlobalMemory.no:
        break;
      case GlobalMemory.ifNotSet:
        Memory.global ??= memory;
        Table.global ??= module.indirectFunctionTable;
        break;
    }

    return DynamicLibrary._(module, memory);
  }

  /// Looks up a symbol in the DynamicLibrary and returns its address in memory.
  ///
  /// Throws an [ArgumentError] if it fails to lookup the symbol.
  ///
  /// While this method checks if the underyling wasm symbol is a actually
  /// a function when you lookup a [NativeFunction]`<T>`, it does not check if
  /// the return type and parameters of `T` match the wasm function.
  Pointer<T> lookup<T extends NativeType>(String name) =>
      _module.lookup(name, _memory);

  /// Checks whether this dynamic library provides a symbol with the given
  /// name.
  bool providesSymbol(String symbolName) => _module.providesSymbol(symbolName);

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

  /// Helper that combines lookup and cast to a Dart function.
  ///
  /// This simply calls [DynamicLibrary.lookup] and [NativeFunctionPointer.asFunction]
  /// internally, so see this two methods for additional insights.
  F lookupFunction<T extends Function, F extends Function>(String name) =>
      _module.lookupFunction(name, _memory);
}
