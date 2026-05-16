#include "platform.h"
#include "lw_usb/GenericMacros.h"
#include "lw_usb/GenericTypeDefs.h"
#include "lw_usb/MAX3421E.h"
#include "lw_usb/USB.h"
#include "lw_usb/usb_ch9.h"
#include "lw_usb/transfer.h"
#include "lw_usb/HID.h"
#include <stdio.h>
#include <xgpio.h>
#include "sleep.h"
#include "gb_gpu.h"
#include "tileData.h"

// Define Tile IDs
#define TILE_FLOOR         0
#define TILE_WALL          1
#define TILE_BOX           2
#define TILE_GOAL          3
#define TILE_PLAYER        4
#define TILE_BOX_GOAL      5
#define TILE_PLAYER_GOAL   6

//"You Win" screen
#define TILE_Y             7
#define TILE_O             8
#define TILE_U             9
#define TILE_W             10
#define TILE_I             11
#define TILE_N             12
#define TILE_EXCLAIM       13

//Start screen
#define TILE_S0            14
#define TILE_S1            15
#define TILE_S2            16
#define TILE_S3            17

#define TILE_O0            18
#define TILE_O1            19
#define TILE_O2            20
#define TILE_O3            21

#define TILE_K0            22
#define TILE_K1            23
#define TILE_K2            24
#define TILE_K3            25

#define TILE_B0            26
#define TILE_B1            27
#define TILE_B2            28
#define TILE_B3            29

#define TILE_A0            30
#define TILE_A1            31
#define TILE_A2            32
#define TILE_A3            33

#define TILE_N0            34
#define TILE_N1            35
#define TILE_N2            36
#define TILE_N3            37

#define TILE_P             38
#define TILE_R             39
#define TILE_S             40
#define TILE_E             41
#define TILE_A             42
#define TILE_C             43
#define TILE_D             44
#define TILE_H             45
#define TILE_AMP           46
#define TILE_DSMALL        47

#define TILE_BBOX0          48
#define TILE_BBOX1          49
#define TILE_BBOX2          50
#define TILE_BBOX3          51
#define TILE_BBOX4          52
#define TILE_BBOX5          53
#define TILE_BBOX6          54
#define TILE_BBOX7          55
#define TILE_BBOX8          56
#define TILE_BBOX9          57
#define TILE_BBOX10         58
#define TILE_BBOX11         59
#define TILE_BBOX12         60
#define TILE_BBOX13         61
#define TILE_BBOX14         62
#define TILE_BBOX15         63
#define TILE_BBOX16         64
#define TILE_BBOX17         65
#define TILE_BBOX18         66
#define TILE_BBOX19         67
#define TILE_BBOX20         68
#define TILE_BBOX21         69
#define TILE_BBOX22         70
#define TILE_BBOX23         71
#define TILE_BBOX24         72

#define NUM_LEVELS 3

static XGpio Gpio_hex;

// Game State
uint8_t player_x;
uint8_t player_y;
uint8_t current_level = 0;
uint8_t game_finished = 0; // Flag for when all levels are beaten

