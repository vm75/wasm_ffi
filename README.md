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
    * To concretize the things above, [return_types.md](https://github.com/vm75/wasm_ffi/blob/main/wasm_ffi/return_types.md) lists what may be used as return type, everyhing else will cause a runtime error.
    * WORKAROUND: If you need something else (e.g. `Pointer<Pointer<Pointer<Double>>>`), use `Pointer<IntPtr>` and cast it yourselfe afterwards using [`Pointer.cast()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Pointer/cast.html).

### Memory
NOTE: While most of this section is still correct, some of it is now automated.
The first call you sould do when you want to use `wasm_ffi` is [`Memory.init()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi_modules/Memory/init.html). It has an optional parameter where you can adjust your pointer size. The argument defaults to 4 to represent 32bit pointers, if you use wasm64, call `Memory.init(8)`.
Contraty to `dart:ffi` where the dart process shares all the memory, on `WebAssembly`, each instance is bound to a `WebAssembly.Memory` object. For now, we assume that every `WebAssembly` module you use has it's own memory. If you think we should change that, open a issue on [GitHub](https://github.com/vm75/wasm_ffi/) and report your usecase.
Every pointer you use is bound to a memory object. This memory object is accessible using the [`@extra Pointer.boundMemory`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Pointer/boundMemory.html) field. If you want to create a Pointer using the [`Pointer.fromAddress()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Pointer/Pointer.fromAddress.html) constructor, you may notice the optional `bindTo` parameter. Since each pointer must be bound to a memory object, you can explicitly speficy a memory object here. To match the `dart:ffi` API, the `bindTo` parameter is optional. Because it is optional, there has to be a fallback mechanism if no `bindTo` is specified: The static [`Memory.global`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi_modules/Memory/global.html) field. If that field is also not set, an exception is thrown when invoking the `Pointer.fromAddress()` constructor.
Also, each [`DynamicLibrary`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary-class.html) is bound to a memory object, which is again accessible with [`@extra DynamicLibrary.boundMemory`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary/boundMemory.html). This might come in handy, since `Memory` implements the [`Allocator`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Allocator-class.html) class.


## Usage

### Install
```
dart pub add wasm_ffi
```

or
```
flutter pub add wasm_ffi
```

### Usage without ffi bindings
```dart
import 'package:wasm_ffi/ffi.dart' as ffi;

Future<void> main() async {
    final library = await DynamicLibrary.open('path to wasm or js'); // NOTE: It is async
    final func = library.lookupFunction<int Function(), int Function()>('functionName');
    print(func());
}
```

### Usage with ffi bindings
Generates ffi bindings using [`package:ffigen`](https://pub.dev/packages/ffigen) on the header file.
In the generated bindings file, replace `import 'dart:ffi' as ffi;` with `import 'package:wasm_ffi/ffi.dart' as ffi;`

```
import 'package:wasm_ffi/ffi.dart';
import 'package:wasm_ffi/ffi_utils.dart';
import 'native_example_bindings.dart';

...
  final library = await DynamicLibrary.open(libName);
  final bindings = NativeExampleBindings(library);

  // assuming that native library is has a function `hello` which takes a name and returns a string `Hello name!`
  using((Arena arena) {
    final cString = name.toNativeUtf8(allocator: arena).cast<Char>();
    return bindings.hello(cString).cast<Utf8>().toDartString();
  }, library.allocator); // library.allocator is optional if only one module is loaded
...

```

### build wasm

The generated wasm file needs all exported function. To ensure that, one of the two can be done:
* Use EMSCRIPTEN_KEEPALIVE annotation on all exported functions
* Define EXPORTED_FUNCTIONS when compiling the wasm

## Building WASM with Emscripten

This section provides detailed instructions on how to create WASM modules using Emscripten (emcc) for both Emscripten and standalone configurations. Emscripten generates JavaScript glue code along with WASM, while standalone produces pure WASM without JavaScript.

### Prerequisites

- Install Emscripten: Follow the [official installation guide](https://emscripten.org/docs/getting_started/downloads.html).
- Ensure `emcc` is in your PATH.

### Emscripten WASM (with JavaScript glue)

Emscripten WASM is suitable for web applications where you need JavaScript interop and access to browser APIs. It generates both a `.js` file (containing the module and runtime) and a `.wasm` file.

#### Basic Command

```bash
emcc -o output.js input.c \
  -s MODULARIZE=1 \
  -s 'EXPORT_NAME="MyModule"' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s EXPORTED_RUNTIME_METHODS=HEAPU8 \
  -s EXPORTED_FUNCTIONS=["_myFunction", "_malloc", "_free"]
```

#### Key Options Explained

- `-s MODULARIZE=1`: Wraps the generated code in a function, making it a module that can be instantiated multiple times.
- `-s 'EXPORT_NAME="MyModule"'`: Specifies the name of the exported module (replace `"MyModule"` with your desired name).
- `-s ALLOW_MEMORY_GROWTH=1`: Allows the WASM memory to grow dynamically as needed.
- `-s EXPORTED_RUNTIME_METHODS=HEAPU8`: **Important**: Exports `HEAPU8`, a Uint8Array view of the WASM memory, allowing direct access to the memory buffer from JavaScript. This is crucial for `wasm_ffi` to interact with the WASM memory.
- `-s EXPORTED_FUNCTIONS=["_myFunction", "_malloc", "_free"]`: Lists the functions to export from the WASM module. Prefix C function names with `_`. Include `_malloc` and `_free` if your code uses dynamic memory allocation.

#### Additional Optimization Options

For production builds, add these flags:

```bash
-Oz -fno-exceptions -fno-rtti -fno-stack-protector -ffunction-sections -fdata-sections -fno-math-errno -DNDEBUG
```

For debugging:

```bash
-g3 --profiling-funcs -s ASSERTIONS=1 -fsanitize=address
```

### Standalone WASM

Standalone WASM produces a pure `.wasm` file without JavaScript glue code. It's suitable for environments where you have direct WASM support without JavaScript interop.

#### Basic Command

```bash
emcc -o output.wasm input.c \
  -s STANDALONE_WASM=1 \
  -s EXPORTED_FUNCTIONS=["_myFunction", "_malloc", "_free"]
```

#### Key Options Explained

- `-s STANDALONE_WASM=1`: Generates standalone WASM without Emscripten runtime.
- `-s EXPORTED_FUNCTIONS=["_myFunction", "_malloc", "_free"]`: Same as above, lists exported functions.

#### Additional Options

Same optimization and debugging flags as Emscripten can be used.

### Example from this Repository

See the [example/Makefile](example/Makefile) for a complete build setup that generates both Emscripten and standalone WASM.

### Notes

- Always include `_malloc` and `_free` in `EXPORTED_FUNCTIONS` if your C code uses dynamic memory allocation.
- For Emscripten, `HEAPU8` export is essential for `wasm_ffi` to access the WASM memory.
- Test your builds in the target environment (web browser for Emscripten, WASM runtime for standalone).

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
