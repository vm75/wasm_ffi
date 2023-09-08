import 'dart:convert';
import 'package:wasm_ffi/proxy_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inject_js/inject_js.dart';
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

Future<String> hello<T>(String name) async {
  Module? module;
  if (T == StandaloneWasmModule) {
    // Load the WebAssembly binary from assets
    String path = 'assets/standalone.wasm';
    Uint8List wasmBinaries = (await rootBundle.load(path)).buffer.asUint8List();

    // After we loaded the wasm binaries, we obtain a module
    module = await StandaloneWasmModule.compile(wasmBinaries, "WasmFfi");
  } else {
    await importLibrary('assets/emscripten.js');

    // Load the WebAssembly binaries from assets
    String path = 'assets/emscripten.wasm';
    Uint8List wasmBinaries = (await rootBundle.load(path)).buffer.asUint8List();

    // After we loaded the wasm binaries and injected the js code
    // into our webpage, we obtain a module
    module = await EmscriptenModule.compile(wasmBinaries, "WasmFfi");
  }

  DynamicLibrary library = module.getLibrary();
  WasmBindings bindings = WasmBindings(library);

  String result = "";
  using((Arena arena) {
    Pointer<Char> cString = toCString(name, arena);
    result = fromCString(bindings.hello(cString));

    bindings.freeMemory(cString);
  }, library.boundMemory);

  return result;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String standaloneResult =
      await hello<StandaloneWasmModule>("standalone world");
  String emscriptenResult = await hello<EmscriptenModule>("js world");

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
