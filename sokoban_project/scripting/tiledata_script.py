def convert_grid_to_tiles(grid_text, width, height):
    # Mapping symbols to 2-bit color values
    char_map = {'-': 0, '.': 1, '+': 2, '*': 3}
    
    # Clean input: remove spaces and C-style comments
    raw_lines = grid_text.strip().split('\n')
    lines = []
    for line in raw_lines:
        cleaned = line.replace(' ', '').replace('/*', '').replace('*/', '').strip()
        if cleaned:
            lines.append(cleaned)
            
    # Calculate padded dimensions to ensure multiples of 8
    padded_width = ((width + 7) // 8) * 8
    padded_height = ((height + 7) // 8) * 8
    
    # Build 2D array of pixel values
    grid = []
    for y in range(padded_height):
        row = []
        for x in range(padded_width):
            if y < len(lines) and x < len(lines[y]):
                char = lines[y][x]
                row.append(char_map.get(char, 0))
            else:
                row.append(0)
        grid.append(row)
        
    all_bytes = []
    
    # Extract tiles and convert to byte data
    for ty in range(0, padded_height, 8):
        for tx in range(0, padded_width, 8):
            for y in range(8):
                row_pixels = grid[ty + y][tx : tx + 8]
                # Little Endian Packing
                byte1 = (row_pixels[3] << 6) | (row_pixels[2] << 4) | (row_pixels[1] << 2) | row_pixels[0]
                byte2 = (row_pixels[7] << 6) | (row_pixels[6] << 4) | (row_pixels[5] << 2) | row_pixels[4]
                all_bytes.extend([byte1, byte2])

    # Split into 16-byte chunks and format as C arrays
    output_lines = []
    for i in range(0, len(all_bytes), 16):
        tile_index = i // 16
        chunk = all_bytes[i : i + 16]
        
        output_lines.append(f"const uint8_t tile_{tile_index}[16] = {{")
        # Format bytes: 2 per line to represent one 8-pixel row
        for row_start in range(0, len(chunk), 2):
            b1, b2 = chunk[row_start], chunk[row_start+1]
            output_lines.append(f"    0x{b1:02X}, 0x{b2:02X},")
        output_lines.append("};\n")

    # Write to file and print to console
    final_output = "\n".join(output_lines)
    with open("char.txt", "w") as file:
        file.write(final_output)
    
    print(final_output)

grid_data = """
/*
 - - - - - - - -
 - - - * * - - -
 - - * - - * - -
 - * - - - - * - 
 - - - - - - - -
 - - - - - - - - 
 - - - - - - - -
 - - - - - - - -
*/
"""

convert_grid_to_tiles(grid_data, 8, 8)