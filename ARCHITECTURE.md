# Architecture

## Purpose and scope

This document describes the current runtime layers of `wasm_ffi`: how a web
application loads a Wasm module, discovers symbols, binds memory, and invokes
exported functions. It does not define a new API or promise support beyond the
capabilities documented in [`README.md`](README.md).

## Components

| Component | Responsibility | Important dependencies |
| --- | --- | --- |
| `DynamicLibrary` | Public entry point for loading modules, allocating memory, looking up symbols, and closing a library. | `Module`, `Memory`, JavaScript interop |
| `EmscriptenModule` | Loads Emscripten JavaScript glue and its Wasm exports, including the Emscripten heap and allocator. | `inject_js.dart`, `wasm_interop.dart` |
| `StandaloneWasmModule` | Instantiates a raw Wasm binary and exposes its exported functions, globals, memory, and allocator. | `wasm_interop.dart` |
| `Memory` and `Pointer` | Bind addresses to a module's `ByteBuffer`, provide typed access, and implement the library allocator. | native type definitions |
| marshaller and generated invokers | Convert Dart arguments/results to the JavaScript and Wasm representations used by exported functions. | native type signatures, JSFunction helpers |
| `ffi_utils` | Provide web equivalents of allocation, arenas, and UTF-8/UTF-16 helpers. | `Memory`, `Pointer` |

## Dependency direction

The public FFI surface depends on the internal type, lookup, memory, and
marshaller layers. `DynamicLibrary` selects a concrete `Module`; the concrete
module adapters use JavaScript/WebAssembly interop and do not depend on the
example applications. Examples consume the public package API and provide
their own compiled Wasm assets.

## Main flow

1. `DynamicLibrary.open` infers or accepts a module type and loads either a raw
   `.wasm` binary or Emscripten `.js` glue.
2. The selected module adapter instantiates the module and records exported
   functions and non-function symbols.
3. A `Memory` object is created for the module's exported memory and becomes
   the binding for pointers and the library's `allocator`.
4. `lookup<T>` returns a pointer-like symbol handle. For native-function types,
   `asFunction` routes the exported JavaScript function through the marshaller.
5. The marshaller converts pointer addresses and scalar values, including JS
   `BigInt` values used for 64-bit crossings, and converts results back to Dart.

## Invariants and boundaries

- A pointer is meaningful only with the `Memory` instance to which it is bound;
  memory from different module instances must not be mixed.
- A symbol looked up as `NativeFunction<T>` must be an exported function;
  non-function symbols are rejected. Lookup does not validate the complete
  native signature against the Wasm function.
- Return marshalling supports the types registered by `initTypes`, with at
  most two pointer levels and the documented opaque-type registration rule.
- The current runtime rejects `wasm64` loading in `DynamicLibrary.open`; its
  signature analysis is covered separately but is not runtime support.
- Standalone modules may expose `__wasm_call_ctors`; the loader invokes it when
  present so C++ static initialization can run.

## Failure handling

Missing symbols, non-function symbols used as functions, unsupported Wasm
types, unbound memory, and failed module loads raise argument, state, or
unsupported-operation errors at the relevant boundary. Closing a library
invalidates subsequent use of its module-backed resources.

## Relevant verification

- `test/standalone_wasm_test.dart` exercises standalone loading, function
  lookup, invocation, integer and pointer calls, allocation, and symbol errors.
- `test/marshaller_signature_test.dart` exercises 64-bit and pointer-sized JS
  `BigInt` signature selection, including wasm64 logic without claiming
  wasm64 runtime support.
- `example_flutter/` contains both standalone and Emscripten assets and is
  built in both normal and `--wasm` Flutter web modes by CI.
