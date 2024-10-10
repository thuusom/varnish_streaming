#!/bin/bash

function fetch() {
    mkdir -p "$2"  # Create the directory if it doesn't exist
    cd "$2" || exit  # Change into the directory, exit if it fails
    wget "$1/$2/prog_index.m3u8"
    wget "$1/$2/main.ts"
    cd ..
}

echo "Fetching the Apple HLS streaming sample"

mkdir stream
cd stream

main_url="https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9"
wget "$main_url/bipbop_16x9.m3u8" -O index.m3u8

# Loop through gear1 to gear5 and call the fetch function
for i in {1..5}; do
    fetch "$main_url" "gear$i"
done

mkdir -p "subtitles/eng"
cd subtitles/eng
wget "$main_url/prog_index.m3u8"
for i in {1..59}; do
    wget "$main_url/fileSequence$i.webvtt"
done
