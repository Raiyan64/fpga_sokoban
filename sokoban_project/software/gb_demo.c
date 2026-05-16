#include "gb_gpu.h"

static inline uint32_t hash32(uint32_t x) {
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    return x;
}

void generate_gb_tileset(void) {
    
    uint32_t frame = gpu_get_framecount();
    
    for (int t = 0; t < NUM_TILES; t++) {

        for (int y = 0; y < 8; y++) {

            uint8_t row[8];
            
            for (int x = 0; x < 8; x++) {
                
                uint32_t h = hash32(t * 31 + x * 17 + y * 13 + frame);

                uint8_t color;
                
                // Grass
                if (t < 64) {
                    color = (h & 7);
                    color = (color < 2) ? LIGHT : (color < 5) ? DARK : DARKEST;
                }
                
                // Water
                else if (t < 128) {
                    uint32_t v = (h ^ frame) & 7;
                    color = (v < 2) ? LIGHT : (v < 4) ? DARK : DARKEST;
                }
                
                // Brick
                else if (t < 192) {
                    int bx = x + (t & 1);
                    int by = y + ((t >> 1) & 1);
                    
                    int mortar = (bx % 4 == 0 || by % 4 == 0);
                    
                    color = mortar ? LIGHTEST : ((bx+by)&1) ? DARK : DARKEST;
                }
                
                // CLOUD
                else {
                    uint32_t n = (h >> 2) & 15;
                    
                    color = (n < 6) ? LIGHTEST : (n < 10) ? LIGHT : (n < 13) ? DARK : DARKEST;
                }
                row[x] = color & 0x3;    
            }
            
            gpu_set_tilerow(t, y, row);
        }
    }
}

static void update_tilemap(void) {
    uint32_t frame = gpu_get_framecount();

    for (uint32_t y = 0; y < TILEMAP_H; y++) {
        for (uint32_t x = 0; x < TILEMAP_W; x++) {
            uint8_t tile = ((x ^ y ^ frame) & 0xFF);
            gpu_set_tile(x, y, tile);
        }
    }
}

void gb_demo(void) {

    gpu_set_palette(pack_color(LIGHTEST, LIGHT, DARK, DARKEST));
	
	// clear screen for solid background
	gpu_fill_tilemap(0);
    gpu_clear_tiles(LIGHTEST);

    uint8_t last = gpu_get_framecount();
	
	while (1) {
        uint8_t now = gpu_get_framecount();
        if ((uint8_t)(now-last) >= 10) {
        	last = now;
        	generate_gb_tileset();
        	update_tilemap();
        }
        gpu_wait_frame();
   }
}