import 'dart:typed_data';
import 'package:js/js_util.dart';
import 'package:wasm_interop/wasm_interop.dart' as interop;
import '../../../wasm_ffi_meta.dart';
import '../module.dart';

@extra
class StandaloneWasmModule extends Module {
  final interop.Instance _instance;
  final List<WasmSymbol> _exports = [];

  @override
  List<WasmSymbol> get exports => _exports;

  /// map of instances by their name
  static final Map<String, StandaloneWasmModule> _instances = {};

  static Future<StandaloneWasmModule> compile(
      Uint8List wasmBinary, String moduleName) async {
    if (_instances.containsKey(moduleName)) {
      return _instances[moduleName]!;
    }
    final wasmInstance = await interop.Instance.fromBytesAsync(wasmBinary);
    _instances[moduleName] = StandaloneWasmModule._(wasmInstance);
    return _instances[moduleName]!;
  }

  FunctionDescription _fromWasmFunction(String name, Function func, int index) {
    String? s = getProperty(func, 'name');
    if (s != null) {
      int? length = getProperty(func, 'length');
      if (length != null) {
        return FunctionDescription(
            tableIndex: index,
            name: name,
            function: func,
            argumentCount: length);
      }
    }
    throw ArgumentError('$name does not seem to be a function symbol!');
  }

  StandaloneWasmModule._(this._instance) {
    int index = 0;
    for (final e in _instance.functions.entries) {
      _exports.add(_fromWasmFunction(e.key, e.value, index++));
    }
  }

  @override
  void free(int pointer) {
    final func = _instance.functions['free'];
    func?.call(pointer);
  }

  @override
  ByteBuffer get heap => _instance.memories['memory']!.buffer;

  @override
  int malloc(int size) {
    final func = _instance.functions['malloc'];
    final resp = func?.call(size) as int;
    return resp;
  }

  Function? getMethod(String methodName) {
    return _instance.functions[methodName];
  }
}
