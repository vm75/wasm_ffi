#ifndef __NATIVE_H
#define __NATIVE_H

#ifdef _WIN32
#ifdef NATIVE_EXPORTS
#define NATIVE_API __declspec(dllexport)
#else
#define NATIVE_API __declspec(dllimport)
#endif
#else
#define NATIVE_API
#endif

/// hello world
NATIVE_API char* hello(const char* text);

/// free up the memory allocated by the library
NATIVE_API void freeMemory(char* buffer);

/// size of an int
NATIVE_API int intSize();

/// size of a bool
NATIVE_API int boolSize();

/// size of a pointer
NATIVE_API int pointerSize();

#endif