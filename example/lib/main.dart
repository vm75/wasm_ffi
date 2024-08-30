import 'package:wasm_ffi/ffi_proxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'wasm_bindings.dart';
import 'dart:developer' as developer;

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

// typedef example_foo = Int32 Function(
//     Int32 bar, Pointer<NativeFunction<example_callback>>);
typedef FooFunc = int Function(int bar, Pointer<NativeFunction<CallbackFunc>>);

typedef CallbackFunc = Int32 Function(Pointer<Void>, Int32);

int callback(Pointer<Void> ptr, int i) {
  developer.log('in callback i=$i');
  return i + 1;
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

    if (!standalone) {
      FooFunc nativeFoo =
          library!.lookup<NativeFunction<FooFunc>>('_foo').asFunction();

      const except = -1;

      nativeFoo(
        100,
        Pointer.fromFunction<CallbackFunc>(callback, except),
      );
    }

    return Result(helloStr, sizeOfInt, sizeOfBool, sizeOfPointer);
  }, library.memory);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Result standaloneResult = await testHello("standalone world", true);
  Result emscriptenResult = await testHello("js world", false);

  runApp(MyApp(standaloneResult, emscriptenResult, key: UniqueKey()));
}

class MyApp extends StatelessWidget {
  final Result _standaloneResult;
  final Result _emscriptenResult;

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
