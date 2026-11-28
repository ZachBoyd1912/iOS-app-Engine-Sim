# engine-sim on iOS: feasibility research (audio-only use)

Date of research: 2026-11-18. Researcher: Claude (Haiku 5.5), subagent run.
Scope: can `ange-yaghi/engine-sim` (MIT, C++) run its physics + synthesizer headless on iOS arm64, driven by our Swift app (rpm/throttle in, PCM out), built only in GitHub Actions macOS runners.

**Verdict: NEEDS-SPIKE.** The audio-relevant core is separable from the Windows/DirectX/SDL app and has no SIMD intrinsics, so an arm64 static library looks plausible. Nothing has been compiled for iOS yet, no one has published an iOS build of the core, and real-time CPU cost on a phone is unmeasured and is the largest risk. See section 6.

Conventions:
- `UP:` = upstream `ange-yaghi/engine-sim`, pinned to commit `85f7c3b959a908ed5232ede4f1a4ac7eafe6b630` (default branch HEAD, committed 2023-01-22). Blob URL pattern: `https://github.com/ange-yaghi/engine-sim/blob/85f7c3b959a908ed5232ede4f1a4ac7eafe6b630/<path>`.
- `FORK-OE:` = `carlesonielfa/open-engine-sim` (fork, MIT, created 2026-08-11, pushed 2026-08-14, 7 stars). Its own files were read at default-branch HEAD on 2026-11-18.
- `FORK-KU:` = `kadaxo/engine-sim-community-ultimate` (fork, MIT, created 2026-11-16, 1 star, large consolidation of many forks).
- Local copies of the upstream files read for this report are in the session scratchpad under `es/` (not in the repo). Line numbers below refer to the upstream commit above unless marked otherwise.
- Nothing was compiled. Every "would build" statement is a reading of the source, not a build result.

---

## 0. Repo facts (GitHub API)

| Item | Value | Source |
|---|---|---|
| Stars / forks / open issues | 9,664 / 969 / 144 | `GET /repos/ange-yaghi/engine-sim` |
| Licence | MIT (SPDX `MIT`), text is `Copyright 2022 AngeTheGreat (Ange Yaghi)` | `LICENSE` (UP), `https://github.com/ange-yaghi/engine-sim/blob/85f7c3b959a908ed5232ede4f1a4ac7eafe6b630/LICENSE` |
| Maintenance | `FORK-KU` COMMUNITY.md: "The original repository stopped receiving updates in 2024." Community Edition README (`Engine-Simulator/engine-sim-community-edition`) says the newer app is closed-source and not open source. | `https://github.com/kadaxo/engine-sim-community-ultimate/blob/main/COMMUNITY.md`; `https://github.com/Engine-Simulator/engine-sim-community-edition` (README "Why is this project no longer open source?") |
| Language | C++ (17) | `CMakeLists.txt:` `set(CMAKE_CXX_STANDARD 17)` |
| Upstream CI | `runs-on: windows-latest`, installs Boost 1.78 (MSVC) | `.github/workflows/cmake.yml` (UP) |

Caveat: the Community Edition is not the MIT project. Do not take code from it.

---

## 1. Repository structure, dependencies, iOS feasibility

### 1.1 Layout (UP)

- `src/`, `include/`: engine physics, synthesizer, filters (core) and the desktop application (UI/graphics/audio device). The split is by filename, not by folder, so use the CMake target list below as the source of truth.
- `scripting/src`, `scripting/include`: the Piranha-based `.mr` script compiler/nodes (only needed to load `.mr` engine scripts).
- `dependencies/submodules/`: `delta-studio` (ange-yaghi, MIT, graphics/engine framework), `simple-2d-constraint-solver` (MIT, "scs", the rigid-body/constraint solver), `csv-io` (MIT), `piranha` (MIT, script language). Declared in `.gitmodules` and `dependencies/submodules/CMakeLists.txt` (`add_subdirectory(delta-studio)` at line 1, `simple-2d-constraint-solver` at line 8, `csv-io` at line 13, `piranha` later).
- `dependencies/discord/`: Discord RPC wrapper plus a prebuilt Windows `discord-rpc.lib` (262 KB binary). Exclude from iOS.
- `assets/`: `main.mr`, `engines/` (25 engine scripts), `themes/`, `part-library/`, `sound-library/` (WAV impulse responses and recordings). Total `assets/` 6.53 MB, of which WAV is about 5.1 MB.
- `es/`: the Piranha script library (`engine_sim.mr`, `objects/objects.mr`, `actions/actions.mr`, `sound-library/impulse_responses.mr`, and some extra WAVs under `es/sound-library/new` and `es/sound-library/sharp`). About 0.55 MB.
- `test/`: gtest tests (`gas_system_tests.cpp`, `function_test.cpp`, `synthesizer_tests.cpp`).

### 1.2 Core vs app (UP, CMakeLists.txt)

The upstream top-level CMake defines three relevant targets:

1. `engine-sim` STATIC library, `CMakeLists.txt:47`, 41 `.cpp` files (`src/audio_buffer.cpp`, `camshaft`, `combustion_chamber`, `connecting_rod`, `convolution_filter`, `crankshaft`, `cylinder_bank`, `cylinder_head`, `delay_filter`, `derivative_filter`, `direct_throttle_linkage`, `dynamometer`, `engine`, `exhaust_system`, `feedback_comb_filter`, `filter`, `fuel`, `function`, `gas_system`, `gaussian_filter`, `governor`, `ignition_module`, `impulse_response`, `intake`, `jitter_filter`, `leveling_filter`, `low_pass_filter`, `part`, `piston`, `piston_engine_simulator`, `simulator`, `standard_valvetrain`, `starter_motor`, `synthesizer`, `throttle`, `transmission`, `utilities`, `valvetrain`, `vehicle`, `vehicle_drag_constraint`, `vtec_valvetrain`). Links `simple-2d-constraint-solver csv-io delta-basic` at `CMakeLists.txt:140`.
2. `engine-sim-script-interpreter` (optional, `PIRANHA_ENABLED`, default ON): 4 `.cpp` in `scripting/src` + nodes, links `csv-io piranha`.
3. `engine-sim-app` (`add_executable(... WIN32 ...)` at line 206): `main.cpp` (`DeviceAPI::DirectX11` at `src/main.cpp:16`), `engine_sim_application.cpp`, all `*_object.cpp`, UI, gauges, oscilloscope, shaders, geometry generator, Discord.

Also `googletest` is pulled with `FetchContent` from `https://github.com/google/googletest/archive/609281...zip` (`CMakeLists.txt:32-38`) and `enable_testing()` is at line 306. Top-level CMake therefore needs network access and builds gtest for every configuration. Do not use the upstream top-level for iOS; write a small CMake that lists the core sources.

### 1.3 What is needed for audio-only

