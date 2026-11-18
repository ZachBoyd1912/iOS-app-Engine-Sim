# engine-sim spike (throwaway, branch spike/engine-sim-ios)

Proves whether engine-sim (MIT, ange-yaghi/engine-sim @ 85f7c3b) can make Piston Forge's engine
sound on an iPhone. `prepare.sh` patches an upstream checkout (MSVC-only habits that clang rejects,
delta-studio and Boost removed), `CMakeLists.txt` builds the sound core, `esim_render.cpp` is a
headless driver. Results: docs/research/raw/engine-sim-spike-results.md.
