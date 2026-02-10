# wasm_ffi

[![build_badge]][build_url]
[![github_badge]][wasm_ffi_github_url]
[![wasm_ffi_pub_ver]][wasm_ffi_pub_url]
[![wasm_ffi_pub_points]][wasm_ffi_pub_score_url]
[![wasm_ffi_pub_popularity]][wasm_ffi_pub_score_url]
[![wasm_ffi_pub_likes]][wasm_ffi_pub_score_url]
[![license_badge]][license_url]

`wasm_ffi` intends to be a drop-in replacement for `dart:ffi` on the web platform using wasm. wasm_ffi is built on top of [web_ffi](https://pub.dev/packages/web_ffi).
The general idea is to expose an API that is compatible with `dart:ffi` but translates all calls through `dart:js` to a browser running `WebAssembly`.
Wasm with js helper as well as standalone wasm is supported. For testing emcc is used.

To simplify the usage, [universal_ffi](https://pub.dev/packages/universal_ffi) is provided, which uses `wasm_ffi` on web and `dart:ffi` on other platforms.

## Differences to dart:ffi

While `wasm_ffi` tries to mimic the `dart:ffi` API as close as possible, there are some differences. The list below documents the most importent ones, make sure to read it. For more insight, take a look at the API documentation.

* The [`DynamicLibrary`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary-class.html) `open` method is asynchronous. It also accepts some additional optional parameters.
* If more than one library is loaded, the memory will continue to refer to the first library. **This breaks calls to later loaded libraries!** One workaround is to specify the correct library.allocator for each usage of `using`.
* Each library has its own memory, so objects cannot be shared between libraries.
* Some advanced types are still unsupported.
* There are some classes and functions that are present in `wasm_ffi` but not in `dart:ffi`; such things are annotated with [`@extra`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi_meta/extra-constant.html).
* There is a new class [`Memory`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi_modules/Memory-class.html) which is **IMPORTANT** and explained in deepth below.
* If you extend the [`Opaque`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Opaque-class.html) class, you must register the extended class using [`@extra registerOpaqueType<T>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi_modules/registerOpaqueType.html) before using it! Also, your class MUST NOT have type arguments (what should not be a problem).
* There are some rules concerning interacting with native functions, as listed below.

### Rules for functions

There are some rules and things to notice when working with functions:

* When looking up a function using [`DynamicLibrary.lookup<NativeFunction<NF>>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary/lookup.html) (or [`DynamicLibraryExtension.lookupFunction<T extends Function, F extends Function>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibraryExtension/lookupFunction.html)) the actuall type argument `NF` (or `T` respectively) of is not used: There is no type checking, if the function exported from `WebAssembly` has the same signature or amount of parameters, only the name is looked up.
* There are special constraints on the return type (not on parameter types) of functions `DF` (or `F` ) if you call [`NativeFunctionPointer.asFunction<DF>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/NativeFunctionPointer/asFunction.html) (or [`DynamicLibraryExtension.lookupFunction<T extends Function, F extends Function>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibraryExtension/lookupFunction.html) what uses the former internally):
  * You may nest the pointer type up to two times but not more:
    * e.g. `Pointer<Int32>` and `Pointer<Pointer<Int32>>` are allowed but `Pointer<Pointer<Pointer<Int32>>>` is not.
  * If the return type is `Pointer<NativeFunction>` you MUST use `Pointer<NativeFunction<dynamic>>`, everything else will fail. You can restore the type arguments afterwards yourself using casting. On the other hand, as stated above, type arguments for `NativeFunction`s are just ignored anyway.
  * To concretize the things above, [the Appendix](#appendix-return-types) lists what may be used as return type, everyhing else will cause a runtime error.
  * WORKAROUND: If you need something else (e.g. `Pointer<Pointer<Pointer<Double>>>`), use `Pointer<IntPtr>` and cast it yourselfe afterwards using [`Pointer.cast()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Pointer/cast.html).

### Memory

NOTE: While most of this section is still correct, some of it is now automated.
The first call you sould do when you want to use `wasm_ffi` is [`Memory.init()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi_modules/Memory/init.html). It has an optional parameter where you can adjust your pointer size. The argument defaults to 4 to represent 32bit pointers, if you use wasm64, call `Memory.init(8)`.
Contraty to `dart:ffi` where the dart process shares all the memory, on `WebAssembly`, each instance is bound to a `WebAssembly.Memory` object. For now, we assume that every `WebAssembly` module you use has it's own memory. If you think we should change that, open a issue on [GitHub](https://github.com/vm75/wasm_ffi/) and report your usecase.
Every pointer you use is bound to a memory object. This memory object is accessible using the [`@extra Pointer.boundMemory`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Pointer/boundMemory.html) field. If you want to create a Pointer using the [`Pointer.fromAddress()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Pointer/Pointer.fromAddress.html) constructor, you may notice the optional `bindTo` parameter. Since each pointer must be bound to a memory object, you can explicitly speficy a memory object here. To match the `dart:ffi` API, the `bindTo` parameter is optional. Because it is optional, there has to be a fallback mechanism if no `bindTo` is specified: The static [`Memory.global`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi_modules/Memory/global.html) field. If that field is also not set, an exception is thrown when invoking the `Pointer.fromAddress()` constructor.
Also, each [`DynamicLibrary`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary-class.html) is bound to a memory object, which is again accessible with [`@extra DynamicLibrary.boundMemory`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary/boundMemory.html). This might come in handy, since `Memory` implements the [`Allocator`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Allocator-class.html) class.

## Usage Guide

This guide covers how to build your WASM modules, generate bindings, and use them in both vanilla Dart and Flutter applications.

### 1. Building WASM with Emscripten

You can compile your C/C++ code to WebAssembly using [Emscripten](https://emscripten.org/). There are two main modes: with JavaScript glue code (recommended for most web apps) and standalone WASM.

#### Prerequisite

* Install Emscripten: [Download Guide](https://emscripten.org/docs/getting_started/downloads.html).
* Ensure `emcc` is in your PATH.

#### Option A: Emscripten WASM (with JavaScript glue)

Best for web apps needing JS interop.

```bash
emcc -o output.js input.c \
  -s MODULARIZE=1 \
  -s 'EXPORT_NAME="MyModule"' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s EXPORTED_RUNTIME_METHODS=HEAPU8 \
  -s EXPORTED_FUNCTIONS=["_myFunction", "_malloc", "_free"]
```

**Key Flags:**

* `-s MODULARIZE=1`: Wraps code in a module.
* `-s EXPORTED_RUNTIME_METHODS=HEAPU8`: **Required** for `wasm_ffi` to access memory.
* `-s EXPORTED_FUNCTIONS`: List all C functions to export (prefix with `_`). Always include `_malloc` and `_free`.

#### Option B: Standalone WASM

Best for environments with direct WASM support.

```bash
emcc -o output.wasm input.c \
  -s STANDALONE_WASM=1 \
  -s EXPORTED_FUNCTIONS=["_myFunction", "_malloc", "_free"]
```

#### Notes

* **C++ Support**: Explicitly export `__wasm_call_ctors` to ensure static constructors run: `-Wl,--export=__wasm_call_ctors`.
* **Optimization**: Use `-Oz` for size, `-O3` for speed.

### 2. Generating Bindings with `ffigen`

You can use `ffigen` to generate bindings, but you need a proxy to handle the difference between `dart:ffi` and `wasm_ffi`.

1. **Create a Proxy File** (`lib/src/proxy_ffi.dart`):

    ```dart
    export 'package:wasm_ffi/wasm_ffi.dart' if (dart.library.ffi) 'dart:ffi';
    ```

2. **Generate Bindings**: Configure `ffigen` to generate bindings as usual.

3. **Update Generated File**: Open the generated binding file and replace:

    ```dart
    import 'dart:ffi' as ffi;
    ```

    with:

    ```dart
    import 'proxy_ffi.dart' as ffi;
    ```

    *Note: You can automate this with a simple script.*

### 3. Usage in Vanilla Dart

For a pure Dart web application:

1. **Compile WASM**: Use Option A (with JS glue) to get `libexample.js` and `libexample.wasm`.
2. **HTML Setup**: Include the JS glue in your `index.html`.

    ```html
    <script src="libexample.js"></script>
    ```

3. **Dart Code**:

    ```dart
    import 'package:wasm_ffi/wasm_ffi.dart';
    import 'package:wasm_ffi/wasm_ffi_modules.dart';

    void main() async {
      // Initialize Memory
      Memory.init();

      // Load Module (processes the script tag)
      var module = await EmscriptenModule.process('MyModule');
      var dylib = DynamicLibrary.fromModule(module);

      // Use dylib to look up functions or use generated bindings
      // ...
    }
    ```

### 4. Usage in Flutter

For Flutter Web applications:

1. **Assets**: Place `libexample.js` and `libexample.wasm` in your `assets/` folder and add them to `pubspec.yaml`.
2. **Dependency**: Add `inject_js` to your `pubspec.yaml` to help load the JS.
3. **Initialization**:

    ```dart
    import 'package:flutter/services.dart';
    import 'package:inject_js/inject_js.dart' as Js;
    import 'package:wasm_ffi/wasm_ffi.dart';
    import 'package:wasm_ffi/wasm_ffi_modules.dart';

    Future<void> init() async {
      Memory.init();

      // 1. Inject JS Glue
      await Js.importLibrary('assets/libexample.js');

      // 2. Load WASM Binary
      var wasmFile = await rootBundle.load('assets/libexample.wasm');
      var wasmMap = {'wasmBinary': wasmFile.buffer.asUint8List()};

      // 3. Compile & Instantiate
      var module = await EmscriptenModule.compile(wasmMap, 'MyModule');
      var dylib = DynamicLibrary.fromModule(module);
    }
    ```

### 5. Cross-Platform Support (Web + Native)

To support both Web (via `wasm_ffi`) and Native (via `dart:ffi`) in the same codebase:

1. **Proxy File**: Enhance your `proxy_ffi.dart` to conditionally export initialization logic.

    ```dart
    export 'package:wasm_ffi/wasm_ffi.dart' if (dart.library.ffi) 'dart:ffi';
    export 'init_web.dart' if (dart.library.ffi) 'init_native.dart';
    ```

2. **Init Files**:
    * `init_web.dart`: Implements `initFfi()` using `wasm_ffi` (as shown in the Flutter/Vanilla sections).
    * `init_native.dart`: Implements `initFfi()` as a no-op or native setup.

3. **Main Code**:

    ```dart
    import 'proxy_ffi.dart';

    void main() async {
      await initFfi();
      // ... use your bindings
    }
    ```

## Appendix: Return Types

Allowed return types for functions used as type parameter in [`NativeFunctionPointer.asFunction<DF>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/NativeFunctionPointer/asFunction.html) and [`DynamicLibraryExtension.lookupFunction<T extends Function, F extends Function>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary/lookupFunction.html):

* `int`
* `double`
* `bool`
* `void`
* `Pointer<Float>`, `Pointer<Pointer<Float>>`
* `Pointer<Double>`, `Pointer<Pointer<Double>>`
* `Pointer<Int8>`, `Pointer<Pointer<Int8>>`
* `Pointer<Uint8>`, `Pointer<Pointer<Uint8>>`
* `Pointer<Int16>`, `Pointer<Pointer<Int16>>`
* `Pointer<Uint16>`, `Pointer<Pointer<Uint16>>`
* `Pointer<Int32>`, `Pointer<Pointer<Int32>>`
* `Pointer<Uint32>`, `Pointer<Pointer<Uint32>>`
* `Pointer<Int64>`, `Pointer<Pointer<Int64>>`
* `Pointer<Uint64>`, `Pointer<Pointer<Uint64>>`
* `Pointer<IntPtr>`, `Pointer<Pointer<IntPtr>>`
* `Pointer<Opaque>`, `Pointer<Pointer<Opaque>>`
* `Pointer<Void>`, `Pointer<Pointer<Void>>`
* `Pointer<NativeFunction<dynamic>>`, `Pointer<Pointer<NativeFunction<dynamic>>>`
* `Pointer<MyOpaque>`, `Pointer<Pointer<MyOpaque>>` where `MyOpaque` is a class extending `Opaque` and was registered before using [`registerOpaqueType<MyOpaque>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/registerOpaqueType.html)

---

Contributions are welcome! 🚀

[license_badge]: https://img.shields.io/badge/license-BSD-blue.svg
[license_url]: https://github.com/vm75/wasm_ffi/blob/main/LICENSE

[build_badge]: https://img.shields.io/github/actions/workflow/status/vm75/wasm_ffi/.github/workflows/publish.yml?branch=main
[build_url]: https://github.com/vm75/wasm_ffi/actions

[github_badge]: https://img.shields.io/badge/github-gray?style=flat&logo=Github

[wasm_ffi_pub_ver]: https://img.shields.io/pub/v/wasm_ffi
[wasm_ffi_pub_points]: https://img.shields.io/pub/points/wasm_ffi
[wasm_ffi_pub_popularity]: https://img.shields.io/pub/popularity/wasm_ffi
[wasm_ffi_pub_likes]: https://img.shields.io/pub/likes/wasm_ffi
[wasm_ffi_github_url]: https://github.com/vm75/wasm_ffi
[wasm_ffi_pub_url]: https://pub.dev/packages/wasm_ffi
[wasm_ffi_pub_score_url]: https://pub.dev/packages/wasm_ffi/score
