# Project Agent Guide

## Project overview

`wasm_ffi` is a Dart web package that exposes a `dart:ffi`-like API for
WebAssembly modules. It loads standalone `.wasm` modules or Emscripten
JavaScript glue, maps exported symbols to Dart pointers, and marshals calls
through JavaScript/WebAssembly interop.

## Repository map

- `lib/ffi.dart` — public FFI-compatible types, pointers, lookup, and marshalling exports.
- `lib/ffi_utils.dart` — public allocation, arena, and string helpers for web FFI.
- `lib/src/ffi/` — pointer types, memory, lookup, invocation, and marshalling implementation.
- `lib/src/ffi/modules/` — standalone Wasm and Emscripten module adapters.
- `lib/src/js_utils/` — JavaScript and WebAssembly interop declarations.
- `test/` — Chrome tests, signature tests, and the standalone Wasm fixture.
- `example/` — vanilla Dart web example.
- `example_flutter/` — Flutter web example using standalone and Emscripten assets.
- `.github/workflows/` — pull-request CI and the version-triggered publish workflow.

## Working commands

Run from the repository root unless noted:

- Setup: `dart pub get`
- Format: `dart format --output=none --set-exit-if-changed .`
- Analyze package: `dart analyze lib test`
- Test: `dart test`
- Test signature logic with dart2wasm: `dart test --compiler=dart2wasm test/marshaller_signature_test.dart`
- Compile a Wasm entry point: `dart compile wasm <entrypoint.dart> -o <output.wasm>`
- Validate package contents: `dart pub publish --dry-run`
- Build Flutter examples: `cd example_flutter && flutter pub get && flutter build web && flutter build web --wasm`
- Build example Wasm assets: `make build`

`dart test` is configured for Chrome because the package imports web-only
JavaScript interop APIs. The default suite exercises standalone Wasm at runtime;
the dart2wasm test command is currently limited to signature tests because the
test runner's generated suite can exceed Chromium's WasmGC subtype-depth limit.

## Engineering constraints

- Follow KISS and YAGNI; make the smallest coherent change supported by the code.
- Preserve the public API and behavior expected by `universal_ffi`.
- Keep pointers bound to the `Memory` instance belonging to their module; use a
  library's `allocator` for allocations associated with that library.
- `DynamicLibrary.open` currently rejects `wasm64` runtime loading. Do not
  describe wasm64 runtime support unless it is implemented and exercised.
- Exported function signatures are not checked against the Wasm signature at
  lookup time. Callers must provide matching native and Dart function types.
- Keep standalone and Emscripten behavior compatible when changing shared
  marshalling or JavaScript interop code.

## Context discipline

- Start with targeted search and this repository map.
- Read only files relevant to the task; follow links to focused documentation.
- Do not load `.dart_tool/`, build outputs, generated dependency code, or binary
  fixtures unless the task requires them.
- Preserve existing conventions and unrelated worktree changes.

## Documentation routing

- User setup, API differences, and examples: [`README.md`](README.md)
- Component boundaries and data flow: [`ARCHITECTURE.md`](ARCHITECTURE.md)
- Vanilla web example: [`example/README.md`](example/README.md)
- Flutter web example: [`example_flutter/README.md`](example_flutter/README.md)
- Release history: [`CHANGELOG.md`](CHANGELOG.md)

## Definition of done

- Relevant formatting, analysis, tests, and builds pass.
- New behavior has regression coverage when practical.
- Documentation claims match the current source, manifests, and CI.
- No unrelated files, dependencies, generated artifacts, or publishing behavior
  were changed.

## Documentation maintenance

- Update `AGENTS.md` when agent workflow, commands, navigation, or constraints change.
- Update `README.md` when user-facing setup, usage, capabilities, or limitations change.
- Update `ARCHITECTURE.md` when component boundaries or invariants change.
- Update example documentation only when the corresponding example changes.
- Update `CHANGELOG.md` only for user-visible release history under the existing policy.
