library;

import 'package:wasm_ffi/ffi.dart';
import 'package:wasm_ffi/ffi_utils.dart';
import 'native_example_bindings.dart';

class Example {
  final DynamicLibrary library;
  final NativeExampleBindings bindings;

  Example._(this.library) : bindings = NativeExampleBindings(library);

  static Future<Example> create(String libPath) async {
    final library = await DynamicLibrary.open(libPath);
    return Example._(library);
  }

  String getLibraryName() =>
      bindings.getLibraryName().cast<Utf8>().toDartString();

  String hello(String name) {
    return using((Arena arena) {
      final cString = name.toNativeUtf8(allocator: arena).cast<Char>();
      return bindings.hello(cString).cast<Utf8>().toDartString();
    }, library.allocator);
  }

  int intSize() => bindings.intSize();

  int boolSize() => bindings.boolSize();

  int pointerSize() => bindings.pointerSize();

  bool staticInitCheck() => bindings.static_init_check() != 0;
}
