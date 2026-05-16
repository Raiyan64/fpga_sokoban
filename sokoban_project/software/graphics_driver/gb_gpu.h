#ifndef GB_GPU_H
#define GB_GPU_H

#include <assert.h>
#include "xil_types.h"
#include "xparameters.h"

#define GPU_BASE              XPAR_GB_GPU_0_AXI_BASEADDR

// Tilemap: 0x0000 - 0x01FF (512 bytes, we use 360)
#define REG_TILEMAP_BASE      0x0000u
#define TILEMAP_W             20u
#define TILEMAP_H             18u
#define TILEMAP_SIZE          (TILEMAP_W * TILEMAP_H)

// Tile data: 0x2000 - 0x2FFF
#define REG_TILEDATA_BASE     0x2000u

#define NUM_TILES             256u
#define TILE_W                8u
#define TILE_H		          8u
#define TILE_SIZE             16u
#define TILE_BYTES            (NUM_TILES * TILE_SIZE)

// Palette register
#define REG_PALETTE           0x3000u

// Frame counter register
#define REG_FRAME_COUNT       0x3004u

#define GPU_FRAME_TIMEOUT     10000000u


////////////////////////////////////////////////////////////////////////////////
// Coloring struct

typedef enum {
    LIGHTEST = 0x0,
    LIGHT    = 0x1,
    DARK     = 0x2,
    DARKEST  = 0x3
} COLOR;


////////////////////////////////////////////////////////////////////////////////
// Memory mapped I/O operations

static inline void gpu_write8(uint32_t addr, uint8_t val) {
    *(volatile uint8_t *)(GPU_BASE + addr) = val;
}

static inline uint8_t gpu_read8(uint32_t addr) {
    return *(volatile uint8_t *)(GPU_BASE + addr);
}

////////////////////////////////////////////////////////////////////////////////
// Tile map API

void gpu_set_tile(uint32_t x, uint32_t y, uint8_t tile_id);
uint8_t gpu_get_tile(uint32_t x, uint32_t y);
void gpu_fill_tilemap(uint8_t tile_id);

////////////////////////////////////////////////////////////////////////////////
// Tile data API

void gpu_set_pixel(uint8_t tile, uint8_t row, uint8_t col, COLOR c);
COLOR gpu_get_pixel(uint8_t tile, uint8_t row, uint8_t col);
void gpu_set_tilerow(uint8_t tile, uint8_t row, const COLOR* data_8);
void gpu_get_tilerow(uint8_t tile, uint8_t row, COLOR* out_8);
void gpu_set_tiledata(uint8_t tile, const uint8_t* data_16);
void gpu_get_tiledata(uint8_t tile, uint8_t* out_16);
void gpu_clear_tiles(COLOR c);

////////////////////////////////////////////////////////////////////////////////
// palette register

void gpu_set_palette(uint8_t value);
uint8_t gpu_get_palette(void);

static inline uint8_t pack_color(COLOR c0, COLOR c1, COLOR c2, COLOR c3) {
	return ((c3 & 0x3) << 6) | ((c2 & 0x3) << 4) | ((c1 & 0x3) << 2) | (c0 & 0x3);
}

////////////////////////////////////////////////////////////////////////////////
// frame counter

uint8_t gpu_get_framecount(void);
int gpu_wait_frame(void);

////////////////////////////////////////////////////////////////////////////////
// potential sprite manipulation

typedef struct {
    uint8_t x;
    uint8_t y;
    uint8_t tile;
} Sprite;

void sprite_set(Sprite *s, uint8_t x, uint8_t y, uint8_t tile);
void sprite_draw(const Sprite *s);

#endif // GB_GPU_H