#!/bin/sh
# Throwaway spike (branch spike/engine-sim-ios): prepare an upstream engine-sim checkout so its
# sound core builds without the Windows app, delta-studio or Boost.
#
#   prepare.sh <engine-sim checkout> <output dir for generated parser files>
#
# Every edit below is one of the blockers found in docs/research/raw/engine-sim-ios.md, plus one
# the research missed: piranha (the script loader) uses boost::filesystem.
set -eu
ES="$1"
GEN="$2"
mkdir -p "$GEN"

# B1: the synthesizer includes delta-studio but uses nothing from it.
sed -i.bak '/#include "..\/include\/delta.h"/d' "$ES/src/synthesizer.cpp"

# New: piranha's Path wraps boost::filesystem. std::filesystem has the same calls.
P="$ES/dependencies/submodules/piranha"
sed -i.bak 's#<boost/filesystem.hpp>#<filesystem>#; s#boost::filesystem#std::filesystem#g; s#is_complete()#is_absolute()#' "$P/src/path.cpp"
# path.h forward-declares boost::filesystem::path; replace the whole block with the real header.
python3 - "$P/include/path.h" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
s = re.sub(r"// Forward Boost declaration\nnamespace boost \{.*?\} /\* namespace boost \*/\n",
           "#include <filesystem>\n", s, flags=re.S)
s = s.replace("boost::filesystem", "std::filesystem")
open(p, "w").write(s)
PY

# New (clang is stricter than MSVC): gas_system.h uses `const Mix &mix = {}` as a default
# argument while Mix, a nested struct with default member initializers, is still being defined.
# Replace those defaults with overloads that are defined after the class.
python3 - "$ES/include/gas_system.h" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
pairs = [
 ("void initialize(double P, double V, double T, const Mix &mix = {}, int degreesOfFreedom = 5);",
  "void initialize(double P, double V, double T, const Mix &mix, int degreesOfFreedom);\n"
  "        void initialize(double P, double V, double T);\n"
  "        void initialize(double P, double V, double T, const Mix &mix);"),
 ("void reset(double P, double T, const Mix &mix = {});",
  "void reset(double P, double T, const Mix &mix);\n        void reset(double P, double T);"),
 ("double gainN(double dn, double E_k_per_mol, const Mix &mix = {});",
  "double gainN(double dn, double E_k_per_mol, const Mix &mix);\n        double gainN(double dn, double E_k_per_mol);"),
 ("double flow(double k_flow, double dt, double P_env, double T_env, const Mix &mix = {});",
  "double flow(double k_flow, double dt, double P_env, double T_env, const Mix &mix);\n"
  "        double flow(double k_flow, double dt, double P_env, double T_env);"),
]
for a, b in pairs:
    assert a in s, a
    s = s.replace(a, b)
tail = """
inline void GasSystem::initialize(double P, double V, double T) { initialize(P, V, T, Mix(), 5); }
inline void GasSystem::initialize(double P, double V, double T, const Mix &mix) { initialize(P, V, T, mix, 5); }
inline void GasSystem::reset(double P, double T) { reset(P, T, Mix()); }
inline double GasSystem::gainN(double dn, double E_k_per_mol) { return gainN(dn, E_k_per_mol, Mix()); }
inline double GasSystem::flow(double k_flow, double dt, double P_env, double T_env) { return flow(k_flow, dt, P_env, T_env, Mix()); }

"""
i = s.rfind("#endif")
s = s[:i] + tail + s[i:]
open(p, "w").write(s)
PY

# More MSVC-only habits found by compiling with clang (each is a tiny, behaviour-neutral edit):
#  - Windows backslashes inside #include paths
find "$ES/src" "$ES/include" "$ES/scripting" "$P/src" "$P/include" \( -name '*.cpp' -o -name '*.h' \) \
  -exec sed -i '/^[[:space:]]*#[[:space:]]*include/ s#\\#/#g' {} +
#  - the MSVC type name unsigned __int64
find "$P" "$ES/src" "$ES/include" "$ES/scripting" \( -name '*.cpp' -o -name '*.h' \) \
  -exec sed -i 's#unsigned __int64#unsigned long long#g; s#__int64#long long#g' {} +
#  - an upstream typo MSVC accepted: ring_buffer.h overwrite() says `start` for `m_start`
sed -i 's#if (start + index < m_capacity)#if (m_start + index < m_capacity)#' "$ES/include/ring_buffer.h"
#  - a template parameter shadowed by a member template of the same name
sed -i 's#template <typename Type>\n        void overrideType#&#' "$ES/scripting/include/object_reference_node.h"
python3 - "$ES/scripting/include/object_reference_node.h" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
a = "template <typename Type>\n        void overrideType() {\n            m_output.overrideType(LookupChannelType<Type>());"
b = "template <typename T_Override>\n        void overrideType() {\n            m_output.overrideType(LookupChannelType<T_Override>());"
assert a in s
open(p, "w").write(s.replace(a, b))
PY
#  - unqualified fpclassify
sed -i 's#\([^:_a-zA-Z]\)fpclassify(#\1std::fpclassify(#g' "$ES/src/synthesizer.cpp"

#  - `extern constexpr` in headers (units.h, constants.h) is one shared definition to MSVC but a
#    duplicate in every file to clang; `inline constexpr` means what the author intended
find "$ES/src" "$ES/include" "$ES/scripting" \( -name '*.cpp' -o -name '*.h' \) \
  -exec sed -i 's#extern constexpr#inline constexpr#g' {} +

# B5: generate the script parser once, on the host, with the same commands piranha's CMake uses.
(cd "$P" &&
  flex --header-file="$GEN/scanner.auto.h" -o "$GEN/scanner.auto.cpp" flex-bison/scanner.l &&
  bison --defines="$GEN/parser.auto.h" -o "$GEN/parser.auto.cpp" flex-bison/specification.y)

# Engine scripts for the test: one main file per engine so the app's loader can import them.
cd "$ES/assets"
for f in engines/atg-video-2/01_subaru_ej25_eh.mr engines/atg-video-2/08_ferrari_f136_v8.mr \
         engines/atg-video-2/10_lfa_v10.mr engines/atg-video-2/12_ferrari_412_t2.mr; do
  name=$(basename "$f" .mr)
  cat > "main_$name.mr" <<EOF
import "engine_sim.mr"
import "themes/default.mr"
import "$f"

use_default_theme()
main()
EOF
done
echo "prepared $ES"
