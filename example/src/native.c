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
