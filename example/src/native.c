#include "native.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/// hello world
char* hello(const char* text)
{
    char* buffer = (char*)malloc(strlen(text) + 8);
    sprintf(buffer, "Hello %s!", text);
    return buffer;
}

/// freeMemory
void freeMemory(char* buffer)
{
    if (buffer) {
        free(buffer);
    }
}

/// size of an int
int intSize()
{
    return (int)sizeof(int);
}

/// size of a bool
int boolSize()
{
    return (int)sizeof(_Bool);
}

/// size of a pointer
int pointerSize()
{
    return (int)sizeof(void*);
}

/// callback
int foo(int bar, int (*callback)(void*, int))
{
    return callback(NULL, bar);
}