class Extra {
  const Extra();
}

/// A class, field or method annotated with extra is present in `wasm_ffi`,
/// but not in `dart:ffi`.
const Extra extra = Extra();

class NoGeneric {
  const NoGeneric();
}

/// If a class which is annotead with [noGeneric] is extended or implemented,
/// the derived class MUST NOT impose a type argument!
const NoGeneric noGeneric = NoGeneric();

class NotConstructible {
  const NotConstructible();
}

/// A [NativeType] annotated with unsized should not be instantiated.
///
/// However, they are not marked as `abstract` to meet the dart:ffi API.
const NotConstructible notConstructible = NotConstructible();

class Unsized {
  const Unsized();
}

/// A [NativeType] annotated with unsized does not have a predefined size.
///
/// Unsized [NativeType]s do not support [sizeOf] because their size is unknown,
/// so calling [sizeOf] with an @[unsized] [NativeType] will throw an exception.
/// Consequently, [Pointer.elementAt] is not available and will also throw an exception.
const Unsized unsized = Unsized();
