tilemap = []
width = 80
height = 60

for y in range(height):
    for x in range(width):
        tile = (x + y) % 4
        tilemap.append(tile)

with open("tilemap.coe", "w") as f:
    f.write("memory_initialization_radix=16;\n")
    f.write("memory_initialization_vector=\n")
    for i, v in enumerate(tilemap):
        f.write(f"{v:02X}")
        if i != len(tilemap) - 1:
            f.write(",\n")
        else:
            f.write(";")