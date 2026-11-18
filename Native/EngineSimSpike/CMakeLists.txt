# Throwaway spike (branch spike/engine-sim-ios): engine-sim's sound core as a plain static
# library plus a headless command-line driver. No delta-studio, no Boost, no gtest, no Discord.
#
#   cmake -S Native/EngineSimSpike -B build -DES_SRC=<prepared engine-sim checkout> \
#         -DES_GEN=<dir from prepare.sh>
#
# On the Mac runner the same file is built for macOS arm64, the iOS simulator and an iPhone
# (CMAKE_SYSTEM_NAME=iOS), which is the whole point of the spike.
cmake_minimum_required(VERSION 3.20)
project(EngineSimSpike CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(ES_SRC "" CACHE PATH "prepared engine-sim checkout")
set(ES_GEN "" CACHE PATH "generated piranha parser sources")
if(NOT ES_SRC OR NOT ES_GEN)
  message(FATAL_ERROR "pass -DES_SRC and -DES_GEN")
endif()

set(SCS ${ES_SRC}/dependencies/submodules/simple-2d-constraint-solver)
set(PIR ${ES_SRC}/dependencies/submodules/piranha)

# B3: MSVC keyword used in three headers.
add_compile_definitions(__forceinline=inline)

# New (clang is stricter than MSVC): scs's sparse_matrix.h uses Matrix's members inside a
# template while Matrix is only forward-declared. Including matrix.h first everywhere fixes it.
add_compile_options(-include ${SCS}/include/matrix.h)

# ---- scs: the rigid-body solver (B4: it uses memcpy/memset without <cstring>) -------------
file(GLOB SCS_SOURCES ${SCS}/src/*.cpp)
add_library(scs STATIC ${SCS_SOURCES})
target_include_directories(scs PUBLIC ${SCS}/include)
target_compile_options(scs PRIVATE -include cstring)

# ---- piranha: the engine script language ---------------------------------------------------
file(GLOB PIR_SOURCES ${PIR}/src/*.cpp)
add_library(piranha STATIC ${PIR_SOURCES} ${ES_GEN}/scanner.auto.cpp ${ES_GEN}/parser.auto.cpp)
target_include_directories(piranha PUBLIC ${PIR}/include ${ES_GEN} ${PIR}/dependencies/libraries/flex/include)

# ---- engine-sim core (list copied from upstream CMakeLists.txt, app files left out) --------
set(CORE_NAMES audio_buffer camshaft crankshaft combustion_chamber connecting_rod convolution_filter
  cylinder_bank cylinder_head delay_filter derivative_filter direct_throttle_linkage dynamometer
  engine exhaust_system feedback_comb_filter filter fuel function gas_system gaussian_filter
  governor ignition_module impulse_response intake jitter_filter leveling_filter low_pass_filter
  part piston piston_engine_simulator simulator standard_valvetrain starter_motor synthesizer
  throttle transmission utilities valvetrain vehicle vehicle_drag_constraint vtec_valvetrain)
set(CORE_SOURCES "")
foreach(n ${CORE_NAMES})
  list(APPEND CORE_SOURCES ${ES_SRC}/src/${n}.cpp)
endforeach()
file(GLOB SCRIPT_SOURCES ${ES_SRC}/scripting/src/*.cpp)
add_library(enginesim_core STATIC ${CORE_SOURCES} ${SCRIPT_SOURCES})
target_include_directories(enginesim_core PUBLIC ${ES_SRC}/include ${ES_SRC}/scripting/include
  ${ES_SRC}/dependencies/submodules)
target_compile_definitions(enginesim_core PUBLIC ATG_ENGINE_SIM_PIRANHA_ENABLED)
target_link_libraries(enginesim_core PUBLIC scs piranha)

find_package(Threads REQUIRED)
add_executable(esim_render esim_render.cpp)
target_link_libraries(esim_render PRIVATE enginesim_core Threads::Threads)
