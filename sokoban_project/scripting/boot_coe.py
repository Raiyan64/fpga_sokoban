def generate_coe(filename="ninmap.coe"):
    with open(filename, "w") as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")

        for i in range(168):
            if (i % 10 == 0):
                f.write("\n")
            f.write("00,")
        f.write("\n")
        f.write("01,\n") # N
        f.write("02,\n") # I
        f.write("01,\n") # N
        f.write("03,\n") # T
        f.write("04,\n") # E
        f.write("01,\n") # N
        f.write("05,\n") # D
        f.write("06,\n") # O
        f.write("07;") # ?

    print(f"Done! {filename} now contains exactly 8192 values.")

if __name__ == "__main__":
    generate_coe()