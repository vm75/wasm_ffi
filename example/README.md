# wasm_ffi Example

This directory contains a complete example of using `wasm_ffi` to port the [opus_dart](https://github.com/EPNW/opus_dart) library to the web.

It demonstrates:

* Compiling a C library (`libopus`) to WebAssembly using Emscripten.
* Using `ffigen` with a proxy file to generate bindings.
* Setting up the necessary boilerplate to initialize `wasm_ffi` in a vanilla Dart web app.

## Project Structure

* `bin/`: Contains the main entry point for the vanilla Dart app.
* `lib/src/`: Contains the specific binding code (`generated.dart`), the proxy (`proxy_ffi.dart`), and initialization logic.
* `web/`: Contains the HTML and build artifacts for the web.

## Building the C Library

We use [Docker](https://www.docker.com/) to ensure a consistent build environment for the `libopus` library.

1. **Build the Docker image**:
    The generic `Dockerfile` is available in the root of the example.

2. **Compile to WASM**:
    Detailed instructions and the `Makefile` are in the `Makefile` (if present) or described in the original tutorial.
    *> Note: The pre-compiled `libopus.js` and `libopus.wasm` are already included in the `web/` directory for convenience.*

    To rebuild them yourself using the Docker method from the original tutorial:

    ```bash
    docker build -t wasm_ffi_opus_builder .
    docker run --rm -v $(pwd):/src wasm_ffi_opus_builder
    ```

    *(Adjust the commands based on the actual Dockerfile logic if you want to reproduce the build exactly).*

## Running the Example

1. **Compile Dart to JavaScript**:
    We use `dart2js` to compile the Dart application code.

    ```shell
    dart compile js ./bin/main.dart -o ./web/main.dart.js
    ```

2. **Serve the Web Application**:
    You need a simple HTTP server to serve the `web` directory. We recommend `dhttpd`.

    Install `dhttpd` if you haven't:

    ```shell
    dart pub global activate dhttpd
    ```

    Run the server:

    ```shell
    cd web
    dart pub global run dhttpd -p 8080
    ```

3. **Open in Browser**:
    Navigate to [http://localhost:8080](http://localhost:8080) in your browser.
    Open the **Developer Console** (F12) to see the output. You should see the Opus version string printed (e.g., `libopus 1.3.1`).

## Learn More

For a detailed explanation of the concepts used here, including how `proxy_ffi.dart` works and how to support both Native and Web platforms, please refer to the main [wasm_ffi README](../README.md).
