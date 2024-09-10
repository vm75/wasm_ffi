library wasm_ffi;

import 'ffi_bridge.dart';
import 'ffi_utils_bridge.dart';
import 'src/_wasm_ffi/helper.dart'
    if (dart.library.ffi) 'src/_dart_ffi/helper.dart';

export 'src/_wasm_ffi/helper.dart'
    if (dart.library.ffi) 'src/_dart_ffi/helper.dart';

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
