#include "native_example.h"

// Use a volatile variable to prevent compiler optimization.
// Initialize to 0. The constructor should set it to 1.
static volatile int initialization_state = 0;

struct Initializer {
  Initializer()
  {
    initialization_state = 1;
  }
};

static Initializer global_initializer;

extern "C" {

EXPORT int static_init_check(void)
{
  // If the constructor ran, initialization_state will be 1.
  // Otherwise, it will be 0.
  return initialization_state;
}
}
