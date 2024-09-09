library wasm_ffi;

import '_wasm_ffi/helper.dart' if (dart.library.ffi) './_dart_ffi/helper.dart';
import 'ffi_bridge.dart';
import 'ffi_utils_bridge.dart';

export 'package:wasm_ffi/_wasm_ffi/helper.dart'
    if (dart.library.ffi) 'package:wasm_ffi/_dart_ffi/helper.dart';

class FfiWrapper {
  final DynamicLibrary _library;

  FfiWrapper._(this._library);

  DynamicLibrary get library => _library;

  static Future<FfiWrapper> load(String modulePath) async {
    return FfiWrapper._(await DynamicLibrary.open(getFilename(modulePath)));
  }

  R safeUsing<R>(R Function(Arena) computation, [Allocator? allocator]) {
    return using(computation, allocator ?? _library.memory);
  }
}
