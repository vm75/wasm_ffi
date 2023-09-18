SHELL := /bin/sh

.PHONY: all clean run

# Set up directories and exported variables
ASSETS_DIR := ./assets
EXPORTED_RUNTIME_METHODS := '["ccall", "cwrap"]'
EXPORTED_FUNCTIONS := '["_malloc", "_free", "_hello", "_intSize", "_boolSize", "_pointerSize", "_freeMemory"]'

# Define source file and output paths
SRC_DIR := ./src
SRC_FILES := $(SRC_DIR)/native.c
STANDALONE_WASM := $(ASSETS_DIR)/standalone.wasm
EMSCRIPTEN_JS := $(ASSETS_DIR)/emscripten.js
WASM_JS_GLUE := lib/wasm_bindings.dart

EMCC_CHECK := $(shell command -v emcc 2> /dev/null)

ifeq ($(strip $(EMCC_CHECK)),)
$(error "emcc tool not found. Please install emscripten before running this Makefile.")
endif

all: $(STANDALONE_WASM) $(EMSCRIPTEN_JS) $(WASM_JS_GLUE)

$(STANDALONE_WASM): $(SRC_DIR)/native.c $(SRC_DIR)/native.h
	emcc $(SRC_FILES) -I $(SRC_DIR) -O3 "-Wl,--gc-sections,--no-entry" -s EXPORT_NAME=WasmFfi -s EXPORTED_FUNCTIONS=$(EXPORTED_FUNCTIONS) -s FILESYSTEM=0 -o $(STANDALONE_WASM)

$(EMSCRIPTEN_JS): $(SRC_DIR)/native.c $(SRC_DIR)/native.h
	emcc $(SRC_FILES) -I $(SRC_DIR) -O3 -s MAIN_MODULE=2 -s EXPORT_NAME=WasmFfi -s MODULARIZE=1  -s EXPORTED_FUNCTIONS=$(EXPORTED_FUNCTIONS) -s EXPORTED_RUNTIME_METHODS=$(EXPORTED_RUNTIME_METHODS) -o $(EMSCRIPTEN_JS)

$(WASM_JS_GLUE): $(SRC_DIR)/native.h
	dart run ffigen --config ffigen.yaml
	sed -e 's#dart:ffi#package:wasm_ffi/ffi_proxy.dart#' -i $(WASM_JS_GLUE)

clean:
	rm -rf $(ASSETS_DIR)/*

run:
	flutter run
