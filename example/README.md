A vanilla Dart example for [wasm_ffi](https://pub.dev/packages/wasm_ffi).

# Setup

## ffigen (if native source is modified)
Generates bindings using [`package:ffigen`](https://pub.dev/packages/ffigen).
Replace `import 'dart:ffi' as ffi;` with `import 'package:wasm_ffi/ffi_bridge.dart' as ffi;` in the generated binding files

## Running web app

Running the example app requires [`package:webdev`](https://dart.dev/tools/webdev).
```
dart pub global activate webdev
```

To run the web app, cd to example folder and run:
```
webdev serve
```
Then open http://localhost:8080 in your browser

## Running dart app

To run the app, cd to example folder and run:
```
dart run
```