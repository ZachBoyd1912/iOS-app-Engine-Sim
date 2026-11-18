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
