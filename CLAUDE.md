# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Configure (ROCm/HIP for RX 7900 XTX + SDL2 for whisper-stream)
cmake -B build -DGGML_HIP=ON -DWHISPER_SDL2=ON -DAMDGPU_TARGETS=gfx1100

# Build
cmake --build build --config Release -j$(nproc)

# Run tests
cd build && ctest --output-on-failure
# or
bash ./tests/run-tests.sh
```

## Model

The large-v3 model is stored locally at `models/ggml-large-v3.bin` (2.9 GB, not tracked in git). Download via:
```bash
bash ./models/download-ggml-model.sh large-v3
```

## Running whisper-stream

```bash
# From repo root — routes Discord call audio via PipeWire automatically
./start-whisper.sh

# Direct invocation
./build/bin/whisper-stream -m models/ggml-large-v3.bin --language auto -tr --step 0 --length 8000 -vth 0.8
```

The `start-whisper.sh` script:
- Validates binary and model exist before launching
- Runs a background loop using `pw-link` to connect Discord's `WEBRTC VoiceEngine:output_FL/FR` to `SDL Application:input_MONO` every 3 seconds
- Disconnects the Scarlett Solo USB microphone from SDL input (so only Discord call audio is transcribed)
- Cleans up background jobs on exit

## Architecture

- **`whisper.h` / `whisper.cpp`** — Core C API. Entry point for all inference.
- **`ggml/`** — Submodule providing tensor ops and GPU backends (CUDA, HIP/ROCm, Metal, CPU).
- **`examples/stream/stream.cpp`** — The `whisper-stream` binary: real-time microphone transcription using SDL2 audio capture. This is the primary binary used here.
- **`examples/`** — Other example binaries (main, server, bench, etc.). Not used in this setup.
- **`bindings/`** — Language bindings (Go, Ruby, etc.).

## GPU Backend

This build targets AMD RX 7900 XTX (gfx1100) via ROCm/HIP. The relevant CMake flag is `GGML_HIP=ON` (not the older `GGML_HIPBLAS`). The env var `HSA_OVERRIDE_GFX_VERSION=11.0.0` is set in NuShell config to ensure ROCm recognizes the GPU.

## Audio Routing (PipeWire)

SDL2's audio capture does not respect `PULSE_SOURCE`. Instead, route audio directly at the PipeWire graph level using `pw-link` or `qpwgraph`. The target sink for whisper-stream is `SDL Application:input_MONO`.
