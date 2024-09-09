library wasm_ffi;

import '../wasm_ffi.dart';
import '../wasm_ffi_utils.dart';
import './_export_ffi/helper_wasm_ffi.dart'
    if (dart.library.ffi) './_export_ffi/helper_dart_ffi.dart';

export 'package:wasm_ffi/_export_ffi/helper_wasm_ffi.dart'
    if (dart.library.ffi) 'package:wasm_ffi/_export_ffi/helper_dart_ffi.dart';

class FfiHelper {
  final DynamicLibrary _library;

  FfiHelper._(this._library);

  DynamicLibrary get library => _library;

  static Future<FfiHelper> load(String modulePath) async {
    return FfiHelper._(await DynamicLibrary.open(getFilename(modulePath)));
  }

  R safeUsing<R>(R Function(Arena) computation, [Allocator? allocator]) {
    return using(computation, allocator ?? _library.memory);
  }
}