Needed (core + script loader):
- Physics: `crankshaft`, `connecting_rod`, `piston`, `cylinder_bank`, `cylinder_head`, `camshaft`, `valvetrain`/`standard_valvetrain`/`vtec_valvetrain`, `combustion_chamber`, `gas_system`, `intake`, `exhaust_system`, `fuel`, `ignition_module`, `starter_motor`, `dynamometer`, `throttle`/`direct_throttle_linkage`/`governor`, `vehicle`, `vehicle_drag_constraint`, `transmission`, `engine`, `simulator`, `piston_engine_simulator`, `utilities`, `units`, `function`.
- Audio DSP: `synthesizer`, `convolution_filter`, `impulse_response`, `delay_filter`, `derivative_filter`, `jitter_filter`, `leveling_filter`, `low_pass_filter`, `butterworth_low_pass_filter.h`, `feedback_comb_filter`, `gaussian_filter`, `ring_buffer.h`, `audio_buffer`.
- Solver: `simple-2d-constraint-solver` (scs, 30 `.cpp` files, C++11, no platform code; its own CMake only adds gtest tests).
- Script loading: `scripting/src/*.cpp` + `scripting/include/*.h` nodes, and `piranha`.

Not needed: everything in section 1.2 item 3, `*_object.cpp`, `ui_*`, `gauge*`, `oscilloscope*`, `*_cluster.cpp`, `shaders.cpp`, `geometry_generator.cpp`, `engine_view.cpp`, `dtv`, `discord`, `csv-io` (only used by the app `engine_sim_application.cpp:12`).

### 1.4 Blockers found by reading the code (UP unless marked)

| # | Blocker | Evidence | Fix |
|---|---|---|---|
| B1 | `delta-studio` include in the synthesizer | `src/synthesizer.cpp:4` `#include "../include/delta.h"`; `include/delta.h:4-5` includes `<delta-studio/include/yds_core.h>` and `<delta-studio/engines/basic/include/delta_basic_engine.h>`. No other core `.cpp` includes `delta.h`; the grep shows only `include/engine_sim_application.h`, `src/engine_sim_application.cpp` and `src/synthesizer.cpp`. | Delete the include from `synthesizer.cpp`. No `yds_*` symbol appears in that file as read, so it should compile without it. Unverified until compiled. |
| B2 | CMake links `delta-basic` into the core lib | `CMakeLists.txt:140` | Do not link delta. Build the core lib from our own CMake. |
| B3 | `__forceinline` (MSVC keyword) | `include/butterworth_low_pass_filter.h:28`, `include/jitter_filter.h:22`, `include/low_pass_filter.h:15` | Compile definition `-D__forceinline=inline` on the Apple toolchain. FORK-OE does the same for its scs target (`CMakeLists.txt:39`, PUBLIC so it propagates). |
| B4 | scs uses `memcpy/memset` without `<cstring>` | FORK-OE `cmake/EngineSimLegacySolverCompatibility.h`: "The retained upstream solver uses memcpy/memset without including <cstring> in every translation unit." | Force-include `<cstring>` for the scs target, as FORK-OE does with `-include`. |
| B5 | Piranha needs Flex and Bison at build time | Piranha `CMakeLists.txt:31-32`: `find_package(FLEX REQUIRED)`, `find_package(BISON REQUIRED)`; generated scanner/parser in `flex-bison/`. FORK-OE `cmake/EngineSimScripting.cmake` requires Bison 3.2+ and copies `FlexLexer.h` so the target compiler does not pick host headers during cross-compilation. | Install `bison` and `flex` via Homebrew on the macOS runner (macOS ships Bison 2.3, which FORK-OE says is too old). Only host tools run during cross-compile. |
| B6 | Boost | No `find_package(Boost)` anywhere in upstream CMake; no `boost` include in core or piranha `include/path.h`. Upstream CI still installs Boost 1.78 (`cmake.yml`). FORK-KU README: "Boost is no longer needed." | Probably not needed. Verify by compiling without Boost. |
| B7 | App-only audio/IR loader | `src/engine_sim_application.cpp:493-497` loads impulse responses with `ysWindowsAudioWaveFile` (delta). Core `ImpulseResponse` only stores a filename (`src/impulse_response.cpp`). | Write a 44-byte-header WAV reader (the IR files are 16-bit mono 44.1 kHz, see 2.5). |
| B8 | Asset paths | `delta.conf` maps `/delta` and `/assets` (`configuration/delta.conf`). Core takes plain strings. `.mr` imports and WAV names are relative (`es/sound-library/impulse_responses.mr`). | Pass an absolute search path to the compiler. FORK-KU's `SessionConfig.searchPaths` does this (see 4.4). |
| B9 | Mixed asset locations | `impulse_responses.mr` references `new/mild_exhaust_reverb.wav`, `new/mild_exhaust.wav`, `sharp/sharp_01.wav`, `new/minimal_muffling_01.wav`. These exist only under `es/sound-library/`, not under `assets/sound-library/` (which has only `archive/` and `smooth/`). How the upstream loader resolves them was not established. | Verify on the first build that every `.mr` IR path resolves, and copy all WAVs into the bundle. |
| B10 | SIMD | No `xmmintrin`, `emmintrin`, `immintrin` or `_mm_*` use in upstream core, piranha or scs source. So no sse2neon needed for the core. (The boxofbox/tjvjk macOS forks mention sse2neon; that is for delta, not the core.) | None for core. |

No Windows API (`windows.h`, `__declspec`, `_WIN32`) appears in any core file read. The Windows dependency is `main.cpp` (DirectX11) and the app.

### 1.5 FORK-OE: a cleaner core (evidence)

`https://github.com/carlesonielfa/open-engine-sim`. Its README says: "The simulator, scripting, rendering, and desktop/audio-device adapters are therefore kept as distinct layers." Its CMake has:
- `CMakeLists.txt:31`: `# Core simulation has no desktop, graphics, or audio-device dependency.`
- `CMakeLists.txt:44`: `set(ENGINE_SIM_CORE_SOURCES ...)`, 40 `.cpp` files (upstream lists 41; which upstream file is dropped was not traced).
- `CMakeLists.txt:86`: `add_library(engine-sim-core STATIC ...)`, linked only to scs.
- `CMakeLists.txt:12`: `ENGINE_SIM_BUILD_SCRIPTING` default OFF (scripting is a separate step).
- `include/audio_output.h`: abstract `AudioOutput` (`start(Simulator*)`, `loadImpulseResponse(...)`, `stop()`, `outputSampleRate()` default 44100).
- `include/spsc_audio_ring.h`: lock-free single-producer/single-consumer ring "for the simulation-to-device hand-off ... the consumer is the platform's real-time audio callback. Neither side waits."
- `include/synthesizer.h:41-49`: `#if !defined(__EMSCRIPTEN__)` around `<thread>`/`<mutex>`; `src/synthesizer.cpp` has `renderRealtimeAudio(float*, int)` (line ~491) and a non-blocking `pumpAudioRendering()` (line 158).
- `.github/workflows/cmake.yml`: CI matrix Linux x86_64, **macOS arm64 (`macos-15`)**, Windows x86_64, plus a Web (Emscripten) job. Runs `ctest` on core tests. No iOS job.

Status of FORK-OE: 2026 rewrite, one maintainer, 7 stars, 4 months old. Treat as a reference for the layering and as a candidate base, not as a stable dependency. Pin a SHA.

### 1.6 Can the core be built for iOS arm64 in CI?

Likely yes after B1-B5 patches (about 10-20 lines of CMake and one source edit). Not verified. No iOS build of engine-sim (upstream or any fork reviewed) was found. The FORK-OE CI validates macOS arm64 desktop and Emscripten, not iOS.

