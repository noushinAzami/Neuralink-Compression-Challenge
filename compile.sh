#!/usr/bin/env bash

# Set the source files and the output executables
ENCODE_SOURCE="neuralink-comp.cpp"
DECODE_SOURCE="neuralink-decomp.cpp"
ENCODE_OUTPUT="encode"
DECODE_OUTPUT="decode"

# Default compilation flags
FLAGS="-O3 -march=native -std=c++17"

# Check for OpenMP flag
if [[ $1 == "--openmp" ]]; then
    FLAGS="$FLAGS -fopenmp"
    echo "Compiling with OpenMP support"
else
    echo "Compiling without OpenMP support"
fi

# Function to compile a source file
compile() {
    local source_file=$1
    local output_file=$2

    echo "Compiling $source_file to $output_file..."
    g++ $FLAGS -o $output_file $source_file
    if [ $? -ne 0 ]; then
        echo "Error: Compilation of $source_file failed."
        exit 1
    fi
    echo "$output_file compiled successfully."
}

# Check if g++ is installed
if ! command -v g++ &> /dev/null; then
    echo "Error: g++ is not installed."
    exit 1
fi

# Compile the encode program
compile $ENCODE_SOURCE $ENCODE_OUTPUT

# Compile the decode program
compile $DECODE_SOURCE $DECODE_OUTPUT

