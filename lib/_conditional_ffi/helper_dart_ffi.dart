import 'dart:io' show Platform;
import 'package:path/path.dart' as path;

String getFilename(String modulePath) {
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

  return path.join(moduleDir, fileName);
}
