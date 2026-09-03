#include <stdint.h>

// A global to ensure memory is generated
uint8_t dummy[1024];

uint32_t add32(uint32_t a, uint32_t b) { return a + b; }
uint64_t add64(uint64_t a, uint64_t b) { return a + b; }
uint8_t deref_u8(uint8_t* ptr) { return *ptr; }
void write_u8(uint8_t* ptr, uint8_t val) { *ptr = val; }

// Dummy malloc to avoid out of bounds
static uint32_t heap_ptr = 16;
void* malloc(uint32_t size) {
    uint32_t ptr = heap_ptr;
    heap_ptr += size;
    return (void*)ptr;
}
void free(void* ptr) {}
