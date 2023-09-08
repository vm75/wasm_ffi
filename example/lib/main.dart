import 'dart:convert';
import 'package:wasm_ffi/proxy_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inject_js/inject_js.dart';
import 'src/wasm_bindings.dart';

Future<Module> initStandalone() async {
  // Load the WebAssembly binaries from assets
  String path = 'assets/standalone.wasm';
  Uint8List wasmBinaries = (await rootBundle.load(path)).buffer.asUint8List();

  // After we loaded the wasm binaries and injected the js code
  // into our webpage, we obtain a module
  return await StandaloneWasmModule.compile(wasmBinaries, "WasmFfi");
}

Future<Module> initEmscripten() async {
  await importLibrary('assets/emscripten.js');

  // Load the WebAssembly binaries from assets
  String path = 'assets/emscripten.wasm';
  Uint8List wasmBinaries = (await rootBundle.load(path)).buffer.asUint8List();

  // After we loaded the wasm binaries and injected the js code
  // into our webpage, we obtain a module
  return await EmscriptenModule.compile(wasmBinaries, "WasmFfi");
}

String fromCString(Pointer<Char> cString) {
  int len = 0;
  while (cString[len] != 0) {
    len++;
  }
  return len > 0 ? ascii.decode(cString.asTypedList(len)) : '';
}

/// Don't forget to free the c string using the same allocator if your are done with it!
Pointer<Char> toCString(String dartString, Allocator allocator) {
  List<int> bytes = ascii.encode(dartString);
  Pointer<Char> cString = allocator.allocate<Char>(bytes.length);
  cString.asTypedList(bytes.length).setAll(0, bytes);
  return cString;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Module standaloneModule = await initStandalone();
  WasmBindings standaloneBindings =
      WasmBindings(standaloneModule.getLibrary(MemoryRegisterMode.yes));
  String standaloneResult =
      fromCString(standaloneBindings.hello(toCString("world", Arena())));
  Module emscriptenModule = await initEmscripten();
  WasmBindings emscriptenBindings =
      WasmBindings(emscriptenModule.getLibrary(MemoryRegisterMode.yes));
  String emscriptenResult =
      fromCString(emscriptenBindings.hello(toCString("world", Arena())));

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
