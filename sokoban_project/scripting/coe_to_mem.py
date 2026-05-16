def coe_to_mem(coe_filename, mem_filename):
    with open(coe_filename, 'r') as coe:
        lines = coe.readlines()

    # Locate the start of the data vector
    vector_start = False
    raw_data = ""
    
    for line in lines:
        clean_line = line.strip().lower()
        if "memory_initialization_vector" in clean_line:
            vector_start = True
            if "=" in clean_line:
                raw_data += clean_line.split("=")[1]
            continue
        
        if vector_start:
            raw_data += clean_line

    # Remove the trailing semicolon and split by commas or whitespace
    raw_data = raw_data.replace(";", "").replace(",", " ")
    hex_values = raw_data.split()

    # Write to .mem file (one hex value per line)
    with open(mem_filename, 'w') as mem:
        mem.write("\n".join(hex_values))

# Usage
coe_to_mem("data/underwater2.coe", "underwater2.mem")