Suggested CMake (not run; to be validated in the spike):

```sh
# host tools (macOS runner)
brew install bison flex cmake ninja
export PATH="$(brew --prefix bison)/bin:$(brew --prefix flex)/bin:$PATH"

cmake -S Native/EngineSimCore -B build/ios-arm64 -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
  -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
  -DCMAKE_CXX_STANDARD=17 \
  -DCMAKE_CXX_STANDARD_REQUIRED=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY

cmake --build build/ios-arm64 --config Release --target EngineSimCore

# simulator slice for a host-side smoke test on the same runner
#   -DCMAKE_OSX_SYSROOT=iphonesimulator  (arm64)
```

Compile definitions to add to the core target: `__forceinline=inline`. Force-include for scs: `<cstring>`. Do not add `-ffast-math` (see 2.6, it changes DSP results).

Do not use Swift C++ interop for the first spike. Wrap the core in a plain C ABI (`extern "C"`) and call it from Swift. This keeps the Swift/C++ boundary small.

---

## 2. The engine definition system

### 2.1 Where scripts live and how they load

- Entry point: `assets/main.mr` (imports `engine_sim.mr`, `themes/default.mr`, `engines/atg-video-2/01_subaru_ej25_eh.mr`; calls `use_default_theme()` and `main()`).
- Library: `es/engine_sim.mr` imports `types/`, `actions/`, `objects/objects.mr` (617 lines, the node definitions), `constants/`, `part-library/`, `sound-library/impulse_responses.mr`, `utilities/`, `settings/application_settings.mr`.
- Script compiler: `scripting/src/compiler.cpp`, `scripting/src/engine_context.cpp` (Piranha-based). The app calls it at `src/engine_sim_application.cpp:623-642` under `ATG_ENGINE_SIM_PIRANHA_ENABLED`.
- Each engine file is a Piranha program: `engine <name>(...)`, `cylinder_bank`, `piston`, `connecting_rod`, `crankshaft`, `intake`, `exhaust_system`, `ignition_module`, `camshaft`, `cylinder_head`, `fuel`, `impulse_response`, functions for curves.

### 2.2 Bundled engine scripts (UP `assets/engines/`)

25 engine scripts (8 + 12 + 1 + 1 + 2 + 1). Helper files (`radial.mr`) are excluded.

atg-video-1 (8): `01_honda_trx520` (Honda TRX520 ATV, 1 cyl), `02_kohler_ch750` (Kohler CH750, 2 cyl), `03_harley_davidson_shovelhead` (2 cyl), `04_hayabusa` (Suzuki Hayabusa I4), `05_honda_vtec` (Honda B18C5, I4, VTEC), `06_subaru_ej25` (boxer 4), `07_audi_i5` (Audi 2.3 inline-5), `08_radial_5` (radial 5).

atg-video-2 (12): `01_subaru_ej25_eh` (equal-length headers), `02_subaru_ej25_uh` (unequal headers), `03_2jz` (I6), `04_60_degree_v6`, `05_odd_fire_v6`, `06_even_fire_v6`, `07_gm_ls` (V8), `08_ferrari_f136_v8` (V8, 8 cyl, 2 banks, 2 exhaust systems), `09_radial_9`, `10_lfa_v10` (V10), `11_merlin_v12`, `12_ferrari_412_t2` (V12).

Other: `audi/i5.mr` (inline-5), `bmw/M52B28.mr` (I6), `chevrolet/chev_truck_454.mr` and `chevrolet/engine_03_for_e1.mr` (both V8), `kohler/kohler_ch750.mr` (duplicate of atg-video-1/02).

Source: `https://github.com/ange-yaghi/engine-sim/tree/85f7c3b959a908ed5232ede4f1a4ac7eafe6b630/assets/engines`. The atg-video READMEs (`assets/engines/atg-video-1/README.md`, `atg-video-2/README.md`) list the names and link the YouTube videos they came from.

### 2.3 Parameter map (concrete from `assets/engines/atg-video-2/08_ferrari_f136_v8.mr`)

| Requirement | Where / what | Notes |
|---|---|---|
| Firing order | `ignition_module.connect_wire(wireN, angle)` (lines ~ 'connect_wire' block) plus per-cylinder `ignition_wire: wires.wireN` in `add_cylinder`. Comment in file: `// 1 5 3 7 4 8 2 6`. Angles are multiples of 90 deg in a 720 deg cycle. | Firing order is set by the wire-to-angle map, not a single integer list. |
| Bank angle | `cylinder_bank b0(bank_params, angle: v_angle / 2.0)` / `b1(... angle: -v_angle / 2.0)`; `label v_angle(90 * units.deg)` | Any angle is accepted by the script. |
| Crank | `crankshaft c0(throw, flywheel_mass, mass, friction_torque, moment_of_inertia, position_x/y, tdc)`; `rod_journal rj0..rj3(angle:)` | Rod journal angle = firing geometry. |
| Cam timing | `camshaft` with `intake_lobe_center: 116 * units.deg`, `exhaust_lobe_center: 116 * units.deg`, `advance`, `base_radius`. Lobes are `harmonic_cam_lobe(duration_at_50_thou, gamma, lift, steps)`. `include/camshaft.h`: `setLobeCenterline(lobe, crankAngle) { m_lobeAngles[lobe] = crankAngle / 2; }`. | Lobe centre is given in crank degrees and halved internally. |
| Valve lift / flow | `generic_cylinder_head` with `intake_port_flow`/`exhaust_port_flow` tables (`add_flow_sample(lift, flow)`), `standard_valvetrain(...)`. VTEC exists upstream (`src/vtec_valvetrain.cpp`; `assets/engines/atg-video-1/05_honda_vtec.mr` line 63 uses `vtec_valvetrain(`). | |
| Chamber / runners | `chamber_volume`, `intake_runner_volume`, `intake_runner_cross_section_area`, `exhaust_runner_volume`, `exhaust_runner_cross_section_area`. | |
| Exhaust headers (primary length) | Per cylinder: `primary_length: 2 * units.cm` etc. Exhaust collector: `exhaust_system exhaust0(es_params, audio_volume: 2.0 * 0.1, length: 100 * units.inch, impulse_response: ir_lib.mild_exhaust_0_reverb)`. | Sound delay per cylinder = (header primary length + exhaust length) / 343 m/s, `src/piston_engine_simulator.cpp:221-226` and `390-403`. |
| Muffler / IR | `impulse_response(filename:, volume:)` in `es/sound-library/impulse_responses.mr`; per-exhaust `impulse_response:`. | IR is a WAV convolved with the synthesized exhaust pulse (2.5). |
| Intake | `intake(plenum_volume, plenum_cross_section_area, intake_flow_rate: k_carb(700.0), runner_flow_rate, runner_length, idle_flow_rate, idle_throttle_plate_position, velocity_decay)` | One shared intake plenum for all 8 cylinders in the F136. |
| Throttle | `direct_throttle_linkage(gamma: throttle_gamma)` (`es/objects/objects.mr:109-111`); `throttle_gamma: 2.0` in F136. | |
| Ignition timing | `timing_curve` is a `function` of rpm -> advance (F136: 12 deg at 0-1000 rpm, 40 deg from 4000 rpm). `ignition_module(timing_curve:, rev_limit:, limiter_duration:)`. | |
| Rev limiter | `ignition_module` `rev_limit` and `limiter_duration`. Implementation: `src/ignition_module.cpp:88-94` sets a timer that **stops spark** (`ignitionEvent` is only set when `m_revLimitTimer == 0`, line 56). No fuel cut found. | Limiter is ignition-only. |
| Fuel / AFR | Intake flow mixes air and fuel automatically: `src/intake.cpp:61` `const double ideal_afr = 0.8 * m_molecularAfr * 4;` with `m_molecularAfr` = intake `MolecularAfr` (default `25/2`, `include/intake.h`). No direct lambda/AFR input in scripts. `fuel(...)` sets molecular mass, energy density, density, `max_burning_efficiency`, `turbulence_to_flame_speed_ratio` (`include/fuel.h`). `Engine::getIntakeAfr()` reports AFR (`src/engine.cpp:314`). | AFR is not a tuning knob in the script API as far as read. |
| Redline / starter / dyno | `engine(name:, starter_torque:, starter_speed:, redline:, throttle_gamma:, fuel:, hf_gain:, noise:, jitter:, simulation_frequency:)`; default redline 6500 rpm (`include/engine.h:36`). `dyno_min_speed`, `dyno_max_speed`, `dyno_hold_step` in objects.mr. | |
| Simulation frequency | Default 10,000 Hz (`src/simulator.cpp:13`); F136 sets 10,000; W16 (FORK-KU) sets 5,000. | Main CPU knob. |
| Vehicle / gearbox | Not in engine scripts; app builds `Vehicle` and `Transmission` in code (`src/engine_sim_application.cpp:645-662`: 1597 kg, diff 3.42, 6 gears). | |

