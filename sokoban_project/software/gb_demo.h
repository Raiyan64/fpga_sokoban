#ifndef GB_DEMO_H
#define GB_DEMO_H

#include "gb_gpu.h"

static inline uint32_t hash32(uint32_t x) {
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    return x;
}

void generate_gb_tileset(void);
void gb_demo(void);

#endif