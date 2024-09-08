import 'dart:io' show Platform;
import 'package:path/path.dart' as path;
import '../wasm_ffi.dart';
import '../wasm_ffi_utils.dart';

class FfiHelper {
  final DynamicLibrary _library;

  FfiHelper._(this._library);

  DynamicLibrary get library => _library;

  static Future<FfiHelper> load(String modulePath) async {
    final moduleName = path.basenameWithoutExtension(modulePath);
    final moduleDir = path.dirname(modulePath);

    late String fileName;
    if (Platform.isWindows) {
      fileName = '$moduleName.dll';
    } else if (Platform.isLinux || Platform.isAndroid) {
      fileName = 'lib$moduleName.so';
    } else if (Platform.isMacOS || Platform.isIOS) {
      fileName = '$moduleName.framework/$moduleName';
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    fileName = path.join(moduleDir, fileName);

    return FfiHelper._(await DynamicLibrary.open(fileName));
  }

  R usingLibrary<R>(R Function(Arena) computation) {
    return using(computation);
  }
}
