## [2.1.0]
* Fixed support for wasm with emscripten js glue

## [2.0.7]
* Remove pubspec.lock

## [2.0.6]
* Pulling universal_ffi into a separate repo. Fixing License

## [2.0.5]
* Adding topics for pub.dev

## [2.0.4]
* Deprecating DynamicLibrary.memory in favour of DynamicLibrary.allocator

## [2.0.3]
* Fixing documentation issues

## [2.0.2]
* Updated readme

## [2.0.1]
* Fixed some urls

## [2.0.0]
* Removed ffi dependency into universal_ffi, making it pure wasm_ffi

## [1.1.0]
* Fixed standalone & emscripten wasm examples, flutter example.

## [1.0.2]
* Changed library names

## [1.0.1]
* Minor code reorganization

## [1.0.0]
* Added support for standalone wasm and added wrapper utility

## [0.9.5]
* Fixed compatibility with Emscripten 3.1.44
* Improved support for `Pointer<Utf8>`
* Added missing types `UintPtr`, `Bool`, `Int` and `UnsignedInt`
* Added `Arena` (added in Dart ffi 1.1.0)

## [0.9.4]
* Fixed analyzer warnings

## [0.9.3]
* Fixed github links

## [0.9.2]
* Fix plugin platform and example

## [0.9.1]
* Rebranded as wasm_ffi. Merged changes for Char & Utf8 support and fixed a memory bug.

## [0.7.4]
* UTF8 extension and `Char` type.

## [0.7.3]
* More lenient exports parsing. Latest Emscripten will output additional non function exports which need to be skipped.

## [0.7.2]
* Fixed errors related to unexpected `runtimeType` names due to minifying in release builds

## [0.7.1]
* Fixing dead links

## [0.7.0]
* Initial release
* No struct support yet
* No pointer array extension support yet