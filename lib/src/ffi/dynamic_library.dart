import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../ffi_utils/utf16.dart';
import '../ffi_utils/utf8.dart';
import '../js_utils/inject_js.dart';
import '../js_utils/wasm_interop.dart' as interop;
import 'annotations.dart';
import 'marshaller.dart';
import 'memory.dart';
import 'modules/emscripten_module.dart';
import 'modules/module.dart';
import 'modules/standalone_module.dart';
import 'types.dart';

/// An interface for loading module binary.
mixin ModuleLoader {
  Future<Uint8List> load(String modulePath);
}

/// Enum for StandaloneWasmModule and EmscriptenModule
enum WasmType {
  /// The module is loaded from a wasm file
  wasm32Standalone,
  wasm64Standalone,

  /// The module is loaded using emscripten js
  wasm32Emscripten,
  wasm64Emscripten,
}

/// Used on [DynamicLibrary] creation to control if the therby newly created
/// [Memory] object should be registered as [Memory.global].
@extra
enum GlobalMemory { yes, no, ifNotSet }

class WebModuleLoader implements ModuleLoader {
  @override
  Future<Uint8List> load(String modulePath) async {
    final response = await http.get(Uri.parse(modulePath));
    if (response.statusCode != 200) {
      throw Exception('Failed to load module: $modulePath');
    }
    return response.bodyBytes;
  }
}

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
  /// The [wasmType] parameter can be used to control if the module should be
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
    String modulePath, {
    String? moduleName,
    ModuleLoader? moduleLoader,
    WasmType? wasmType,
    GlobalMemory? useAsGlobal,
  }) async {
    /// 64-bit wasm is not supported
    if (wasmType == WasmType.wasm64Standalone ||
        wasmType == WasmType.wasm64Emscripten) {
      throw UnsupportedError('64-bit wasm is not supported');
    }

    moduleLoader ??= WebModuleLoader();

    /// Initialize the native types in marshaller
    initTypes(4);
    registerOpaqueType<Utf8>(1);
    registerOpaqueType<Utf16>(2);

    final uri = Uri.parse(modulePath);

    moduleName ??= path.basenameWithoutExtension(uri.pathSegments.last);
    if (wasmType == null) {
      final ext = path.extension(uri.pathSegments.last);
      if (ext == '.wasm') {
        wasmType = WasmType.wasm32Standalone;
      } else if (ext == '.js') {
        wasmType = WasmType.wasm32Emscripten;
      } else {
        throw Exception('Unsupported wasm type: $ext');
      }
    }

    Module? module;
    if (wasmType == WasmType.wasm32Emscripten) {
      await importLibrary(modulePath);
      module = await EmscriptenModule.compile(moduleName);
    } else {
      final wasmBinary = await moduleLoader.load(modulePath);
      module = await StandaloneWasmModule.compile(wasmBinary);
    }

    Memory memory = createMemory(module);

    // TODO: use ifNotSet
    switch (useAsGlobal ?? GlobalMemory.yes) {
      case GlobalMemory.yes:
        Memory.global = memory;
        interop.WasmTable.global = module.indirectFunctionTable;
        break;
      case GlobalMemory.no:
        break;
      case GlobalMemory.ifNotSet:
        Memory.global ??= memory;
        interop.WasmTable.global ??= module.indirectFunctionTable;
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
