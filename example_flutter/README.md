# wasm_ffi Flutter Example

This project demonstrates how to use `wasm_ffi` in a Flutter web application.

It shows:

1. **Asset Management**: How to include `.wasm` and `.js` files as Flutter assets.
2. **Initialization**: How to load these assets and initialize the `wasm_ffi` runtime using `inject_js` and `EmscriptenModule.compile()`.
3. **UI Integration**: Calling C functions (via WASM) and displaying the result in a Flutter widget.

## Getting Started

1. **Prerequisites**:
    * Flutter SDK installed.
    * `wasm_ffi` and `inject_js` dependencies (see `pubspec.yaml`).
    * Compiled `libopus.js` and `libopus.wasm` in `assets/`.

2. **Run the App**:
    * Chrome is the recommended target for testing WASM.
    * Run:

        ```bash
        flutter run -d chrome
        ```

3. **What to Expect**:
    * The app should launch in Chrome.
    * It will load the WASM module.
    * It will display the Opus version string (e.g., `libopus 1.3.1`) in the center of the screen.

## Key Files

* `lib/main.dart`: The main entry point and UI.
* `lib/src/init_web.dart`: Web-specific initialization logic for `wasm_ffi`.
* `assets/`: Contains the compiled WASM and JS glue code.

## Learn More

For a comprehensive guide on building WASM modules and using `wasm_ffi`, see the main [wasm_ffi README](../README.md).
