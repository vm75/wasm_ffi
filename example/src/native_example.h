#ifndef __NATIVE_H
#define __NATIVE_H

#if defined(__EMSCRIPTEN__)
// In the case of Emscripten, we need to use EMSCRIPTEN_KEEPALIVE
#include <emscripten.h>
#define EXPORT EMSCRIPTEN_KEEPALIVE
#elif defined(_MSC_VER)
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

#pragma pack(1)
struct TestStruct {
  short s;
  char a[5];
  int i;
};
#pragma pack()

union TestUnion {
  struct TestStruct s;
  char a[10];
};

/// library name
EXPORT const char* getLibraryName(void);

/// hello world
EXPORT char* hello(const char* text);

/// free up the memory allocated by the library
EXPORT void freeMemory(char* buffer);

/// size of an int
EXPORT int intSize(void);

/// size of a bool
EXPORT int boolSize(void);

/// size of a pointer
EXPORT int pointerSize(void);

EXPORT struct TestStruct updateStruct(struct TestStruct s);

EXPORT union TestUnion updateUnion(union TestUnion u);

#endif