.PHONY: clean

default: build

build: assets/standalone/native_example.wasm assets/emscripten/native_example.js

SRC=src/native_example.c src/native_example_cpp.cpp
DEPS=$(SRC) $(SRC:.c=.h)
EMCC ?= emcc

# Wasm options
ifdef  DEBUG
	COMPILER_OPTIONS=-g3 --profiling-funcs -s ASSERTIONS=1 -fsanitize=address
	LINKER_OPTIONS=-Wl,--no-entry,--export=__wasm_call_ctors
else
	COMPILER_OPTIONS=-fPIC -Oz -fno-exceptions -fno-rtti -fno-stack-protector -ffunction-sections -fdata-sections -fno-math-errno -DNDEBUG
	LINKER_OPTIONS=-Wl,--gc-sections,--no-entry,--export=__wasm_call_ctors
endif
COMPILED_EXPORTS="EXPORTED_FUNCTIONS=[\"_malloc\", \"_free\"]"

clean:
	rm -rf assets/standalone/*
	rm -rf assets/emscripten/*

lib/native_example_bindings.dart: $(DEPS)
	dart run ffigen --config ffigen.yaml && perl -pi -e "s#(['\"])dart:ffi\\1#'package:wasm_ffi/ffi.dart'#g" $@

assets/standalone/native_example.wasm: $(DEPS) lib/native_example_bindings.dart
	$(EMCC) -o assets/standalone/native_example.wasm $(COMPILER_OPTIONS) $(LINKER_OPTIONS) \
		$(SRC) \
		-s STANDALONE_WASM=1 \
		-s $(COMPILED_EXPORTS)

assets/emscripten/native_example.js: $(DEPS) lib/native_example_bindings.dart
	$(EMCC) -o assets/emscripten/native_example.js $(COMPILER_OPTIONS) $(LINKER_OPTIONS) \
		$(SRC) \
		-s MODULARIZE=1 -s 'EXPORT_NAME="native_example"' -s ALLOW_MEMORY_GROWTH=1 \
		-s EXPORTED_RUNTIME_METHODS=HEAPU8 \
		-s $(COMPILED_EXPORTS)

run:
	flutter run -d chrome
