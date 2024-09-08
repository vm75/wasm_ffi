import '../src/ffi/memory.dart';
import '../wasm_ffi.dart';
import '../wasm_ffi_utils.dart';

class FfiHelper {
  final DynamicLibrary _library;

  FfiHelper._(this._library);

  DynamicLibrary get library => _library;

  static Future<FfiHelper> load(String modulePath) async {
    return FfiHelper._(await DynamicLibrary.open(modulePath));
  }

  R usingLibrary<R>(R Function(Arena) computation) {
    final orginalMemory = Memory.global;
    Memory.global = _library.memory;
    final result = using(computation, _library.memory);
    Memory.global = orginalMemory;
    return result;
  }
}