// Master Templates for 3 Levels
const uint8_t levels[NUM_LEVELS][TILEMAP_H][TILEMAP_W] = {
    // Level 0 (Your original map)
    {
		{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
		{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
		{1,0,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1,0,1},
		{1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1},
		{1,0,1,0,4,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1},
		{1,0,1,0,0,1,1,1,1,0,0,1,1,1,1,0,0,1,0,1},
		{1,0,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,1},
		{1,0,0,0,0,1,0,2,0,0,0,0,2,0,1,0,0,0,0,1},
		{1,0,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,1},
		{1,0,1,0,0,1,1,1,0,0,0,0,1,1,1,0,0,1,0,1},
		{1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1},
		{1,0,1,0,0,0,0,0,0,3,3,0,0,0,0,0,0,1,0,1},
		{1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1},
		{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
		{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
		{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
		{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
		{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
    },
    // Level 1 (A new simple challenge)
    {

		{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
		{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
		{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
		{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
		{1,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,1},
		{1,0,0,0,0,1,1,1,0,0,0,1,0,0,0,0,0,0,0,1},
		{1,0,0,0,0,1,3,4,2,0,0,1,0,0,0,0,0,0,0,1},
		{1,0,0,0,0,1,1,1,0,2,3,1,0,0,0,0,0,0,0,1},
		{1,0,0,0,0,1,3,1,1,2,0,1,0,0,0,0,0,0,0,1},
		{1,0,0,0,0,1,0,1,0,3,0,1,1,0,0,0,0,0,0,1},
		{1,0,0,0,0,1,2,0,5,2,2,3,1,0,0,0,0,0,0,1},
		{1,0,0,0,0,1,0,0,0,3,0,0,1,0,0,0,0,0,0,1},
		{1,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1},
		{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
		{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
		{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
		{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
		{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}

    },
    // Level 2 (A tighter squeeze)
    {

    		{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
			{1,3,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,3,1},
			{1,0,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1,1,0,1},
			{1,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,1},
			{1,0,0,0,0,0,0,1,1,1,0,1,1,0,0,0,0,1,0,1},
			{1,0,1,0,2,0,0,0,0,0,0,0,0,0,0,2,0,1,0,1},
			{1,0,1,1,0,1,1,1,1,1,1,1,1,1,1,0,1,1,0,1},
			{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
			{1,1,1,1,0,0,0,1,1,4,0,1,1,0,0,0,0,1,1,1},
			{1,0,0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,1,1,1},
			{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
			{1,0,1,1,0,1,1,1,0,0,0,1,1,1,1,0,1,1,0,1},
			{1,0,1,0,2,0,0,1,1,0,0,0,1,0,0,2,0,1,0,1},
			{1,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,1},
			{1,0,1,0,0,0,0,1,0,1,0,0,1,0,0,0,0,1,0,1},
			{1,0,1,1,1,1,1,1,0,1,0,0,1,1,1,1,1,1,0,1},
			{1,3,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,3,1},
			{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}

    }
};

// Active game map (Mutable)
uint8_t game_map[TILEMAP_H][TILEMAP_W];

//I/O signals
extern HID_DEVICE hid_device;
static BYTE addr = 1;
const char* const devclasses[] = { " Uninitialized", " HID Keyboard", " HID Mouse", " Mass storage" };
BYTE rcode;
BOOT_KBD_REPORT kbdbuf;
BYTE runningdebugflag = 0;
BYTE errorflag = 0;

// --- New Win Detection ---
int check_win() {
    for (int y = 0; y < TILEMAP_H; y++) {
        for (int x = 0; x < TILEMAP_W; x++) {
            if (game_map[y][x] == TILE_GOAL || game_map[y][x] == TILE_PLAYER_GOAL) {
                return 0; // Found an unfilled goal
            }
        }
    }
    return 1; // All goals are filled!
}

// Loads a specific level index
void load_level(uint8_t level_idx) {
    for (int y = 0; y < TILEMAP_H; y++) {
        for (int x = 0; x < TILEMAP_W; x++) {
            game_map[y][x] = levels[level_idx][y][x];
            if (game_map[y][x] == TILE_PLAYER || game_map[y][x] == TILE_PLAYER_GOAL) {
                player_x = x;
                player_y = y;
            }
        }
    }
}

// Blanks out the map for the "You Win" screen
// Displays the "YOU WIN!" screen
void load_win_screen() {
    // 1. First, clear the entire board to floor tiles
    for (int y = 0; y < TILEMAP_H; y++) {
        for (int x = 0; x < TILEMAP_W; x++) {
            game_map[y][x] = TILE_FLOOR;
        }
    }

    // 2. Place the text centered horizontally (starting at x=6) and vertically (y=8)
    int center_y = 8;

    // "YOU"
    game_map[center_y][6] = TILE_Y;
    game_map[center_y][7] = TILE_O;
    game_map[center_y][8] = TILE_U;

    // Space at x=9 is naturally left as TILE_FLOOR

    // "WIN!"
    game_map[center_y][10] = TILE_W;
    game_map[center_y][11] = TILE_I;
    game_map[center_y][12] = TILE_N;
    game_map[center_y][13] = TILE_EXCLAIM;
}


void init_graphics() {
    xil_printf("generating graphics\n");

    gpu_set_palette(pack_color(LIGHTEST, LIGHT, DARK, DARKEST));
    gpu_clear_tiles(LIGHT);
    gpu_fill_tilemap(0);

    gpu_set_tiledata(TILE_FLOOR, data_floor);

    gpu_set_tiledata(TILE_WALL, data_wall);


    gpu_set_tiledata(TILE_BOX, data_box);

    gpu_set_tiledata(TILE_BOX_GOAL, data_box_goal);


    gpu_set_tiledata(TILE_GOAL, data_goal);

    gpu_set_tiledata(TILE_PLAYER, data_player);

    gpu_set_tiledata(TILE_PLAYER_GOAL, data_player_goal);


    gpu_set_tiledata(TILE_Y, data_y);

    gpu_set_tiledata(TILE_O, data_o);

    gpu_set_tiledata(TILE_U, data_u);


    gpu_set_tiledata(TILE_W, data_w);


    gpu_set_tiledata(TILE_I, data_i);


    gpu_set_tiledata(TILE_N, data_n);

	gpu_set_tiledata(TILE_EXCLAIM, data_exclaim);


	gpu_set_tiledata(TILE_S0, tile_s0);


	gpu_set_tiledata(TILE_S1, tile_s1);

	gpu_set_tiledata(TILE_S2, tile_s2);

	gpu_set_tiledata(TILE_S3, tile_s3);

	gpu_set_tiledata(TILE_O0, tile_o0);
	gpu_set_tiledata(TILE_O1, tile_o1);

	gpu_set_tiledata(TILE_O2, tile_o2);
	gpu_set_tiledata(TILE_O3, tile_o3);
	gpu_set_tiledata(TILE_K0, tile_k0);
	gpu_set_tiledata(TILE_K1, tile_k1);
	gpu_set_tiledata(TILE_K2, tile_k2);
	gpu_set_tiledata(TILE_K3, tile_k3);
	gpu_set_tiledata(TILE_B0, tile_b0);
	gpu_set_tiledata(TILE_B1, tile_b1);
	gpu_set_tiledata(TILE_B2, tile_b2);
	gpu_set_tiledata(TILE_B3, tile_b3);
	gpu_set_tiledata(TILE_N0, tile_n0);

	gpu_set_tiledata(TILE_N1, tile_n1);
	gpu_set_tiledata(TILE_N2, tile_n2);
	gpu_set_tiledata(TILE_N3, tile_n3);

	gpu_set_tiledata(TILE_A0, tile_a0);

	gpu_set_tiledata(TILE_A1, tile_a1);

	gpu_set_tiledata(TILE_A2, tile_a2);

	gpu_set_tiledata(TILE_A3, tile_a3);

	gpu_set_tiledata(TILE_P, tile_p);

	gpu_set_tiledata(TILE_R, tile_r);
	gpu_set_tiledata(TILE_S, tile_s);

	gpu_set_tiledata(TILE_E, tile_e);

	gpu_set_tiledata(TILE_A, tile_a);

	gpu_set_tiledata(TILE_C, tile_c);

	gpu_set_tiledata(TILE_D, tile_d);
	gpu_set_tiledata(TILE_H, tile_h);

	gpu_set_tiledata(TILE_AMP, tile_ampersand);

	gpu_set_tiledata(TILE_DSMALL, tile_d_skinny);

	gpu_set_tiledata(TILE_BBOX0, tile_box0);
	gpu_set_tiledata(TILE_BBOX1, tile_box1);
	gpu_set_tiledata(TILE_BBOX2, tile_box2);
	gpu_set_tiledata(TILE_BBOX3, tile_box3);
	gpu_set_tiledata(TILE_BBOX4, tile_box4);
	gpu_set_tiledata(TILE_BBOX5, tile_box5);
	gpu_set_tiledata(TILE_BBOX6, tile_box6);
	gpu_set_tiledata(TILE_BBOX7, tile_box7);
	gpu_set_tiledata(TILE_BBOX8, tile_box8);
	gpu_set_tiledata(TILE_BBOX9, tile_box9);
	gpu_set_tiledata(TILE_BBOX10, tile_box10);
	gpu_set_tiledata(TILE_BBOX11, tile_box11);
	gpu_set_tiledata(TILE_BBOX12, tile_box12);
	gpu_set_tiledata(TILE_BBOX13, tile_box13);
	gpu_set_tiledata(TILE_BBOX14, tile_box14);
	gpu_set_tiledata(TILE_BBOX15, tile_box15);
	gpu_set_tiledata(TILE_BBOX16, tile_box16);
	gpu_set_tiledata(TILE_BBOX17, tile_box17);
	gpu_set_tiledata(TILE_BBOX18, tile_box18);
	gpu_set_tiledata(TILE_BBOX19, tile_box19);
	gpu_set_tiledata(TILE_BBOX20, tile_box20);
	gpu_set_tiledata(TILE_BBOX21, tile_box21);
	gpu_set_tiledata(TILE_BBOX22, tile_box22);
	gpu_set_tiledata(TILE_BBOX23, tile_box23);
	gpu_set_tiledata(TILE_BBOX24, tile_box24);

}

void render_full_map() {
    for (int y = 0; y < TILEMAP_H; y++) {
        for (int x = 0; x < TILEMAP_W; x++) {
            gpu_set_tile(x, y, game_map[y][x]);
        }
    }
}


void printHex(uint32_t data, unsigned channel){
	XGpio_DiscreteWrite(&Gpio_hex, channel, data);
}

char get_user_input() {
    MAX3421E_Task();
    USB_Task();

    if (GetUsbTaskState() == USB_STATE_RUNNING) {
            if (!runningdebugflag) {
                runningdebugflag = 1;
            } else{
                rcode = kbdPoll(&kbdbuf);
                if (rcode == hrNAK) {
                    return 0;
                } else if (rcode) {
                    xil_printf("Rcode: %x \n", rcode);
                    return 0;
                }

                switch (kbdbuf.keycode[0]) {
                    case 0x1A: return 'w';
                    case 0x04: return 'a';
                    case 0x16: return 's';
                    case 0x07: return 'd';
                    case 0x15: return 'r'; // Restart current level
                    case 0x2C: return ' '; // Spacebar - Reset entirely to Level 1
                    case 0x20:
                    case 0x1F:
                    case 0x1E:
                    case 0x00:
                    case 0x13:
                    	printHex(kbdbuf.keycode[0] + (kbdbuf.keycode[1] << 8) + (kbdbuf.keycode[2] << 16) + (kbdbuf.keycode[3] << 24), 1);
                    	break;
                    default:   return 0;
                }
            }
    } else if (GetUsbTaskState() == USB_STATE_ERROR) {
            if (!errorflag) {
                errorflag = 1;
                xil_printf("USB Error State\n");
            }
        } else {
            if (runningdebugflag) {
                runningdebugflag = 0;
                MAX3421E_init();
                USB_init();
            }
            errorflag = 0;
        }

    return 0;
}

void move_player(int dx, int dy) {
    int next_x = player_x + dx;
    int next_y = player_y + dy;

    if (next_x < 0 || next_x >= TILEMAP_W || next_y < 0 || next_y >= TILEMAP_H) return;

    uint8_t target = game_map[next_y][next_x];
    if (target == TILE_WALL) return;

    if (target == TILE_BOX || target == TILE_BOX_GOAL) {
        int push_x = next_x + dx;
        int push_y = next_y + dy;
        uint8_t push_target = game_map[push_y][push_x];

        if (push_target == TILE_FLOOR || push_target == TILE_GOAL) {
            game_map[push_y][push_x] = (push_target == TILE_GOAL) ? TILE_BOX_GOAL : TILE_BOX;
            gpu_set_tile(push_x, push_y, game_map[push_y][push_x]);

            game_map[next_y][next_x] = (target == TILE_BOX_GOAL) ? TILE_PLAYER_GOAL : TILE_PLAYER;
            gpu_set_tile(next_x, next_y, game_map[next_y][next_x]);

            game_map[player_y][player_x] = (game_map[player_y][player_x] == TILE_PLAYER_GOAL) ? TILE_GOAL : TILE_FLOOR;
            gpu_set_tile(player_x, player_y, game_map[player_y][player_x]);

            player_x = next_x;
            player_y = next_y;
        }
    }
    else if (target == TILE_FLOOR || target == TILE_GOAL) {
        game_map[next_y][next_x] = (target == TILE_GOAL) ? TILE_PLAYER_GOAL : TILE_PLAYER;
        gpu_set_tile(next_x, next_y, game_map[next_y][next_x]);

        game_map[player_y][player_x] = (game_map[player_y][player_x] == TILE_PLAYER_GOAL) ? TILE_GOAL : TILE_FLOOR;
        gpu_set_tile(player_x, player_y, game_map[player_y][player_x]);

        player_x = next_x;
        player_y = next_y;
    }
}

void transition(){
	for(int i = 0; i < 8; i++){
		uint8_t curPalette = gpu_get_palette();
		gpu_set_palette((curPalette << 1) | (curPalette >> 7));
		gpu_wait_frame();
		gpu_wait_frame();
		gpu_wait_frame();
	}

}

void run_start_screen(){

	//clear board
	for (int y = 0; y < TILEMAP_H; y++) {
	        for (int x = 0; x < TILEMAP_W; x++) {
	            game_map[y][x] = TILE_FLOOR;
	        }
	}


	//set desired squares
	int titleY = 3;
	game_map[titleY][3] = TILE_S0;
	game_map[titleY][4] = TILE_S1;
	game_map[titleY][5] = TILE_O0;
	game_map[titleY][6] = TILE_O1;
	game_map[titleY][7] = TILE_K0;
	game_map[titleY][8] = TILE_K1;
	game_map[titleY][9] = TILE_O0;
	game_map[titleY][10] = TILE_O1;
	game_map[titleY][11] = TILE_B0;
	game_map[titleY][12] = TILE_B1;
	game_map[titleY][13] = TILE_A0;
	game_map[titleY][14] = TILE_A1;
	game_map[titleY][15] = TILE_N0;
	game_map[titleY][16] = TILE_N1;

	game_map[titleY+1][3] = TILE_S2;
	game_map[titleY+1][4] = TILE_S3;
	game_map[titleY+1][5] = TILE_O2;
	game_map[titleY+1][6] = TILE_O3;
	game_map[titleY+1][7] = TILE_K2;
	game_map[titleY+1][8] = TILE_K3;
	game_map[titleY+1][9] = TILE_O2;
	game_map[titleY+1][10] = TILE_O3;
	game_map[titleY+1][11] = TILE_B2;
	game_map[titleY+1][12] = TILE_B3;
	game_map[titleY+1][13] = TILE_A2;
	game_map[titleY+1][14] = TILE_A3;
	game_map[titleY+1][15] = TILE_N2;
	game_map[titleY+1][16] = TILE_N3;


	int pressY = 15;
	game_map[pressY][5] = TILE_P;
	game_map[pressY][6] = TILE_R;
	game_map[pressY][7] = TILE_E;
	game_map[pressY][8] = TILE_S;
	game_map[pressY][9] = TILE_S;
	game_map[pressY][11] = TILE_S;
	game_map[pressY][12] = TILE_P;
	game_map[pressY][13] = TILE_A;
	game_map[pressY][14] = TILE_C;
	game_map[pressY][15] = TILE_E;


	game_map[17][15] = TILE_R;
	game_map[17][16] = TILE_H;
	game_map[17][17] = TILE_AMP;
	game_map[17][18] = TILE_A;
	game_map[17][19] = TILE_DSMALL;



	game_map[7][8] = TILE_BBOX0;
	game_map[7][9] = TILE_BBOX1;
	game_map[7][10] = TILE_BBOX2;
	game_map[7][11] = TILE_BBOX3;
	game_map[7][12] = TILE_BBOX4;

	game_map[8][8] = TILE_BBOX5;
	game_map[8][9] = TILE_BBOX6;
	game_map[8][10] = TILE_BBOX7;
	game_map[8][11] = TILE_BBOX8;
	game_map[8][12] = TILE_BBOX9;

	game_map[9][8] = TILE_BBOX10;
	game_map[9][9] = TILE_BBOX11;
	game_map[9][10] = TILE_BBOX12;
	game_map[9][11] = TILE_BBOX13;
	game_map[9][12] = TILE_BBOX14;

	game_map[10][8] = TILE_BBOX15;
	game_map[10][9] = TILE_BBOX16;
	game_map[10][10] = TILE_BBOX17;
	game_map[10][11] = TILE_BBOX18;
	game_map[10][12] = TILE_BBOX19;

	game_map[11][8] = TILE_BBOX20;
	game_map[11][9] = TILE_BBOX21;
	game_map[11][10] = TILE_BBOX22;
	game_map[11][11] = TILE_BBOX23;
	game_map[11][12] = TILE_BBOX24;

	render_full_map();

    uint8_t last_frame = gpu_get_framecount();

        while(1){
            uint8_t now = gpu_get_framecount();

            if ((uint8_t)(now-last_frame) >= 10) {
                last_frame = now;
                char input = get_user_input();
                if (input == ' ') {
                	transition();
                    return;
                }
            }
        }
}


int main(void) {
    init_platform();
    xil_printf("starting up\n");

    XGpio_Initialize(&Gpio_hex, XPAR_GPIO_USB_KEYCODE_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio_hex, 1, 0x00000000);
    XGpio_SetDataDirection(&Gpio_hex, 2, 0x00000000);

    //Initialize I/O
	xil_printf("initializing MAX3421E...\n");
	MAX3421E_init();
	xil_printf("initializing USB...\n");
	USB_init();


    //set start screen
    init_graphics();
    run_start_screen();

    // Start at Level 0
    current_level = 0;
    game_finished = 0;
    load_level(current_level);
    render_full_map();

    uint8_t last_frame = gpu_get_framecount();

    while(1){
        uint8_t now = gpu_get_framecount();

        if ((uint8_t)(now-last_frame) >= 10) {
            last_frame = now;

            char input = get_user_input();

            if (input) {
                if (input == ' ') {
                	transition();
                    current_level = 0;
                    game_finished = 0;
                	run_start_screen();
                    load_level(current_level);
                    render_full_map();
                    uint8_t last_frame = gpu_get_framecount();
                    continue;
                }

                if (game_finished) continue;

                // Standard Gameplay Logic
                switch(input) {
                    case 'w': move_player(0, -1); break;
                    case 's': move_player(0, 1);  break;
                    case 'a': move_player(-1, 0); break;
                    case 'd': move_player(1, 0);  break;
                    case 'r': load_level(current_level); break;
                }

                render_full_map(); 

                // Check Win Condition
                if ((input == 'w' || input == 's' || input == 'a' || input == 'd') && check_win()) {

                    xil_printf("Level %d Complete!\n", current_level);

                    transition();

                    current_level++;

                    if (current_level >= NUM_LEVELS) {
                        game_finished = 1;
                        load_win_screen();
                        render_full_map();
                        xil_printf("Game Completed! Press Space to reset.\n");
                    } else {
                        load_level(current_level);
                        render_full_map();
                    }
                }
            }
        }
    }

    cleanup_platform();
    return 0;
}
