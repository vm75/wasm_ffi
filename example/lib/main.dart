import 'dart:convert';
import 'package:wasm_ffi/ffi_proxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/wasm_bindings.dart';

String fromCString(Pointer<Char> cString) {
  int len = 0;
  while (cString[len] != 0) {
    len++;
  }
  return len > 0 ? ascii.decode(cString.asTypedList(len)) : '';
}

Pointer<Char> toCString(String dartString, Allocator allocator) {
  List<int> bytes = ascii.encode(dartString);
  Pointer<Char> cString = allocator.allocate<Char>(bytes.length);
  cString.asTypedList(bytes.length).setAll(0, bytes);
  return cString;
}

Future<String> testHello(String name, bool standalone) async {
  DynamicLibrary? library;
  if (standalone) {
    // Load the WebAssembly binary from assets
    String path = 'assets/standalone.wasm';
    Uint8List wasmBinary = (await rootBundle.load(path)).buffer.asUint8List();
    library = await DynamicLibrary.open(
      WasmType.standalone,
      wasmBinary: wasmBinary,
    );
  } else {
    // Load the WebAssembly binaries from assets
    String path = 'assets/emscripten.wasm';
    Uint8List wasmBinary = (await rootBundle.load(path)).buffer.asUint8List();

    // After we loaded the wasm binaries and injected the js code
    // into our webpage, we obtain a module
    library = await DynamicLibrary.open(
      WasmType.withJs,
      moduleName: "WasmFfi",
      wasmBinary: wasmBinary,
      jsModule: 'assets/emscripten.js',
    );
  }

  WasmBindings bindings = WasmBindings(library);

  String result = "";
  using((Arena arena) {
    Pointer<Char> cString = toCString(name, arena);
    result = fromCString(bindings.hello(cString));

    bindings.freeMemory(cString);
  }, library.memory);

  return result;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String standaloneResult = await testHello("standalone world", true);
  String emscriptenResult = await testHello("js world", false);

  runApp(MyApp(standaloneResult, emscriptenResult, key: UniqueKey()));
}

class MyApp extends StatelessWidget {
  final String _standaloneResult;
  final String _emscriptenResult;

  const MyApp(this._standaloneResult, this._emscriptenResult, {super.key});

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
              ],
            ),
          )),
    );
  }
}