### 2.4 Forced induction

- Upstream: none found. Searched `src/`, `include/`, `scripting/`, `assets/` for `turbo`, `supercharg`, `nitrous`, `compressor`, `wastegate`, `boost` (only `boostUnits` as a settings string in `es/settings/application_settings.mr`). Zero engine-physics hits.
- FORK-KU (`https://github.com/kadaxo/engine-sim-community-ultimate`): README feature list "Forced induction: turbochargers (with lag, wastegate and blow-off valve) and Roots, twin-screw or centrifugal superchargers" with `docs/forced-induction.md`, `include/forced_induction.h`, `src/forced_induction.cpp`, `scripting/include/forced_induction_node.h`, and examples `assets/engines/forced-induction/*.mr` (GM LS supercharged, EJ25 twin-scroll turbo, 2JZ-GTE, BMW B58, F1 2026 V6). The model is credited to `kyan0s-git/engine-sim` in the doc.
- Nitrous: no hits in FORK-KU's file list.
- DDev247 fork (`https://github.com/DDev247/engine-sim`, pushed 2026-08-19) links a "turbocharged version" release. Not inspected.

### 2.5 Impulse responses and sample format

Checked with Python `wave` on the repository WAVs (local copies in scratchpad):

| IR (path in repo) | Rate | Channels | Duration | Length with |x|>100 | Taps used (cap 10,000) |
|---|---|---|---|---|
| `es/sound-library/new/mild_exhaust_reverb.wav` (V8 default) | 44100 | 1 | 0.96 s | 10,103 | **10,000** |
| `assets/sound-library/smooth/smooth_39.wav` (W16 `default_0`) | 44100 | 1 | 0.76 s | 6,907 | 6,907 |
| `assets/sound-library/archive/test_engine_16_eq_adjusted_16.wav` | 44100 | 1 | 0.51 s | 14,430 | 10,000 |
| `es/sound-library/new/mild_exhaust.wav` | 44100 | 1 | 0.22 s | 1,893 | 1,893 |
| `es/sound-library/sharp/sharp_01.wav` | 44100 | 1 | 0.27 s | 2,022 | 2,022 |
| `es/sound-library/new/minimal_muffling_01.wav` | 44100 | 1 | 0.40 s | 5,979 | 5,979 |

Synthesizer cap: `src/synthesizer.cpp:99` `const unsigned int sampleCount = std::min(10000U, clippedLength);`. Format: 16-bit mono PCM, read as `int16_t` (`src/synthesizer.cpp:86-105`).

### 2.6 Synthesizer / sample rates / threading (UP `src/synthesizer.cpp`, `src/simulator.cpp`)

- Output: 44,100 Hz, `int16_t` samples. `Simulator::initializeSynthesizer()` sets `audioSampleRate = 44100`, `audioBufferSize = 44100`, `inputBufferSize = 44100` (`src/simulator.cpp:204-212`).
- Input: one channel per exhaust system (`inputChannelCount = getExhaustSystemCount()`, line 209). Sim writes at simulation frequency (e.g. 10 kHz) and the synth resamples by linear interpolation (`writeInput`, `src/synthesizer.cpp:168-195`) then applies a Butterworth anti-alias at **1900 Hz** on input (`src/synthesizer.cpp:73`) and the output anti-alias at 0.45 x sample rate (line 79).
- Per output sample: jitter filter, DC filter, derivative, air-noise high-pass (uses `rand()`, lines 288, 298), then convolution (`m_filters[i].convolution.f(v_in)`, line 312), sum over channels, anti-alias, loudness/peak leveler, clip to int16 (lines 281-331).
- Convolution is direct form, O(N) per sample: `src/convolution_filter.cpp:37-46` loops over all taps with a float reduction. With no `-ffast-math`, a compiler will not vectorize this reduction. Expect scalar cost unless rewritten (e.g. partitioned FFT with Accelerate/vDSP). This is reasoning from the code, not a measurement.
- Threading (UP): `Synthesizer::startAudioRenderingThread()` creates a `std::thread` (`src/synthesizer.cpp:107-110`). The render thread waits on a condition variable and keeps a reservoir of up to 2,000 samples (`renderAudio()` lines 222-256). The consumer calls `readAudioOutput(samples, buffer)` under a mutex (lines 141-159).
- Real-time hazard: consumer under a mutex inside an iOS audio render callback can cause priority inversion. FORK-OE replaces this with `SpscAudioRing` and `renderRealtimeAudio` for the browser worklet; reuse that pattern on iOS.
- Latency control: `Simulator::startFrame(dt)` adjusts the step count by feedback on synth input latency (target 0.1 s, `src/simulator.cpp:12`, `74-86`: multiplies steps by 1.1 or 0.9). The sim is therefore paced by the audio consumer.

### 2.7 CPU and memory estimates (reasoned, NOT measured)

Per 1 s of real time, V8 (F136 script, 10 kHz, 8 fluid substeps, 2 exhaust channels):
- Physics: 10,000 rigid steps/s; fluid: `m_fluidSimulationSteps = 8` (`src/piston_engine_simulator.cpp:26`, `302-318`) gives 80,000 gas-dynamics substeps/s, each touching 8 chambers, 2 exhaust systems and 1 intake. That is about 640,000 chamber updates/s.
- Convolution: 2 channels x 10,000 taps x 44,100 = **882 MMAC/s** (float, scalar unless rewritten).

