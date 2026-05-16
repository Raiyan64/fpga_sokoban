#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>

//Pure software implementation of Sokoban, prints game map to terminal after each move instead of 
//calling the hardware drawing functions. Use to test the software algorithm and overall game flow.

// Tile IDs
#define TILE_FLOOR         0
#define TILE_WALL          1
#define TILE_BOX           2
#define TILE_GOAL          3
#define TILE_PLAYER        4
#define TILE_BOX_GOAL      5
#define TILE_PLAYER_GOAL   6

#define MAP_W 10
#define MAP_H 8

// The "Master Copy" of your level
const uint8_t level_template[MAP_H][MAP_W] = {
    {1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,1,0,0,0,0,1},
    {1,0,4,0,1,0,3,0,0,1},
    {1,0,2,0,0,0,0,0,0,1},
    {1,0,2,0,1,0,3,0,0,1},
    {1,0,0,0,1,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1},
    {0,0,0,0,0,0,0,0,0,0} 
};

// Current active game state
uint8_t game_map[MAP_H][MAP_W];
uint8_t player_x, player_y;

// --- Helper Functions ---

void restart_game() {
    // Copy the template into the active game map
    memcpy(game_map, level_template, sizeof(level_template));
    
    // Find the player in the template to set initial coordinates
    for (int y = 0; y < MAP_H; y++) {
        for (int x = 0; x < MAP_W; x++) {
            if (game_map[y][x] == TILE_PLAYER || game_map[y][x] == TILE_PLAYER_GOAL) {
                player_x = x;
                player_y = y;
            }
        }
    }
}

bool check_win() {
    for (int y = 0; y < MAP_H; y++) {
        for (int x = 0; x < MAP_W; x++) {
            // If any "Goal" or "Player on Goal" exists, the game isn't won yet
            // Because a win requires ALL goals to be covered by boxes (TILE_BOX_GOAL)
            if (game_map[y][x] == TILE_GOAL || game_map[y][x] == TILE_PLAYER_GOAL) {
                return false;
            }
        }
    }
    return true;
}

void draw_map_terminal() {
    printf("\033[H\033[J"); // Clear screen
    printf("--- Sokoban Algorithm Test v2 ---\n");
    for (int y = 0; y < MAP_H; y++) {
        for (int x = 0; x < MAP_W; x++) {
            switch(game_map[y][x]) {
                case TILE_WALL:        printf("# "); break;
                case TILE_BOX:         printf("$ "); break;
                case TILE_GOAL:        printf(". "); break;
                case TILE_PLAYER:      printf("@ "); break;
                case TILE_BOX_GOAL:    printf("* "); break;
                case TILE_PLAYER_GOAL: printf("+ "); break;
                default:               printf("  "); break;
            }
        }
        printf("\n");
    }
    printf("\nControls: W/A/S/D | [Space] Restart | Q: Quit\n");
}

void move_player(int dx, int dy) {
    int next_x = player_x + dx;
    int next_y = player_y + dy;

    if (next_x < 0 || next_x >= MAP_W || next_y < 0 || next_y >= MAP_H) return;

    uint8_t target = game_map[next_y][next_x];
    if (target == TILE_WALL) return;

    // Box Pushing Logic
    if (target == TILE_BOX || target == TILE_BOX_GOAL) {
        int push_x = next_x + dx;
        int push_y = next_y + dy;
        uint8_t push_target = game_map[push_y][push_x];

        if (push_target == TILE_FLOOR || push_target == TILE_GOAL) {
            game_map[push_y][push_x] = (push_target == TILE_GOAL) ? TILE_BOX_GOAL : TILE_BOX;
            game_map[next_y][next_x] = (target == TILE_BOX_GOAL) ? TILE_PLAYER_GOAL : TILE_PLAYER;
            game_map[player_y][player_x] = (game_map[player_y][player_x] == TILE_PLAYER_GOAL) ? TILE_GOAL : TILE_FLOOR;
            player_x = next_x; player_y = next_y;
        }
    } 
    // Normal Movement
    else if (target == TILE_FLOOR || target == TILE_GOAL) {
        game_map[next_y][next_x] = (target == TILE_GOAL) ? TILE_PLAYER_GOAL : TILE_PLAYER;
        game_map[player_y][player_x] = (game_map[player_y][player_x] == TILE_PLAYER_GOAL) ? TILE_GOAL : TILE_FLOOR;
        player_x = next_x; player_y = next_y;
    }
}

int main() {
    restart_game();
    
    while (1) {
        draw_map_terminal();
        
        if (check_win()) {
            printf("\n*** YOU WIN! ***\nPlay again? (y/n): ");
            char choice;
            scanf(" %c", &choice);
            if (choice == 'y' || choice == 'Y') {
                restart_game();
                continue;
            } else {
                break;
            }
        }

        char input;
        // Using scanf(" %c") for input for testing
        scanf("%c", &input); 

        if (input == 'q' || input == 'Q') break;
        if (input == ' ') {
            restart_game();
        } else {
            switch(input) {
                case 'w': case 'W': move_player(0, -1); break;
                case 's': case 'S': move_player(0, 1);  break;
                case 'a': case 'A': move_player(-1, 0); break;
                case 'd': case 'D': move_player(1, 0);  break;
            }
        }
    }

    printf("Goodbye!\n");
    return 0;
}