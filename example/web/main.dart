import 'package:example/example.dart';
import 'package:example/native_example_bindings.dart';
import 'package:wasm_ffi/src/ffi/types.dart';
import 'package:web/web.dart';

Element createKeyVal(String key, String value) {
  final div = document.createElement('p');
  final label = document.createElement('strong');
  label.text = '$key: ';
  div.append(label);
  final span = document.createElement('span');
  span.text = value;
  div.append(span);
  return div;
}

Future<Element> runTests(String source, String name) async {
  final container = document.createElement('div');
  final header = document.createElement('h2');
  header.text = 'Test WasmFfi ($name)';
  container.append(header);
  final runner = await Example.create('assets/$source');
  container.append(createKeyVal('Library Name', runner.getLibraryName()));
  container.append(createKeyVal('Hello String', runner.hello(name)));
  container.append(createKeyVal('Size of Int', runner.intSize().toString()));
  container.append(createKeyVal('Size of Bool', runner.boolSize().toString()));
  container
      .append(createKeyVal('Size of Pointer', runner.pointerSize().toString()));
  TestStruct s = TestStruct();
  s.s = 1;
  s.a[0] = 2 as Char;
  s.a[1] = 3 as Char;
  s.a[2] = 4 as Char;
  s.a[3] = 5 as Char;
  s.a[4] = 6 as Char;
  s.i = 7;

  container
      .append(createKeyVal('TestStruct', runner.updateStruct(s).toString()));
  return container;
}

void main() {
  final app = (document.querySelector('body')! as HTMLElement);

  final container = document.createElement('div');
  final header = document.createElement('h2');
  header.text = 'wasm-ffi tests';
  container.append(header);

  app.append(container);

  runTests('standalone/native_example.wasm', 'Standalone').then((result) {
    container.append(result);
  });

  runTests('emscripten/native_example.js', 'Emscripten').then((result) {
    container.append(result);
  });
}