W16 (FORK-KU `vw_w16.mr`, 16 cylinders, 4 banks, 5,000 Hz, `default_0` IR = 6,907 taps, 2 exhaust systems):
- Physics: 5,000 rigid steps/s; fluid 40,000 substeps/s x 16 chambers = about 640,000 chamber updates/s (same order as V8).
- Convolution: 2 x 6,907 x 44,100 = **609 MMAC/s**.

Summary: both engines cost about the same in physics and convolution per second of audio. Convolution alone is roughly 0.6-0.9 GMAC/s scalar. A single iPhone performance core may not sustain that with headroom for physics, so plan for either fewer taps (truncate IR to ~2,000 taps; the 1,900-2,000-tap IRs are already in the repo) or FFT-based convolution.

Memory (computed from the code): per exhaust channel, input ring 44,100 floats (176 KB), convolution buffers 2 x 10,000 floats (80 KB), output ring 44,100 int16 (88 KB). Total synth state for 2 channels is a few MB. Asset bundle 6.5 MB for `assets/` plus `es/` 0.55 MB.

Upstream data point: issues report poor real-time behaviour on desktop hardware (see 4.2), so these estimates are if anything optimistic.

---

## 3. Synthesizer / audio output design detail (what to reuse)

- Core output is plain `int16_t` PCM at 44.1 kHz. There is no device code in the core.
- Upstream app uses `ysAudio` (delta) to create a looping `ysAudioSource` fed by `readAudioOutput` (`src/engine_sim_application.cpp:169-184`, `253-305`). That is Windows/DirectX-era code. Replace with `AVAudioSourceNode` (or an `AudioUnit` render callback) pulling from an SPSC ring that the sim thread fills.
- Keep the simulation on its own thread and the audio callback wait-free. FORK-OE's `include/spsc_audio_ring.h` (lines 1-60, "bounded, preallocated single-producer/single-consumer queue") fits. `discard()` lets the consumer fast-forward to the newest state.
- FORK-OE `include/audio_output.h` is the right abstraction: `AudioOutput::start(Simulator*)`, `loadImpulseResponse(Synthesizer&, path, volume, index)`, `stop()`, `outputSampleRate()` (default 44,100; "Browser hosts may expose a different fixed device clock and override this"). An iOS host implements it with AVAudioEngine.

---

## 4. Driving it from outside

### 4.1 Setting rpm / throttle / load (UP)

- Throttle: `Engine::setThrottle(double)` sets each intake's throttle value (`src/engine.cpp:147-151`); `Engine::setSpeedControl(double)` forwards to the engine's throttle object (`src/engine.cpp:139-141`). Engine `update(dt)` calls `m_throttle->update(dt, this)` (line 301-303). Default throttle: direct linkage with gamma (objects.mr).
- Governor (speed control): `src/governor.cpp:36-70` drives throttle to hold a target speed via `engine->getSpeed()`.
- Dynamometer (load / rpm hold): `Dynamometer` is an scs `Constraint` (`include/dynamometer.h`, `src/dynamometer.cpp`). Fields `m_enabled`, `m_hold`, `m_rotationSpeed` (velocity bias), `m_maxTorque` (default 10,000 ft-lb, line 11), `m_ks`, `m_kd`. `calculate()` (lines 25-49) sets a velocity bias and torque limits: when `m_hold && m_enabled`, the dyno can motor the crank in both directions; otherwise the limits depend on direction. This is a torque-limited velocity hold, not an exact rpm setter and not an arbitrary torque injector.
- Application controls use these: `src/engine_sim_application.cpp:818-838` toggles `m_dyno.m_enabled`/`m_hold`, and `m_dynoSpeed` clamps to `[dynoMinSpeed, dynoMaxSpeed]` (line 770).
- Starter: `StarterMotor` constraint, `m_enabled`, `m_maxTorque`, `m_rotationSpeed` (`include/starter_motor.h`).
- Ignition: `IgnitionModule::m_enabled` (`src/ignition_module.cpp:56`).
- Telemetry readbacks: `Engine::getRpm()` (`src/engine.cpp:398-401`, from `crankshaft[0].m_body.v_theta`), `Simulator::getFilteredDynoTorque()` (average of 512 samples, `src/simulator.cpp:183-192`), `getDynoPower()` (line 194-198), `Engine::getIntakeAfr()` (`engine.cpp:314`).
- Load: the physical alternative is the vehicle + gearbox model (`Vehicle::Parameters`: mass, drag coefficient, cross-section, diff ratio, tyre radius, rolling resistance; `Transmission` with gear ratios and clutch torque; `include/vehicle.h`, `include/transmission.h`). The app's defaults are at `src/engine_sim_application.cpp:645-662`.

### 4.2 Fixed-dt stepping and audio pull (UP)

- `Simulator::simulateStep()` (`src/simulator.cpp:95-153`) performs one physics step with `timestep = 1 / simulationFrequency` (`include/simulator.h:60`), then writes exhaust pulses to the synthesizer (`writeToSynthesizer`).
- `Simulator::startFrame(dt)` (lines 64-93) sets `m_steps = round(dt * speed / timestep)` and then applies the latency feedback described in 2.6. For strict fixed-dt, either disable that feedback in our copy or drive `m_steps`/`m_currentIteration` ourselves. Not verified.
- Audio pull: `Simulator::readAudioOutput(int, int16_t*)` (`include/simulator.h:41`, `src/simulator.cpp:159-161`) forwards to `Synthesizer::readAudioOutput`. `Synthesizer::renderAudio()` (void) is public (`include/synthesizer.h`, line 79) but blocks on a condition variable until the render thread is needed; without a thread, its behaviour was not verified.
- Upstream issues show the frame loop is wall-clock driven (`src/engine_sim_application.cpp:235-239`: `startFrame(1 / avgFramerate)` then loop `simulateStep()`).

### 4.3 Can we make the sim follow OUR dyno model?

Short answer: not directly. There is no API to inject an arbitrary external torque. Options:

A. **Engine-sim as authority** (recommended first spike). Set throttle; let combustion and rotational inertia decide rpm; read rpm and dyno torque back. This is how the app works when the dyno is off. Our Swift dyno uses the sim's torque as its input. Risk: our tuning/damage logic must accept the sim's rpm dynamics.

