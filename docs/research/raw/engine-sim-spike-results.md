# engine-sim spike results (18/11/2026, branch spike/engine-sim-ios)

Question: can engine-sim (MIT, ange-yaghi/engine-sim @ 85f7c3b) make Piston Forge's engine sound on an iPhone?
Code: `Native/EngineSimSpike/` (prepare.sh patches an upstream checkout; CMakeLists.txt; esim_render.cpp
headless driver; App/ phone test app). CI: `.github/workflows/engine-sim-spike.yml` (run 44346718049 last).

## Proven in CI
- Core builds and renders audio: Linux (clang), macOS arm64 (AppleClang 17), iOS Simulator arm64 (ran the
  V8 inside the simulator), and iPhone arm64 static libraries plus a linked executable.
- No delta-studio, SDL or Boost symbols remain.
- Phone test app builds as an unsigned .ipa (2.8 MB): `EngineSoundTest-unsigned-ipa` artifact.

## Cost on GitHub shared runners (noisy; not phone numbers)
| Engine | Linux x86 | macOS arm64 | cores | memory |
|---|---|---|---|---|
| Flat-4 | 1.3-2.2x real time | n/a | 1.3 | 42 MB |
| V8 | 1.0-1.7x | 1.1-1.2x | 1.6-1.9 | 45 MB |
| V10 | 1.0-1.9x | n/a | 1.9 | 45 MB |
| V12 (5 kHz) | 1.2-2.2x | 1.9x | 1.6-1.9 | 49 MB |
Run-to-run variation on the same runner type was up to 2x. One underrun at start is normal (first block).

## What the research report missed (fixed by prepare.sh / CMake)
- piranha (script loader) uses boost::filesystem: replaced with std::filesystem.
- MSVC-only habits clang rejects: backslash include paths, `unsigned __int64`, `extern constexpr` in
  headers (duplicate symbols), default `= {}` arguments of a nested struct, a member-name typo in
  ring_buffer.h, a shadowed template parameter, unqualified fpclassify, missing standard includes,
  `<malloc.h>`, forward-declared Matrix used in a template.

## Not proven
- Sound quality (needs ears), real iPhone CPU, heat and battery (needs the phone test app).
- W16 and forced induction (not in upstream; community fork unlicensed/untested).
- Upstream engine scripts and exhaust recordings have no stated licence: not to be shipped; we write our own.
