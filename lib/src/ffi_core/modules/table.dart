import 'package:js/js.dart';

@JS('WebAssembly.Table')
class Table {
  /// The default [Memory] object to use.
  ///
  /// This field is null until it is either manually set to a [Memory] object,
  /// or automatically set by [DynamicLibrary.fromModule].
  ///
  /// This is most notably used when creating a pointer using [Pointer.fromAddress]
  /// with no explicite memory to bind to given.
  static Table? global;

  external int grow(int delta);
  external Object? get(int index);
  external void set(int index, Object? value);
  external int get length;
}
