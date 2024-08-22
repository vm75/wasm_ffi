#ifndef __NATIVE_H
#define __NATIVE_H

/// hello world
char* hello(const char* text);

/// free up the memory allocated by the library
void freeMemory(char* buffer);

/// size of an int
int intSize();

/// size of a bool
int boolSize();

/// size of a pointer
int pointerSize();

/// callback
int foo(int bar, int (*callback)(void*, int));

#endif