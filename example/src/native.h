#ifndef __NATIVE_H
#define __NATIVE_H

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#else
#define EMSCRIPTEN_KEEPALIVE
#endif

/* DLL defines
  Define UNDECO_DLL for un-decorated dll
  verify compiler option __cdecl for un-decorated and __stdcall for decorated */
/*#define UNDECO_DLL*/
#ifdef MAKE_DLL
#if defined(PASCAL) || defined(__stdcall)
#if defined UNDECO_DLL
#define CALL_CONV EMSCRIPTEN_KEEPALIVE __cdecl
#else
#define CALL_CONV EMSCRIPTEN_KEEPALIVE __stdcall
#endif
#else
#define CALL_CONV EMSCRIPTEN_KEEPALIVE
#endif
/* To export symbols in the new DLL model of Win32, Microsoft
   recommends the following approach */
#define EXP32 __declspec(dllexport)
#else
#define CALL_CONV EMSCRIPTEN_KEEPALIVE
#define EXP32
#endif

/* ext_def(x) evaluates to x on Unix */
#define ext_def(x) extern EXP32 x CALL_CONV

/// hello world
ext_def(char*) hello(const char* text);

/// free up the memory allocated by the library
ext_def(void) freeMemory(char* buffer);

#endif