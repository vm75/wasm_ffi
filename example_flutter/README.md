# Flutter web example

This example loads the same native API in two forms: a standalone Wasm module
and an Emscripten module with JavaScript glue. It uses `wasm_ffi` bindings to
display library metadata, string results, native sizes, and the C++ static
initialization check.

## Files

- `lib/main.dart` — Flutter UI showing both module variants.
- `lib/example_library_wrapper.dart` — module loading and typed calls.
- `lib/native_example_bindings.dart` — `ffigen` output adapted to
  `package:wasm_ffi/ffi.dart`.
- `assets/standalone/` — raw standalone Wasm module.
- `assets/emscripten/` — Emscripten JavaScript glue and Wasm module.
- `src/` — C/C++ sources for rebuilding the assets.
- `Makefile` — asset generation commands.

## Build and run

From this directory:

```shell
flutter pub get
make build
flutter run -d chrome
```

To validate the two Flutter web compilers:

```shell
flutter build web
flutter build web --wasm
```

Serve `build/web` over HTTP when testing a built application. The browser
must be able to fetch the `.wasm` and `.js` assets; opening the files directly
with `file://` is not a supported runtime setup.

See the root [`README.md`](../README.md) for API differences, module loading,
memory ownership, and current limitations.
