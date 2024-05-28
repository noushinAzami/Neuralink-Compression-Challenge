#!/usr/bin/env bash

rm -rf data
unzip data.zip

get_file_size() {
  find "$1" -printf "%s\n"
}

total_size_raw=0
encoder_size=$(get_file_size encode)
decoder_size=$(get_file_size decode)
total_size_compressed=$((encoder_size + decoder_size))
total_encode_time=0
total_decode_time=0
total_encode_throughput=0
total_decode_throughput=0
file_count=0

for file in data/*
do
  echo "Processing $file"
  compressed_file_path="${file}.brainwire"
  decompressed_file_path="${file}.copy"

  # Run encode and decode, capturing output
  encode_output=$(./encode "$file" "$compressed_file_path")
  decode_output=$(./decode "$compressed_file_path" "$decompressed_file_path")

  # Extract encoded and decoded sizes, ratio, times, and throughputs
  encoded_size=$(echo "$encode_output" | awk '/encoded size:/ {print $3}')
  decoded_size=$(echo "$encode_output" | awk '/decoded size:/ {print $3}')
  encode_time=$(echo "$encode_output" | awk '/encoding time:/ {print $3}')
  encode_throughput=$(echo "$encode_output" | awk '/encoding throughput:/ {print $3}')
  decode_time=$(echo "$decode_output" | awk '/decoding time:/ {print $3}')
  decode_throughput=$(echo "$decode_output" | awk '/decoding throughput:/ {print $3}')

  # Output information
  echo "Encoded size: $encoded_size"
  echo "Decoded size: $decoded_size"
  echo "Encode time: $encode_time ms"
  echo "Encode throughput: $encode_throughput Mbytes/s"
  echo "Decode time: $decode_time ms"
  echo "Decode throughput: $decode_throughput Mbytes/s"

  # Accumulate times and throughputs for averages
  total_encode_time=$(echo "$total_encode_time + $encode_time" | bc)
  total_decode_time=$(echo "$total_decode_time + $decode_time" | bc)
  total_encode_throughput=$(echo "$total_encode_throughput + $encode_throughput" | bc)
  total_decode_throughput=$(echo "$total_decode_throughput + $decode_throughput" | bc)

  # Check for lossless compression
  file_size=$(get_file_size "$file")
  compressed_size=$(get_file_size "$compressed_file_path")

  if diff -q "$file" "$decompressed_file_path" > /dev/null; then
      echo "${file} losslessly compressed from ${file_size} bytes to ${compressed_size} bytes"
  else
      echo "ERROR: ${file} and ${decompressed_file_path} are different."
      exit 1
  fi

  total_size_raw=$((total_size_raw + file_size))
  total_size_compressed=$((total_size_compressed + compressed_size))
  file_count=$((file_count + 1))
done

# Calculate averages
average_encode_time=$(echo "scale=3; $total_encode_time / $file_count" | bc)
average_decode_time=$(echo "scale=3; $total_decode_time / $file_count" | bc)
average_encode_throughput=$(echo "scale=3; $total_encode_throughput / $file_count" | bc)
average_decode_throughput=$(echo "scale=3; $total_decode_throughput / $file_count" | bc)

compression_ratio=$(echo "scale=2; ${total_size_raw} / ${total_size_compressed}" | bc)

echo "All recordings successfully compressed."
echo "Original size (bytes): ${total_size_raw}"
echo "Compressed size (bytes): ${total_size_compressed}"
echo "Compression ratio: ${compression_ratio}"
echo "Average encode time: ${average_encode_time} ms"
echo "Average encode throughput: ${average_encode_throughput} Mbytes/s"
echo "Average decode time: ${average_decode_time} ms"
echo "Average decode throughput: ${average_decode_throughput} Mbytes/s"

