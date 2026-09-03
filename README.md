# wasm_ffi

[![build_badge]][build_url]
[![github_badge]][wasm_ffi_github_url]
[![wasm_ffi_pub_ver]][wasm_ffi_pub_url]
[![wasm_ffi_pub_points]][wasm_ffi_pub_score_url]
[![wasm_ffi_pub_popularity]][wasm_ffi_pub_score_url]
[![wasm_ffi_pub_likes]][wasm_ffi_pub_score_url]
[![license_badge]][license_url]

`wasm_ffi` provides a `dart:ffi`-like API for WebAssembly modules on the web.
It supports Dart web applications compiled with `dart2js` or `dart2wasm`,
including standalone Wasm and Emscripten JavaScript glue. JavaScript `BigInt`
conversion is used for 64-bit values crossing the JS boundary.

To simplify the usage, [universal_ffi](https://pub.dev/packages/universal_ffi) is provided, which uses `wasm_ffi` on web and `dart:ffi` on other platforms.

## Differences to dart:ffi

While `wasm_ffi` tries to mimic the `dart:ffi` API closely, there are some
important differences:

* The [`DynamicLibrary`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary-class.html) `open` method is asynchronous. It also accepts some additional optional parameters.
* If more than one library is loaded, the memory will continue to refer to the first library. **This breaks calls to later loaded libraries!** One workaround is to specify the correct library.allocator for each usage of `using`.
* Each library has its own memory, so objects cannot be shared between libraries.
* Some advanced types are still unsupported.
* There are some classes and functions that are present in `wasm_ffi` but not in `dart:ffi`; such things are annotated with [`@extra`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi_meta/extra-constant.html).
* Each loaded library has a module-specific `Memory` and `allocator`.
* If you extend the [`Opaque`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Opaque-class.html) class, you must register it with [`registerOpaqueType<T>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/registerOpaqueType.html) before use. The class must not have type arguments.
* There are some rules concerning interacting with native functions, as listed below.

### Rules for functions

There are some rules and things to notice when working with functions:

* When looking up a function using [`DynamicLibrary.lookup<NativeFunction<NF>>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary/lookup.html) or [`DynamicLibrary.lookupFunction<T extends Function, F extends Function>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary/lookupFunction.html), the native type argument is not used to validate the exported signature. The caller must provide the correct name, signature, and arity.
* There are special constraints on the return type (not on parameter types) of functions `DF` (or `F`) if you call [`NativeFunctionPointer.asFunction<DF>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/NativeFunctionPointer/asFunction.html) or `DynamicLibrary.lookupFunction` (which uses the former internally):
  * You may nest the pointer type up to two times but not more:
    * e.g. `Pointer<Int32>` and `Pointer<Pointer<Int32>>` are allowed but `Pointer<Pointer<Pointer<Int32>>>` is not.
  * If the return type is `Pointer<NativeFunction>` you MUST use `Pointer<NativeFunction<dynamic>>`, everything else will fail. You can restore the type arguments afterwards yourself using casting. On the other hand, as stated above, type arguments for `NativeFunction`s are just ignored anyway.
  * To concretize the things above, [the Appendix](#appendix-return-types) lists what may be used as return type, everyhing else will cause a runtime error.
  * WORKAROUND: If you need something else (e.g. `Pointer<Pointer<Pointer<Double>>>`), use `Pointer<IntPtr>` and cast it yourselfe afterwards using [`Pointer.cast()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Pointer/cast.html).

### Memory

Each `DynamicLibrary.open` call creates or binds a module-specific memory
object. Contrary to `dart:ffi`, separately loaded WebAssembly modules do not
share memory, so their pointers cannot be mixed.
Every pointer is bound to a memory object. Use [`Pointer.fromAddress()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Pointer/Pointer.fromAddress.html) with its optional `bindTo` argument when an address must be bound explicitly.
Use the [`DynamicLibrary.allocator`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary/allocator.html)
property for allocations passed to that library.

## Usage Guide

This guide covers how to build your WASM modules, generate bindings, and use them in both vanilla Dart and Flutter applications.

### Quick start

Load a standalone module by URL and invoke an exported function:

```dart
import 'package:wasm_ffi/ffi.dart';

typedef AddNative = Int32 Function(Int32, Int32);
typedef AddDart = int Function(int, int);

Future<void> main() async {
  final library = await DynamicLibrary.open('assets/example.wasm');
  final add = library.lookupFunction<AddNative, AddDart>('add');
  print(add(2, 3));
  await library.close();
}
```

Use a generated Emscripten `.js` glue file in the same way. `open` infers the
module kind from the extension and fetches the asset asynchronously.

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

**Crucial:** You **MUST** include `-s EXPORTED_RUNTIME_METHODS=HEAPU8`. This exports the memory object so `universal_ffi` can access it.
**Optimization:** Use `-Oz` for size, `-O3` for speed.

#### Option B: Standalone WASM

Best for environments with direct WASM support.

```bash
emcc -o output.wasm input.c \
  -s STANDALONE_WASM=1 \
  -s EXPORTED_FUNCTIONS=["_myFunction", "_malloc", "_free"]
```

**Crucial:** You **MUST** include `--export=__wasm_call_ctors` if you are using C++ to ensure static constructors run.
**Optimization:** Use `-Oz` for size, `-O3` for speed.

### 2. Generating Bindings with `ffigen`

You can use `ffigen` to generate bindings, but you need a proxy to handle the difference between `dart:ffi` and `wasm_ffi`.

1. **Create a proxy file** in the consuming package:

    ```dart
    export 'package:wasm_ffi/ffi.dart' if (dart.library.ffi) 'dart:ffi';
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
    import 'package:wasm_ffi/ffi.dart';

    void main() async {
      final dylib = await DynamicLibrary.open('assets/example.js');

      // Use dylib to look up functions or use generated bindings
      // ...
    }
    ```

### 4. Usage in Flutter

For Flutter Web applications:

1. **Assets**: Place the generated `.js` and `.wasm` files in the Flutter asset directory and add them to `pubspec.yaml`.
2. **Initialization**:

    ```dart
    import 'package:wasm_ffi/ffi.dart';

    Future<void> init() async {
      final dylib = await DynamicLibrary.open('assets/libexample.js');
    }
    ```

### 5. Cross-Platform Support (Web + Native)

To support both Web (via `wasm_ffi`) and Native (via `dart:ffi`) in the same codebase:

1. **Proxy File**: Enhance your `proxy_ffi.dart` to conditionally export initialization logic.

    ```dart
    export 'package:wasm_ffi/ffi.dart' if (dart.library.ffi) 'dart:ffi';
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

## Development and verification

Run these commands from the repository root:

```shell
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze lib test
dart test
dart test --compiler=dart2wasm test/marshaller_signature_test.dart
dart compile wasm test/standalone_wasm_test.dart -o /tmp/standalone_wasm_test.wasm
dart pub publish --dry-run
```

The default test suite runs on Chrome because the implementation uses
web-only JavaScript interop. CI also runs `flutter analyze`, `flutter build
web`, and `flutter build web --wasm` in `example_flutter`. The complete test
suite compiled as dart2wasm may exceed Chromium's WasmGC subtype-depth limit;
the repository therefore tests dart2wasm signature logic separately and does
not claim wasm64 runtime support.

See [`AGENTS.md`](AGENTS.md) for contributor workflow and
[`ARCHITECTURE.md`](ARCHITECTURE.md) for component boundaries.

## Appendix: Return Types

Allowed return types for functions used as type parameter in [`NativeFunctionPointer.asFunction<DF>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/NativeFunctionPointer/asFunction.html) and [`DynamicLibrary.lookupFunction<T extends Function, F extends Function>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary/lookupFunction.html):

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

[build_badge]: https://img.shields.io/github/actions/workflow/status/vm75/wasm_ffi/.github/workflows/ci.yml?branch=main
[build_url]: https://github.com/vm75/wasm_ffi/actions

[github_badge]: https://img.shields.io/badge/github-gray?style=flat&logo=Github

[wasm_ffi_pub_ver]: https://img.shields.io/pub/v/wasm_ffi
[wasm_ffi_pub_points]: https://img.shields.io/pub/points/wasm_ffi
[wasm_ffi_pub_popularity]: https://img.shields.io/pub/popularity/wasm_ffi
[wasm_ffi_pub_likes]: https://img.shields.io/pub/likes/wasm_ffi
[wasm_ffi_github_url]: https://github.com/vm75/wasm_ffi
[wasm_ffi_pub_url]: https://pub.dev/packages/wasm_ffi
[wasm_ffi_pub_score_url]: https://pub.dev/packages/wasm_ffi/score
