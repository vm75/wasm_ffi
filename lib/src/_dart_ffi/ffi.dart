import 'dart:ffi';
import 'package:ffi/ffi.dart';
export 'dart:ffi';

extension LibraryExtensions on DynamicLibrary {
  Allocator get memory => calloc;
}
