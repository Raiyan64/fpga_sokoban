#include "gb_gpu.h"

////////////////////////////////////////////////////////////////////////////////
// Tile map API

void gpu_set_tile(uint32_t x, uint32_t y, uint8_t tile_id) {
    assert(x < TILEMAP_W && y < TILEMAP_H);

    uint32_t index = y * TILEMAP_W + x;

    gpu_write8(REG_TILEMAP_BASE + index, tile_id);
}

uint8_t gpu_get_tile(uint32_t x, uint32_t y) {
    assert(x < TILEMAP_W && y < TILEMAP_H);

    uint32_t index = y * TILEMAP_W + x;

    return gpu_read8(REG_TILEMAP_BASE + index);
}

void gpu_fill_tilemap(uint8_t tile_id) {
    for (uint32_t i = 0; i < TILEMAP_SIZE; i++) {
        gpu_write8(REG_TILEMAP_BASE + i, tile_id);
    }
}

////////////////////////////////////////////////////////////////////////////////
// Tile data API

void gpu_set_pixel(uint8_t tile, uint8_t row, uint8_t col, COLOR c) {
    assert(tile < NUM_TILES && row < TILE_H && col < TILE_W);

    uint32_t addr = REG_TILEDATA_BASE + tile * TILE_SIZE + (row << 1) + (col >> 2);

    uint8_t byte = gpu_read8(addr);

    uint8_t shift = (col & 0x3) << 1;
    byte &= ~(0x3 << shift);
    byte |= (c & 0x3) << shift;

    gpu_write8(addr, byte);
}

COLOR gpu_get_pixel(uint8_t tile, uint8_t row, uint8_t col) {
    assert(tile < NUM_TILES && row < TILE_H && col < TILE_W);

    uint32_t addr = REG_TILEDATA_BASE + tile * TILE_SIZE + (row << 1) + (col >> 2);

    uint8_t byte = gpu_read8(addr);
    uint8_t shift = (col & 0x3) << 1;

    return (COLOR)((byte >> shift) & 0x3);
}

void gpu_set_tilerow(uint8_t tile, uint8_t row, const COLOR* data_8) {
    assert(tile < NUM_TILES && row < TILE_H);

	uint32_t addr = REG_TILEDATA_BASE + tile * TILE_SIZE + (row << 1);

	uint8_t packed0 = ((data_8[3] & 0x3) << 6) | ((data_8[2] & 0x3) << 4) |
		              ((data_8[1] & 0x3) << 2) | (data_8[0] & 0x3);
	uint8_t packed1 = ((data_8[7] & 0x3) << 6) | ((data_8[6] & 0x3) << 4) |
		              ((data_8[5] & 0x3) << 2) | (data_8[4] & 0x3);

	gpu_write8(addr, packed0);
	gpu_write8(addr + 1, packed1);
}

void gpu_get_tilerow(uint8_t tile, uint8_t row, COLOR* out_8) {
    assert(tile < NUM_TILES && row < TILE_H);

	uint32_t addr = REG_TILEDATA_BASE + tile * TILE_SIZE + (row << 1);

	uint8_t byte0 = gpu_read8(addr);
	uint8_t byte1 = gpu_read8(addr + 1);

	out_8[0] = (COLOR)(byte0 & 0x3);
	out_8[1] = (COLOR)((byte0 >> 2) & 0x3);
	out_8[2] = (COLOR)((byte0 >> 4) & 0x3);
	out_8[3] = (COLOR)((byte0 >> 6) & 0x3);
	out_8[4] = (COLOR)(byte1 & 0x3);
	out_8[5] = (COLOR)((byte1 >> 2) & 0x3);
	out_8[6] = (COLOR)((byte1 >> 4) & 0x3);
	out_8[7] = (COLOR)((byte1 >> 6) & 0x3);
}

void gpu_set_tiledata(uint8_t tile, const uint8_t* data_16) {
    assert(tile < NUM_TILES);

	uint32_t base = REG_TILEDATA_BASE + tile * TILE_SIZE;
	
	for (uint32_t i = 0; i < TILE_SIZE; i++) {
		gpu_write8(base + i, data_16[i]);
	}
}

void gpu_get_tiledata(uint8_t tile, uint8_t* out_16) {
    assert(tile < NUM_TILES);

	uint32_t base = REG_TILEDATA_BASE + tile * TILE_SIZE;
	
	for (uint32_t i = 0; i < TILE_SIZE; i++) {
		out_16[i] = gpu_read8(base + i);
	}
}

void gpu_clear_tiles(COLOR c) {
    uint8_t fill = ((c & 0x3) << 6) | ((c & 0x3) << 4) | ((c & 0x3) << 2) | (c & 0x3);

    for (uint32_t i = 0; i < TILE_BYTES; i++) {
        gpu_write8(REG_TILEDATA_BASE + i, fill);
    }
}

////////////////////////////////////////////////////////////////////////////////
// palette register

void gpu_set_palette(uint8_t value) {
    gpu_write8(REG_PALETTE, value);
}

uint8_t gpu_get_palette(void) {
    return gpu_read8(REG_PALETTE);
}

////////////////////////////////////////////////////////////////////////////////
// frame counter

uint8_t gpu_get_framecount(void) {
    return gpu_read8(REG_FRAME_COUNT);
}

int gpu_wait_frame(void) {
    uint8_t f = gpu_get_framecount();
    uint32_t timeout = GPU_FRAME_TIMEOUT;
    while (gpu_get_framecount() == f) {
        if (--timeout == 0) return 1; // stall protection
    }
    return 0;
}

////////////////////////////////////////////////////////////////////////////////
// potential sprite manipulation

void sprite_set(Sprite *s, uint8_t x, uint8_t y, uint8_t tile) {
    s->x = x;
    s->y = y;
    s->tile = tile;
}

void sprite_draw(const Sprite *s) {
    gpu_set_tile(s->x, s->y, s->tile);
}