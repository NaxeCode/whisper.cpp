#!/bin/bash

# Force script to run from its own directory
cd "$(dirname "$0")"

MODEL="models/ggml-large-v3.bin"
BINARY="./build/bin/whisper-stream"

cleanup() {
    echo -e "\nClosing whisper..."
    kill $(jobs -p) 2>/dev/null
    exit
}

trap cleanup EXIT

if [ ! -f "$BINARY" ]; then
    echo "Error: Binary not found in $(pwd)/build/bin/"
    echo "Did you compile it?"
    exit 1
fi

if [ ! -f "$MODEL" ]; then
    echo "Error: Model not found at $(pwd)/$MODEL"
    exit 1
fi

# Connect Discord call audio directly to whisper-stream's SDL capture input.
# Retries every 3s to pick up calls that start after whisper is already running.
connect_discord() {
    while true; do
        pw-link "WEBRTC VoiceEngine:output_FL" "SDL Application:input_MONO" 2>/dev/null
        pw-link "WEBRTC VoiceEngine:output_FR" "SDL Application:input_MONO" 2>/dev/null
        pw-link -d "Scarlett Solo USB:capture_MONO" "SDL Application:input_MONO" 2>/dev/null
        sleep 3
    done
}

connect_discord &

echo "Starting Whisper (RX 7900 XTX Optimized)..."
"$BINARY" -m "$MODEL" --language auto -tr --step 0 --length 8000 -vth 0.8