B. **Our model as authority, via dyno hold**. Set `m_enabled=true`, `m_hold=true`, `m_rotationSpeed = target_rpm`. The sim holds rpm with a torque-limited velocity constraint and reports the torque needed. Usable for steady-state points; not exact at transients; clamped at `m_maxTorque` (issue #429: "Torque caps out at 10000 lb-ft in dynamometer", closed 2023-06-10, shows a 10,000 lb-ft cap that acts like a slipping clutch).

C. **Physical load** via `Vehicle`/`Transmission` (gears, mass, drag, rolling resistance). Parameterize identically to our model and let the sim produce the load.

D. **Patch** a new scs constraint that applies a commanded torque (e.g. a `Constraint` with equal lower/upper limits `T` and no velocity bias). This is an idea from reading `Constraint` usage (`src/dynamometer.cpp`, `src/starter_motor.cpp`); **not verified** and would need a spike.

Recommendation: A for sound and rpm dynamics, with our Swift model consuming rpm/torque, and check whether C matches our load model closely enough before attempting D.

### 4.4 Existing headless / decoupled APIs (forks)

- **FORK-KU `game_audio::EngineSession`** (`include/game_audio/engine_session.h`, 142 lines, read in full). This is the closest existing decoupled API:
  - `create(SessionConfig{scriptPath, searchPaths, simulationFrequency, starterRpm, crankThrottle}, &error)`
  - `setThrottle(target)` (follows target with a time constant), `setThrottleImmediate`, `setIgnition(bool)`, `setStarter(bool)`, `setDynoHold(rpm)`, `releaseDyno()`
  - `advance(seconds, std::vector<float>* audio, std::vector<TelemetrySample>* telemetry)` and `advanceUntil(condition, timeout, ...)`; block = 1/250 s; `TelemetrySample{time, audioSample, rpm, throttle, dynoTorque}`; audio at 44,100 Hz "without a window, audio device or audio thread".
  - Header comment: "Creation is serialized internally because the script compiler keeps global state."
  - It still links `engine-sim` which links `delta-basic` (FORK-KU `CMakeLists.txt:163`; `engine-sim-game-audio` links `engine-sim` at lines 459-462). So **not delta-free**. Its logic is reusable; its build is not.
- **FORK-KU `engine-sim-export`** (`src/game_audio/export_main.cpp`, `docs/game-audio-export.md`): "The physics runs offline, without a window or audio device." Dyno holds rpm for seamless loops (`--onload-throttle`, `--offload-throttle`). Reported cost: "A full set (29 clips, 1000-6000 rpm in 500 rpm steps) takes about 40 seconds on a 16-thread CPU." Also a UDP rpm input (`RPM_SYNC.md`: `127.0.0.1:8765`, plain-text rpm packets, applied through dyno hold, throttle full). Not an in-process API but proves external rpm control works.
- **Talhasarac/engine-sim-sound-exporter** (`https://github.com/Talhasarac/engine-sim-sound-exporter`, MIT, pushed 2026-04-13): "loads an `.mr` engine script, runs the simulation headless, and writes 44.1 kHz, 16-bit, mono WAV files" plus a Unity manifest. Source `src/audio_export_main.cpp` (uses `include/engine.h`, `simulator.h`, `transmission.h`, `vehicle.h`, `scripting/include/compiler.h`). Proves a headless loop on upstream code.
- **FORK-OE** `include/audio_output.h` / `spsc_audio_ring.h` / `renderRealtimeAudio` — device-independent output seam (section 3); no offline exporter.
- Upstream: no headless API; `Simulator`/`Synthesizer` are usable in-process but the app is the only driver.

---

## 5. Licence compliance

### 5.1 Code

- Upstream `LICENSE`: MIT, `Copyright 2022 AngeTheGreat (Ange Yaghi)`, full text. For binary distribution keep the copyright and permission notice in the app's licence/acknowledgements screen (MIT: "shall be included in all copies or substantial portions of the Software").
- Submodules per GitHub API `license` field: `delta-studio` MIT, `simple-2d-constraint-solver` MIT, `csv-io` MIT, `piranha` MIT. **Not read**: their LICENSE text. Copy the text when shipping.
- FORK-OE and FORK-KU: both state they preserve the upstream MIT licence. Use the fork's `LICENSE` plus the upstream copyright line.
- Excluded from iOS build: `dependencies/discord/lib/discord-rpc.lib` (prebuilt binary; its licence not checked here).
- No copyleft in the chain reviewed. MIT permits commercial use.

### 5.2 Assets (unknown; ask)

- The repository `LICENSE` covers "the Software". No licence file for `assets/`, `es/sound-library/` (the WAVs), or the engine `.mr` scripts was found in the upstream tree or READMEs.
- Engine scripts and IRs were produced by the author for his videos (per the atg-video READMEs). The Community Edition README says the author chose a paid model for the newer app and cites third parties using the work "pretending that it was actually their own creation" — indicating he cares about attribution, but it does not license the assets.
- FORK-KU `COMMUNITY.md` credits engine scripts to individual contributors (e.g. VW W16 and I3/Lamborghini/Viper entries) with no licence stated for any of them.
- **Unknown**: whether the IR WAVs (which look like recordings or derived captures: `test_engine_*` and `archive/`) may be redistributed in a commercial app. Ask the author (the Community Edition README points to his Discord server and YouTube channel) or replace them with IRs we record or generate.
- Recommendation: do not ship the upstream WAVs or the community `.mr` scripts until licensing is confirmed. Build a minimal engine (e.g. our own script, or a script written from scratch) for the first spike.

### 5.3 Naming and trademarks

- The App Store app "Engine Simulator" (`id6772016143`) states it is an "unofficial port ... not affiliated with, endorsed by, or supported by AngeTheGreat". Do not use "Engine Simulator" as our product name. Do not copy that app's assets or text.

---

## 6. Plan, top risks, sizing

### 6.1 Ordered plan to prove feasibility

Step 0 (no iOS yet, ~1 CI run): host macOS arm64 smoke test.
1. Create `Native/EngineSimCore/` with: a pinned git submodule or vendored copy of FORK-OE (preferred) **or** upstream at `85f7c3b` with patches B1-B4 applied via a `patch` step. Record the SHA.
2. Write `Native/EngineSimCore/CMakeLists.txt` that lists the core sources (no gtest, no delta, no app), builds `scs` with `-include <cstring>` and `-D__forceinline=inline`, builds the Piranha interpreter (FLEX/BISON from brew), and exposes a `EngineSimCore` static library.
3. Add a tiny host executable `esim_render` (C ABI) that loads `assets/main.mr` (or one engine), sets throttle 0.3, holds 3,000 rpm via dyno, runs 10 s, writes `out.wav`. Run it on `macos-15` (arm64). Upload `out.wav` and a log of wall-clock time per simulated second as an artifact. This proves the physics and synth compile and run.
4. Record: CPU seconds per simulated second, peak RSS, rpm settling time.

Step 1: iOS arm64 static library.
5. Same CMake with `-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphoneos -DCMAKE_OSX_ARCHITECTURES=arm64` (section 1.6). Generate with `-G Xcode` or Ninja; `cmake --build ... --target EngineSimCore`. Check `lipo -info` and `nm` for undefined symbols (`delta`, `ysX`, `SDL`).
6. Also build the `iphonesimulator` slice and run the host test inside the simulator if the runner supports it (`xcrun simctl`); this gives a runtime test without a device.

Step 2: Xcode integration via XcodeGen (`Native/project.yml`).
7. `project.yml` targets: `EngineSimCore` (external, built by a pre-build script that runs the CMake command, or consumed as a prebuilt `.a` artifact from step 5), and the iOS app target with `OTHER_LDFLAGS: -lc++`, `HEADER_SEARCH_PATHS` to the C header, a bridging header or module map, and `Resources` containing `assets/` (copied at build time, not referenced from the repo root).
8. Swift side: a single `final class EngineSimBridge` calling the C ABI: `create(scriptPath, searchPath)`, `setThrottle`, `setDynoHold`, `setIgnition`, `setStarter`, `advance(seconds, int16 buffer)`, `rpm()`, `dynoTorque()`.
9. Audio: `AVAudioEngine` + `AVAudioSourceNode` pulling from an SPSC ring filled by a sim thread (section 3). `AVAudioSession` category `.playback`.

Step 3: device validation (requires a physical iPhone; CI cannot measure it).
10. TestFlight or ad-hoc build installed on a phone (the user). Measure: sustained real-time factor at 3,000 rpm and 6,000 rpm, underruns per minute, thermal state after 5 min, battery drain, app memory. **Gate:** sustained real-time factor >= 1.5x with no audio underruns, otherwise reduce sim frequency / IR taps / cylinders.

Decision point after step 3: go / no-go on upstream-based core vs writing our own simplified synthesizer.

### 6.2 Top 5 risks

1. **Phone CPU budget.** Convolution (609-882 MMAC/s scalar) plus 80k gas substeps/s (V8) may not fit a phone core with headroom, and no mobile benchmark of engine-sim exists publicly (see 4.5). Mitigations: lower simulation frequency (W16 uses 5 kHz), truncate IRs to ~2,000 taps, FFT convolution (Accelerate), profile with Instruments on device, cut cylinders for first release. Likelihood high; impact high.
2. **Upstream maintenance and provenance.** Upstream stopped in 2024 (COMMUNITY.md), 144 open issues, the author moved his newer app to closed source. The MIT base is fine, but there is no upstream to send fixes to, and the fork landscape is churning (FORK-OE created 2026-08, FORK-KU created 2026-11-16). Mitigation: pin a SHA; keep a patch series; avoid depending on either fork's non-core code.
3. **Assets and attribution.** No licence for WAVs or engine scripts; community scripts with no stated licence. Shipping them could infringe. Mitigation: confirm with the author or ship only our own engines/IRs (section 5.2). Likelihood medium-high; impact high (App Store removal or claim).
4. **Control-model mismatch.** The sim owns rpm dynamics; the dyno is a torque-limited velocity hold (`dynamometer.cpp:39-48`), not a torque input. Our Swift dyno model may disagree (idle, transients, clutch). Also `Simulator::startFrame` latency feedback couples sim speed to audio consumption, which breaks deterministic offline runs. Mitigation: spike option A and C first; if needed, write the small scs constraint patch (option D); add a fixed-step driver modelled on FORK-KU `EngineSession::advance`.
5. **Build and runtime surprises on iOS.** Piranha generated parsers need host Flex/Bison (Apple's bison is 2.3); Piranha compile of `.mr` at runtime may be slow on device and the compiler "keeps global state" (FORK-KU); scs force-include and `__forceinline` fixes; IR path resolution (B9). Also no iOS build exists anywhere to copy from. Mitigation: first spike on macOS host (step 0) before iOS; measure script compile time on device; pre-compile/cache if slow.

Honourable mention: we cannot listen in CI. A human must judge the sound. Plan a listening test with the user on a phone.

### 6.3 Size and CPU estimates (reasoned from source, not measured)

| | V8 (`08_ferrari_f136_v8`) | W16 (`vw_w16`, FORK-KU) |
|---|---|---|
| Cylinders / banks / exhaust systems | 8 / 2 / 2 | 16 / 4 / 2 |
| Sim frequency | 10,000 Hz | 5,000 Hz |
| Gas-dynamics substeps/s (x8) | 80,000 | 40,000 |
| Chamber updates/s | ~640,000 | ~640,000 |
| IR taps per exhaust channel | 10,000 (capped) | 6,907 |
| Convolution MAC/s (2 channels, 44.1 kHz) | 882 M | 609 M |
| Synth state | a few MB | a few MB |
| Engine script `.mr` size | 15 KB (F136, `08_ferrari_f136_v8.mr`) | not measured |
| Static core lib size on iOS | not measured (no iOS build) | not measured |

Realistic expectation: both are at or above what a single phone core can run at 1x real time in scalar code. Target: at least one phone performance core fully dedicated, or reduced sim frequency and IR length. This is a reasoning estimate; do not quote it as a benchmark.

Data points from upstream/FORK-KU (not phones):
- Issue #392 (2022-12-05): "Ran smooth up to 50kHz simulation frequency on the 2-cyl ... model", later "it can barely run the 454 V8" with degraded performance (desktop).
- Issue #111 (2022-08-16, open): Ryzen 5 2600 + RX 560 "performing very bad on 2+ cylinders".
- Issue #381 (2022-11-09, open): i9-7960X + RTX 2080 Ti "unusable even with simfreq all the way down".
- FORK-KU: 29 clips (1000-6000 rpm) in about 40 s on a 16-thread CPU, offline.

### 6.4 Phone performance data that exists publicly

- The App Store app "Engine Simulator" (id6772016143): free with IAP ("Lifetime $8.99"), iOS 18.6+, 308 ratings, 4.4 average. Listing text claims "The sound and motion come from a real rigid body simulation of the crank, pistons, valves, and combustion, not recordings" and "live power and torque on the dyno". No frame-rate, CPU, battery or latency figures are published. The listing says it is an "unofficial port" but does not say it reuses engine-sim code. **So it is evidence that a physics-based engine sim can run on iPhone, not evidence of engine-sim's cost.** (Source: `https://apps.apple.com/us/app/engine-simulator/id6772016143`, read 2026-11-18.)
- No Reddit or other user benchmark found (search tool returned none).
- No Android port found (issue #458, 2025-09-12: user asks for Android; Winlator crashes). No WebAssembly in upstream (issue #428 open since 2023-06-06), but FORK-OE ships one (`cmake/EngineSimWeb.cmake`, WebAssembly + WebGL 2 + AudioWorklet, CI-validated on ubuntu).
- Issue #447 (2024-07-26, open, 13 comments): "will this be added for mobile" — no official answer found.
- Issue #20 (2022-08-10, open): Godot port interest; no port found.

---

## 7. Issues and forks: quick map

| Topic | Item | URL |
|---|---|---|
| Mobile request | #447 "will this be added for mobile" (2024-07-26, open) | `https://github.com/ange-yaghi/engine-sim/issues/447` |
| Android request | #458 (2025-09-12, open) | `https://github.com/ange-yaghi/engine-sim/issues/458` |
| WASM request | #428 "Webassembly and browser support" (2023-06-06, open) | `https://github.com/ange-yaghi/engine-sim/issues/428` |
| Headless record request | #49 "run sim out of realtime and record results to wav" (2022-08-12, open) | `https://github.com/ange-yaghi/engine-sim/issues/49` |
| Multithreading idea | #87 (closed 2023-05-05) | `https://github.com/ange-yaghi/engine-sim/issues/87` |
| Audio latency | #392 (open), #243/#307 (closed) | `https://github.com/ange-yaghi/engine-sim/issues/392` |
| Torque cap | #429 "Torque caps out at 10000 lb-ft in dynamometer" (closed 2023-06-10) | `https://github.com/ange-yaghi/engine-sim/issues/429` |
| Performance | #31, #111, #381 (open), #194 (closed: ~15% CPU, stutter) | `https://github.com/ange-yaghi/engine-sim/issues/111` |
| Linux build | #421, #2 (open) | `https://github.com/ange-yaghi/engine-sim/issues/421` |
| Win-only build error | #437 `LNK1104` (open) | `https://github.com/ange-yaghi/engine-sim/issues/437` |

Forks with platform work (MIT):
- FORK-OE (iOS: none; WASM, macOS arm64, Linux, Windows): `https://github.com/carlesonielfa/open-engine-sim`
- FORK-KU (exporter, forced induction, ~100 engines, RPM sync; delta still linked): `https://github.com/kadaxo/engine-sim-community-ultimate`
- `boxofbox/engine-sim-APPLE_ARM` (2023-01, macOS arm64 build notes, delta): `https://github.com/boxofbox/engine-sim-APPLE_ARM`
- `tjvjk/engine-sim-macos` (2026-01, macOS arm64, delta): `https://github.com/tjvjk/engine-sim-macos`
- `Talhasarac/engine-sim-sound-exporter` (2026-04, headless WAV export): `https://github.com/Talhasarac/engine-sim-sound-exporter`
- `DDev247/engine-sim` (turbo release link, pushed 2026-08-19): `https://github.com/DDev247/engine-sim`
- `Engine-Simulator/engine-sim-community-edition` (closed-source distribution, 3,060 stars, do not use code): `https://github.com/Engine-Simulator/engine-sim-community-edition`

Not found: any Unity, Godot, Android or iOS runtime port of engine-sim with source. The Unity connection is only the Talhasarac offline exporter.

---

## 8. Community engine scripts (what exists)

From FORK-KU `assets/engines/` (MIT fork; credits in `COMMUNITY.md`):
- **W16**: `atg-video-2/vw_w16.mr` ("VAG 8.0 W16", 16 cylinders, 4 banks, 5,000 Hz). Credit: Evert Jans (ejans) per COMMUNITY.md.
- **V10**: `atg-video-2/10_lfa_v10.mr` (upstream, LFA 1LR-GUE), `custom/dodge_viper_v10_8_4l.mr`, `custom/lamborghini_v10_5_2l.mr`, `maximumqc/TJv10.mr` (Cosworth TJ V10).
- **Flat-6 / boxer**: `custom/porsche_tt_flat6_3_8l.mr`, `porsche/B6_4.0L.mr`, `atg-video-2/porsche_993.mr`, `subaru/boxer.mr`.
- **I3 / I5 / I7**: `atg-video-2/the_i3.mr`, `custom/I3_5_7.mr`, `custom/I5I4.mr`.
- **V6 variants**: upstream `04_60_degree_v6`, `05_odd_fire_v6`, `06_even_fire_v6`; community `atg-video-2/04_60_degree_big_bang_v6.mr`.
- **Forced induction**: `forced-induction/*.mr` (listed in 2.4).
- **Others**: steam (`steam/*.mr`), small singles (`atg-video-2/25cc.mr`, `50cc.mr`), V12 (`kohler/kohler_V12.mr`, `dacxl/Lamborghini_6_5.mr`), tanks/trucks/cars. Full list was taken from the FORK-KU tree (`git/trees` API, 529 files).
- **Rotary / Wankel**: no script found by file name (grep of the full FORK-KU file list for `rotary|wankel`: none).
- **Flat-plane V8**: none found by file name. The upstream video title mentions flat-plane V8s; the script files were not checked for that layout.

Upstream bundled set is the 25 in 2.2. The Community Edition app bundles more but is closed.

---

## 9. What I did not check

- Compiling anything (host, iOS or simulator). Every buildability claim is from reading.
- The scs and piranha full source (only file lists and key CMake lines were read). Piranha's `include/path.h` uses `std::filesystem` (`getBoostPath()` naming is historical).
- The delta-studio LICENSE text and the csv-io/piranha/scs LICENSE text (only API licence field).
- The W16 script beyond cylinder count, banks, IR and sim frequency.
- How `Synthesizer::renderAudio()` behaves single-threaded (needed for offline rendering). Read, not executed.
- Whether DDev247's turbo fork or boxofbox/tjvjk macOS forks change core physics or synth.
- Exact convolution performance on ARM (no benchmark).
- Whether the IR WAVs in `es/sound-library/new` load via the upstream path rules (B9).
- Engine-sim GitHub issues beyond the keyword searches above. During the keyword batch, the searches for `mobile`, `linux`, `macos` and `arm` returned HTTP 403 (rate limit), so those terms are not covered; `raspberry`, `headless` and `unity` returned 0 matches.
- Reddit: the search tool returned no Reddit results for this topic.

## 10. Sources used (URLs)

- Upstream repo: `https://github.com/ange-yaghi/engine-sim` (commit `85f7c3b959a908ed5232ede4f1a4ac7eafe6b630`)
- Upstream files: `CMakeLists.txt`, `dependencies/submodules/CMakeLists.txt`, `.gitmodules`, `.github/workflows/cmake.yml`, `LICENSE`, `README.md`, `configuration/delta.conf`, `include/delta.h`, `include/synthesizer.h`, `src/synthesizer.cpp`, `src/simulator.cpp`, `include/simulator.h`, `src/piston_engine_simulator.cpp`, `src/intake.cpp`, `src/engine.cpp`, `include/engine.h`, `src/governor.cpp`, `src/dynamometer.cpp`, `include/dynamometer.h`, `src/ignition_module.cpp`, `src/convolution_filter.cpp`, `src/impulse_response.cpp`, `src/engine_sim_application.cpp`, `src/main.cpp`, `assets/main.mr`, `assets/engines/atg-video-1/README.md`, `assets/engines/atg-video-2/README.md`, `assets/engines/atg-video-2/08_ferrari_f136_v8.mr`, `es/objects/objects.mr`, `es/sound-library/impulse_responses.mr`
- FORK-OE: `https://github.com/carlesonielfa/open-engine-sim` (README, `CMakeLists.txt`, `cmake/EngineSimWeb.cmake`, `cmake/EngineSimScripting.cmake`, `cmake/EngineSimLegacySolverCompatibility.h`, `include/audio_output.h`, `include/spsc_audio_ring.h`, `include/synthesizer.h`, `src/synthesizer.cpp`, `.github/workflows/cmake.yml`)
- FORK-KU: `https://github.com/kadaxo/engine-sim-community-ultimate` (README, `COMMUNITY.md`, `docs/game-audio-export.md`, `docs/forced-induction.md`, `RPM_SYNC.md`, `include/game_audio/engine_session.h`, `CMakeLists.txt`, `assets/engines/atg-video-2/vw_w16.mr`)
- Talhasarac exporter: `https://github.com/Talhasarac/engine-sim-sound-exporter`
- Community Edition: `https://github.com/Engine-Simulator/engine-sim-community-edition`
- App Store listing: `https://apps.apple.com/us/app/engine-simulator/id6772016143`
- Piranha: `https://github.com/ange-yaghi/piranha` (`CMakeLists.txt`, `include/path.h`, `src/path.cpp`)
- scs: `https://github.com/ange-yaghi/simple-2d-constraint-solver` (`CMakeLists.txt`, `include/*.h`, `src/*.cpp`)
- Issues: `https://github.com/ange-yaghi/engine-sim/issues/{20,31,49,87,111,194,381,392,428,429,447,458}`
- Search (WebSearch tool): App Store and general web results only; no Reddit threads; no headless API docs found.
