# wasm_ffi
`wasm_ffi` intends to be a drop-in replacement for `dart:ffi` on the web platform using wasm. wasm_ffi is built on top of [web_ffi](https://pub.dev/packages/web_ffi).
For ease of use cross-platform, the following are provided:
* ffi_bridge: selects `wasm_ffi/ffi.dart` for web and `dart:ffi` for other platforms
* ffi_utils_bridge: selects `wasm_ffi/ffi_utils.dart` for web and `package:ffi` for other platforms
* FfiWrapper: a simple wrapper utility which loads `DynamicLibrary` asynchronously. Also provides a `safeUsing` method which uses the current library's memory.

The general idea is to expose an API that is compatible with `dart:ffi` but translates all calls through `dart:js` to a browser running `WebAssembly`.

Webassembly (wasm) compiled with [emscripten](https://emscripten.org/) as well as standalone wasm is supported.

The provided example shows how to use wasm_ffi both in web and in dart.

## Installation

* Dart
```
dart pub add wasm_ffi
```

* Flutter
```
flutter pub add wasm_ffi
```

## Usage examples

### FfiWrapper and ffigen (all platforms)
* Generate bindings using `ffigen`
* Replace `import 'dart:ffi' as ffi;` with `import 'package:wasm_ffi/ffi_bridge.dart' as ffi;` in the generated binding files
* Instantiate FfiWrapper: `ffiWrapper = await FfiWrapper.load('path to wasm or js');`
* Create binding instance: `BindingClass bindings = BindingClass(ffiWrapper.library);`
* Call method: `ffiWrapper.safeUsing((Arena arena) { ... });`


### Direct load example (only for web)
```dart
import 'package:wasm_ffi/ffi.dart' as ffi;

Future<void> main() async {
    final library = await DynamicLibrary.open('path to wasm or js'); // NOTE: It is async
    final func = library.lookupFunction<int Function(), int Function()>('functionName');
    print(func());
}
```

## Differences to dart:ffi
While `wasm_ffi` tries to mimic the `dart:ffi` API as close as possible, there are some differences. The list below documents the most importent ones, make sure to read it. For more insight, take a look at the API documentation.

* The [`DynamicLibrary`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary-class.html) class constructor is different. One key difference is that the 'load' method is asynchronous.
* If more than one library is loaded, it is recommended to use `FfiWrapper:safeUsing` instead of `using`, as it ensure that the correct memory is used.
* Each library has its own memory, so objects cannot be shared between libraries.
* Some advanced types are still unsupported.
* There are some classes and functions that are present in `wasm_ffi` but not in `dart:ffi`; such things are annotated with [`@extra`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi_meta/extra-constant.html).
* There is a new class [`Memory`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi_modules/Memory-class.html) which is **IMPORTANT** and explained in deepth below.
* If you extend the [`Opaque`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Opaque-class.html) class, you must register the extended class using [`@extra registerOpaqueType<T>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi_modules/registerOpaqueType.html) before using it! Also, your class MUST NOT have type arguments (what should not be a problem).
* There are some rules concerning interacting with native functions, as listed below.

## Rules for functions (TODO: needs update)
There are some rules and things to notice when working with functions:
* When looking up a function using [`DynamicLibrary.lookup<NativeFunction<NF>>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary/lookup.html) (or [`DynamicLibraryExtension.lookupFunction<T extends Function, F extends Function>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibraryExtension/lookupFunction.html)) the actuall type argument `NF` (or `T` respectively) of is not used: There is no type checking, if the function exported from `WebAssembly` has the same signature or amount of parameters, only the name is looked up.
* There are special constraints on the return type (not on parameter types) of functions `DF` (or `F` ) if you call [`NativeFunctionPointer.asFunction<DF>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/NativeFunctionPointer/asFunction.html) (or [`DynamicLibraryExtension.lookupFunction<T extends Function, F extends Function>()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibraryExtension/lookupFunction.html) what uses the former internally):
    * You may nest the pointer type up to two times but not more:
        * e.g. `Pointer<Int32>` and `Pointer<Pointer<Int32>>` are allowed but `Pointer<Pointer<Pointer<Int32>>>` is not.
    * If the return type is `Pointer<NativeFunction>` you MUST use `Pointer<NativeFunction<dynamic>>`, everything else will fail. You can restore the type arguments afterwards yourself using casting. On the other hand, as stated above, type arguments for `NativeFunction`s are just ignored anyway.
    * To concretize the things above, [return_types.md](https://github.com/vm75/wasm_ffi/tree/main/return_types.md) lists what may be used as return type, everyhing else will cause a runtime error.
    * WORKAROUND: If you need something else (e.g. `Pointer<Pointer<Pointer<Double>>>`), use `Pointer<IntPtr>` and cast it yourselfe afterwards using [`Pointer.cast()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Pointer/cast.html).

## Memory (TODO: needs update)
NOTE: While most of this section is still correct, some of it is now automated.
The first call you sould do when you want to use `wasm_ffi` is [`Memory.init()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi_modules/Memory/init.html). It has an optional parameter where you can adjust your pointer size. The argument defaults to 4 to represent 32bit pointers, if you use wasm64, call `Memory.init(8)`.
Contraty to `dart:ffi` where the dart process shares all the memory, on `WebAssembly`, each instance is bound to a `WebAssembly.Memory` object. For now, we assume that every `WebAssembly` module you use has it's own memory. If you think we should change that, open a issue on [GitHub](https://github.com/vm75/wasm_ffi/) and report your usecase.
Every pointer you use is bound to a memory object. This memory object is accessible using the [`@extra Pointer.boundMemory`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Pointer/boundMemory.html) field. If you want to create a Pointer using the [`Pointer.fromAddress()`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Pointer/Pointer.fromAddress.html) constructor, you may notice the optional `bindTo` parameter. Since each pointer must be bound to a memory object, you can explicitly speficy a memory object here. To match the `dart:ffi` API, the `bindTo` parameter is optional. Because it is optional, there has to be a fallback mechanism if no `bindTo` is specified: The static [`Memory.global`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi_modules/Memory/global.html) field. If that field is also not set, an exception is thrown when invoking the `Pointer.fromAddress()` constructor.
Also, each [`DynamicLibrary`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary-class.html) is bound to a memory object, which is again accessible with [`@extra DynamicLibrary.boundMemory`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/DynamicLibrary/boundMemory.html). This might come in handy, since `Memory` implements the [`Allocator`](https://pub.dev/documentation/wasm_ffi/latest/wasm_ffi/Allocator-class.html) class.
