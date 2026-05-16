def generate_coe(filename="vram_data.coe"):
    with open(filename, "w") as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")

        # 1. TILES 0-383 (Address 0x0000 to 0x17FF)
        # Tile 0
        f.write("FF,00,7E,FF,81,81,81,81,81,81,81,81,7E,FF,00,00,\n")
        # Tile 1
        f.write("3C,3C,42,42,A5,A5,81,81,A5,A5,99,99,42,42,3C,3C,\n")
        # Tiles 2-383 (Blank)
        for _ in range(382):
            f.write("00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,\n")

        # 2. BG MAP (Address 0x1800 to 0x1BFF)
        # 1024 entries total (32x32 map)
        for _ in range(64): # 64 lines * 16 bytes = 1024
            f.write("01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,01,\n")

        # 3. WINDOW MAP (Address 0x1C00 to 0x1FFF)
        # 1024 entries total (32x32 map)
        for i in range(64):
            if i == 63:
                f.write("00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00;\n")
            else:
                f.write("00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,\n")

    print(f"Done! {filename} now contains exactly 8192 values.")

if __name__ == "__main__":
    generate_coe()