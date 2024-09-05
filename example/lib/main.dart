import 'package:wasm_ffi/ffi_proxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'hello_bindings.dart';
import 'libopus_bindings.dart';
// import 'dart:developer' as developer;

class Result {
  final String helloStr;
  int sizeOfInt;
  int sizeOfBool;
  int sizeOfPointer;

  Result(this.helloStr, this.sizeOfInt, this.sizeOfBool, this.sizeOfPointer);

  @override
  String toString() {
    return 'hello: $helloStr, int: $sizeOfInt, bool: $sizeOfBool, pointer: $sizeOfPointer';
  }
}

Future<Result> testHello(String name, bool standalone) async {
  DynamicLibrary? library;
  if (standalone) {
    // Load the WebAssembly binary from assets
    String path = 'assets/standalone.wasm';
    Uint8List wasmBinary = (await rootBundle.load(path)).buffer.asUint8List();
    library = await DynamicLibrary.open(
      WasmType.wasm32Standalone,
      wasmBinary: wasmBinary,
    );
  } else {
    // Load the WebAssembly binaries from assets
    String path = 'assets/emscripten.wasm';
    Uint8List wasmBinary = (await rootBundle.load(path)).buffer.asUint8List();

    // After we loaded the wasm binaries and injected the js code
    // into our webpage, we obtain a module
    library = await DynamicLibrary.open(
      WasmType.wasm32WithJs,
      moduleName: "WasmFfi",
      wasmBinary: wasmBinary,
      jsModule: 'assets/emscripten.js',
    );
  }

  WasmBindings bindings = WasmBindings(library);

  return using((Arena arena) {
    Pointer<Char> cString = name.toNativeUtf8(arena).cast<Char>();
    String helloStr = bindings.hello(cString).cast<Utf8>().toDartString();
    int sizeOfInt = bindings.intSize();
    int sizeOfBool = bindings.boolSize();
    int sizeOfPointer = bindings.pointerSize();
    return Result(helloStr, sizeOfInt, sizeOfBool, sizeOfPointer);
  }, library.memory);
}

Future<String> testLibOpus() async {
  DynamicLibrary? library;
  // Load the WebAssembly binaries from assets
  String path = 'assets/libopus.wasm';
  Uint8List wasmBinary = (await rootBundle.load(path)).buffer.asUint8List();

  // After we loaded the wasm binaries and injected the js code
  // into our webpage, we obtain a module
  library = await DynamicLibrary.open(
    WasmType.wasm32WithJs,
    moduleName: "libopus",
    wasmBinary: wasmBinary,
    jsModule: 'assets/libopus.js',
  );

  FunctionsAndGlobals bindings = FunctionsAndGlobals(library);

  return using((Arena arena) {
    String version =
        bindings.opus_get_version_string().cast<Utf8>().toDartString();
    return version;
  }, library.memory);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Result standaloneResult = await testHello("standalone world", true);
  Result emscriptenResult = await testHello("js world", false);
  String version = await testLibOpus();

  runApp(MyApp(standaloneResult, emscriptenResult, version, key: UniqueKey()));
}

class MyApp extends StatelessWidget {
  final Result _standaloneResult;
  final Result _emscriptenResult;
  final String _libopusVersion;

  const MyApp(
      this._standaloneResult, this._emscriptenResult, this._libopusVersion,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'wasm_ffi Demo',
      home: Scaffold(
          appBar: AppBar(
            title: const Text('wasm_ffi Demo'),
            centerTitle: true,
          ),
          body: Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Standalone: $_standaloneResult',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Emscripten: $_emscriptenResult',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'libopus version: $_libopusVersion',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          )),
    );
  }
}
