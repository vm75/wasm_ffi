import 'package:wasm_ffi_example_no_flutter/example_no_flutter.dart';

Future<void> main() async {
  await initFfi();
  DynamicLibrary opus = openOpus();
  FunctionsAndGlobals opusLibinfo = FunctionsAndGlobals(opus);
  Pointer<Uint8> cString = opusLibinfo.opus_get_version_string();
  // ignore: avoid_print
  print(cString.cast<Utf8>().toDartString());
}
