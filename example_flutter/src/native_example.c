#include "native_example.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/// library name
EXPORT const char* getLibraryName(void)
{
  return "native_example";
}

/// hello world
EXPORT char* hello(const char* text)
{
  char* buffer = (char*)malloc(strlen(text) + 8);
  sprintf(buffer, "Hello %s!", text);
  return buffer;
}

/// freeMemory
EXPORT void freeMemory(char* buffer)
{
  if (buffer) {
    free(buffer);
  }
}

/// size of an int
EXPORT int intSize(void)
{
  return (int)sizeof(int);
}

/// size of a bool
EXPORT int boolSize(void)
{
  return (int)sizeof(_Bool);
}

/// size of a pointer
EXPORT int pointerSize(void)
{
  return (int)sizeof(void*);
}

/// sum four numbers
EXPORT int sum4(int a, int b, int c, int d)
{
  return a + b + c + d;
}
