import sys

#The input file should be an 8-bit unsigned PCM .raw file.
#This converts it into .coe to put into BRAM.

def raw_to_coe(input_file, output_file):
    with open(input_file, 'rb') as raw_file:
        binary_data = raw_file.read()

    hex_data = binary_data.hex()

    # Running FPGA with 8kHz sampling rate, so collecting
    # 32768 bytes of data gives sound clips of about 4 seconds long.
    required_length = 32768 * 2
    if len(hex_data) < required_length:
        hex_data = hex_data.ljust(required_length, '0')
    else:
        hex_data = hex_data[:required_length]


    coe_content = "memory_initialization_radix=16;\nmemory_initialization_vector=\n"
    words = [hex_data[i:i+2] for i in range(0, len(hex_data), 2)]
    coe_content += ",\n".join(words) + ";\n"

    # Write the .coe file
    with open(output_file, 'w') as coe_file:
        coe_file.write(coe_content)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 file.py <input.raw> <output.coe>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    raw_to_coe(input_file, output_file)
    print(f"Converted {input_file} to {output_file} successfully.")